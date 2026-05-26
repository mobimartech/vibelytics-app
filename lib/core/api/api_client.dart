import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'endpoints.dart';
import 'token_manager.dart';
import '../utils/app_logger.dart';

/// API Exception Types
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Unauthorized', statusCode: 401);
}

class InsufficientCreditsException extends ApiException {
  InsufficientCreditsException()
    : super('Insufficient credits', statusCode: 402);
}

class NotFoundException extends ApiException {
  NotFoundException() : super('Not found', statusCode: 404);
}

class NetworkException extends ApiException {
  NetworkException() : super('Network error - check your connection');
}

/// 413 Payload Too Large — emitted by Caddy (edge), no JSON envelope.
class PayloadTooLargeException extends ApiException {
  PayloadTooLargeException() : super('Payload too large', statusCode: 413);
}

/// Edge-emitted transient 5xx (502/503/504) — distinct from app 500.
/// Pollers should retry these up to 3× with backoff per api.md §8.
class TransientServerException extends ApiException {
  TransientServerException(int code)
      : super('Transient edge error', statusCode: code);
}

/// Vibelytics API Client
///
/// Dio client wrapper with automatic authentication handling.
/// - Adds Authorization header to all requests
/// - Automatically refreshes token pair on 401 (with rotation)
/// - Queues concurrent requests during refresh to avoid race conditions
/// - Returns typed exceptions for specific error cases
class ApiClient {
  ApiClient._() {
    _initDio();
  }
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  late final Dio
  _refreshDio; // Separate Dio for token refresh to avoid deadlock
  final TokenManager _tokenManager = TokenManager.instance;

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
      ),
    );

    // Create a separate Dio instance for token refresh (no interceptors)
    // This prevents deadlock with QueuedInterceptorsWrapper
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor in all modes for debugging
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        logPrint: (obj) {
          AppLogger.d(obj.toString());
        },
      ),
    );

    // Use QueuedInterceptorsWrapper so concurrent 401s queue up and wait
    // for the single refresh to complete, then all retry with the new token.
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenManager.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Only handle 401 errors for token refresh
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          // Skip refresh for auth endpoints themselves
          final path = error.requestOptions.path;
          if (path == Endpoints.authRefresh ||
              path == Endpoints.authSignup ||
              path == Endpoints.authLogin ||
              path == Endpoints.authOtpVerify) {
            handler.next(error);
            return;
          }

          AppLogger.d('Got 401, attempting token refresh...');

          try {
            final refreshed = await _refreshToken();
            if (refreshed) {
              AppLogger.i('Token refreshed, retrying original request');

              // Get new token and update the request
              final newToken = await _tokenManager.getAccessToken();
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';

              // Retry the original request with new token
              final response = await _refreshDio.fetch(opts);
              handler.resolve(response);
              return;
            }

            // Refresh failed — session is expired
            AppLogger.w('Token refresh failed, forcing logout');
            await _tokenManager.forceLogout();
            handler.next(error);
          } catch (retryError) {
            AppLogger.e(
              'Error during retry after token refresh',
              error: retryError,
            );
            if (retryError is DioException) {
              handler.reject(retryError);
            } else {
              handler.next(error);
            }
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HTTP METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    return _request(() => _dio.get(path, queryParameters: queryParams));
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request(() => _dio.post(path, data: body));
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request(() => _dio.put(path, data: body));
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request(() => _dio.patch(path, data: body));
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String path) async {
    return _request(() => _dio.delete(path));
  }

  /// POST request with extended timeout for long-running operations
  /// Use this for AI analysis, photo enhancement, etc.
  Future<Map<String, dynamic>> postLongRunning(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    return _request(
      () => _dio.post(
        path,
        data: body,
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
          headers: {'Connection': 'keep-alive', 'Keep-Alive': 'timeout=180'},
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTIPART UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload a file
  Future<Map<String, dynamic>> uploadFile(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalFields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
      ...?additionalFields,
    });

    return _request(() => _dio.post(path, data: formData));
  }

  /// Upload multiple files
  Future<Map<String, dynamic>> uploadFiles(
    String path,
    List<File> files, {
    String fieldName = 'files',
    Map<String, dynamic>? additionalFields,
  }) async {
    final multipartFiles = await Future.wait(
      files.map(
        (file) => MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      ),
    );

    final formData = FormData.fromMap({
      fieldName: multipartFiles,
      ...?additionalFields,
    });

    return _request(() => _dio.post(path, data: formData));
  }

  /// Upload files with extended timeout for long-running operations
  /// Use this for AI analysis uploads that trigger processing
  Future<Map<String, dynamic>> uploadFilesLongRunning(
    String path,
    List<File> files, {
    String fieldName = 'files',
    Map<String, dynamic>? additionalFields,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final multipartFiles = await Future.wait(
      files.map(
        (file) => MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      ),
    );

    final formData = FormData.fromMap({
      fieldName: multipartFiles,
      ...?additionalFields,
    });

    return _request(
      () => _dio.post(
        path,
        data: formData,
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
          headers: {'Connection': 'keep-alive', 'Keep-Alive': 'timeout=180'},
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _request(
    Future<Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn();
      return _handleResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      if (response.data == null || response.data == '') {
        return {'success': true};
      }
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {'data': response.data};
    }
    throw ApiException('Unexpected response', statusCode: response.statusCode);
  }

  Never _handleDioError(DioException error) {
    AppLogger.e('API Error: ${error.message}', error: error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 401:
            throw ApiException(
              _extractErrorMessage(
                error.response?.data,
                fallback: 'Unauthorized',
              ),
              statusCode: 401,
            );
          case 402:
            throw InsufficientCreditsException();
          case 404:
            throw NotFoundException();
          case 410:
            // Account deleted — force logout
            AppLogger.w('Account deleted (410 Gone)');
            _tokenManager.forceLogout();
            throw ApiException('Account has been deleted', statusCode: 410);
          case 413:
            // Caddy hard-cap (10MB) — empty body, no JSON envelope.
            throw PayloadTooLargeException();
          case 502:
          case 503:
          case 504:
            // Edge-emitted transient errors (Cloudflare/FrankenPHP). The
            // underlying job in the worker is unaffected — polling loops
            // should retry these per api.md §8.
            throw TransientServerException(statusCode!);
          default:
            String message = 'Request failed';
            message = _extractErrorMessage(
              error.response?.data,
              fallback: message,
            );
            throw ApiException(message, statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        throw ApiException('Request cancelled');

      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        if (error.error is SocketException) {
          throw NetworkException();
        }
        throw ApiException(error.message ?? 'Unknown error');
    }
  }

  String _extractErrorMessage(dynamic data, {required String fallback}) {
    try {
      if (data is Map) {
        final rawMsg = data['message'] ?? data['error'];
        return rawMsg is String ? rawMsg : rawMsg?.toString() ?? fallback;
      }
    } catch (e, st) {
      AppLogger.e(
        'Error extracting API error message',
        error: e,
        stackTrace: st,
      );
    }
    return fallback;
  }

  /// Refresh the token pair using the stored refresh token.
  ///
  /// The backend rotates tokens: both access_token and refresh_token
  /// are returned and the old refresh token is revoked.
  ///
  /// Uses a Completer mutex so concurrent callers reuse the same
  /// in-flight refresh request instead of firing duplicates.
  Completer<bool>? _refreshCompleter;

  Future<bool> _refreshToken() async {
    // If a refresh is already in-flight, reuse it
    if (_refreshCompleter != null) {
      AppLogger.d('Token refresh already in-flight, waiting...');
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final result = await _doRefreshToken();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e, stackTrace) {
      AppLogger.e('Token refresh wrapper failed', error: e, stackTrace: stackTrace);
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _doRefreshToken() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.w('No refresh token available');
        return false;
      }

      // Use separate Dio instance to avoid interceptor deadlock
      final response = await _refreshDio.post(
        Endpoints.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final tokens = data['tokens'] as Map<String, dynamic>?;

        final newAccessToken =
            tokens?['access_token']?.toString() ??
            data['access_token']?.toString();
        final newRefreshToken =
            tokens?['refresh_token']?.toString() ??
            data['refresh_token']?.toString();

        if (newAccessToken == null || newAccessToken.isEmpty) {
          AppLogger.e('Refresh response missing access_token');
          return false;
        }

        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _tokenManager.updateTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          AppLogger.i('Token pair rotated successfully');
        } else {
          await _tokenManager.updateTokens(
            accessToken: newAccessToken,
            refreshToken: refreshToken,
          );
          AppLogger.i('Access token refreshed (no rotation)');
        }

        return true;
      }

      AppLogger.w('Refresh returned status: ${response.statusCode}');
      return false;
    } catch (e) {
      AppLogger.e('Token refresh failed', error: e);
      return false;
    }
  }
}

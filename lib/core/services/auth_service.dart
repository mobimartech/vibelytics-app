import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../api/token_manager.dart';
import '../utils/app_logger.dart';
import 'purchase_service.dart';

/// Safely parse an int from a dynamic value (handles String, num, null).
int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely parse a double from a dynamic value (handles String, num, null).
double _toDouble(dynamic value, [double fallback = 0.0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely parse a bool from a dynamic value (handles String, num, null).
bool _toBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return fallback;
}

/// Authentication service for Vibelytics
///
/// Handles social login (Google, Apple), OTP authentication,
/// and token management.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final ApiClient _api = ApiClient.instance;
  final TokenManager _tokenManager = TokenManager.instance;

  // Google Sign-In configuration.
  //
  // The server client ID must be the Web OAuth client ID because the backend
  // verifies the Google ID token audience against this value.
  static const String _googleServerClientId =
      '866327749261-3dt34ouvjloev3euo36m4gep595vpqfq.apps.googleusercontent.com';
  static bool get isAppleSignInAvailable => Platform.isIOS || Platform.isMacOS;
  // Android OAuth client registered for package play.store.vibelytics.
  // This is not sent as requestIdToken(), but keeping it here makes runtime
  // diagnostics explicit when Google reports SHA/package configuration errors.
  static const String _googleAndroidClientId =
      '866327749261-ko6tp7r5h47vvaonbcuique231q32fgt.apps.googleusercontent.com';

  // Native method channel for Google Sign-In (bypasses broken CredentialManager)
  static const _googleAuthChannel = MethodChannel('vibelytics/google_auth');

  // Stored referral code to apply after signup
  String? _pendingReferralCode;

  /// Whether Google Sign-In is available on this platform
  static bool get isGoogleSignInAvailable =>
      Platform.isAndroid || Platform.isIOS;

  /// Set a referral code to be applied after successful signup
  void setPendingReferralCode(String? code) {
    _pendingReferralCode = code;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOOGLE SIGN IN (native method channel for Android)
  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  // APPLE SIGN IN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<AuthResult> signInWithApple() async {
    try {
      AppLogger.i('Apple Sign-In: Starting sign-in flow...');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      final userId = credential.userIdentifier;

      AppLogger.d(
        'Apple Sign-In: identityToken=${identityToken != null ? "present (${identityToken.length} chars)" : "null"}',
      );

      if (identityToken == null || identityToken.isEmpty) {
        AppLogger.e('Apple Sign-In: No identity token received');
        return AuthResult.error('auth.apple_no_token');
      }

      AppLogger.i(
        'Apple Sign-In: Token obtained, authenticating with backend...',
      );

      return await _authenticateWithBackend(
        provider: 'apple',
        providerToken: identityToken,
        providerId: userId,
      );
    } on SignInWithAppleAuthorizationException catch (e, stackTrace) {
      AppLogger.e(
        'Apple Sign-In authorization error: ${e.code} - ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );

      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.cancelled();
      }

      return AuthResult.error('auth.apple_error');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Apple Sign-In error: ${e.runtimeType} - $e',
        error: e,
        stackTrace: stackTrace,
      );
      return AuthResult.error('auth.apple_error');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      AppLogger.i('Google Sign-In: Starting sign-in flow...');

      if (Platform.isAndroid) {
        final result = await _googleAuthChannel
            .invokeMapMethod<String, dynamic>('signInWithGoogle', {
              'serverClientId': _googleServerClientId,
              'androidClientId': _googleAndroidClientId,
            });

        if (result == null) {
          return AuthResult.error('auth.google_error');
        }

        final idToken = result['idToken']?.toString();
        final userId = result['id']?.toString();

        if (idToken == null || idToken.isEmpty) {
          return AuthResult.error('auth.google_no_token');
        }

        return await _authenticateWithBackend(
          provider: 'google',
          providerToken: idToken,
          providerId: userId ?? '',
        );
      }

      if (Platform.isIOS) {
        await GoogleSignIn.instance.initialize(
          serverClientId: _googleServerClientId,
        );

        final account = await GoogleSignIn.instance.authenticate();

        final auth = account.authentication;
        final idToken = auth.idToken;

        if (idToken == null || idToken.isEmpty) {
          return AuthResult.error('auth.google_no_token');
        }

        return await _authenticateWithBackend(
          provider: 'google',
          providerToken: idToken,
          providerId: account.id,
        );
      }

      return AuthResult.error('auth.google_error');
    } on GoogleSignInException catch (e, stackTrace) {
      AppLogger.e(
        'Google Sign-In error: ${e.code} - ${e.description}',
        error: e,
        stackTrace: stackTrace,
      );

      if (e.code == GoogleSignInExceptionCode.canceled) {
        return AuthResult.cancelled();
      }

      return AuthResult.error('auth.google_error');
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e(
        'Google Sign-In platform error: ${e.code} - ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );

      if (e.code == 'CANCELLED') {
        return AuthResult.cancelled();
      }

      return AuthResult.error(_googlePlatformErrorKey(e.code));
    } catch (e, stackTrace) {
      AppLogger.e(
        'Google Sign-In error: ${e.runtimeType} - $e',
        error: e,
        stackTrace: stackTrace,
      );

      return AuthResult.error('auth.google_error');
    }
  }
  // /// Sign in with Google using native legacy API (works on all Android devices)
  // Future<AuthResult> signInWithGoogle() async {
  //   try {
  //     AppLogger.i('Google Sign-In: Starting sign-in flow...');

  //     final result = await _googleAuthChannel
  //         .invokeMapMethod<String, dynamic>('signInWithGoogle', {
  //           'serverClientId': _googleServerClientId,
  //           'androidClientId': _googleAndroidClientId,
  //         });

  //     if (result == null) {
  //       AppLogger.e('Google Sign-In: No result from native channel');
  //       return AuthResult.error('auth.google_error');
  //     }

  //     AppLogger.i('Google Sign-In: User authenticated: ${result['email']}');

  //     final idToken = result['idToken']?.toString();
  //     final userId = result['id']?.toString();

  //     AppLogger.d(
  //       'Google Sign-In: idToken=${idToken != null ? "present (${idToken.length} chars)" : "null"}',
  //     );

  //     if (idToken == null || idToken.isEmpty) {
  //       AppLogger.e('Google Sign-In: No ID token received');
  //       return AuthResult.error('auth.google_no_token');
  //     }

  //     AppLogger.i(
  //       'Google Sign-In: Token obtained, authenticating with backend...',
  //     );

  //     return await _authenticateWithBackend(
  //       provider: 'google',
  //       providerToken: idToken,
  //       providerId: userId ?? '',
  //     );
  //   } on PlatformException catch (e, stackTrace) {
  //     AppLogger.e(
  //       'Google Sign-In platform error: ${e.code} - ${e.message} - details: ${e.details}',
  //       error: e,
  //       stackTrace: stackTrace,
  //     );

  //     if (e.code == 'CANCELLED') {
  //       return AuthResult.cancelled();
  //     }
  //     return AuthResult.error(_googlePlatformErrorKey(e.code));
  //   } on MissingPluginException catch (e, stackTrace) {
  //     AppLogger.e(
  //       'Google Sign-In: Method channel not available',
  //       error: e,
  //       stackTrace: stackTrace,
  //     );
  //     return AuthResult.error('auth.google_error');
  //   } catch (e, stackTrace) {
  //     AppLogger.e(
  //       'Google Sign-In error: ${e.runtimeType} - $e',
  //       error: e,
  //       stackTrace: stackTrace,
  //     );
  //     return AuthResult.error('auth.google_error');
  //   }
  // }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleAuthChannel.invokeMethod('signOut');
    } catch (e) {
      AppLogger.e('Google Sign-Out error', error: e);
    }
  }

  String _googlePlatformErrorKey(String code) {
    switch (code) {
      case 'GOOGLE_DEVELOPER_ERROR':
        return 'auth.google_config_error';
      case 'GOOGLE_PLAY_SERVICES_UNAVAILABLE':
        return 'auth.google_play_services_unavailable';
      case 'GOOGLE_NETWORK_ERROR':
        return 'auth.google_network_error';
      default:
        return 'auth.google_error';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OTP AUTHENTICATION (WhatsApp / Telegram)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Request OTP for phone authentication
  ///
  /// [provider] - 'whatsapp' or 'telegram'
  /// [phoneNumber] - Phone number with country code (e.g., +1234567890)
  /// [telegramId] - Optional Telegram user ID (for telegram provider)
  Future<OtpRequestResult> requestOtp({
    required String provider,
    required String phoneNumber,
    String? telegramId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'provider': provider,
        'phone_number': phoneNumber,
      };
      if (telegramId != null) {
        body['telegram_id'] = telegramId;
      }

      final response = await _api.post(Endpoints.authOtpRequest, body: body);

      if (response['success'] == true) {
        final expiresIn = _toInt(response['expires_in'], 300);
        AppLogger.i('OTP requested successfully for $phoneNumber');
        return OtpRequestResult.success(expiresIn: expiresIn);
      }

      return OtpRequestResult.error(
        response['message']?.toString() ?? 'auth.otp_request_failed',
      );
    } on ApiException catch (e) {
      AppLogger.e('OTP request error', error: e);
      if (e.statusCode == 429) {
        return OtpRequestResult.error('auth.rate_limit_exceeded');
      }
      return OtpRequestResult.error('auth.otp_request_failed');
    } catch (e) {
      AppLogger.e('OTP request error', error: e);
      return OtpRequestResult.error('auth.unknown_error');
    }
  }

  /// Verify OTP and complete authentication
  ///
  /// [provider] - 'whatsapp' or 'telegram'
  /// [phoneNumber] - Phone number with country code
  /// [otpCode] - 6-digit OTP code
  Future<AuthResult> verifyOtp({
    required String provider,
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final response = await _api.post(
        Endpoints.authOtpVerify,
        body: {
          'provider': provider,
          'phone_number': phoneNumber,
          'otp_code': otpCode,
        },
      );

      if (response['success'] != true) {
        return AuthResult.error(
          response['message']?.toString() ?? 'auth.otp_invalid',
        );
      }

      // Extract tokens
      final tokens = response['tokens'] as Map<String, dynamic>?;
      final userId = response['user_id']?.toString();
      final isNewUser = _toBool(response['is_new_user']);

      if (tokens == null || userId == null) {
        AppLogger.e('Invalid OTP verify response: $response');
        return AuthResult.error('auth.invalid_response');
      }

      final accessToken = tokens['access_token']?.toString();
      final refreshToken = tokens['refresh_token']?.toString();

      if (accessToken == null || refreshToken == null) {
        return AuthResult.error('auth.invalid_response');
      }

      // Save tokens
      await _tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
      );

      AppLogger.i(
        'OTP verified successfully for user: $userId (new: $isNewUser)',
      );

      // Identify user in RevenueCat
      await PurchaseService.instance.logIn(userId);

      // Apply pending referral code if this is a new user
      if (isNewUser && _pendingReferralCode != null) {
        await _applyReferralCode(_pendingReferralCode!);
        _pendingReferralCode = null;
      }

      return AuthResult.success(userId: userId, isNewUser: isNewUser);
    } on ApiException catch (e) {
      AppLogger.e('OTP verify error', error: e);
      if (e.statusCode == 400) {
        return AuthResult.error('auth.otp_invalid');
      }
      return AuthResult.error('auth.server_error');
    } catch (e) {
      AppLogger.e('OTP verify error', error: e);
      return AuthResult.error('auth.unknown_error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKEND AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<AuthResult> _authenticateWithBackend({
    required String provider,
    required String providerToken,
    String? providerId,
  }) async {
    try {
      AppLogger.i(
        'Backend Auth: Starting authentication with provider: $provider',
      );

      final Map<String, dynamic> body = {
        'provider': provider,
        'provider_token': providerToken,
      };
      if (providerId != null) {
        body['provider_id'] = providerId;
      }

      AppLogger.d('Backend Auth: Sending request to ${Endpoints.authSignup}');

      final response = await _api.post(Endpoints.authSignup, body: body);

      AppLogger.d('Backend Auth: Response received: ${response.keys.toList()}');

      final tokens = response['tokens'] as Map<String, dynamic>?;
      final userId = response['user_id']?.toString();

      if (tokens == null || userId == null) {
        AppLogger.e(
          'Backend Auth: Invalid response - tokens: ${tokens != null}, userId: $userId',
        );
        AppLogger.e('Backend Auth: Full response: $response');
        return AuthResult.error('auth.invalid_response');
      }

      final accessToken = tokens['access_token']?.toString();
      final refreshToken = tokens['refresh_token']?.toString();

      if (accessToken == null || refreshToken == null) {
        AppLogger.e(
          'Backend Auth: Missing tokens - access: ${accessToken != null}, refresh: ${refreshToken != null}',
        );
        return AuthResult.error('auth.invalid_response');
      }

      AppLogger.d('Backend Auth: Saving tokens for user: $userId');

      await _tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
      );

      AppLogger.i('Backend Auth: User authenticated successfully: $userId');

      // Identify user in RevenueCat
      await PurchaseService.instance.logIn(userId);

      // Apply pending referral code only for new users
      final isNewUser = response['is_new_user'] == true;
      if (isNewUser && _pendingReferralCode != null) {
        AppLogger.d('Backend Auth: Applying pending referral code');
        await _applyReferralCode(_pendingReferralCode!);
        _pendingReferralCode = null;
      }

      return AuthResult.success(userId: userId, isNewUser: isNewUser);
    } on ApiException catch (e, stackTrace) {
      AppLogger.e(
        'Backend Auth: API error - status: ${e.statusCode}, message: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
      final message = e.message.toLowerCase();
      if (e.statusCode == 401 &&
          (message.contains('audience') ||
              message.contains('google') ||
              message.contains('token'))) {
        return AuthResult.error('auth.google_config_error');
      }
      return AuthResult.error('auth.server_error');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Backend Auth: Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );
      return AuthResult.error('auth.unknown_error');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFERRAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply a referral code for the current user
  Future<ReferralResult> applyReferralCode(String code) async {
    return _applyReferralCode(code);
  }

  Future<ReferralResult> _applyReferralCode(String code) async {
    try {
      final response = await _api.post(
        Endpoints.referralTrackClick,
        body: {'code': code, 'conversion_type': 'signup'},
      );

      if (response['success'] == true) {
        AppLogger.i('Referral code applied: $code');
        return ReferralResult.success(creditsEarned: 5);
      }

      return ReferralResult.error(
        response['message']?.toString() ?? 'referral.invalid_code',
      );
    } on ApiException catch (e) {
      AppLogger.e('Referral code error', error: e);
      if (e.statusCode == 404) {
        return ReferralResult.error('referral.code_not_found');
      }
      return ReferralResult.error('referral.apply_failed');
    } catch (e) {
      AppLogger.e('Referral code error', error: e);
      return ReferralResult.error('auth.unknown_error');
    }
  }

  /// Get current user's referral code
  Future<String?> getMyReferralCode() async {
    try {
      final response = await _api.get(Endpoints.referralMyCode);
      return response['referral_code']?.toString();
    } catch (e) {
      AppLogger.e('Get referral code error', error: e);
      return null;
    }
  }

  /// Get referral statistics
  Future<ReferralStats?> getReferralStats() async {
    try {
      final response = await _api.get(Endpoints.referralStats);
      return ReferralStats.fromJson(response);
    } catch (e) {
      AppLogger.e('Get referral stats error', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get current user profile
  Future<UserProfile?> getProfile() async {
    try {
      final response = await _api.get(Endpoints.authProfile);
      if (response['success'] == true) {
        return UserProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      AppLogger.e('Get profile error', error: e);
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? email}) async {
    try {
      final Map<String, dynamic> body = {};
      if (email != null) body['email'] = email;

      final response = await _api.put(Endpoints.authProfile, body: body);
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Update profile error', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _tokenManager.hasTokens();
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return _tokenManager.getUserId();
  }

  /// Log out user
  Future<void> logout() async {
    await signOutGoogle();
    await PurchaseService.instance.logOut();
    await _tokenManager.clearAll();
    AppLogger.i('User logged out');
  }

  /// Delete user account permanently
  Future<bool> deleteAccount() async {
    try {
      final response = await _api.delete(Endpoints.authDeleteAccount);
      if (response['success'] == true) {
        AppLogger.i('Account deleted successfully');
        await logout();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('Delete account error', error: e);
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULT CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Result of an authentication attempt
class AuthResult {
  final AuthStatus status;
  final String? userId;
  final String? errorKey;
  final bool isNewUser;

  AuthResult._({
    required this.status,
    this.userId,
    this.errorKey,
    this.isNewUser = false,
  });

  factory AuthResult.success({required String userId, bool isNewUser = false}) {
    return AuthResult._(
      status: AuthStatus.success,
      userId: userId,
      isNewUser: isNewUser,
    );
  }

  factory AuthResult.cancelled() {
    return AuthResult._(status: AuthStatus.cancelled);
  }

  factory AuthResult.error(String errorKey) {
    return AuthResult._(status: AuthStatus.error, errorKey: errorKey);
  }

  bool get isSuccess => status == AuthStatus.success;
  bool get isCancelled => status == AuthStatus.cancelled;
  bool get isError => status == AuthStatus.error;
}

enum AuthStatus { success, cancelled, error }

/// Result of an OTP request
class OtpRequestResult {
  final bool isSuccess;
  final int expiresIn;
  final String? errorKey;

  OtpRequestResult._({
    required this.isSuccess,
    this.expiresIn = 300,
    this.errorKey,
  });

  factory OtpRequestResult.success({int expiresIn = 300}) {
    return OtpRequestResult._(isSuccess: true, expiresIn: expiresIn);
  }

  factory OtpRequestResult.error(String errorKey) {
    return OtpRequestResult._(isSuccess: false, errorKey: errorKey);
  }
}

/// Result of applying a referral code
class ReferralResult {
  final bool isSuccess;
  final int creditsEarned;
  final String? errorKey;

  ReferralResult._({
    required this.isSuccess,
    this.creditsEarned = 0,
    this.errorKey,
  });

  factory ReferralResult.success({int creditsEarned = 5}) {
    return ReferralResult._(isSuccess: true, creditsEarned: creditsEarned);
  }

  factory ReferralResult.error(String errorKey) {
    return ReferralResult._(isSuccess: false, errorKey: errorKey);
  }
}

/// Referral statistics
class ReferralStats {
  final String referralCode;
  final int totalClicks;
  final int totalSignups;
  final int totalPurchases;
  final double totalEarned;
  final String currency;

  ReferralStats({
    required this.referralCode,
    required this.totalClicks,
    required this.totalSignups,
    required this.totalPurchases,
    required this.totalEarned,
    required this.currency,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final earnings = json['earnings'] as Map<String, dynamic>? ?? {};

    return ReferralStats(
      referralCode: json['referral_code']?.toString() ?? '',
      totalClicks: _toInt(stats['total_clicks']),
      totalSignups: _toInt(stats['total_signups']),
      totalPurchases: _toInt(stats['total_purchases']),
      totalEarned: _toDouble(earnings['total_earned']),
      currency: earnings['currency']?.toString() ?? 'USD',
    );
  }
}

/// User profile data
class UserProfile {
  final int id;
  final String? authProvider;
  final String? email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final int creditsBalance;
  final bool isTrialUsed;
  final DateTime memberSince;
  final int totalAnalyses;
  final int totalEnhancedPhotos;
  final int totalPostedPhotos;

  UserProfile({
    required this.id,
    this.authProvider,
    this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    required this.creditsBalance,
    required this.isTrialUsed,
    required this.memberSince,
    required this.totalAnalyses,
    required this.totalEnhancedPhotos,
    required this.totalPostedPhotos,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};

    return UserProfile(
      id: _toInt(user['id']),
      authProvider: user['auth_provider']?.toString(),
      email: user['email']?.toString(),
      phoneNumber: user['phone_number']?.toString(),
      profilePhotoUrl: user['profile_photo_url']?.toString(),
      creditsBalance: _toInt(user['credits_balance']),
      isTrialUsed: _toBool(user['is_trial_used']),
      memberSince:
          DateTime.tryParse(user['member_since']?.toString() ?? '') ??
          DateTime.now(),
      totalAnalyses: _toInt(stats['total_analyses']),
      totalEnhancedPhotos: _toInt(stats['total_enhanced_photos']),
      totalPostedPhotos: _toInt(stats['total_posted_photos']),
    );
  }
}

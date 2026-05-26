import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

/// Manages JWT tokens for authentication.
///
/// Uses flutter_secure_storage for encrypted token persistence.
/// - iOS: Keychain with first_unlock accessibility
/// - Android: EncryptedSharedPreferences (AES256)
class TokenManager {
  TokenManager._();
  static final TokenManager instance = TokenManager._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  /// Stream controller that fires when the session is invalidated
  /// (refresh token expired or revoked). Listeners should navigate to login.
  static final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  /// Listen to this stream to handle force-logout when refresh fails.
  static Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN STORAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save authentication tokens and user ID
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
        _storage.write(key: _userIdKey, value: userId),
      ]);
    } catch (e) {
      AppLogger.e('Failed to save tokens to secure storage', error: e);
      rethrow;
    }
  }

  /// Get the current access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      AppLogger.e('Failed to read access token', error: e);
      return null;
    }
  }

  /// Get the current refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      AppLogger.e('Failed to read refresh token', error: e);
      return null;
    }
  }

  /// Get the current user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      AppLogger.e('Failed to read user ID', error: e);
      return null;
    }
  }

  /// Update both tokens after a refresh (the backend rotates refresh tokens).
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
    } catch (e) {
      AppLogger.e('Failed to update tokens', error: e);
      rethrow;
    }
  }

  /// Clear all stored tokens (logout)
  Future<void> clearAll() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
      ]);
    } catch (e) {
      AppLogger.e('Failed to clear tokens', error: e);
    }
  }

  /// Clear tokens and notify listeners that the session is expired.
  /// Called when token refresh fails — forces the app to navigate to login.
  Future<void> forceLogout() async {
    await clearAll();
    _sessionExpiredController.add(null);
  }

  /// Check if user has valid tokens stored (both access AND refresh)
  Future<bool> hasTokens() async {
    final results = await Future.wait([
      getAccessToken(),
      getRefreshToken(),
    ]);
    final accessToken = results[0];
    final refreshToken = results[1];
    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }
}

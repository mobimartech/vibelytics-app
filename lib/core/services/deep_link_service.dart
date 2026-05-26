import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../utils/app_logger.dart';

/// Handles referral deep links from vibelytics.org/r/{code}
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const _pendingReferralKey = 'pending_referral_code';

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  /// Initialize and check for incoming deep link
  Future<void> initialize() async {
    try {
      // Check initial link (app opened/cold-started via deep link)
      final initialLink = await _getInitialLink();
      if (initialLink != null) {
        await _handleLink(initialLink);
      }

      // Listen for subsequent deep links while app is running
      _linkSub = _appLinks.uriLinkStream.listen((uri) {
        _handleLink(uri.toString());
      });
    } catch (e) {
      AppLogger.w('Deep link init error: $e');
    }
  }

  Future<String?> _getInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      return uri?.toString();
    } catch (e) {
      AppLogger.w('Failed to get initial deep link: $e');
      return null;
    }
  }

  Future<void> _handleLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;

    // Match vibelytics.org/r/{code}
    if (uri.host == 'vibelytics.org' && uri.pathSegments.length == 2) {
      if (uri.pathSegments[0] == 'r') {
        final code = uri.pathSegments[1];
        if (code.isNotEmpty) {
          AppLogger.i('Referral code from deep link: $code');
          await savePendingReferral(code);
        }
      }
    }
  }

  /// Save a referral code to apply after signup
  Future<void> savePendingReferral(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingReferralKey, code.toUpperCase());
    AppLogger.d('Saved pending referral: ${code.toUpperCase()}');
  }

  /// Get and clear the pending referral code
  Future<String?> consumePendingReferral() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_pendingReferralKey);
    if (code != null) {
      await prefs.remove(_pendingReferralKey);
      AppLogger.d('Consumed pending referral: $code');
    }
    return code;
  }

  /// Track a referral conversion (call after signup, no auth needed)
  Future<void> trackReferralSignup(String code, {int? userId}) async {
    try {
      final Map<String, dynamic> body = {
        'code': code,
        'conversion_type': 'signup',
      };
      if (userId != null) body['user_id'] = userId;

      await ApiClient.instance.post(
        Endpoints.referralTrackClick,
        body: body,
      );
      AppLogger.i('Referral signup tracked for code: $code');
    } catch (e) {
      AppLogger.w('Failed to track referral signup: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _linkSub?.cancel();
  }
}

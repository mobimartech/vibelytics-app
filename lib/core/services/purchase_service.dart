import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/app_logger.dart';

/// Result of a purchase attempt.
///
/// Named `CreditPurchaseResult` to avoid collision with RevenueCat's
/// `PurchaseResult` class (introduced in purchases_flutter v9).
enum CreditPurchaseStatus { success, cancelled, error }

class CreditPurchaseResult {
  final CreditPurchaseStatus status;
  final String? errorMessage;

  CreditPurchaseResult._(this.status, [this.errorMessage]);

  factory CreditPurchaseResult.success() =>
      CreditPurchaseResult._(CreditPurchaseStatus.success);
  factory CreditPurchaseResult.cancelled() =>
      CreditPurchaseResult._(CreditPurchaseStatus.cancelled);
  factory CreditPurchaseResult.error(String message) =>
      CreditPurchaseResult._(CreditPurchaseStatus.error, message);

  bool get isSuccess => status == CreditPurchaseStatus.success;
  bool get isCancelled => status == CreditPurchaseStatus.cancelled;
  bool get isError => status == CreditPurchaseStatus.error;
}

/// RevenueCat in-app purchase service.
///
/// Handles SDK initialization, customer identification,
/// fetching offerings, and executing purchases.
/// The backend webhook handles credit granting automatically.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  // Platform-specific API keys — replace with real keys from RevenueCat dashboard
  static const String _androidApiKey = 'goog_dRchyyqyxCOwfpshJJOZutuiXVp';
  static const String _iosApiKey = '';

  bool _initialized = false;

  /// Whether the SDK was successfully initialized.
  bool get isAvailable => _initialized;

  /// Initialize the RevenueCat SDK.
  ///
  /// Safe to call on unsupported platforms (web, desktop) — will
  /// silently skip initialization.
  Future<void> initialize() async {
    if (_initialized) return;

    // RevenueCat only supports iOS and Android
    if (!Platform.isAndroid && !Platform.isIOS) {
      AppLogger.d('PurchaseService: Skipping init — platform not supported');
      return;
    }

    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;

    // Don't initialize with placeholder keys
    if (apiKey.isEmpty || apiKey.contains('YOUR_KEY_HERE')) {
      AppLogger.w(
        'PurchaseService: Skipping init — API key is a placeholder. '
        'Set real keys in purchase_service.dart.',
      );
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _initialized = true;
      AppLogger.i('PurchaseService: Initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.e(
        'PurchaseService: Initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log in to RevenueCat with the backend user ID.
  ///
  /// Uses the `user_{userId}` format matching the backend webhook config.
  Future<void> logIn(String userId) async {
    if (!_initialized) return;
    try {
      final result = await Purchases.logIn('user_$userId');
      AppLogger.i(
        'PurchaseService: Logged in as user_$userId '
        '(created: ${result.created})',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'PurchaseService: logIn failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log out the current RevenueCat customer (resets to anonymous).
  Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
      AppLogger.i('PurchaseService: Logged out');
    } catch (e, stackTrace) {
      AppLogger.e(
        'PurchaseService: logOut failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetch available packages from the current RevenueCat offering.
  Future<List<Package>> getPackages() async {
    if (!_initialized) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e, stackTrace) {
      AppLogger.e(
        'PurchaseService: getPackages failed',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Execute a purchase for the given [package].
  Future<CreditPurchaseResult> purchasePackage(Package package) async {
    if (!_initialized) {
      return CreditPurchaseResult.error('Purchase service not available');
    }
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      AppLogger.i(
        'PurchaseService: Purchase completed — ${package.identifier}',
      );
      return CreditPurchaseResult.success();
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        AppLogger.d('PurchaseService: Purchase cancelled by user');
        return CreditPurchaseResult.cancelled();
      }
      AppLogger.e(
        'PurchaseService: Purchase error — ${errorCode.name}',
        error: e,
      );
      return CreditPurchaseResult.error(e.message ?? 'Purchase failed');
    } catch (e, stackTrace) {
      AppLogger.e(
        'PurchaseService: Unexpected purchase error',
        error: e,
        stackTrace: stackTrace,
      );
      return CreditPurchaseResult.error('Purchase failed');
    }
  }

  /// Restore previous purchases.
  ///
  /// Returns `true` if any entitlements were restored.
  Future<bool> restorePurchases() async {
    if (!_initialized) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      final restored = customerInfo.entitlements.active.isNotEmpty;
      AppLogger.i('PurchaseService: Restore complete (restored: $restored)');
      return restored;
    } catch (e, stackTrace) {
      AppLogger.e(
        'PurchaseService: restorePurchases failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

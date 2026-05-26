import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../utils/app_logger.dart';

/// Safely parse an int from a dynamic value (handles String, num, null).
int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely parse a bool from a dynamic value (handles String, num, null).
bool _toBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return fallback;
}

/// Service for managing user credits
class CreditsService {
  CreditsService._();
  static final CreditsService instance = CreditsService._();
  final ApiClient _api = ApiClient.instance;

  // Cached balance for quick access
  int _cachedBalance = 0;
  DateTime? _lastFetchTime;

  // Pending coupon code entered before login
  String? _pendingCouponCode;

  /// Get current credit balance
  int get cachedBalance => _cachedBalance;

  /// Fetch current credit balance from server
  Future<int> getBalance({bool forceRefresh = false}) async {
    // Use cache if fresh (less than 30 seconds old)
    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inSeconds < 30) {
      return _cachedBalance;
    }

    try {
      final response = await _api.get(Endpoints.creditsBalance);
      _cachedBalance = _toInt(response['balance']);
      _lastFetchTime = DateTime.now();
      return _cachedBalance;
    } catch (e) {
      AppLogger.e('Get balance error', error: e);
      return _cachedBalance;
    }
  }

  /// Get credit transaction history
  Future<CreditHistoryResult> getHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.creditsHistory,
        queryParams: {
          'limit': limit,
          'offset': offset,
        },
      );

      final history = (response['history'] as List<dynamic>?)
              ?.map((e) => CreditTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return CreditHistoryResult(
        transactions: history,
        hasMore: history.length >= limit,
      );
    } catch (e) {
      AppLogger.e('Get history error', error: e);
      return CreditHistoryResult(transactions: [], hasMore: false);
    }
  }

  /// Validate a coupon code without redeeming
  Future<CouponValidation?> validateCoupon(String code) async {
    try {
      final response = await _api.get(
        Endpoints.couponValidate,
        queryParams: {'code': code},
      );

      if (response['valid'] == true) {
        return CouponValidation.fromJson(response);
      }
      return null;
    } on ApiException catch (e) {
      AppLogger.e('Validate coupon error', error: e);
      return null;
    } catch (e) {
      AppLogger.e('Validate coupon error', error: e);
      return null;
    }
  }

  /// Redeem a coupon code
  Future<CouponRedeemResult> redeemCoupon(String code) async {
    try {
      final response = await _api.post(
        Endpoints.couponRedeem,
        body: {'coupon_code': code},
      );

      if (response['success'] == true) {
        final creditsGranted = _toInt(response['credits_granted']);
        _cachedBalance += creditsGranted;
        return CouponRedeemResult.success(creditsGranted: creditsGranted);
      }

      return CouponRedeemResult.error(
        response['message']?.toString() ?? 'credits.coupon_invalid',
      );
    } on ApiException catch (e) {
      AppLogger.e('Redeem coupon error', error: e);
      if (e.statusCode == 409) {
        return CouponRedeemResult.error('credits.coupon_already_redeemed');
      }
      if (e.statusCode == 400) {
        return CouponRedeemResult.error('credits.coupon_invalid');
      }
      return CouponRedeemResult.error('credits.redeem_failed');
    } catch (e) {
      AppLogger.e('Redeem coupon error', error: e);
      return CouponRedeemResult.error('common.error');
    }
  }

  /// Get subscription and credit status
  Future<SubscriptionStatus?> getSubscriptionStatus() async {
    try {
      final response = await _api.get(Endpoints.subscriptionStatus);
      return SubscriptionStatus.fromJson(response);
    } catch (e) {
      AppLogger.e('Get subscription status error', error: e);
      return null;
    }
  }

  /// Initialize subscription (grants free credits for new users)
  Future<bool> initializeSubscription() async {
    try {
      final response = await _api.post(Endpoints.subscriptionInitialize);
      if (response['success'] == true) {
        _cachedBalance = _toInt(response['credits_balance'], _cachedBalance);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('Initialize subscription error', error: e);
      return false;
    }
  }

  /// Check if user has enough credits for an action
  bool hasEnoughCredits(int required) {
    return _cachedBalance >= required;
  }

  /// Deduct credits locally (call after successful API operation)
  void deductCredits(int amount) {
    _cachedBalance = (_cachedBalance - amount).clamp(0, double.maxFinite.toInt());
  }

  /// Add credits locally (call after earning credits)
  void addCredits(int amount) {
    _cachedBalance += amount;
  }

  /// Store a coupon code to be applied after login
  void setPendingCouponCode(String? code) {
    _pendingCouponCode = code?.trim().isEmpty == true ? null : code?.trim();
  }

  /// Apply the pending coupon code if one exists. Returns null if no pending code.
  Future<CouponRedeemResult?> applyPendingCoupon() async {
    final code = _pendingCouponCode;
    _pendingCouponCode = null;
    if (code == null || code.isEmpty) return null;
    return redeemCoupon(code);
  }

  /// Clear cached data (on logout)
  void clearCache() {
    _cachedBalance = 0;
    _lastFetchTime = null;
    _pendingCouponCode = null;
  }
}

/// Credit transaction record
class CreditTransaction {
  final int id;
  final int amount;
  final String type;
  final String description;
  final DateTime createdAt;
  final int balanceAfter;

  CreditTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    required this.balanceAfter,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: _toInt(json['id']),
      amount: _toInt(json['amount']),
      type: json['type']?.toString() ?? 'unknown',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      balanceAfter: _toInt(json['balance_after']),
    );
  }

  bool get isPositive => amount > 0;
}

/// Credit history result
class CreditHistoryResult {
  final List<CreditTransaction> transactions;
  final bool hasMore;

  CreditHistoryResult({
    required this.transactions,
    required this.hasMore,
  });
}

/// Coupon validation result
class CouponValidation {
  final String code;
  final String type;
  final int creditsAmount;
  final DateTime? expiresAt;
  final bool canUse;
  final int globalUsesLeft;

  CouponValidation({
    required this.code,
    required this.type,
    required this.creditsAmount,
    this.expiresAt,
    required this.canUse,
    required this.globalUsesLeft,
  });

  factory CouponValidation.fromJson(Map<String, dynamic> json) {
    final coupon = json['coupon'] as Map<String, dynamic>? ?? {};
    return CouponValidation(
      code: coupon['code']?.toString() ?? '',
      type: coupon['type']?.toString() ?? 'gift_card',
      creditsAmount: _toInt(coupon['credits_amount']),
      expiresAt: DateTime.tryParse(coupon['expires_at']?.toString() ?? ''),
      canUse: _toBool(json['can_use']),
      globalUsesLeft: _toInt(json['global_uses_left']),
    );
  }
}

/// Coupon redeem result
class CouponRedeemResult {
  final bool isSuccess;
  final int creditsGranted;
  final String? errorKey;

  CouponRedeemResult._({
    required this.isSuccess,
    this.creditsGranted = 0,
    this.errorKey,
  });

  factory CouponRedeemResult.success({required int creditsGranted}) {
    return CouponRedeemResult._(isSuccess: true, creditsGranted: creditsGranted);
  }

  factory CouponRedeemResult.error(String errorKey) {
    return CouponRedeemResult._(isSuccess: false, errorKey: errorKey);
  }
}

/// Subscription status
class SubscriptionStatus {
  final String system;
  final int creditsBalance;
  final bool isTrialUsed;
  final String tier;
  final bool hasActiveSubscription;

  SubscriptionStatus({
    required this.system,
    required this.creditsBalance,
    required this.isTrialUsed,
    required this.tier,
    required this.hasActiveSubscription,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>? ?? {};
    final trialInfo = json['trial_info'] as Map<String, dynamic>? ?? {};
    final subscription = json['subscription'] as Map<String, dynamic>? ?? {};

    return SubscriptionStatus(
      system: json['system']?.toString() ?? 'credits',
      creditsBalance: _toInt(credits['balance']),
      isTrialUsed: _toBool(trialInfo['initial_credits_granted']),
      tier: subscription['tier']?.toString() ?? 'credit_based',
      hasActiveSubscription:
          _toBool(subscription['has_active_subscription']),
    );
  }
}

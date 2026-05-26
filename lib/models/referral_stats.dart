/// Referral statistics model
class ReferralStats {
  final String referralCode;
  final int totalClicks;
  final int totalSignups;
  final int totalPurchases;
  final double totalEarned;

  const ReferralStats({
    required this.referralCode,
    required this.totalClicks,
    required this.totalSignups,
    required this.totalPurchases,
    required this.totalEarned,
  });

  /// Calculate conversion rate (signups / clicks)
  double get conversionRate {
    if (totalClicks == 0) return 0;
    return totalSignups / totalClicks;
  }

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      referralCode: json['referral_code'],
      totalClicks: json['total_clicks'] ?? 0,
      totalSignups: json['total_signups'] ?? 0,
      totalPurchases: json['total_purchases'] ?? 0,
      totalEarned: (json['total_earned'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'referral_code': referralCode,
        'total_clicks': totalClicks,
        'total_signups': totalSignups,
        'total_purchases': totalPurchases,
        'total_earned': totalEarned,
      };
}

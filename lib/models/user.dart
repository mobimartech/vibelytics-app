/// User statistics
class UserStats {
  final int totalAnalyses;
  final int totalEnhancedPhotos;
  final int totalPostedPhotos;

  const UserStats({
    required this.totalAnalyses,
    required this.totalEnhancedPhotos,
    required this.totalPostedPhotos,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalAnalyses: json['total_analyses'] ?? 0,
      totalEnhancedPhotos: json['total_enhanced_photos'] ?? 0,
      totalPostedPhotos: json['total_posted_photos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_analyses': totalAnalyses,
        'total_enhanced_photos': totalEnhancedPhotos,
        'total_posted_photos': totalPostedPhotos,
      };
}

/// User model
class User {
  final int id;
  final String? authProvider;
  final String? email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final int creditsBalance;
  final bool isTrialUsed;
  final DateTime memberSince;
  final UserStats stats;

  const User({
    required this.id,
    this.authProvider,
    this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    required this.creditsBalance,
    required this.isTrialUsed,
    required this.memberSince,
    required this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      authProvider: json['auth_provider'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'],
      profilePhotoUrl: json['profile_photo_url'],
      creditsBalance: json['credits_balance'] ?? 0,
      isTrialUsed: json['is_trial_used'] ?? false,
      memberSince: DateTime.tryParse(json['member_since']?.toString() ?? '') ?? DateTime.now(),
      stats: UserStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'auth_provider': authProvider,
        'email': email,
        'phone_number': phoneNumber,
        'profile_photo_url': profilePhotoUrl,
        'credits_balance': creditsBalance,
        'is_trial_used': isTrialUsed,
        'member_since': memberSince.toIso8601String(),
        'stats': stats.toJson(),
      };
}

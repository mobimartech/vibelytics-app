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

/// Safely parse a double from a dynamic value (handles String, num, null).
double _toDouble(dynamic value, [double fallback = 0.0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Service for leaderboard operations
class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();
  final ApiClient _api = ApiClient.instance;

  /// Get global leaderboard
  Future<LeaderboardResult> getLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.leaderboard,
        queryParams: {'limit': limit, 'offset': offset},
      );

      final entries = (response['leaderboard'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      final total = _toInt(pagination['total'], entries.length);

      return LeaderboardResult(
        entries: entries,
        rankingType: response['ranking_type']?.toString() ?? 'wilson_score',
        hasMore: offset + entries.length < total,
        total: total,
      );
    } catch (e) {
      AppLogger.e('Get leaderboard error', error: e);
      return LeaderboardResult(
        entries: [],
        rankingType: 'wilson_score',
        hasMore: false,
        total: 0,
      );
    }
  }

  /// Get tag-specific leaderboard
  Future<LeaderboardResult> getLeaderboardByTag(
    String tagSlug, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.leaderboardByTag(tagSlug),
        queryParams: {'limit': limit, 'offset': offset},
      );

      final entries = (response['leaderboard'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      final total = _toInt(pagination['total'], entries.length);
      final tag = response['tag'] as Map<String, dynamic>? ?? {};

      return LeaderboardResult(
        entries: entries,
        rankingType: response['ranking_type']?.toString() ?? 'wilson_score',
        hasMore: offset + entries.length < total,
        total: total,
        tagName: tag['name']?.toString(),
        tagSlug: tag['slug']?.toString(),
      );
    } catch (e) {
      AppLogger.e('Get leaderboard by tag error', error: e);
      return LeaderboardResult(
        entries: [],
        rankingType: 'wilson_score',
        hasMore: false,
        total: 0,
      );
    }
  }

  /// Get user's leaderboard stats
  Future<UserLeaderboardStats?> getUserStats(int userId) async {
    try {
      final response = await _api.get(Endpoints.leaderboardUser(userId));

      if (response['success'] == true) {
        return UserLeaderboardStats.fromJson(response);
      }
      return null;
    } catch (e) {
      AppLogger.e('Get user stats error', error: e);
      return null;
    }
  }

  /// Get global leaderboard statistics
  Future<LeaderboardStats?> getGlobalStats() async {
    try {
      final response = await _api.get(Endpoints.leaderboardStats);

      if (response['success'] == true) {
        return LeaderboardStats.fromJson(response);
      }
      return null;
    } catch (e) {
      AppLogger.e('Get global stats error', error: e);
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Leaderboard entry
class LeaderboardEntry {
  final int rank;
  final int photoId;
  final String photoUrl;
  final int userId;
  final String? username;
  final String? userPhotoUrl;
  final double averageRating;
  final int totalRatings;
  final double wilsonScore;
  final List<String> tags;

  LeaderboardEntry({
    required this.rank,
    required this.photoId,
    required this.photoUrl,
    required this.userId,
    this.username,
    this.userPhotoUrl,
    required this.averageRating,
    required this.totalRatings,
    required this.wilsonScore,
    required this.tags,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final tagsStr = json['tags']?.toString() ?? '';
    return LeaderboardEntry(
      rank: _toInt(json['rank']),
      photoId: _toInt(json['photo_id'], _toInt(json['id'])),
      photoUrl: json['photo_url']?.toString() ?? '',
      userId: _toInt(json['user_id']),
      username: json['username']?.toString(),
      userPhotoUrl: json['user_photo']?.toString(),
      averageRating: _toDouble(json['average_rating']),
      totalRatings: _toInt(json['total_ratings']),
      wilsonScore: _toDouble(json['wilson_score']),
      tags: tagsStr.isNotEmpty ? tagsStr.split('|') : [],
    );
  }
}

/// User's leaderboard statistics
class UserLeaderboardStats {
  final int userId;
  final int totalPhotos;
  final double avgRating;
  final int totalRatingsReceived;
  final double bestRating;
  final List<LeaderboardEntry> topPhotos;

  UserLeaderboardStats({
    required this.userId,
    required this.totalPhotos,
    required this.avgRating,
    required this.totalRatingsReceived,
    required this.bestRating,
    required this.topPhotos,
  });

  factory UserLeaderboardStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return UserLeaderboardStats(
      userId: _toInt(json['user_id']),
      totalPhotos: _toInt(stats['total_photos']),
      avgRating: _toDouble(stats['avg_rating']),
      totalRatingsReceived: _toInt(stats['total_ratings_received']),
      bestRating: _toDouble(stats['best_rating']),
      topPhotos: (json['top_photos'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Global leaderboard statistics
class LeaderboardStats {
  final int totalPhotos;
  final int totalRaters;
  final int totalRatings;
  final double avgRating;
  final double highestRating;
  final double lowestRating;
  final List<LeaderboardEntry> highestRated;
  final List<LeaderboardEntry> mostPopular;
  final List<TagUsage> tagUsage;
  final DateTime lastUpdated;

  LeaderboardStats({
    required this.totalPhotos,
    required this.totalRaters,
    required this.totalRatings,
    required this.avgRating,
    required this.highestRating,
    required this.lowestRating,
    required this.highestRated,
    required this.mostPopular,
    required this.tagUsage,
    required this.lastUpdated,
  });

  factory LeaderboardStats.fromJson(Map<String, dynamic> json) {
    final overallStats = json['overall_stats'] as Map<String, dynamic>? ?? {};
    final topLists = json['top_lists'] as Map<String, dynamic>? ?? {};

    return LeaderboardStats(
      totalPhotos: _toInt(overallStats['total_photos']),
      totalRaters: _toInt(overallStats['total_raters']),
      totalRatings: _toInt(overallStats['total_ratings']),
      avgRating: _toDouble(overallStats['avg_rating']),
      highestRating: _toDouble(overallStats['highest_rating'], 5.0),
      lowestRating: _toDouble(overallStats['lowest_rating'], 1.0),
      highestRated: (topLists['highest_rated'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mostPopular: (topLists['most_popular'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tagUsage: (json['tag_usage'] as List<dynamic>?)
              ?.map((e) => TagUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.tryParse(json['last_updated']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Tag usage statistics
class TagUsage {
  final String name;
  final String slug;
  final int count;

  TagUsage({
    required this.name,
    required this.slug,
    required this.count,
  });

  factory TagUsage.fromJson(Map<String, dynamic> json) {
    return TagUsage(
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      count: _toInt(json['count']),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULT CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class LeaderboardResult {
  final List<LeaderboardEntry> entries;
  final String rankingType;
  final bool hasMore;
  final int total;
  final String? tagName;
  final String? tagSlug;

  LeaderboardResult({
    required this.entries,
    required this.rankingType,
    required this.hasMore,
    required this.total,
    this.tagName,
    this.tagSlug,
  });
}

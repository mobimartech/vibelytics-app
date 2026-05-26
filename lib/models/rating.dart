/// Rating model for photo ratings
class Rating {
  const Rating({
    required this.id,
    required this.photoId,
    required this.userId,
    required this.score,
    required this.createdAt,
    this.reaction,
  });

  final String id;
  final String photoId;
  final String userId;
  final double score; // 1-5 or 1-10 scale
  final DateTime createdAt;
  final String? reaction; // Emoji reaction

  factory Rating.fromJson(Map<String, dynamic> json) {
    final scoreVal = json['score'];
    final score = scoreVal is num
        ? scoreVal.toDouble()
        : double.tryParse(scoreVal?.toString() ?? '') ?? 0.0;

    return Rating(
      id: json['id']?.toString() ?? '',
      photoId: json['photo_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      score: score,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      reaction: json['reaction']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photo_id': photoId,
      'user_id': userId,
      'score': score,
      'created_at': createdAt.toIso8601String(),
      'reaction': reaction,
    };
  }

  Rating copyWith({
    String? id,
    String? photoId,
    String? userId,
    double? score,
    DateTime? createdAt,
    String? reaction,
  }) {
    return Rating(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      reaction: reaction ?? this.reaction,
    );
  }
}

/// Aggregated rating stats for a photo
class RatingStats {
  const RatingStats({
    required this.averageScore,
    required this.totalRatings,
    required this.distribution,
  });

  final double averageScore;
  final int totalRatings;
  final Map<int, int> distribution; // score -> count

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    final avgVal = json['average_score'];
    final avgScore = avgVal is num
        ? avgVal.toDouble()
        : double.tryParse(avgVal?.toString() ?? '') ?? 0.0;

    final totalVal = json['total_ratings'];
    final total = totalVal is int
        ? totalVal
        : int.tryParse(totalVal?.toString() ?? '') ?? 0;

    final distMap = json['distribution'] as Map<String, dynamic>? ?? {};

    return RatingStats(
      averageScore: avgScore,
      totalRatings: total,
      distribution: distMap.map(
        (key, value) => MapEntry(
          int.tryParse(key) ?? 0,
          value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0,
        ),
      ),
    );
  }

  factory RatingStats.empty() {
    return const RatingStats(
      averageScore: 0,
      totalRatings: 0,
      distribution: {},
    );
  }
}

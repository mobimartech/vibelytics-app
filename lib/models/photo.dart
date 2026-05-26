/// Photo model for community feed and gallery
class Photo {
  final int id;
  final String photoUrl;
  final double averageRating;
  final int totalRatings;
  final int viewCount;
  final String? userPhoto;
  final String? username;
  final String tags; // Pipe-separated: "dating|professional"
  final DateTime createdAt;
  final bool isPublic;

  const Photo({
    required this.id,
    required this.photoUrl,
    required this.averageRating,
    required this.totalRatings,
    required this.viewCount,
    this.userPhoto,
    this.username,
    required this.tags,
    required this.createdAt,
    required this.isPublic,
  });

  /// Get tags as a list
  List<String> get tagList => tags.isEmpty ? [] : tags.split('|');

  /// Check if photo has enough ratings for Polaroid frame
  bool get hasPolaroidFrame => totalRatings >= 3;

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] ?? 0,
      photoUrl: json['photo_url'] ?? '',
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      userPhoto: json['user_photo'],
      username: json['username'],
      tags: json['tags'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isPublic: json['is_public'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'photo_url': photoUrl,
        'average_rating': averageRating,
        'total_ratings': totalRatings,
        'view_count': viewCount,
        'user_photo': userPhoto,
        'username': username,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'is_public': isPublic,
      };
}

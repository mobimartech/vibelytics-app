/// Comment model for photo comments
class Comment {
  final int id;
  final String content;
  final String? avatarUrl;
  final String username;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;

  const Comment({
    required this.id,
    required this.content,
    this.avatarUrl,
    required this.username,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
  });

  /// Creates a copy with modified fields
  Comment copyWith({
    int? id,
    String? content,
    String? avatarUrl,
    String? username,
    DateTime? createdAt,
    int? likeCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['comment'] ?? json['content'] ?? '',
      avatarUrl: json['user_photo'] ?? json['avatar_url'],
      username: json['username'],
      createdAt: DateTime.parse(json['created_at']),
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'avatar_url': avatarUrl,
        'username': username,
        'created_at': createdAt.toIso8601String(),
        'like_count': likeCount,
        'is_liked': isLiked,
      };
}

/// Notification item model
class NotificationItem {
  final String type; // 'rating', 'comment', 'credit', 'follow', 'enhancement'
  final String message;
  final String? avatarUrl;
  final List<String>? avatarUrls; // For grouped notifications
  final DateTime createdAt;
  final bool isRead;
  final int? relatedId; // Photo ID, comment ID, etc.

  const NotificationItem({
    required this.type,
    required this.message,
    this.avatarUrl,
    this.avatarUrls,
    required this.createdAt,
    required this.isRead,
    this.relatedId,
  });

  /// Check if this is a grouped notification (multiple users)
  bool get isGrouped => avatarUrls != null && avatarUrls!.length > 1;

  /// Get the count of grouped users
  int get groupCount => avatarUrls?.length ?? (avatarUrl != null ? 1 : 0);

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      type: json['type'],
      message: json['message'],
      avatarUrl: json['avatar_url'],
      avatarUrls: (json['avatar_urls'] as List<dynamic>?)?.cast<String>(),
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      relatedId: json['related_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'avatar_url': avatarUrl,
        'avatar_urls': avatarUrls,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
        'related_id': relatedId,
      };
}

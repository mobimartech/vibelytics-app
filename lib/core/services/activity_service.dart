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

/// Safely parse a nullable int from a dynamic value.
int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Safely parse a bool from a dynamic value (handles String, num, null).
bool _toBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return fallback;
}

/// Service for the activity feed
class ActivityService {
  ActivityService._();
  static final ActivityService instance = ActivityService._();
  final ApiClient _api = ApiClient.instance;

  /// Get paginated activity feed
  Future<ActivityFeedResult> getActivities({
    int limit = 20,
    int offset = 0,
    String? type,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'limit': limit,
        'offset': offset,
      };
      if (type != null && type != 'all') params['type'] = type;

      final response = await _api.get(
        Endpoints.activity,
        queryParams: params,
      );

      final activities = (response['activities'] as List<dynamic>?)
              ?.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final pagination =
          response['pagination'] as Map<String, dynamic>? ?? {};
      final hasMoreVal = pagination['has_more'];
      final hasMore = hasMoreVal != null
          ? _toBool(hasMoreVal)
          : (offset + activities.length <
              _toInt(pagination['total'], activities.length));

      final unreadCount = _toInt(response['unread_count']);

      return ActivityFeedResult(
        activities: activities,
        hasMore: hasMore,
        unreadCount: unreadCount,
      );
    } catch (e) {
      AppLogger.e('Get activities error', error: e);
      return ActivityFeedResult(
        activities: [],
        hasMore: false,
        unreadCount: 0,
      );
    }
  }

  /// Get unread activity count (lightweight, for badge)
  Future<int> getUnreadCount() async {
    try {
      final response = await _api.get(Endpoints.activityUnreadCount);
      return _toInt(response['unread_count']);
    } catch (e) {
      AppLogger.e('Get unread count error', error: e);
      return 0;
    }
  }

  /// Mark specific activities as read
  Future<bool> markAsRead(List<int> activityIds) async {
    try {
      final response = await _api.post(
        Endpoints.activityMarkRead,
        body: {'activity_ids': activityIds},
      );
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Mark as read error', error: e);
      return false;
    }
  }

  /// Mark all activities as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _api.post(
        Endpoints.activityMarkRead,
        body: {'all': true},
      );
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Mark all as read error', error: e);
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class ActivityItem {
  final int id;
  final String type;
  final int? actorUserId;
  final String? actorPhoto;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.type,
    this.actorUserId,
    this.actorPhoto,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: _toInt(json['id']),
      type: json['type']?.toString() ?? '',
      actorUserId: _toIntOrNull(json['actor_user_id']),
      actorPhoto: json['actor_photo']?.toString(),
      relatedEntityType: json['related_entity_type']?.toString(),
      relatedEntityId: _toIntOrNull(json['related_entity_id']),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isRead: _toBool(json['is_read']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get hasActor => actorUserId != null;
  bool get isSystemEvent => actorUserId == null;
}

class ActivityFeedResult {
  final List<ActivityItem> activities;
  final bool hasMore;
  final int unreadCount;

  ActivityFeedResult({
    required this.activities,
    required this.hasMore,
    required this.unreadCount,
  });
}

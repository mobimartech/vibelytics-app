import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../utils/app_logger.dart';

/// Service for photo-related operations
class PhotosService {
  PhotosService._();
  static final PhotosService instance = PhotosService._();
  final ApiClient _api = ApiClient.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO FEED
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get public photo feed
  Future<PhotoFeedResult> getFeed({
    int limit = 50,
    int offset = 0,
    String? tag,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'limit': limit,
        'offset': offset,
      };
      if (tag != null) params['tag'] = tag;

      final response = await _api.get(Endpoints.photosFeed, queryParams: params);

      final photos = (response['photos'] as List<dynamic>?)
              ?.map((e) => FeedPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return PhotoFeedResult(photos: photos, hasMore: photos.length >= limit);
    } catch (e) {
      AppLogger.e('Get feed error', error: e);
      return PhotoFeedResult(photos: [], hasMore: false, errorKey: 'home.load_failed');
    }
  }

  /// Get user's posted photos
  Future<PhotoFeedResult> getMyPhotos({
    int limit = 20,
    int offset = 0,
    bool includePrivate = true,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.photosMyPhotos,
        queryParams: {
          'limit': limit,
          'offset': offset,
          'private': includePrivate.toString(),
        },
      );

      final photos = (response['photos'] as List<dynamic>?)
              ?.map((e) => FeedPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      final total = _toInt(pagination['total'], photos.length);

      return PhotoFeedResult(
        photos: photos,
        hasMore: offset + photos.length < total,
      );
    } catch (e) {
      AppLogger.e('Get my photos error', error: e);
      return PhotoFeedResult(photos: [], hasMore: false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED PHOTOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's enhanced photos
  Future<EnhancedPhotosResult> getEnhancedPhotos({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.photosEnhanced,
        queryParams: {'limit': limit, 'offset': offset},
      );

      final photos = (response['photos'] as List<dynamic>?)
              ?.map((e) => EnhancedPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      final total = _toInt(pagination['total'], photos.length);

      return EnhancedPhotosResult(
        photos: photos,
        hasMore: offset + photos.length < total,
      );
    } catch (e) {
      AppLogger.e('Get enhanced photos error', error: e);
      return EnhancedPhotosResult(photos: [], hasMore: false);
    }
  }

  /// Delete an enhanced photo
  Future<bool> deleteEnhancedPhoto(int photoId) async {
    try {
      final response = await _api.delete(Endpoints.photoEnhancedDelete(photoId));
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Delete enhanced photo error', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rate a photo (1-5 stars, earns 5 credits)
  Future<RatingResult> ratePhoto(int photoId, int rating) async {
    final clampedRating = rating.clamp(1, 5);
    try {
      final response = await _api.post(
        Endpoints.photoRate(photoId),
        body: {'rating': clampedRating},
      );

      if (response['success'] == true) {
        return RatingResult.success(creditsEarned: 5);
      }

      return RatingResult.error(
        response['message']?.toString() ?? 'photo.rate_failed',
      );
    } on ApiException catch (e) {
      AppLogger.e('Rate photo error', error: e);
      if (e.statusCode == 400) {
        return RatingResult.error('photo.cannot_rate_own');
      }
      if (e.statusCode == 409) {
        return RatingResult.error('photo.already_rated');
      }
      return RatingResult.error('photo.rate_failed');
    } catch (e) {
      AppLogger.e('Rate photo error', error: e);
      return RatingResult.error('common.error');
    }
  }

  /// Post enhanced photo to public gallery
  Future<PostPhotoResult> postToGallery({
    required int aiPhotoId,
    required List<int> tagIds,
    bool isPublic = true,
    String? caption,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'ai_photo_id': aiPhotoId,
        'tags': tagIds,
        'is_public': isPublic,
      };
      if (caption != null && caption.isNotEmpty) {
        body['caption'] = caption;
      }

      final response = await _api.post(
        Endpoints.photos,
        body: body,
      );

      if (response['success'] == true) {
        return PostPhotoResult.success(
          photoId: _toInt(response['photo_id']),
          photoUrl: response['photo_url']?.toString() ?? '',
        );
      }

      return PostPhotoResult.error(
        response['message']?.toString() ?? 'photo.post_failed',
      );
    } catch (e) {
      AppLogger.e('Post to gallery error', error: e);
      return PostPhotoResult.error('photo.post_failed');
    }
  }

  /// Update photo privacy
  Future<bool> updatePrivacy(int photoId, bool isPublic) async {
    try {
      final response = await _api.patch(
        Endpoints.photoPrivacy(photoId),
        body: {'is_public': isPublic},
      );
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Update privacy error', error: e);
      return false;
    }
  }

  /// Delete a posted photo
  Future<bool> deletePhoto(int photoId) async {
    try {
      final response = await _api.delete(Endpoints.photoDelete(photoId));
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Delete photo error', error: e);
      return false;
    }
  }

  /// Report a photo
  Future<bool> reportPhoto(int photoId, String reason, {String? description}) async {
    try {
      final Map<String, dynamic> body = {'reason': reason};
      if (description != null) body['description'] = description;

      final response = await _api.post(
        Endpoints.photoReport(photoId),
        body: body,
      );
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Report photo error', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get photo comments
  Future<CommentsResult> getComments(int photoId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await _api.get(
        Endpoints.photoComments(photoId),
        queryParams: {'limit': limit, 'offset': offset},
      );

      final comments = (response['comments'] as List<dynamic>?)
              ?.map((e) => PhotoComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return CommentsResult(comments: comments, hasMore: comments.length >= limit);
    } catch (e) {
      AppLogger.e('Get comments error', error: e);
      return CommentsResult(comments: [], hasMore: false);
    }
  }

  /// Add a comment to a photo
  Future<CommentResult> addComment(int photoId, String comment) async {
    try {
      final response = await _api.post(
        Endpoints.photoComment(photoId),
        body: {'comment': comment},
      );

      if (response['success'] == true) {
        return CommentResult.success(
          commentId: _toInt(response['comment_id']),
        );
      }

      return CommentResult.error('comments.add_failed');
    } catch (e) {
      AppLogger.e('Add comment error', error: e);
      return CommentResult.error('comments.add_failed');
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await _api.delete(Endpoints.commentDelete(commentId));
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Delete comment error', error: e);
      return false;
    }
  }

  /// Report a comment
  Future<bool> reportComment(int commentId, String reason, {String? description}) async {
    try {
      final Map<String, dynamic> body = {'reason': reason};
      if (description != null) body['description'] = description;

      final response = await _api.post(
        Endpoints.commentReport(commentId),
        body: body,
      );
      return response['success'] == true;
    } catch (e) {
      AppLogger.e('Report comment error', error: e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CDN UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload an existing online image to CDN (Cloudflare R2).
  ///
  /// [imageUrl] must be a publicly accessible URL (e.g. Replicate output).
  /// [type] must be `enhanced` or `profile`.
  /// Returns the CDN URL or null on failure.
  Future<String?> uploadToCdn(String imageUrl, {String type = 'enhanced'}) async {
    try {
      final response = await _api.post(
        Endpoints.cdnUpload,
        body: {
          'image_url': imageUrl,
          'type': type,
        },
      );

      if (response['success'] == true) {
        return response['cdn_url']?.toString();
      }
      return null;
    } catch (e) {
      AppLogger.e('CDN upload error', error: e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all available tags
  Future<List<PhotoTag>> getTags() async {
    try {
      final response = await _api.get(Endpoints.tags);

      return (response['tags'] as List<dynamic>?)
              ?.map((e) => PhotoTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      AppLogger.e('Get tags error', error: e);
      return [];
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// JSON HELPERS
// ═══════════════════════════════════════════════════════════════════════════

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

/// Photo from the feed
class FeedPhoto {
  final int id;
  final String photoUrl;
  final double averageRating;
  final int totalRatings;
  final int viewCount;
  final String? userPhotoUrl;
  final List<String> tags;
  final DateTime? createdAt;

  FeedPhoto({
    required this.id,
    required this.photoUrl,
    required this.averageRating,
    required this.totalRatings,
    required this.viewCount,
    this.userPhotoUrl,
    required this.tags,
    this.createdAt,
  });

  factory FeedPhoto.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final tagsStr = tagsRaw is String ? tagsRaw : (tagsRaw?.toString() ?? '');
    return FeedPhoto(
      id: _toInt(json['id']),
      photoUrl: json['photo_url']?.toString() ?? '',
      averageRating: _toDouble(json['average_rating']),
      totalRatings: _toInt(json['total_ratings']),
      viewCount: _toInt(json['view_count']),
      userPhotoUrl: json['user_photo']?.toString(),
      tags: tagsStr.isNotEmpty ? tagsStr.split('|') : [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// Enhanced photo
class EnhancedPhoto {
  final int id;
  final String photoUrl;
  final bool isWatermarked;
  final DateTime createdAt;
  final String? seedreamPrompt;
  final String language;
  final String? goal;

  EnhancedPhoto({
    required this.id,
    required this.photoUrl,
    required this.isWatermarked,
    required this.createdAt,
    this.seedreamPrompt,
    required this.language,
    this.goal,
  });

  factory EnhancedPhoto.fromJson(Map<String, dynamic> json) {
    return EnhancedPhoto(
      id: _toInt(json['id']),
      photoUrl: json['photo_url']?.toString() ?? '',
      isWatermarked: json['is_watermarked'] == true || json['is_watermarked'] == 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      seedreamPrompt: json['seedream_prompt']?.toString(),
      language: json['language']?.toString() ?? 'en',
      goal: json['goal']?.toString(),
    );
  }
}

/// Photo tag
class PhotoTag {
  final int id;
  final String name;
  final String slug;
  final int displayOrder;
  final int photoCount;

  PhotoTag({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayOrder,
    required this.photoCount,
  });

  factory PhotoTag.fromJson(Map<String, dynamic> json) {
    return PhotoTag(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      displayOrder: _toInt(json['display_order']),
      photoCount: _toInt(json['photo_count']),
    );
  }
}

/// Photo comment
class PhotoComment {
  final int id;
  final int userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;

  PhotoComment({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory PhotoComment.fromJson(Map<String, dynamic> json) {
    return PhotoComment(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      username: json['username']?.toString() ?? 'user',
      avatarUrl: json['avatar_url']?.toString(),
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULT CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class PhotoFeedResult {
  final List<FeedPhoto> photos;
  final bool hasMore;
  final String? errorKey;

  PhotoFeedResult({required this.photos, required this.hasMore, this.errorKey});

  bool get hasError => errorKey != null;
}

class EnhancedPhotosResult {
  final List<EnhancedPhoto> photos;
  final bool hasMore;

  EnhancedPhotosResult({required this.photos, required this.hasMore});
}

class RatingResult {
  final bool isSuccess;
  final int creditsEarned;
  final String? errorKey;

  RatingResult._({required this.isSuccess, this.creditsEarned = 0, this.errorKey});

  factory RatingResult.success({int creditsEarned = 5}) {
    return RatingResult._(isSuccess: true, creditsEarned: creditsEarned);
  }

  factory RatingResult.error(String errorKey) {
    return RatingResult._(isSuccess: false, errorKey: errorKey);
  }
}

class PostPhotoResult {
  final bool isSuccess;
  final int? photoId;
  final String? photoUrl;
  final String? errorKey;

  PostPhotoResult._({
    required this.isSuccess,
    this.photoId,
    this.photoUrl,
    this.errorKey,
  });

  factory PostPhotoResult.success({required int photoId, required String photoUrl}) {
    return PostPhotoResult._(isSuccess: true, photoId: photoId, photoUrl: photoUrl);
  }

  factory PostPhotoResult.error(String errorKey) {
    return PostPhotoResult._(isSuccess: false, errorKey: errorKey);
  }
}

class CommentsResult {
  final List<PhotoComment> comments;
  final bool hasMore;

  CommentsResult({required this.comments, required this.hasMore});
}

class CommentResult {
  final bool isSuccess;
  final int? commentId;
  final String? errorKey;

  CommentResult._({required this.isSuccess, this.commentId, this.errorKey});

  factory CommentResult.success({required int commentId}) {
    return CommentResult._(isSuccess: true, commentId: commentId);
  }

  factory CommentResult.error(String errorKey) {
    return CommentResult._(isSuccess: false, errorKey: errorKey);
  }
}

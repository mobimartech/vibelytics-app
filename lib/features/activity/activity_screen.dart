import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/feature_flags.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/activity_service.dart';
import '../../core/services/analysis_service.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import '../../main_shell.dart';
import '../home/comments_screen.dart';
import '../photo/photo_detail_screen.dart';
import '../credits/credit_history_screen.dart';
import '../enhance/enhance_gallery_screen.dart';
import '../enhance/analysis_results_screen.dart';
import '../enhance/chat_results_screen.dart';

/// Activity feed screen - Tab 4
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<ActivityItem> _activities = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _selectedFilter = 0;
  String? _errorMessage;

  static const _filterTypes = [
    'all',
    'rating_received',
    'comment_received',
    'credits_earned',
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
    MainShell.tabChangeNotifier.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // Reload when Activity tab (index 3) becomes visible
    if (MainShell.tabChangeNotifier.value == 3) {
      _loadActivities();
    }
  }

  @override
  void dispose() {
    MainShell.tabChangeNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final type = _filterTypes[_selectedFilter.clamp(0, _filterTypes.length - 1)];
      final result = await ActivityService.instance.getActivities(
        type: type == 'all' ? null : type,
      );

      if (mounted) {
        setState(() {
          _activities = result.activities;
          _hasMore = result.hasMore;
          _isLoading = false;
        });

        MainShell.unreadActivityNotifier.value = result.unreadCount;

        if (result.unreadCount > 0) {
          ActivityService.instance.markAllAsRead();
          MainShell.unreadActivityNotifier.value = 0;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'common.error'.tr();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final type = _filterTypes[_selectedFilter.clamp(0, _filterTypes.length - 1)];
      final result = await ActivityService.instance.getActivities(
        offset: _activities.length,
        type: type == 'all' ? null : type,
      );

      if (mounted) {
        setState(() {
          _activities.addAll(result.activities);
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onFilterChanged(int index) {
    if (_selectedFilter == index) return;
    VHaptics.light();
    setState(() => _selectedFilter = index);
    _loadActivities();
  }

  Future<void> _onActivityTap(ActivityItem item) async {
    VHaptics.light();

    switch (item.type) {
      case 'rating_received':
        final photoId = _resolvePhotoId(item);
        final photoUrl = _resolvePhotoUrl(item);
        if (photoId != null && photoUrl != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhotoDetailScreen(
                photoId: photoId,
                imageUrl: photoUrl,
              ),
            ),
          );
          return;
        }
        if (photoId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CommentsScreen(photoId: photoId),
            ),
          );
          return;
        }
        _showNavigationUnavailable();
        return;
      case 'comment_received':
        final photoId = _resolvePhotoId(item);
        if (photoId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CommentsScreen(photoId: photoId),
            ),
          );
          return;
        }
        _showNavigationUnavailable();
        return;
      case 'credits_earned':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreditHistoryScreen(),
          ),
        );
        return;
      case 'analysis_complete':
        final analysisId = _resolveAnalysisId(item);
        if (analysisId != null) {
          await _openCompletedAnalysis(analysisId);
          return;
        }
        _showNavigationUnavailable();
        return;
      case 'enhancement_ready':
        final photoUrls = _resolveEnhancedPhotoUrls(item);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EnhanceGalleryScreen(
              photos: photoUrls.isEmpty ? null : photoUrls,
              loadFromApi: photoUrls.isEmpty,
            ),
          ),
        );
        return;
    }
  }

  String? _resolvePhotoId(ActivityItem item) {
    final photoId = item.relatedEntityId ??
        _tryParseInt(item.metadata['photo_id']) ??
        _tryParseInt(item.metadata['related_photo_id']) ??
        _tryParseInt(item.metadata['image_id']);
    return photoId?.toString();
  }

  String? _resolvePhotoUrl(ActivityItem item) {
    final candidates = [
      item.metadata['photo_url'],
      item.metadata['image_url'],
      item.metadata['thumbnail_url'],
      item.metadata['preview_url'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  int? _resolveAnalysisId(ActivityItem item) {
    if (item.relatedEntityType == 'analysis' && item.relatedEntityId != null) {
      return item.relatedEntityId;
    }

    return _tryParseInt(item.metadata['analysis_id']) ?? item.relatedEntityId;
  }

  List<String> _resolveEnhancedPhotoUrls(ActivityItem item) {
    final raw = item.metadata['enhanced_photo_urls'] ??
        item.metadata['photo_urls'] ??
        item.metadata['photos'] ??
        item.metadata['photo_url'];

    if (raw is List) {
      return raw
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList();
    }

    final singleUrl = raw?.toString().trim();
    if (singleUrl != null && singleUrl.isNotEmpty) {
      return [singleUrl];
    }

    return const [];
  }

  int? _tryParseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _openCompletedAnalysis(int analysisId) async {
    final analysis = await AnalysisService.instance.getAnalysis(analysisId);
    if (!mounted || analysis == null || analysis.data == null) return;

    if (analysis.isChatAnalysis) {
      if (!FeatureFlags.chatAnalysisEnabled) {
        _showNavigationUnavailable();
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatResultsScreen(
            analysisId: analysisId,
            data: ChatAnalysisData.fromJson(analysis.data!),
            contextUsed: analysis.contextUsed,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisResultsScreen(
          analysisId: analysisId,
          data: ProfileAnalysisData.fromJson(analysis.data!),
          photoPromptsCount: analysis.photoPrompts.length,
        ),
      ),
    );
  }

  void _showNavigationUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('common.error'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200) {
              _loadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: _loadActivities,
            color: VColors.accentPrimary,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: VSpace.screenH,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VSpace.v4,
                        Text(
                          'activity.title'.tr(),
                          style: VType.display
                              .copyWith(color: VColors.text(context)),
                        ),
                        VSpace.v4,
                        // Filter tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'activity.tab_all'.tr(),
                                isActive: _selectedFilter == 0,
                                onTap: () => _onFilterChanged(0),
                              ),
                              VSpace.h2,
                              _FilterChip(
                                label: 'activity.tab_ratings'.tr(),
                                isActive: _selectedFilter == 1,
                                onTap: () => _onFilterChanged(1),
                              ),
                              VSpace.h2,
                              _FilterChip(
                                label: 'activity.tab_comments'.tr(),
                                isActive: _selectedFilter == 2,
                                onTap: () => _onFilterChanged(2),
                              ),
                              VSpace.h2,
                              _FilterChip(
                                label: 'activity.tab_credits'.tr(),
                                isActive: _selectedFilter == 3,
                                onTap: () => _onFilterChanged(3),
                              ),
                            ],
                          ),
                        ),
                        VSpace.v4,
                      ],
                    ),
                  ),
                ),

                // Error state
                if (_errorMessage != null && !_isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(VIcons.warning, size: 48, color: VColors.textTer(context)),
                          VSpace.v4,
                          Text(
                            _errorMessage!,
                            style: VType.body.copyWith(color: VColors.textSec(context)),
                          ),
                          VSpace.v4,
                          TextButton(
                            onPressed: _loadActivities,
                            child: Text('common.retry'.tr()),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                // Content
                if (_isLoading)
                  SliverPadding(
                    padding: VSpace.screenH,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, _) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShimmerSkeleton(
                            height: 72,
                            borderRadius: VRadii.lgRadius,
                          ),
                        ),
                        childCount: 6,
                      ),
                    ),
                  )
                else if (_activities.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: VSpace.screenH,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _activities.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ShimmerSkeleton(
                                height: 72,
                                borderRadius: VRadii.lgRadius,
                              ),
                            );
                          }
                          return _ActivityTile(
                            item: _activities[index],
                            onTap: () => _onActivityTap(_activities[index]),
                          );
                        },
                        childCount:
                            _activities.length + (_isLoadingMore ? 2 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            VIcons.notification,
            size: 64,
            color: VColors.textTer(context),
          ),
          VSpace.v4,
          Text(
            'activity.empty_title'.tr(),
            style: VType.h3.copyWith(color: VColors.text(context)),
          ),
          VSpace.v2,
          Text(
            'activity.empty_desc'.tr(),
            style: VType.body.copyWith(color: VColors.textSec(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? VColors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(color: VColors.borderStrong),
        ),
        child: Text(
          label,
          style: VType.label.copyWith(
            color: isActive ? VColors.textInverse : VColors.textSec(context),
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.item,
    required this.onTap,
  });

  final ActivityItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: VColors.border(context), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / Icon
            _buildAvatar(context),
            VSpace.h3,
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayText,
                    style: VType.body.copyWith(
                      color: VColors.text(context),
                      fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  VSpace.v1,
                  Text(
                    _formatTime(item.createdAt),
                    style: VType.caption.copyWith(color: VColors.textTer(context)),
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!item.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: VColors.accentPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (item.hasActor && item.actorPhoto != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: item.actorPhoto!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: (ctx, _, _) => _iconAvatar(ctx),
        ),
      );
    }
    return _iconAvatar(context);
  }

  Widget _iconAvatar(BuildContext context) {
    final (icon, color) = switch (item.type) {
      'rating_received' => (VIcons.star, VColors.warning),
      'comment_received' => (VIcons.comment, VColors.accentPrimary),
      'credits_earned' => (VIcons.credits, VColors.success),
      'analysis_complete' => (VIcons.aiAnalysis, VColors.aiGradientStart),
      'enhancement_ready' => (VIcons.photoEnhance, VColors.aiGradientEnd),
      _ => (VIcons.notification, VColors.textTer(context)),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  String get _displayText {
    return switch (item.type) {
      'rating_received' => () {
          final rating = item.metadata['rating'];
          final ratingText = rating != null ? ' $rating' : '';
          return 'activity.rating_received'.tr(args: [ratingText]);
        }(),
      'comment_received' => 'activity.comment_received'.tr(),
      'credits_earned' => 'activity.credits_earned'.tr(),
      'analysis_complete' => 'activity.analysis_complete'.tr(),
      'enhancement_ready' => () {
          final count = item.metadata['photo_count'];
          final countText = count != null ? '$count ' : '';
          return 'activity.enhancement_ready'.tr(args: [countText]);
        }(),
      _ => 'activity.new_activity'.tr(),
    };
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'activity.just_now'.tr();
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.month}/${date.day}';
  }
}

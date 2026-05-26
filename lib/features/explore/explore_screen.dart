import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/services/photos_service.dart';
import '../../core/utils/app_logger.dart';
import '../../components/inputs/tag_chip.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import 'leaderboard_screen.dart';
import '../photo/photo_detail_screen.dart';

/// Explore/Discover screen - Tab 2
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<PhotoTag> _tags = [];
  List<FeedPhoto> _trendingPhotos = [];
  bool _isLoading = true;
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        PhotosService.instance.getTags(),
        PhotosService.instance.getFeed(limit: 20, tag: _selectedTag),
      ]);
      if (!mounted) return;
      setState(() {
        _tags = results[0] as List<PhotoTag>;
        _trendingPhotos = (results[1] as PhotoFeedResult).photos;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Explore load failed', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTagSelected(String? tagSlug) {
    setState(() {
      _selectedTag = tagSlug;
      _isLoading = true;
    });
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final result = await PhotosService.instance.getFeed(
      limit: 20,
      tag: _selectedTag,
    );
    if (mounted) {
      setState(() {
        _trendingPhotos = result.photos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: VColors.accentPrimary,
          child: CustomScrollView(
            slivers: [
              // Large title
              SliverToBoxAdapter(
                child: Padding(
                  padding: VSpace.screenH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: VSpace.screenTopGap),
                      Text(
                        'explore.title'.tr(),
                        style: VType.screenTitle.copyWith(
                          color: VColors.text(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tag filter chips
              if (_tags.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: VSpace.screenH,
                        itemCount: _tags.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return TagChip(
                              label: 'home.all_tags'.tr(),
                              isSelected: _selectedTag == null,
                              onTap: () => _onTagSelected(null),
                            );
                          }
                          final tag = _tags[index - 1];
                          return TagChip(
                            label: tag.name,
                            isSelected: _selectedTag == tag.slug,
                            onTap: () => _onTagSelected(tag.slug),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // Quick actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: VSpace.screenH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VSpace.v4,
                      _QuickActionCard(
                        icon: VIcons.leaderboard,
                        title: 'explore.leaderboard'.tr(),
                        subtitle: 'explore.top_rated'.tr(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: VSpace.v4),

              // Trending photos grid
              if (_isLoading)
                SliverPadding(
                  padding: VSpace.screenH,
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, _) => ShimmerSkeleton(borderRadius: VRadii.lgRadius),
                      childCount: 4,
                    ),
                  ),
                )
              else if (_trendingPhotos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          VIcons.explore,
                          size: 64,
                          color: VColors.textTer(context),
                        ),
                        VSpace.v4,
                        Text(
                          'explore.no_photos'.tr(),
                          style: VType.body.copyWith(color: VColors.textSec(context)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: VSpace.screenH,
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final photo = _trendingPhotos[index];
                        return _TrendingPhotoCard(
                          photo: photo,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PhotoDetailScreen(
                                  photoId: photo.id.toString(),
                                  imageUrl: photo.photoUrl,
                                  currentRating: photo.averageRating > 0
                                      ? photo.averageRating
                                      : null,
                                  totalRatings: photo.totalRatings,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: _trendingPhotos.length,
                    ),
                  ),
                ),

              SliverToBoxAdapter(child: VSpace.v8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingPhotoCard extends StatelessWidget {
  const _TrendingPhotoCard({
    required this.photo,
    required this.onTap,
  });

  final FeedPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: VRadii.lgRadius,
          color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: photo.photoUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ShimmerSkeleton(),
              errorWidget: (_, _, _) => Icon(
                VIcons.image,
                size: 32,
                color: VColors.textTer(context),
              ),
            ),
            if (photo.totalRatings > 0)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        VIcons.star,
                        size: 12,
                        color: VColors.accentSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        photo.averageRating.toStringAsFixed(1),
                        style: VType.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: VSpace.card,
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.lgRadius,
          border: Border.all(color: VColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: VColors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: VColors.accentPrimary),
            ),
            VSpace.h3,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VType.screenSectionTitle.copyWith(
                      color: VColors.text(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: VType.caption.copyWith(color: VColors.textSec(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              VIcons.chevronRight,
              color: VColors.textTer(context),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/services/photos_service.dart';
import '../../components/feedback/credit_badge.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import '../../components/inputs/tag_chip.dart';
import '../../main_shell.dart';
import '../photo/photo_detail_screen.dart';

/// Home feed screen - Tab 1
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  List<FeedPhoto> _photos = [];
  List<PhotoTag> _tags = [];
  String? _selectedTag;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _feedError;
  int _offset = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
    MainShell.tabChangeNotifier.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // Refresh feed when Home tab (index 0) becomes visible
    if (MainShell.tabChangeNotifier.value == 0 && !_isLoading) {
      _loadFeed(reset: true);
    }
  }

  @override
  void dispose() {
    MainShell.tabChangeNotifier.removeListener(_onTabChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadFeed(reset: true),
      _loadTags(),
    ]);
  }

  Future<void> _loadTags() async {
    final tags = await PhotosService.instance.getTags();
    if (mounted) setState(() => _tags = tags);
  }

  Future<void> _loadFeed({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _offset = 0;
        _hasMore = true;
        _feedError = null;
      });
    }

    final result = await PhotosService.instance.getFeed(
      limit: _pageSize,
      offset: reset ? 0 : _offset,
      tag: _selectedTag,
    );

    if (mounted) {
      setState(() {
        if (result.hasError && reset) {
          _feedError = result.errorKey;
          _photos = [];
        } else {
          _feedError = null;
          if (reset) {
            _photos = result.photos;
          } else {
            _photos.addAll(result.photos);
          }
        }
        _hasMore = result.hasMore;
        _offset = _photos.length;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _isLoadingMore = true;
      _loadFeed();
    }
  }

  void _onTagSelected(String? tagSlug) {
    setState(() => _selectedTag = tagSlug);
    _loadFeed(reset: true);
  }

  Future<void> _onRefresh() async {
    await MainShell.refreshCredits(force: true);
    await _loadFeed(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: VColors.accentPrimary,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Top bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: VSpace.screenH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'home.title'.tr(),
                        style: VType.screenTitle.copyWith(
                          color: VColors.text(context),
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: MainShell.creditNotifier,
                        builder: (_, credits, _) => CreditBadge(
                          credits: credits,
                          size: CreditBadgeSize.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tag filter chips
              if (_tags.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
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

              VSpace.v4.sliver,

              // Content
              if (_isLoading)
                SliverPadding(
                  padding: VSpace.screenH,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, _) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ShimmerSkeleton(
                          height: 300,
                          borderRadius: VRadii.xlRadius,
                        ),
                      ),
                      childCount: 3,
                    ),
                  ),
                )
              else if (_feedError != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          VIcons.warning,
                          size: 64,
                          color: VColors.textTer(context),
                        ),
                        VSpace.v4,
                        Text(
                          _feedError!.tr(),
                          style: VType.body.copyWith(color: VColors.textSec(context)),
                        ),
                        VSpace.v4,
                        TextButton.icon(
                          onPressed: () => _loadFeed(reset: true),
                          icon: Icon(VIcons.refresh, size: 18),
                          label: Text('common.retry'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: VColors.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_photos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          VIcons.gallery,
                          size: 64,
                          color: VColors.textTer(context),
                        ),
                        VSpace.v4,
                        Text(
                          'home.no_photos'.tr(),
                          style: VType.body.copyWith(color: VColors.textSec(context)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: VSpace.screenH,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _photos.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final photo = _photos[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _FeedPhotoCard(
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
                          ),
                        );
                      },
                      childCount: _photos.length + (_hasMore ? 1 : 0),
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

class _FeedPhotoCard extends StatelessWidget {
  const _FeedPhotoCard({
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
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.xlRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            AspectRatio(
              aspectRatio: 4 / 5,
              child: CachedNetworkImage(
                imageUrl: photo.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ShimmerSkeleton(),
                errorWidget: (_, _, _) => Container(
                  color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                  child: Icon(
                    VIcons.image,
                    color: VColors.textTer(context),
                    size: 48,
                  ),
                ),
              ),
            ),
            // Info bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Tags
                  if (photo.tags.isNotEmpty)
                    Expanded(
                      child: Text(
                        photo.tags.join(' · '),
                        style: VType.caption.copyWith(color: VColors.textSec(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  // Rating
                  if (photo.totalRatings > 0) ...[
                    Icon(VIcons.star, size: 14, color: VColors.accentSecondary),
                    const SizedBox(width: 4),
                    Text(
                      photo.averageRating.toStringAsFixed(1),
                      style: VType.labelSm.copyWith(
                        color: VColors.text(context),
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${photo.totalRatings}',
                      style: VType.caption.copyWith(color: VColors.textTer(context)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension SizedBoxSliverExtension on SizedBox {
  Widget get sliver => SliverToBoxAdapter(child: this);
}

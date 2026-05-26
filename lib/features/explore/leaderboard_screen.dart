import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/services/photos_service.dart';
import '../../core/utils/app_logger.dart';
import '../../components/inputs/tag_chip.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import 'user_profile_screen.dart';

/// Leaderboard screen showing top rated photos
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String? _selectedTagSlug;
  List<PhotoTag> _tags = [];
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        PhotosService.instance.getTags(),
        LeaderboardService.instance.getLeaderboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _tags = results[0] as List<PhotoTag>;
        _entries = (results[1] as LeaderboardResult).entries;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Leaderboard load failed', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTagSelected(String? tagSlug) {
    setState(() {
      _selectedTagSlug = tagSlug;
      _isLoading = true;
    });
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final LeaderboardResult result;
    if (_selectedTagSlug != null) {
      result = await LeaderboardService.instance
          .getLeaderboardByTag(_selectedTagSlug!);
    } else {
      result = await LeaderboardService.instance.getLeaderboard();
    }

    if (mounted) {
      setState(() {
        _entries = result.entries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final top3 = _entries.length >= 3 ? _entries.sublist(0, 3) : _entries;
    final rest = _entries.length > 3
        ? _entries.sublist(3)
        : _entries.length < 3
            ? _entries
            : <LeaderboardEntry>[];

    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'leaderboard.title'.tr(),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: VSpace.screenH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: VSpace.screenTopGap),

                    // Category filter from real tags
                    if (_tags.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: TagChip(
                                label: 'home.all_tags'.tr(),
                                isSelected: _selectedTagSlug == null,
                                onTap: () => _onTagSelected(null),
                              ),
                            ),
                            ..._tags.map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: TagChip(
                                  label: tag.name,
                                  isSelected: _selectedTagSlug == tag.slug,
                                  onTap: () => _onTagSelected(tag.slug),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                    VSpace.v4,
                  ],
                ),
              ),
            ),

            // Loading state
            if (_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: VSpace.screenH,
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ShimmerSkeleton(
                          height: 60,
                          borderRadius: VRadii.mdRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (_entries.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        VIcons.leaderboard,
                        size: 64,
                        color: VColors.textTer(context),
                      ),
                      VSpace.v4,
                      Text(
                        'leaderboard.empty'.tr(),
                        style: VType.body.copyWith(color: VColors.textSec(context)),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Top 3 podium
              if (top3.length >= 3)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: VSpace.screenH,
                    child: _TopThreePodium(entries: top3),
                  ),
                ),

              SliverToBoxAdapter(child: VSpace.v6),

              // Rest of leaderboard
              if (rest.isNotEmpty)
                SliverPadding(
                  padding: VSpace.screenH,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = rest[index];
                        return _LeaderboardRow(
                          entry: entry,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                  userId: entry.userId.toString(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: rest.length,
                    ),
                  ),
                ),
            ],

            SliverToBoxAdapter(child: VSpace.v8),
          ],
        ),
      ),
    );
  }
}

class _TopThreePodium extends StatelessWidget {
  const _TopThreePodium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        Expanded(
          child: _PodiumCard(
            entry: entries[1],
            rank: 2,
            height: 160,
            color: const Color(0xFFC0C0C0),
          ),
        ),
        VSpace.h2,
        // 1st place
        Expanded(
          child: _PodiumCard(
            entry: entries[0],
            rank: 1,
            height: 200,
            color: const Color(0xFFFFD700),
          ),
        ),
        VSpace.h2,
        // 3rd place
        Expanded(
          child: _PodiumCard(
            entry: entries[2],
            rank: 3,
            height: 140,
            color: const Color(0xFFCD7F32),
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
  });

  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
            border: Border.all(color: color, width: 3),
          ),
          child: entry.userPhotoUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: entry.userPhotoUrl!,
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
                    errorWidget: (_, _, _) => Icon(
                      VIcons.user,
                      color: VColors.textTer(context),
                      size: 28,
                    ),
                  ),
                )
              : Icon(
                  VIcons.user,
                  color: VColors.textTer(context),
                  size: 28,
                ),
        ),
        VSpace.v2,
        // Username
        Text(
          entry.username ?? 'User #${entry.userId}',
          style: VType.labelSm.copyWith(color: VColors.text(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        VSpace.v1,
        // Rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(VIcons.star, size: 14, color: VColors.accentSecondary),
            const SizedBox(width: 2),
            Text(
              entry.averageRating.toStringAsFixed(1),
              style: VType.labelSm.copyWith(
                color: VColors.textSec(context),
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
        VSpace.v3,
        // Podium block
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: VType.h1.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.onTap,
  });

  final LeaderboardEntry entry;
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
            bottom: BorderSide(color: VColors.border(context)),
          ),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 32,
              child: Text(
                '#${entry.rank}',
                style: VType.label.copyWith(
                  color: VColors.textTer(context),
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
            VSpace.h3,
            // Photo thumbnail
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
              ),
              child: entry.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: entry.photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Icon(
                        VIcons.user,
                        color: VColors.textTer(context),
                        size: 22,
                      ),
                    )
                  : Icon(
                      VIcons.user,
                      color: VColors.textTer(context),
                      size: 22,
                    ),
            ),
            VSpace.h3,
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username ?? 'User #${entry.userId}',
                    style: VType.label.copyWith(color: VColors.text(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'home.ratings_count'.tr(args: ['${entry.totalRatings}']),
                    style: VType.caption.copyWith(color: VColors.textTer(context)),
                  ),
                ],
              ),
            ),
            // Rating
            Row(
              children: [
                Icon(VIcons.star, size: 16, color: VColors.accentSecondary),
                const SizedBox(width: 4),
                Text(
                  entry.averageRating.toStringAsFixed(1),
                  style: VType.label.copyWith(
                    color: VColors.text(context),
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

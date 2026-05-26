import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/leaderboard_service.dart';
import '../../components/layout/glass_halo.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/secondary_button.dart';
import '../../components/navigation/tab_bar_segment.dart';
import '../../components/feedback/shimmer_skeleton.dart';
import '../photo/photo_detail_screen.dart';

/// Other user's profile screen
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    this.username,
  });

  final String userId;
  final String? username;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  bool _isFollowing = false;
  int _selectedTab = 0;

  UserLeaderboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = int.tryParse(widget.userId);
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final stats = await LeaderboardService.instance.getUserStats(userId);

    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _toggleFollow() {
    VHaptics.medium();
    setState(() => _isFollowing = !_isFollowing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: Icon(VIcons.back, color: VColors.text(context)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    widget.username != null
                        ? '@${widget.username}'
                        : 'User #${widget.userId}',
                    style: VType.h3.copyWith(color: VColors.text(context)),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(VIcons.more, color: VColors.text(context)),
                      onPressed: () => _showOptionsSheet(context),
                    ),
                  ],
                ),
                // Profile header
                SliverToBoxAdapter(
                  child: _buildProfileHeader(),
                ),
                // Tab bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: TabBarUnderline(
                      tabs: ['profile.tab_photos'.tr(), 'profile.tab_rated'.tr()],
                      selectedIndex: _selectedTab,
                      onTabChanged: (index) {
                        setState(() => _selectedTab = index);
                      },
                    ),
                  ),
                ),
                // Photo grid from real data
                if (_stats != null && _stats!.topPhotos.isNotEmpty)
                  SliverPadding(
                    padding: VSpace.screenH,
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childCount: _stats!.topPhotos.length,
                      itemBuilder: (context, index) {
                        final photo = _stats!.topPhotos[index];
                        return _PhotoGridItem(
                          entry: photo,
                          index: index,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PhotoDetailScreen(
                                  photoId: photo.photoId.toString(),
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
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'profile.no_photos_title'.tr(),
                          style: VType.body.copyWith(color: VColors.textSec(context)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: VSpace.screenH,
      child: Column(
        children: [
          // Avatar with glass halo
          GlassHalo(
            size: 88,
            glowColor: VColors.accentPrimary,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
              ),
              child: Icon(
                VIcons.user,
                size: 40,
                color: VColors.textTer(context),
              ),
            ),
          ),
          VSpace.v3,
          // Display name
          Text(
            widget.username != null
                ? '@${widget.username}'
                : 'User #${widget.userId}',
            style: VType.screenSectionTitle.copyWith(
              color: VColors.text(context),
            ),
          ),
          VSpace.v4,
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatColumn(
                value: '${_stats?.totalPhotos ?? 0}',
                label: 'profile.photos'.tr(),
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: VColors.border(context),
              ),
              _StatColumn(
                value: '${_stats?.totalRatingsReceived ?? 0}',
                label: 'profile.ratings'.tr(),
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: VColors.border(context),
              ),
              _StatColumn(
                value: _stats?.avgRating.toStringAsFixed(1) ?? '0.0',
                label: 'profile.avg_rating'.tr(),
                icon: VIcons.star,
              ),
            ],
          ),
          VSpace.v4,
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _isFollowing
                    ? SecondaryButton(
                        label: 'profile.following'.tr(),
                        onPressed: _toggleFollow,
                      )
                    : PrimaryButton(
                        label: 'profile.follow'.tr(),
                        onPressed: _toggleFollow,
                      ),
              ),
              VSpace.h3,
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: VColors.borderStrong),
                  borderRadius: VRadii.lgRadius,
                ),
                child: IconButton(
                  icon: Icon(VIcons.message, color: VColors.text(context)),
                  onPressed: () {
                    VHaptics.light();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    VHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(VIcons.share, color: VColors.text(context)),
              title: Text('profile.share_profile'.tr()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(VIcons.block, color: VColors.text(context)),
              title: Text('profile.block_user'.tr()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(VIcons.flag, color: VColors.error),
              title: Text(
                'profile.report_user'.tr(),
                style: TextStyle(color: VColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: VColors.warning),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: VType.h3.copyWith(color: VColors.text(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: VType.caption.copyWith(color: VColors.textSec(context)),
        ),
      ],
    );
  }
}

class _PhotoGridItem extends StatelessWidget {
  const _PhotoGridItem({
    required this.entry,
    required this.index,
    required this.onTap,
  });

  final LeaderboardEntry entry;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = 150.0 + (index % 3) * 50;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
          borderRadius: VRadii.lgRadius,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (entry.photoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: entry.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ShimmerSkeleton(),
                errorWidget: (_, _, _) => Center(
                  child: Icon(
                    VIcons.image,
                    size: 32,
                    color: VColors.textTer(context),
                  ),
                ),
              )
            else
              Center(
                child: Icon(
                  VIcons.image,
                  size: 32,
                  color: VColors.textTer(context),
                ),
              ),
            // Rating badge
            if (entry.totalRatings > 0)
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
                      Icon(VIcons.star, size: 12, color: VColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        entry.averageRating.toStringAsFixed(1),
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

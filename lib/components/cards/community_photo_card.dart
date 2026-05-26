import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../feedback/shimmer_skeleton.dart';

/// Compact photo card for grid layouts (explore, leaderboard)
class CommunityPhotoCard extends StatelessWidget {
  const CommunityPhotoCard({
    super.key,
    required this.imageUrl,
    this.rating,
    this.rank,
    this.onTap,
  });

  final String imageUrl;
  final double? rating;
  final int? rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: VRadii.mdRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ShimmerSkeleton(),
              errorWidget: (context, url, error) => Container(
                color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: VColors.textTer(context),
                  size: 32,
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Rank badge
            if (rank != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _getRankColor(rank!),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: VType.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            // Rating
            if (rating != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: VColors.accentSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating!.toStringAsFixed(1),
                      style: VType.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return VColors.accentPrimary;
    }
  }
}

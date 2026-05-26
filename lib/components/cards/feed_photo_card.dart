import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../feedback/shimmer_skeleton.dart';

/// Photo card for main feed with rating and stats
class FeedPhotoCard extends StatelessWidget {
  const FeedPhotoCard({
    super.key,
    required this.imageUrl,
    required this.username,
    this.userAvatarUrl,
    this.rating,
    this.ratingCount = 0,
    this.isEnhanced = false,
    this.onTap,
    this.onUserTap,
    this.onRateTap,
  });

  final String imageUrl;
  final String username;
  final String? userAvatarUrl;
  final double? rating;
  final int ratingCount;
  final bool isEnhanced;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onRateTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.xlRadius,
          boxShadow: VShadow.level1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerSkeleton(),
                    errorWidget: (context, url, error) => Container(
                      color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: VColors.textTer(context),
                        size: 48,
                      ),
                    ),
                  ),
                  // Enhanced badge
                  if (isEnhanced)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: VColors.aiGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI',
                              style: VType.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Rating badge
                  if (rating != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: VColors.accentSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: VType.label.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: VSpace.cardDense,
              child: Row(
                children: [
                  // User info
                  GestureDetector(
                    onTap: onUserTap,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: VColors.bgSec(context),
                          backgroundImage: userAvatarUrl != null
                              ? CachedNetworkImageProvider(userAvatarUrl!)
                              : null,
                          child: userAvatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 16,
                                  color: VColors.textTer(context),
                                )
                              : null,
                        ),
                        VSpace.h2,
                        Text(
                          '@$username',
                          style: VType.label.copyWith(
                            color: VColors.text(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Rate button
                  if (rating == null)
                    GestureDetector(
                      onTap: onRateTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: VColors.accentPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_outline,
                              size: 16,
                              color: VColors.accentPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Rate',
                              style: VType.labelSm.copyWith(
                                color: VColors.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      '$ratingCount ratings',
                      style: VType.caption.copyWith(
                        color: VColors.textTer(context),
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
}

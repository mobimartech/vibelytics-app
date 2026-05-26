import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/radii.dart';

/// Shimmer loading skeleton
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: VColors.bgSec(context),
      highlightColor: VColors.bgTer(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
          borderRadius: borderRadius ?? VRadii.mdRadius,
        ),
      ),
    );
  }
}

/// Circle shimmer for avatars
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({
    super.key,
    this.size = 48,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: VColors.bgSec(context),
      highlightColor: VColors.bgTer(context),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Text line shimmer
class ShimmerLine extends StatelessWidget {
  const ShimmerLine({
    super.key,
    this.width = 100,
    this.height = 16,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}

/// Card shimmer placeholder
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.aspectRatio = 4 / 5,
  });

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: ShimmerSkeleton(
            borderRadius: VRadii.xlRadius,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const ShimmerCircle(size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLine(width: 100, height: 14),
                  const SizedBox(height: 4),
                  ShimmerLine(width: 60, height: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Feed list shimmer
class ShimmerFeedList extends StatelessWidget {
  const ShimmerFeedList({
    super.key,
    this.itemCount = 3,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }
}

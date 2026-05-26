import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/shadows.dart';
import '../feedback/shimmer_skeleton.dart';

/// Polaroid-style frame for rated photos
class PolaroidFrame extends StatelessWidget {
  const PolaroidFrame({
    super.key,
    required this.imageUrl,
    this.rating,
    this.caption,
    this.rotation = 0,
    this.width = 200,
    this.onTap,
  });

  final String imageUrl;
  final double? rating;
  final String? caption;
  final double rotation; // in degrees
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageHeight = width * 1.0; // Square aspect ratio for polaroid
    final frameHeight = imageHeight + 48; // Extra space for bottom

    return GestureDetector(
      onTap: onTap,
      child: Transform.rotate(
        angle: rotation * (3.14159 / 180),
        child: Container(
          width: width,
          height: frameHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: VShadow.level2,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            children: [
              // Image area with padding
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: width - 16,
                  height: imageHeight - 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerSkeleton(),
                      errorWidget: (context, url, error) => Container(
                        color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: VColors.textTer(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (caption != null)
                        Expanded(
                          child: Text(
                            caption!,
                            style: VType.caption.copyWith(
                              color: VColors.textSec(context),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      if (rating != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: VColors.accentSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: VType.labelSm.copyWith(
                                color: VColors.text(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stack of polaroids with slight rotations
class PolaroidStack extends StatelessWidget {
  const PolaroidStack({
    super.key,
    required this.imageUrls,
    this.maxVisible = 3,
    this.width = 200,
  });

  final List<String> imageUrls;
  final int maxVisible;
  final double width;

  @override
  Widget build(BuildContext context) {
    final visible = imageUrls.take(maxVisible).toList();
    final rotations = [-5.0, 3.0, -2.0, 4.0];

    return SizedBox(
      width: width + 40,
      height: width + 88,
      child: Stack(
        alignment: Alignment.center,
        children: visible.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value;
          final rotation = rotations[index % rotations.length];

          return Positioned(
            left: index * 10.0,
            top: index * 5.0,
            child: PolaroidFrame(
              imageUrl: url,
              rotation: rotation,
              width: width,
            ),
          );
        }).toList(),
      ),
    );
  }
}

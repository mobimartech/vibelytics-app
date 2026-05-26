import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';

/// Glass halo effect around avatars and circular elements
/// Creates a subtle glowing ring effect
class GlassHalo extends StatelessWidget {
  const GlassHalo({
    super.key,
    required this.child,
    this.size = 88,
    this.glowColor,
    this.glowIntensity = 0.3,
    this.glowRadius = 8,
  });

  final Widget child;
  final double size;
  final Color? glowColor;
  final double glowIntensity;
  final double glowRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = glowColor ?? VColors.accentPrimary;

    return Container(
      width: size + (glowRadius * 2),
      height: size + (glowRadius * 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: glowIntensity),
            blurRadius: glowRadius * 2,
            spreadRadius: glowRadius / 2,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: child,
        ),
      ),
    );
  }
}

/// Avatar with glass halo effect
class HaloAvatar extends StatelessWidget {
  const HaloAvatar({
    super.key,
    this.imageUrl,
    this.size = 88,
    this.glowColor,
    this.showHalo = true,
    this.onTap,
  });

  final String? imageUrl;
  final double size;
  final Color? glowColor;
  final bool showHalo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
          border: Border.all(
            color: (glowColor ?? VColors.accentPrimary).withValues(alpha: 0.3),
            width: 3,
          ),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl == null
            ? Icon(
                Icons.person,
                size: size * 0.45,
                color: VColors.textTer(context),
              )
            : null,
      ),
    );

    if (!showHalo) return avatar;

    return GlassHalo(
      size: size,
      glowColor: glowColor,
      child: avatar,
    );
  }
}

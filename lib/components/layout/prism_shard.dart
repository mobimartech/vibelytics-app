import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';

/// Corner badge with gradient effect (AI indicator, premium badge)
class PrismShard extends StatelessWidget {
  const PrismShard({
    super.key,
    this.label,
    this.icon,
    this.position = PrismPosition.topRight,
    this.useAiGradient = true,
    this.backgroundColor,
  });

  final String? label;
  final IconData? icon;
  final PrismPosition position;
  final bool useAiGradient;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position == PrismPosition.topLeft || position == PrismPosition.topRight
          ? 8
          : null,
      bottom: position == PrismPosition.bottomLeft || position == PrismPosition.bottomRight
          ? 8
          : null,
      left: position == PrismPosition.topLeft || position == PrismPosition.bottomLeft
          ? 8
          : null,
      right: position == PrismPosition.topRight || position == PrismPosition.bottomRight
          ? 8
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 10 : 6,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          gradient: useAiGradient ? VColors.aiGradient : null,
          color: useAiGradient ? null : (backgroundColor ?? VColors.accentPrimary),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.white),
              if (label != null) const SizedBox(width: 4),
            ],
            if (label != null)
              Text(
                label!,
                style: VType.labelSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum PrismPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// AI badge shortcut
class AiBadge extends StatelessWidget {
  const AiBadge({
    super.key,
    this.position = PrismPosition.topRight,
    this.showLabel = true,
  });

  final PrismPosition position;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return PrismShard(
      icon: Icons.auto_awesome,
      label: showLabel ? 'AI' : null,
      position: position,
      useAiGradient: true,
    );
  }
}

/// Premium badge shortcut
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    super.key,
    this.position = PrismPosition.topRight,
  });

  final PrismPosition position;

  @override
  Widget build(BuildContext context) {
    return PrismShard(
      icon: Icons.star,
      label: 'PRO',
      position: position,
      useAiGradient: false,
      backgroundColor: VColors.accentSecondary,
    );
  }
}

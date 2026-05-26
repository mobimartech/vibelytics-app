import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';

/// Resolve a semantic color for a credit balance.
/// 0 → error (red), 1-4 → warning (amber), 5+ → success (green).
Color creditTierColor(int credits) {
  if (credits <= 0) return VColors.error;
  if (credits < 5) return VColors.warning;
  return VColors.success;
}

/// Credit balance badge
class CreditBadge extends StatelessWidget {
  const CreditBadge({
    super.key,
    required this.credits,
    this.size = CreditBadgeSize.medium,
    this.showIcon = true,
    this.onTap,
  });

  final int credits;
  final CreditBadgeSize size;
  final bool showIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (iconSize, textStyle, padding) = switch (size) {
      CreditBadgeSize.small => (
          12.0,
          VType.labelSm,
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      CreditBadgeSize.medium => (
          16.0,
          VType.label,
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      CreditBadgeSize.large => (
          20.0,
          VType.h3,
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
    };

    final color = creditTierColor(credits);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                VIcons.credits,
                size: iconSize,
                color: color,
              ),
              SizedBox(width: size == CreditBadgeSize.small ? 4 : 6),
            ],
            Text(
              credits.toString(),
              style: textStyle.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

enum CreditBadgeSize { small, medium, large }

/// Credit cost indicator. Stays accent-colored — represents *cost*, not balance.
class CreditCost extends StatelessWidget {
  const CreditCost({
    super.key,
    required this.cost,
    this.label,
    this.showSuffix = true,
  });

  final int cost;
  final String? label;
  final bool showSuffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          VIcons.credits,
          size: 14,
          color: VColors.accentPrimary,
        ),
        const SizedBox(width: 4),
        Text(
          label ??
              (showSuffix
                  ? '$cost ${cost == 1 ? 'common.credit'.tr() : 'common.credits'.tr()}'
                  : '$cost'),
          style: VType.labelSm.copyWith(color: VColors.accentPrimary),
        ),
      ],
    );
  }
}

/// Low credits warning banner
class LowCreditsBanner extends StatelessWidget {
  const LowCreditsBanner({
    super.key,
    required this.credits,
    this.threshold = 5,
    this.onBuyTap,
  });

  final int credits;
  final int threshold;
  final VoidCallback? onBuyTap;

  @override
  Widget build(BuildContext context) {
    if (credits >= threshold) return const SizedBox.shrink();

    final color = creditTierColor(credits);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            VIcons.warning,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              credits == 0
                  ? 'credits.insufficient_title'.tr()
                  : 'credits.balance'.tr(args: ['$credits']),
              style: VType.bodySm.copyWith(color: VColors.text(context)),
            ),
          ),
          if (onBuyTap != null)
            GestureDetector(
              onTap: onBuyTap,
              child: Text(
                'credits.buy_more'.tr(),
                style: VType.label.copyWith(color: VColors.textLink),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../buttons/primary_button.dart';
import '../buttons/ghost_button.dart';
import '../feedback/credit_badge.dart';
import 'app_bottom_sheet.dart';

/// Insufficient credits bottom sheet
class InsufficientCreditsSheet extends StatelessWidget {
  const InsufficientCreditsSheet({
    super.key,
    required this.requiredCredits,
    required this.currentCredits,
    this.onBuyCredits,
    this.onWatchAd,
  });

  final int requiredCredits;
  final int currentCredits;
  final VoidCallback? onBuyCredits;
  final VoidCallback? onWatchAd;

  static Future<void> show({
    required BuildContext context,
    required int requiredCredits,
    required int currentCredits,
    VoidCallback? onBuyCredits,
    VoidCallback? onWatchAd,
  }) {
    return AppBottomSheet.show(
      context: context,
      showHandle: true,
      isDismissible: true,
      child: InsufficientCreditsSheet(
        requiredCredits: requiredCredits,
        currentCredits: currentCredits,
        onBuyCredits: onBuyCredits,
        onWatchAd: onWatchAd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deficit = requiredCredits - currentCredits;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: VColors.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            VIcons.credits,
            size: 40,
            color: VColors.warning,
          ),
        ),
        VSpace.v4,
        // Title
        Text(
          'credits.insufficient_title'.tr(),
          style: VType.h2.copyWith(color: VColors.text(context)),
          textAlign: TextAlign.center,
        ),
        VSpace.v2,
        // Description
        Text(
          'credits.insufficient_desc'.tr(args: [deficit.toString()]),
          style: VType.body.copyWith(color: VColors.textSec(context)),
          textAlign: TextAlign.center,
        ),
        VSpace.v4,
        // Credit balance display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
            borderRadius: VRadii.lgRadius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CreditColumn(
                label: 'credits.you_have'.tr(),
                value: currentCredits,
                color: creditTierColor(currentCredits),
              ),
              Container(
                width: 1,
                height: 40,
                color: VColors.border(context),
              ),
              _CreditColumn(
                label: 'credits.you_need'.tr(),
                value: requiredCredits,
                color: VColors.warning,
              ),
            ],
          ),
        ),
        VSpace.v6,
        // Buy credits button
        PrimaryButton(
          label: 'credits.buy_credits'.tr(),
          icon: Icon(VIcons.credits, color: Colors.white, size: 20),
          onPressed: () {
            VHaptics.light();
            Navigator.of(context).pop();
            onBuyCredits?.call();
          },
        ),
        VSpace.v3,
        // Watch ad option
        if (onWatchAd != null) ...[
          GhostButton(
            label: 'credits.watch_ad'.tr(),
            onPressed: () {
              VHaptics.light();
              Navigator.of(context).pop();
              onWatchAd?.call();
            },
          ),
          VSpace.v2,
        ],
        // Referral hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VColors.accentSecondary.withValues(alpha: 0.1),
            borderRadius: VRadii.mdRadius,
          ),
          child: Row(
            children: [
              Icon(VIcons.gift, size: 20, color: VColors.accentSecondary),
              VSpace.h2,
              Expanded(
                child: Text(
                  'credits.referral_hint'.tr(),
                  style: VType.bodySm.copyWith(color: VColors.accentSecondary),
                ),
              ),
            ],
          ),
        ),
        VSpace.v2,
      ],
    );
  }
}

class _CreditColumn extends StatelessWidget {
  const _CreditColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: VType.caption.copyWith(color: VColors.textTer(context)),
        ),
        VSpace.v1,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(VIcons.credits, size: 20, color: color),
            VSpace.h1,
            Text(
              '$value',
              style: VType.h2.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }
}

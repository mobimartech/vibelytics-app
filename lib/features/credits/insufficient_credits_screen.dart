import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/ghost_button.dart';
import '../../components/feedback/credit_badge.dart';
import 'buy_credits_screen.dart';

/// Insufficient credits modal screen
class InsufficientCreditsScreen extends StatelessWidget {
  const InsufficientCreditsScreen({
    super.key,
    this.currentCredits = 0,
    this.requiredCredits = 1,
    this.actionName,
  });

  final int currentCredits;
  final int requiredCredits;
  final String? actionName;

  static Future<bool?> show(
    BuildContext context, {
    int currentCredits = 0,
    int requiredCredits = 1,
    String? actionName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => InsufficientCreditsScreen(
        currentCredits: currentCredits,
        requiredCredits: requiredCredits,
        actionName: actionName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortage = requiredCredits - currentCredits;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: VRadii.xlRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          VSpace.v3,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: VColors.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    VIcons.credits,
                    size: 32,
                    color: VColors.warning,
                  ),
                ),

                VSpace.v4,

                // Title
                Text(
                  'credits.not_enough'.tr(),
                  style: VType.screenTitle.copyWith(
                    color: VColors.text(context),
                  ),
                  textAlign: TextAlign.center,
                ),

                VSpace.v2,

                // Description
                Text(
                  actionName != null
                      ? 'credits.need_more_for_action'.tr(args: [actionName!])
                      : 'credits.need_more'.tr(),
                  style: VType.body.copyWith(color: VColors.textSec(context)),
                  textAlign: TextAlign.center,
                ),

                VSpace.v6,

                // Balance info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                    borderRadius: VRadii.lgRadius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BalanceItem(
                        label: 'credits.current'.tr(),
                        value: currentCredits,
                        color: creditTierColor(currentCredits),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: VColors.border(context),
                      ),
                      _BalanceItem(
                        label: 'credits.required'.tr(),
                        value: requiredCredits,
                        color: VColors.accentPrimary,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: VColors.border(context),
                      ),
                      _BalanceItem(
                        label: 'credits.needed'.tr(),
                        value: shortage,
                        color: VColors.warning,
                      ),
                    ],
                  ),
                ),

                VSpace.v6,

                // Buy credits button
                PrimaryButton(
                  label: 'credits.buy_credits'.tr(),
                  onPressed: () {
                    VHaptics.light();
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => const BuyCreditsScreen(),
                      ),
                    );
                  },
                ),

                VSpace.v2,

                // Watch ad option
                GhostButton(
                  label: 'credits.watch_ad'.tr(),
                  onPressed: () {
                    VHaptics.light();
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(context).pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('credits.ad_not_available'.tr()),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(VIcons.video, size: 18, color: VColors.textLink),
                ),

                SizedBox(height: MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
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
          value.toString(),
          style: VType.h3.copyWith(
            color: color,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        VSpace.v05,
        Text(
          label,
          style: VType.caption.copyWith(color: VColors.textSec(context)),
        ),
      ],
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart' hide Share;
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/ghost_button.dart';
import '../credits/buy_credits_screen.dart';

/// Gatekeeper unlock bottom sheet (viral mechanic)
class GatekeeperSheet extends StatelessWidget {
  const GatekeeperSheet({
    super.key,
    this.previewText,
  });

  final String? previewText;

  /// Show the gatekeeper sheet as a modal
  static Future<bool?> show(
    BuildContext context, {
    String? previewText,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GatekeeperSheet(previewText: previewText),
    );
  }

  void _inviteFriend(BuildContext context) {
    VHaptics.light();
    Navigator.of(context).pop();
    SharePlus.instance.share(
      ShareParams(
        text: 'activity.invite_text'.tr(),
      ),
    );
  }

  void _buyCredits(BuildContext context) {
    VHaptics.light();
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => const BuyCreditsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = previewText ?? 'activity.default_preview'.tr();

    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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

          VSpace.v4,

          // Blurred preview area
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
              borderRadius: VRadii.lgRadius,
            ),
            child: Stack(
              children: [
                // Blurred content
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: VRadii.lgRadius,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: VColors.bgTer(context),
                                ),
                                VSpace.h2,
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: VColors.bgTer(context),
                                ),
                                VSpace.h2,
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: VColors.bgTer(context),
                                ),
                              ],
                            ),
                            VSpace.v3,
                            Text(
                              preview,
                              style: VType.body.copyWith(color: VColors.textSec(context)),
                            ),
                            VSpace.v1,
                            Text(
                              'activity.secret_ratings'.tr(),
                              style: VType.bodySm.copyWith(color: VColors.textTer(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Lock overlay
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      VIcons.lock,
                      size: 24,
                      color: VColors.textTer(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          VSpace.v6,

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'activity.unlock_insights'.tr(),
              style: VType.h2.copyWith(color: VColors.text(context)),
              textAlign: TextAlign.center,
            ),
          ),

          VSpace.v2,

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'activity.unlock_description'.tr(),
              style: VType.body.copyWith(color: VColors.textSec(context)),
              textAlign: TextAlign.center,
            ),
          ),

          VSpace.v6,

          // Invite button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryButton(
              label: 'activity.invite_to_unlock'.tr(),
              onPressed: () => _inviteFriend(context),
            ),
          ),

          VSpace.v2,

          // Bonus text
          Text(
            'activity.friend_bonus'.tr(),
            style: VType.bodySm.copyWith(color: VColors.accentSecondary),
          ),

          VSpace.v4,

          // Buy credits option
          GhostButton(
            label: 'activity.buy_instead'.tr(),
            onPressed: () => _buyCredits(context),
          ),

          SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
        ],
      ),
    );
  }
}

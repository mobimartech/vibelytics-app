import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart' hide Share;
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/secondary_button.dart';

/// Guess the Vibe results screen
class GuessVibeResultsScreen extends StatelessWidget {
  const GuessVibeResultsScreen({
    super.key,
    this.gameId,
  });

  final String? gameId;

  static const _voteResults = [
    ('Creative', 35, '🎨'),
    ('Mysterious', 28, '🌙'),
    ('Chill', 20, '😎'),
    ('Adventurous', 10, '🏔️'),
    ('Other', 7, '✨'),
  ];

  @override
  Widget build(BuildContext context) {
    const yourPick = 'Mysterious';
    const friendsTopPick = 'Creative';
    const totalVotes = 23;

    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: Icon(VIcons.back, color: VColors.text(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'referral.guess_results'.tr(),
          style: VType.h3.copyWith(color: VColors.text(context)),
        ),
        actions: [
          IconButton(
            icon: Icon(VIcons.share, color: VColors.text(context)),
            onPressed: () {
              VHaptics.light();
              SharePlus.instance.share(
                ShareParams(
                  text: 'referral.results_share_text'.tr(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: VSpace.screenH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VSpace.v4,

            // Photo preview
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                  borderRadius: VRadii.xlRadius,
                  boxShadow: VShadow.level2,
                ),
                child: Center(
                  child: Icon(
                    VIcons.image,
                    size: 80,
                    color: VColors.textTer(context),
                  ),
                ),
              ),
            ),

            VSpace.v6,

            // Vote stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VColors.card(context),
                borderRadius: VRadii.lgRadius,
                boxShadow: VShadow.level1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value: '$totalVotes',
                    label: 'referral.total_votes'.tr(),
                    icon: VIcons.users,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: VColors.border(context),
                  ),
                  _StatItem(
                    value: '${_voteResults.first.$2}%',
                    label: 'referral.top_vibe'.tr(),
                    icon: VIcons.trophy,
                  ),
                ],
              ),
            ),

            VSpace.v6,

            // Comparison section
            Text(
              'referral.the_verdict'.tr(),
              style: VType.h3.copyWith(color: VColors.text(context)),
            ),
            VSpace.v3,

            Row(
              children: [
                Expanded(
                  child: _ComparisonCard(
                    label: 'referral.you_picked'.tr(),
                    vibe: yourPick,
                    emoji: '🌙',
                    color: VColors.aiGradientStart,
                  ),
                ),
                VSpace.h3,
                Expanded(
                  child: _ComparisonCard(
                    label: 'referral.friends_voted'.tr(),
                    vibe: friendsTopPick,
                    emoji: '🎨',
                    color: VColors.accentSecondary,
                    isWinner: true,
                  ),
                ),
              ],
            ),

            VSpace.v2,

            if (yourPick == friendsTopPick)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VColors.success.withValues(alpha: 0.1),
                  borderRadius: VRadii.mdRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(VIcons.checkCircle, size: 18, color: VColors.success),
                    VSpace.h2,
                    Text(
                      'referral.perfect_match'.tr(),
                      style: VType.label.copyWith(color: VColors.success),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VColors.aiGradientStart.withValues(alpha: 0.1),
                  borderRadius: VRadii.mdRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'referral.surprise_result'.tr(),
                      style: VType.label.copyWith(color: VColors.aiGradientStart),
                    ),
                  ],
                ),
              ),

            VSpace.v6,

            // Vote breakdown
            Text(
              'referral.vote_breakdown'.tr(),
              style: VType.h3.copyWith(color: VColors.text(context)),
            ),
            VSpace.v3,

            ..._voteResults.map((result) => _VoteBar(
                  vibe: result.$1,
                  percentage: result.$2,
                  emoji: result.$3,
                  isTop: result.$1 == friendsTopPick,
                )),

            VSpace.v8,

            // Actions
            PrimaryButton(
              label: 'referral.create_new_game'.tr(),
              onPressed: () {
                VHaptics.light();
                Navigator.of(context).pop();
              },
            ),

            VSpace.v2,

            SecondaryButton(
              label: 'referral.share_results'.tr(),
              onPressed: () {
                VHaptics.light();
                SharePlus.instance.share(
                  ShareParams(
                    text: 'referral.results_share_text'.tr(),
                  ),
                );
              },
            ),

            VSpace.v6,
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: VColors.accentPrimary),
        VSpace.v1,
        Text(
          value,
          style: VType.h2.copyWith(
            color: VColors.text(context),
            fontFamily: 'JetBrains Mono',
          ),
        ),
        Text(
          label,
          style: VType.caption.copyWith(color: VColors.textSec(context)),
        ),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.label,
    required this.vibe,
    required this.emoji,
    required this.color,
    this.isWinner = false,
  });

  final String label;
  final String vibe;
  final String emoji;
  final Color color;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: VRadii.lgRadius,
        border: Border.all(
          color: color.withValues(alpha: isWinner ? 0.5 : 0.2),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: VType.caption.copyWith(color: VColors.textSec(context)),
          ),
          VSpace.v2,
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          VSpace.v1,
          Text(
            vibe,
            style: VType.label.copyWith(color: color),
          ),
          if (isWinner) ...[
            VSpace.v1,
            Icon(VIcons.trophy, size: 16, color: color),
          ],
        ],
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  const _VoteBar({
    required this.vibe,
    required this.percentage,
    required this.emoji,
    required this.isTop,
  });

  final String vibe;
  final int percentage;
  final String emoji;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  VSpace.h1,
                  Text(
                    vibe,
                    style: VType.label.copyWith(
                      color: isTop ? VColors.accentPrimary : VColors.text(context),
                    ),
                  ),
                  if (isTop) ...[
                    VSpace.h1,
                    Icon(VIcons.trophy, size: 14, color: VColors.warning),
                  ],
                ],
              ),
              Text(
                '$percentage%',
                style: VType.label.copyWith(
                  color: isTop ? VColors.accentPrimary : VColors.textSec(context),
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          VSpace.v1,
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: VColors.bgTer(context),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: isTop ? VColors.accentPrimary : VColors.textTer(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/analysis_service.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/secondary_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../components/feedback/voice_summary_button.dart';

/// Chat analysis results screen with real API data
class ChatResultsScreen extends StatelessWidget {
  const ChatResultsScreen({
    super.key,
    required this.analysisId,
    required this.data,
    this.contextUsed = false,
  });

  final int analysisId;
  final ChatAnalysisData data;
  final bool contextUsed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'enhance.chat_results'.tr(),
        leading: IconButton(
          icon: Icon(VIcons.back, color: VColors.text(context)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(VIcons.share, color: VColors.text(context)),
            onPressed: VHaptics.light,
          ),
        ],
      ),
      body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: VSpace.screenH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voice summary
                    VoiceSummaryButton(analysisId: analysisId),

                    VSpace.v4,

                    // Interaction quality header card
                    if (data.interactionQuality.isNotEmpty)
                      _HeaderCard(
                        title: 'enhance.engagement'.tr(),
                        value: data.interactionQuality,
                      ),

                    VSpace.v6,

                    // Conversation analysis
                    if (data.conversationAnalysis.isNotEmpty)
                      _InsightSection(
                        title: 'enhance.conversation_analysis'.tr(),
                        content: data.conversationAnalysis,
                        accentColor: VColors.accentPrimary,
                      ),

                    VSpace.v4,

                    // Communication style
                    if (data.communicationStyle.isNotEmpty)
                      _InsightSection(
                        title: 'enhance.communication_match'.tr(),
                        content: data.communicationStyle,
                        accentColor: const Color(0xFFA66BFF),
                      ),

                    VSpace.v4,

                    // Compatibility insights
                    if (data.compatibilityInsights.isNotEmpty)
                      _InsightSection(
                        title: 'enhance.chemistry_score'.tr(),
                        content: data.compatibilityInsights,
                        accentColor: VColors.accentSecondary,
                      ),

                    VSpace.v4,

                    // Trust indicators (positive signals)
                    if (data.trustIndicators.isNotEmpty)
                      _FlagsSection(
                        title: 'enhance.green_flags'.tr(),
                        icon: VIcons.checkCircle,
                        iconColor: VColors.success,
                        flags: data.trustIndicators,
                      ),

                    VSpace.v4,

                    // Risk flags
                    if (data.riskFlags.isNotEmpty)
                      _FlagsSection(
                        title: 'enhance.red_flags'.tr(),
                        icon: VIcons.warning,
                        iconColor: VColors.error,
                        flags: data.riskFlags,
                      ),

                    VSpace.v4,

                    // Respect level
                    if (data.respectLevel.isNotEmpty)
                      _InsightSection(
                        title: 'enhance.tone'.tr(),
                        content: data.respectLevel,
                        accentColor: VColors.dataGreen,
                      ),

                    VSpace.v4,

                    // Success probability
                    if (data.successProbability.isNotEmpty)
                      _InsightSection(
                        title: 'enhance.chemistry_score'.tr(),
                        content: data.successProbability,
                        accentColor: const Color(0xFFFF6B9D),
                      ),

                    VSpace.v4,

                    // Recommendations
                    if (data.recommendations.isNotEmpty) ...[
                      Text(
                        'enhance.recommendations'.tr(),
                        style: VType.screenSectionTitle
                            .copyWith(color: VColors.text(context)),
                      ),
                      VSpace.v3,
                      ...data.recommendations.map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: VColors.card(context),
                                borderRadius: VRadii.mdRadius,
                                boxShadow: VShadow.level1,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    VIcons.lightbulb,
                                    size: 18,
                                    color: VColors.accentSecondary,
                                  ),
                                  VSpace.h2,
                                  Expanded(
                                    child: Text(
                                      rec,
                                      style: VType.bodySm.copyWith(
                                        color: VColors.textSec(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],

                    // Context used indicator
                    if (contextUsed)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: VColors.aiGradientStart.withValues(alpha: 0.1),
                          borderRadius: VRadii.mdRadius,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              VIcons.ai,
                              size: 18,
                              color: VColors.aiGradientStart,
                            ),
                            VSpace.h2,
                            Expanded(
                              child: Text(
                                'enhance.context_used'.tr(),
                                style: VType.caption.copyWith(
                                  color: VColors.aiGradientStart,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    VSpace.v8,
                  ],
                ),
              ),
            ),

            // Bottom actions
            BottomActionBarSurface(
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'enhance.save_results'.tr(),
                      onPressed: () {
                        VHaptics.success();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('enhance.results_saved'.tr()),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: VColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                  VSpace.h3,
                  Expanded(
                    child: PrimaryButton(
                      label: 'enhance.analyze_another'.tr(),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
      ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: VSpace.card,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B9D),
            const Color(0xFFFF8E53),
          ],
        ),
        borderRadius: VRadii.xlRadius,
        boxShadow: VShadow.level2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: VType.label.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          VSpace.v2,
          Text(
            value,
            style: VType.body.copyWith(color: Colors.white),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.content,
    required this.accentColor,
  });

  final String title;
  final String content;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: VRadii.lgRadius,
        boxShadow: VShadow.level1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent
          Container(
            width: 4,
            constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VType.h3.copyWith(color: VColors.text(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  VSpace.v2,
                  Text(
                    content,
                    style: VType.body.copyWith(color: VColors.textSec(context)),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagsSection extends StatelessWidget {
  const _FlagsSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.flags,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> flags;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: VRadii.lgRadius,
        boxShadow: VShadow.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              VSpace.h2,
              Expanded(
                child: Text(
                  title,
                  style: VType.h3.copyWith(color: VColors.text(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          VSpace.v3,
          ...flags.map((flag) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    VSpace.h2,
                    Expanded(
                      child: Text(
                        flag,
                        style: VType.body.copyWith(color: VColors.textSec(context)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

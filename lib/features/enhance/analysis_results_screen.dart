import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/analysis_service.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/secondary_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../components/feedback/voice_summary_button.dart';
import 'photo_enhance_screen.dart';

/// Analysis results screen with real API data
class AnalysisResultsScreen extends StatelessWidget {
  const AnalysisResultsScreen({
    super.key,
    required this.analysisId,
    required this.data,
    this.photoPromptsCount = 0,
  });

  final int analysisId;
  final ProfileAnalysisData data;
  final int photoPromptsCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'enhance.results_title'.tr(),
        leading: IconButton(
          icon: Icon(VIcons.back, color: VColors.text(context)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(VIcons.share, color: VColors.text(context)),
            onPressed: () {
              final summary = data.personalitySummary.isNotEmpty
                  ? data.personalitySummary
                  : 'enhance.results_title'.tr();
              SharePlus.instance.share(
                ShareParams(
                  text: 'enhance.share_message'.tr(args: [summary]),
                ),
              );
            },
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

                    VSpace.v6,

                    // Personality Summary
                    if (data.personalitySummary.isNotEmpty) ...[
                      Text(
                        'enhance.personality_summary'.tr(),
                        style: VType.screenSectionTitle
                            .copyWith(color: VColors.text(context)),
                      ),
                      VSpace.v3,
                      Container(
                        padding: VSpace.card,
                        decoration: BoxDecoration(
                          color: VColors.card(context),
                          borderRadius: VRadii.lgRadius,
                          boxShadow: VShadow.level1,
                        ),
                        child: Text(
                          data.personalitySummary,
                          style: VType.body.copyWith(color: VColors.textSec(context)),
                        ),
                      ),
                      VSpace.v6,
                    ],

                    // Communication Strategy
                    if (data.communicationStrategy.isNotEmpty) ...[
                      Text(
                        'enhance.communication_strategy'.tr(),
                        style: VType.screenSectionTitle
                            .copyWith(color: VColors.text(context)),
                      ),
                      VSpace.v3,
                      _InsightCard(
                        icon: VIcons.comment,
                        iconColor: VColors.accentPrimary,
                        title: 'enhance.your_style'.tr(),
                        description: data.communicationStrategy,
                      ),
                      VSpace.v6,
                    ],

                    // Cultural & Religious Insights
                    if (data.culturalReligious.isNotEmpty) ...[
                      Text(
                        'enhance.cultural_insights'.tr(),
                        style: VType.screenSectionTitle
                            .copyWith(color: VColors.text(context)),
                      ),
                      VSpace.v3,
                      Container(
                        padding: VSpace.card,
                        decoration: BoxDecoration(
                          color: VColors.card(context),
                          borderRadius: VRadii.lgRadius,
                          boxShadow: VShadow.level1,
                        ),
                        child: Text(
                          data.culturalReligious,
                          style: VType.body.copyWith(color: VColors.textSec(context)),
                        ),
                      ),
                      VSpace.v6,
                    ],

                    // Key Traits
                    if (data.keyTraits.isNotEmpty) ...[
                      Text(
                        'enhance.key_traits'.tr(),
                        style: VType.screenSectionTitle
                            .copyWith(color: VColors.text(context)),
                      ),
                      VSpace.v3,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.keyTraits.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: VColors.accentPrimary.withValues(alpha: 0.1),
                              borderRadius: VRadii.fullRadius,
                              border: Border.all(
                                color: VColors.accentPrimary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              interest,
                              style: VType.label.copyWith(
                                color: VColors.accentPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      VSpace.v6,
                    ],

                    // AI Image Prompts (if available)
                    if (data.aiImagePrompts.isNotEmpty) ...[
                      Text(
                        'enhance.ai_suggestions'.tr(),
                        style: VType.screenSectionTitle
                            .copyWith(color: VColors.text(context)),
                      ),
                      VSpace.v3,
                      ...data.aiImagePrompts.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InsightCard(
                            icon: VIcons.sparkle,
                            iconColor: VColors.aiGradientStart,
                            title: _translatePromptKey(entry.key),
                            description: entry.value,
                          ),
                        );
                      }),
                      VSpace.v6,
                    ],

                    // Photo prompts count
                    if (photoPromptsCount > 0) ...[
                      Container(
                        padding: VSpace.card,
                        decoration: BoxDecoration(
                          gradient: VColors.aiGradient,
                          borderRadius: VRadii.lgRadius,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              VIcons.camera,
                              color: Colors.white,
                              size: 24,
                            ),
                            VSpace.h3,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'enhance.photo_prompts_ready'.tr(),
                                    style: VType.label.copyWith(color: Colors.white),
                                  ),
                                  Text(
                                    'enhance.photo_prompts_count'.tr(
                                      args: [photoPromptsCount.toString()],
                                    ),
                                    style: VType.bodySm.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('enhance.results_saved'.tr()),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  VSpace.h3,
                  Expanded(
                    child: PrimaryButton(
                      label: 'enhance.enhance_photos'.tr(),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PhotoEnhanceScreen(
                              analysisId: analysisId,
                            ),
                          ),
                        );
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

String _translatePromptKey(String key) {
  final translationKey = 'enhance.prompt_$key';
  final translated = translationKey.tr();
  // If the key isn't translated, fall back to a formatted version
  if (translated == translationKey) {
    return key.replaceAll('_', ' ').split(' ').map((w) =>
      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
    ).join(' ');
  }
  return translated;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: VSpace.cardDense,
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: VRadii.lgRadius,
        boxShadow: VShadow.level1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          VSpace.h3,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: VType.label.copyWith(color: VColors.text(context)),
                ),
                VSpace.v05,
                Text(
                  description,
                  style: VType.bodySm.copyWith(color: VColors.textSec(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

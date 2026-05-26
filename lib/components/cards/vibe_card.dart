import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';

/// AI-generated vibe analysis card with stat bars
class VibeCard extends StatelessWidget {
  const VibeCard({
    super.key,
    required this.title,
    required this.vibeStats,
    this.overallScore,
    this.description,
    this.onTap,
  });

  final String title;
  final List<VibeStat> vibeStats;
  final double? overallScore;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: VSpace.card,
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.xlRadius,
          border: Border.all(
            color: VColors.accentPrimary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // AI icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: VColors.aiGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                VSpace.h3,
                Expanded(
                  child: Text(
                    title,
                    style: VType.h3.copyWith(color: VColors.text(context)),
                  ),
                ),
                if (overallScore != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: VColors.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      overallScore!.toStringAsFixed(1),
                      style: VType.label.copyWith(
                        color: VColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (description != null) ...[
              VSpace.v3,
              Text(
                description!,
                style: VType.bodySm.copyWith(color: VColors.textSec(context)),
              ),
            ],

            VSpace.v4,

            // Vibe stats
            ...vibeStats.map((stat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _VibeStatBar(stat: stat),
                )),
          ],
        ),
      ),
    );
  }
}

class _VibeStatBar extends StatelessWidget {
  const _VibeStatBar({required this.stat});

  final VibeStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stat.label,
              style: VType.caption.copyWith(color: VColors.textSec(context)),
            ),
            Text(
              '${(stat.value * 100).round()}%',
              style: VType.labelSm.copyWith(
                color: VColors.text(context),
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
        VSpace.v1,
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stat.value,
            minHeight: 6,
            backgroundColor: VColors.bgSec(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              stat.color ?? VColors.accentPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class VibeStat {
  const VibeStat({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final double value; // 0.0 to 1.0
  final Color? color;
}

/// Factory for creating standard vibe stats
class VibeStats {
  VibeStats._();

  static List<VibeStat> fromAnalysis({
    required double confidence,
    required double energy,
    required double approachability,
    required double creativity,
    required double authenticity,
  }) {
    return [
      VibeStat(
        label: 'vibe.confidence'.tr(),
        value: confidence.clamp(0.0, 1.0),
        color: const Color(0xFF6366F1),
      ),
      VibeStat(
        label: 'vibe.energy'.tr(),
        value: energy.clamp(0.0, 1.0),
        color: const Color(0xFFF59E0B),
      ),
      VibeStat(
        label: 'vibe.approachability'.tr(),
        value: approachability.clamp(0.0, 1.0),
        color: const Color(0xFF10B981),
      ),
      VibeStat(
        label: 'vibe.creativity'.tr(),
        value: creativity.clamp(0.0, 1.0),
        color: const Color(0xFFEC4899),
      ),
      VibeStat(
        label: 'vibe.authenticity'.tr(),
        value: authenticity.clamp(0.0, 1.0),
        color: const Color(0xFF8B5CF6),
      ),
    ];
  }
}

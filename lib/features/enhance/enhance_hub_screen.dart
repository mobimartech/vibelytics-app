import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../../core/tokens/icons.dart';
import '../../core/config/credit_costs.dart';
import '../../core/config/feature_flags.dart';
import '../../components/feedback/credit_badge.dart';
import '../../main_shell.dart';
import 'profile_upload_screen.dart';
import 'chat_upload_screen.dart';
import 'analysis_history_screen.dart';
import '../profile/enhanced_library_screen.dart';

/// Enhance hub screen - Tab 3 (Center)
class EnhanceHubScreen extends StatelessWidget {
  const EnhanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: VSpace.screenH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: VSpace.screenTopGap),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'enhance.title'.tr(),
                    style: VType.screenTitle.copyWith(
                      color: VColors.text(context),
                    ),
                  ),
                  // Real credit badge
                  ValueListenableBuilder<int>(
                    valueListenable: MainShell.creditNotifier,
                    builder: (_, credits, _) => CreditBadge(
                      credits: credits,
                      size: CreditBadgeSize.medium,
                    ),
                  ),
                ],
              ),

              SizedBox(height: VSpace.screenSectionGap),

              // Action cards
              _ActionCard(
                icon: VIcons.aiAnalysis,
                iconBgColor: const Color(0xFFE8F4FD),
                title: 'enhance.profile_analysis'.tr(),
                description: 'enhance.profile_analysis_desc'.tr(),
                cost: CreditCosts.actionCardLabel(CreditCosts.profileAnalysis),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileUploadScreen(),
                    ),
                  );
                },
              ),

              if (FeatureFlags.chatAnalysisEnabled) ...[
                SizedBox(height: VSpace.screenCardGap),
                _ActionCard(
                  icon: VIcons.chatAnalysis,
                  iconBgColor: const Color(0xFFE8FDF0),
                  title: 'enhance.chat_analysis'.tr(),
                  description: 'enhance.chat_analysis_desc'.tr(),
                  cost: CreditCosts.actionCardLabel(CreditCosts.chatAnalysis),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChatUploadScreen(),
                      ),
                    );
                  },
                ),
              ],

              SizedBox(height: VSpace.screenCardGap),

              _ActionCard(
                icon: VIcons.photoEnhance,
                iconBgColor: const Color(0xFFF3EAFF),
                title: 'enhance.photo_enhancement'.tr(),
                description: 'enhance.photo_enhancement_desc'.tr(),
                cost: CreditCosts.actionCardLabel(CreditCosts.photoEnhancement),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AnalysisHistoryScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: VSpace.screenCardGap),

              // Quick access to enhanced photos library
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EnhancedLibraryScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: VSpace.card,
                  decoration: BoxDecoration(
                    color: VColors.card(context),
                    borderRadius: VRadii.lgRadius,
                    boxShadow: VShadow.level1,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: VColors.accentSecondary.withValues(alpha: 0.1),
                          borderRadius: VRadii.mdRadius,
                        ),
                        child: Icon(VIcons.gallery, color: VColors.accentSecondary),
                      ),
                      VSpace.h3,
                      Expanded(
                        child: Text(
                          'profile.enhanced_library'.tr(),
                          style: VType.label.copyWith(color: VColors.text(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(VIcons.chevronRight, color: VColors.textTer(context)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: VSpace.screenSectionGap),

              // Earn free credits card
              Container(
                padding: VSpace.card,
                decoration: BoxDecoration(
                  color: VColors.accentSecondary.withValues(alpha: 0.08),
                  borderRadius: VRadii.lgRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'enhance.earn_free'.tr(),
                      style: VType.screenSectionTitle.copyWith(
                        color: VColors.text(context),
                      ),
                    ),
                    VSpace.v3,
                    _EarnRow(
                      icon: VIcons.star,
                      label: 'enhance.earn_rate'.tr(),
                      bonus: 'enhance.earn_bonus'.tr(),
                    ),
                    VSpace.v2,
                    _EarnRow(
                      icon: VIcons.gift,
                      label: 'enhance.earn_invite'.tr(),
                      bonus: 'enhance.earn_bonus'.tr(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.description,
    this.cost,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String description;
  final String? cost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: VSpace.card,
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.xlRadius,
          boxShadow: VShadow.level1,
        ),
        child: Row(
          children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: VColors.accentPrimary),
              ),
              VSpace.h4,

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: VType.screenSectionTitle.copyWith(
                        color: VColors.text(context),
                      ),
                    ),
                    VSpace.v05,
                    Text(
                      description,
                      style: VType.screenSupporting.copyWith(
                        color: VColors.textSec(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cost != null) ...[
                      VSpace.v1,
                      Text(
                        cost!,
                        style: VType.labelSm.copyWith(
                          color: VColors.accentPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              Icon(
                VIcons.chevronRight,
                color: VColors.textTer(context),
              ),
            ],
          ),
        ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({
    required this.icon,
    required this.label,
    required this.bonus,
  });

  final IconData icon;
  final String label;
  final String bonus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: VColors.accentSecondary),
        VSpace.h2,
        Text(
          label,
          style: VType.screenBody.copyWith(color: VColors.text(context)),
        ),
        const Spacer(),
        Text(
          bonus,
          style: VType.label.copyWith(color: VColors.accentSecondary),
        ),
      ],
    );
  }
}

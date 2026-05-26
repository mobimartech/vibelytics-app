import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import 'analysis_processing_screen.dart';

/// Roast vs Glaze selector screen (viral mechanic)
class RoastGlazeScreen extends StatefulWidget {
  const RoastGlazeScreen({
    super.key,
    required this.images,
  });

  final List<XFile> images;

  @override
  State<RoastGlazeScreen> createState() => _RoastGlazeScreenState();
}

class _RoastGlazeScreenState extends State<RoastGlazeScreen> {
  String? _selectedMode;

  void _selectMode(String mode) {
    VHaptics.light();
    setState(() => _selectedMode = mode);
  }

  void _continue() {
    if (_selectedMode == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisProcessingScreen(
          images: widget.images,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'enhance.choose_vibe'.tr(),
      ),
      bottomNavigationBar: BottomActionBarSurface(
        child: PrimaryButton(
          label: 'enhance.continue_upload'.tr(),
          onPressed: _selectedMode != null ? _continue : null,
          isEnabled: _selectedMode != null,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: VSpace.screenH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: VSpace.screenTopGap),
              Text(
                'enhance.choose_vibe_subtitle'.tr(),
                style: VType.screenBody.copyWith(color: VColors.textSec(context)),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: VSpace.screenSectionGap),

              // Mode cards
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      mode: 'glaze',
                      emoji: '✨',
                      title: 'enhance.glaze_me'.tr(),
                      description: 'enhance.glaze_description'.tr(),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF3EAFF), Color(0xFFFFF0F5)],
                      ),
                      accentColor: VColors.aiGradientStart,
                      isSelected: _selectedMode == 'glaze',
                      onTap: () => _selectMode('glaze'),
                    ),
                  ),
                  VSpace.h2,
                  Expanded(
                    child: _ModeCard(
                      mode: 'roast',
                      emoji: '🔥',
                      title: 'enhance.roast_me'.tr(),
                      description: 'enhance.roast_description'.tr(),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                      ),
                      accentColor: const Color(0xFFFF6B35),
                      isSelected: _selectedMode == 'roast',
                      onTap: () => _selectMode('roast'),
                      isDark: true,
                    ),
                  ),
                ],
              ),

              SizedBox(height: VSpace.screenSectionGap),

              // Info text
              Container(
                padding: VSpace.card,
                decoration: BoxDecoration(
                  color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                  borderRadius: VRadii.lgRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      VIcons.info,
                      size: 20,
                      color: VColors.textSec(context),
                    ),
                    VSpace.h3,
                    Expanded(
                      child: Text(
                        'enhance.mode_info'.tr(),
                        style: VType.bodySm.copyWith(color: VColors.textSec(context)),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradient,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
    this.isDark = false,
  });

  final String mode;
  final String emoji;
  final String title;
  final String description;
  final Gradient gradient;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 200,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: VRadii.xlRadius,
          border: isSelected
              ? Border.all(color: VColors.accentPrimary, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: VColors.accentPrimary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  VSpace.v3,
                  Text(
                    title,
                    style: VType.screenSectionTitle.copyWith(
                      color: isDark ? Colors.white : VColors.text(context),
                    ),
                  ),
                  VSpace.v1,
                  Text(
                    description,
                    style: VType.caption.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : VColors.textSec(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Bottom accent line
            Positioned(
              bottom: 0,
              left: 16,
              right: 16,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

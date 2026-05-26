import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart' hide Share;
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/services/permission_coordinator.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/secondary_button.dart';

/// Guess the Vibe game creator screen
class GuessVibeCreatorScreen extends StatefulWidget {
  const GuessVibeCreatorScreen({super.key});

  @override
  State<GuessVibeCreatorScreen> createState() => _GuessVibeCreatorScreenState();
}

class _GuessVibeCreatorScreenState extends State<GuessVibeCreatorScreen> {
  final _picker = ImagePicker();
  XFile? _selectedPhoto;
  String? _selectedVibe;
  bool _isGenerating = false;
  String? _shareLink;

  static const _vibeOptions = [
    ('Creative', '🎨'),
    ('Adventurous', '🏔️'),
    ('Chill', '😎'),
    ('Mysterious', '🌙'),
    ('Energetic', '⚡'),
    ('Romantic', '💫'),
  ];

  Future<void> _pickPhoto() async {
    final permissionInfo =
        await PermissionCoordinator.instance.ensurePhotoLibraryAccess(context);
    if (!mounted) return;
    if (!permissionInfo.isAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('permissions.photo_library_required'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) {
      setState(() => _selectedPhoto = image);
    }
  }

  void _selectVibe(String vibe) {
    VHaptics.light();
    setState(() => _selectedVibe = vibe);
  }

  Future<void> _generateLink() async {
    if (_selectedPhoto == null || _selectedVibe == null) return;

    setState(() => _isGenerating = true);

    try {
      // Generate a unique code from timestamp + vibe
      final uniqueCode = DateTime.now().millisecondsSinceEpoch
          .toRadixString(36);
      final vibeSlug = _selectedVibe!.toLowerCase();

      if (!mounted) return;
      VHaptics.success();
      setState(() {
        _isGenerating = false;
        _shareLink = 'https://vibelytics.org/guess/$vibeSlug-$uniqueCode';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
    }
  }

  void _onShareLink() {
    if (_shareLink == null) return;

    VHaptics.light();
    SharePlus.instance.share(
      ShareParams(
        text: 'referral.guess_share_text'.tr(args: [_shareLink!]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: Icon(VIcons.back, color: VColors.text(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'referral.guess_the_vibe'.tr(),
          style: VType.h3.copyWith(color: VColors.text(context)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: VSpace.screenH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace.v4,

              // How it works
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      VColors.aiGradientStart.withValues(alpha: 0.1),
                      VColors.aiGradientEnd.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: VRadii.lgRadius,
                  border: Border.all(
                    color: VColors.aiGradientStart.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(VIcons.lightbulb, size: 20, color: VColors.aiGradientStart),
                        VSpace.h2,
                        Text(
                          'referral.how_it_works'.tr(),
                          style: VType.label.copyWith(color: VColors.text(context)),
                        ),
                      ],
                    ),
                    VSpace.v2,
                    Text(
                      'referral.guess_instructions'.tr(),
                      style: VType.bodySm.copyWith(color: VColors.textSec(context)),
                    ),
                  ],
                ),
              ),

              VSpace.v6,

              // Step 1: Select photo
              _StepHeader(
                number: 1,
                title: 'referral.select_photo'.tr(),
              ),
              VSpace.v3,

              GestureDetector(
                onTap: _shareLink == null ? _pickPhoto : null,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                    borderRadius: VRadii.lgRadius,
                    border: Border.all(color: VColors.border(context)),
                  ),
                  child: _selectedPhoto != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: VRadii.lgRadius,
                              child: FutureBuilder<Widget>(
                                future: _buildImage(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) return snapshot.data!;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: VColors.accentPrimary,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_shareLink == null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedPhoto = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(VIcons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              VIcons.addPhoto,
                              size: 48,
                              color: VColors.textTer(context),
                            ),
                            VSpace.v2,
                            Text(
                              'referral.tap_to_select'.tr(),
                              style: VType.body.copyWith(color: VColors.textTer(context)),
                            ),
                          ],
                        ),
                ),
              ),

              VSpace.v6,

              // Step 2: Pick your vibe
              _StepHeader(
                number: 2,
                title: 'referral.pick_your_vibe'.tr(),
              ),
              VSpace.v2,
              Text(
                'referral.pick_vibe_hint'.tr(),
                style: VType.bodySm.copyWith(color: VColors.textSec(context)),
              ),
              VSpace.v3,

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _vibeOptions.map((option) {
                  final isSelected = _selectedVibe == option.$1;
                  return GestureDetector(
                    onTap: _shareLink == null ? () => _selectVibe(option.$1) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? VColors.accentPrimary : VColors.bgSec(context),
                        borderRadius: VRadii.lgRadius,
                        border: Border.all(
                          color: isSelected ? VColors.accentPrimary : VColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(option.$2, style: const TextStyle(fontSize: 18)),
                          VSpace.h1,
                          Text(
                            option.$1,
                            style: VType.label.copyWith(
                              color: isSelected ? Colors.white : VColors.text(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              VSpace.v8,

              if (_shareLink == null) ...[
                // Generate button
                PrimaryButton(
                  label: 'referral.generate_link'.tr(),
                  onPressed: (_selectedPhoto != null && _selectedVibe != null)
                      ? _generateLink
                      : null,
                  isEnabled: _selectedPhoto != null && _selectedVibe != null,
                  isLoading: _isGenerating,
                ),

                VSpace.v2,

                Center(
                  child: Text(
                    'referral.friends_vote_hint'.tr(),
                    style: VType.caption.copyWith(color: VColors.textSec(context)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                // Share link section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VColors.success.withValues(alpha: 0.1),
                    borderRadius: VRadii.lgRadius,
                    border: Border.all(
                      color: VColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(VIcons.checkCircle, size: 32, color: VColors.success),
                      VSpace.v2,
                      Text(
                        'referral.link_ready'.tr(),
                        style: VType.h3.copyWith(color: VColors.success),
                      ),
                      VSpace.v2,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                          borderRadius: VRadii.mdRadius,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _shareLink!,
                                style: VType.bodySm.copyWith(
                                  color: VColors.textSec(context),
                                  fontFamily: 'JetBrains Mono',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                VHaptics.light();
                                Clipboard.setData(ClipboardData(text: _shareLink!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('common.link_copied'.tr()),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Icon(VIcons.copy, size: 20, color: VColors.accentPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                VSpace.v4,

                PrimaryButton(
                  label: 'referral.share_with_friends'.tr(),
                  onPressed: _onShareLink,
                ),

                VSpace.v2,

                SecondaryButton(
                  label: 'referral.create_another'.tr(),
                  onPressed: () {
                    setState(() {
                      _selectedPhoto = null;
                      _selectedVibe = null;
                      _shareLink = null;
                    });
                  },
                ),
              ],

              VSpace.v6,
            ],
          ),
        ),
      ),
    );
  }

  Future<Widget> _buildImage() async {
    if (_selectedPhoto == null) {
      return const SizedBox.shrink();
    }
    final bytes = await _selectedPhoto!.readAsBytes();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.number,
    required this.title,
  });

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: VColors.accentPrimary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: VType.label.copyWith(color: Colors.white),
            ),
          ),
        ),
        VSpace.h2,
        Text(
          title,
          style: VType.h3.copyWith(color: VColors.text(context)),
        ),
      ],
    );
  }
}

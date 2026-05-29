import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/credit_costs.dart';
import '../../core/config/feature_flags.dart';
import '../../core/services/permission_coordinator.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../components/feedback/credit_badge.dart';
import '../../components/modals/insufficient_credits_sheet.dart';
import '../../main_shell.dart';
import '../credits/buy_credits_screen.dart';
import 'chat_processing_screen.dart';

/// Screen for uploading conversation screenshots for AI analysis
class ChatUploadScreen extends StatefulWidget {
  const ChatUploadScreen({super.key});

  @override
  State<ChatUploadScreen> createState() => _ChatUploadScreenState();
}

class _ChatUploadScreenState extends State<ChatUploadScreen> {
  final List<XFile> _selectedImages = [];
  final _picker = ImagePicker();
  static const int _maxImages = 10;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || FeatureFlags.chatAnalysisEnabled) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('enhance.feature_coming_soon'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).maybePop();
    });
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) return;

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

    final remaining = _maxImages - _selectedImages.length;
    final images = await _picker.pickMultiImage(limit: remaining);
    if (!mounted) return;

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(remaining));
      });
    }
  }

  void _removeImage(int index) {
    VHaptics.light();
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _startAnalysis() {
    if (_selectedImages.isEmpty || _isNavigating) return;

    const cost = CreditCosts.chatAnalysis;
    final balance = MainShell.creditNotifier.value;
    if (balance < cost) {
      InsufficientCreditsSheet.show(
        context: context,
        requiredCredits: cost,
        currentCredits: balance,
        onBuyCredits: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BuyCreditPacksScreen()),
        ),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ChatProcessingScreen(images: _selectedImages),
      ),
    )
        .then((_) {
      if (!mounted) return;
      setState(() {
        _isNavigating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'enhance.chat_analysis'.tr(),
        actions: [
          Center(
            child: ValueListenableBuilder<int>(
              valueListenable: MainShell.creditNotifier,
              builder: (_, credits, _) =>
                  CreditBadge(credits: credits, size: CreditBadgeSize.small),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: VSpace.screenH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VSpace.v4,

                    // Description
                    Text(
                      'enhance.chat_upload_description'.tr(),
                      style:
                          VType.screenBody.copyWith(color: VColors.textSec(context)),
                    ),

                    VSpace.v6,

                    // Image grid
                    if (_selectedImages.isNotEmpty) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return _ScreenshotTile(
                            image: _selectedImages[index],
                            index: index + 1,
                            onRemove: () => _removeImage(index),
                          );
                        },
                      ),
                      VSpace.v4,
                    ],

                    // Add button
                    if (_selectedImages.length < _maxImages)
                      _AddScreenshotButton(
                        onTap: _pickImages,
                        isEmpty: _selectedImages.isEmpty,
                      ),

                    VSpace.v4,

                    // Counter
                    Text(
                      'enhance.screenshots_selected'.tr(
                        args: ['${_selectedImages.length}', '$_maxImages'],
                      ),
                      style:
                          VType.screenMeta.copyWith(color: VColors.textTer(context)),
                    ),

                    VSpace.v6,

                    // Tips
                    Container(
                      padding: VSpace.card,
                      decoration: BoxDecoration(
                        color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                        borderRadius: VRadii.lgRadius,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                VIcons.lightbulb,
                                size: 20,
                                color: VColors.accentSecondary,
                              ),
                              VSpace.h2,
                              Text(
                                'enhance.chat_tips_title'.tr(),
                                style: VType.label.copyWith(
                                  color: VColors.text(context),
                                ),
                              ),
                            ],
                          ),
                          VSpace.v3,
                          _TipItem(text: 'enhance.chat_tip_1'.tr()),
                          _TipItem(text: 'enhance.chat_tip_2'.tr()),
                          _TipItem(text: 'enhance.chat_tip_3'.tr()),
                        ],
                      ),
                    ),

                    VSpace.v4,

                    // Privacy notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VColors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: VRadii.mdRadius,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            VIcons.privacy,
                            size: 18,
                            color: VColors.accentPrimary,
                          ),
                          VSpace.h2,
                          Expanded(
                            child: Text(
                              'enhance.chat_privacy'.tr(),
                              style: VType.screenMeta.copyWith(
                                color: VColors.accentPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar
            BottomActionBarSurface(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        VIcons.credits,
                        size: 16,
                        color: VColors.accentPrimary,
                      ),
                      VSpace.h1,
                      Text(
                        CreditCosts.usageLabel(CreditCosts.chatAnalysis),
                        style: VType.screenMeta.copyWith(
                          color: VColors.textSec(context),
                        ),
                      ),
                    ],
                  ),
                  VSpace.v3,
                  PrimaryButton(
                    label: 'enhance.analyze_chat'.tr(),
                    onPressed: _selectedImages.isNotEmpty ? _startAnalysis : null,
                    isEnabled: _selectedImages.isNotEmpty,
                    isLoading: _isNavigating,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddScreenshotButton extends StatelessWidget {
  const _AddScreenshotButton({
    required this.onTap,
    required this.isEmpty,
  });

  final VoidCallback onTap;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isEmpty ? 200 : 100,
        decoration: BoxDecoration(
          color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
          borderRadius: VRadii.lgRadius,
          border: Border.all(
            color: VColors.border(context),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              VIcons.addPhoto,
              size: isEmpty ? 48 : 32,
              color: VColors.textTer(context),
            ),
            VSpace.v2,
            Text(
              isEmpty
                  ? 'enhance.add_screenshots'.tr()
                  : 'enhance.add_more'.tr(),
              style: VType.body.copyWith(color: VColors.textTer(context)),
            ),
            if (isEmpty) ...[
              VSpace.v1,
              Text(
                'enhance.add_screenshots_hint'.tr(),
                style: VType.caption.copyWith(color: VColors.textTer(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScreenshotTile extends StatelessWidget {
  const _ScreenshotTile({
    required this.image,
    required this.index,
    required this.onRemove,
  });

  final XFile image;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: VRadii.mdRadius,
          child: FutureBuilder<Widget>(
            future: _buildImage(),
            builder: (context, snapshot) {
              if (snapshot.hasData) return snapshot.data!;
              return Container(
                color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VColors.accentPrimary,
                  ),
                ),
              );
            },
          ),
        ),
        // Index badge
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: VColors.accentPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: VType.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                VIcons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<Widget> _buildImage() async {
    final bytes = await image.readAsBytes();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: VType.body.copyWith(color: VColors.textSec(context)),
          ),
          VSpace.h2,
          Expanded(
            child: Text(
              text,
              style: VType.bodySm.copyWith(color: VColors.textSec(context)),
            ),
          ),
        ],
      ),
    );
  }
}

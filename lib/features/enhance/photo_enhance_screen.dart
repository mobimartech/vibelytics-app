import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/config/credit_costs.dart';
import '../../core/services/permission_coordinator.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/image_utils.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/ai_gradient_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../components/feedback/credit_badge.dart';
import '../../components/modals/insufficient_credits_sheet.dart';
import '../../main_shell.dart';
import '../credits/buy_credits_screen.dart';
import 'enhance_processing_screen.dart';

/// Photo enhancement screen — pick a reference photo, upload it, call the
/// enhance API, then navigate to the gallery with real enhanced photo URLs.
class PhotoEnhanceScreen extends StatefulWidget {
  const PhotoEnhanceScreen({
    super.key,
    required this.analysisId,
  });

  /// The analysis ID whose prompts will be used for enhancement.
  final int analysisId;

  @override
  State<PhotoEnhanceScreen> createState() => _PhotoEnhanceScreenState();
}

class _PhotoEnhanceScreenState extends State<PhotoEnhanceScreen> {
  XFile? _selectedImage;
  final _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImage() async {
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
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _enhancePhoto() async {
    if (_selectedImage == null) return;

    const cost = CreditCosts.photoEnhancement;
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
      _isProcessing = true;
    });

    try {
      // Convert reference photo to base64 data URI
      AppLogger.i('Converting reference photo to base64...');
      final dataUri = await ImageUtils.xFileToBase64DataUri(_selectedImage!);

      if (!mounted) return;

      // Navigate to processing screen (handles foreground/background)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EnhanceProcessingScreen(
            analysisId: widget.analysisId,
            referencePhotoBase64: dataUri,
          ),
        ),
      );
    } catch (e) {
      AppLogger.e('Failed to convert image', error: e);
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('enhance.failed'.tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'enhance.photo_enhancement'.tr(),
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
              child: _selectedImage == null
                  ? _EmptyState(onPickImage: _pickImage)
                  : _PreviewState(
                      image: _selectedImage!,
                      isProcessing: _isProcessing,
                    ),
            ),

            // Bottom actions
            BottomActionBarSurface(
              child: _buildBottomAction(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    if (_selectedImage == null) {
      return PrimaryButton(
        label: 'enhance.select_photo'.tr(),
        onPressed: _pickImage,
      );
    }

    if (_isProcessing) {
      return Column(
        children: [
          Text(
            'enhance.processing_hint'.tr(),
            style: VType.caption.copyWith(color: VColors.textTer(context)),
            textAlign: TextAlign.center,
          ),
          VSpace.v3,
          PrimaryButton(
            label: 'enhance.processing'.tr(),
            onPressed: null,
            isLoading: true,
          ),
        ],
      );
    }

    return Column(
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
              CreditCosts.usageLabel(CreditCosts.photoEnhancement),
              style: VType.caption.copyWith(color: VColors.textSec(context)),
            ),
          ],
        ),
        VSpace.v3,
        AiGradientButton(
          label: 'enhance.enhance_button'.tr(),
          icon: Icon(VIcons.sparkle, color: Colors.white, size: 20),
          onPressed: _enhancePhoto,
        ),
        VSpace.v2,
        GestureDetector(
          onTap: _pickImage,
          child: Text(
            'enhance.change_photo'.tr(),
            style: VType.label.copyWith(color: VColors.accentPrimary),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPickImage});

  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VSpace.screenH,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: VColors.aiGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              VIcons.photoEnhance,
              size: 56,
              color: Colors.white,
            ),
          ),
          VSpace.v6,
          Text(
            'enhance.photo_enhance_title'.tr(),
            style: VType.screenTitle.copyWith(color: VColors.text(context)),
            textAlign: TextAlign.center,
          ),
          VSpace.v3,
          Text(
            'enhance.photo_enhance_desc'.tr(),
            style: VType.body.copyWith(color: VColors.textSec(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PreviewState extends StatelessWidget {
  const _PreviewState({
    required this.image,
    required this.isProcessing,
  });

  final XFile image;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: VRadii.xlRadius,
            child: FutureBuilder<Widget>(
              future: _buildImage(),
              builder: (context, snapshot) {
                if (snapshot.hasData) return snapshot.data!;
                return Container(color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark));
              },
            ),
          ),
        ),
        if (isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: VColors.aiGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    VIcons.photoEnhance,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                VSpace.v4,
                Text(
                  'enhance.enhancing'.tr(),
                  style: VType.h3.copyWith(color: Colors.white),
                ),
                VSpace.v2,
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      VColors.accentPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<Widget> _buildImage() async {
    final bytes = await image.readAsBytes();
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

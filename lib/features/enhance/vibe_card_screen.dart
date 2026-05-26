import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' hide Share;
import 'package:url_launcher/url_launcher.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/services/permission_coordinator.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/ghost_button.dart';
import '../../components/buttons/secondary_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';

/// Vibe Card screen - shareable trading card with user stats
class VibeCardScreen extends StatefulWidget {
  const VibeCardScreen({
    super.key,
    this.username = 'user',
    this.vibeStats,
  });

  final String username;
  final Map<String, int>? vibeStats;

  @override
  State<VibeCardScreen> createState() => _VibeCardScreenState();
}

class _VibeCardScreenState extends State<VibeCardScreen> {
  final _cardKey = GlobalKey();
  late Map<String, int> _stats;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _stats = widget.vibeStats ?? _generateRandomStats();
  }

  Map<String, int> _generateRandomStats() {
    return {
      'MYSTERY': 92,
      'AESTHETIC': 88,
      'ENERGY': 76,
      'CHAOS': 15,
      'WARMTH': 94,
    };
  }

  String _getRarityBadge() {
    final total = _stats.values.reduce((a, b) => a + b);
    final avg = total / _stats.length;

    if (avg >= 85) return 'enhance.rarity_legendary'.tr();
    if (avg >= 75) return 'enhance.rarity_rare'.tr();
    if (avg >= 60) return 'enhance.rarity_uncommon'.tr();
    return 'enhance.rarity_common'.tr();
  }

  Future<File?> _captureCardImage() async {
    final boundary = _cardKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/vibe_card_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<void> _saveToPhotos() async {
    setState(() => _isSaving = true);

    try {
      final permissionInfo =
          await PermissionCoordinator.instance.ensureGallerySaveAccess(
        context,
      );
      if (!mounted) return;
      if (!permissionInfo.isAllowed) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('permissions.gallery_save_required'.tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.error,
          ),
        );
        return;
      }

      final file = await _captureCardImage();
      if (!mounted) return;

      if (file != null) {
        // Save to device photo gallery
        await Gal.putImage(file.path, album: 'Vibelytics');
        if (!mounted) return;
        VHaptics.success();
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('enhance.card_saved'.tr()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: VColors.success,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.error'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on GalException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppLogger.e('Failed to save to gallery', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _regenerateCard() {
    VHaptics.medium();
    setState(() {
      _stats = {
        'MYSTERY': 50 + (DateTime.now().millisecond % 50),
        'AESTHETIC': 50 + (DateTime.now().microsecond % 50),
        'ENERGY': 40 + (DateTime.now().millisecond % 55),
        'CHAOS': 10 + (DateTime.now().microsecond % 35),
        'WARMTH': 60 + (DateTime.now().millisecond % 40),
      };
    });
  }

  Future<void> _shareToApp(String app) async {
    VHaptics.light();

    // Capture the card as an image for sharing
    final file = await _captureCardImage();
    if (!mounted) return;

    final shareText = 'enhance.share_message'.tr(args: [widget.username]);

    if (file != null) {
      // Share with the captured image
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'enhance.share_subject'.tr(),
          files: [XFile(file.path)],
        ),
      );
    } else {
      // Fallback: share text only via app-specific URL
      switch (app) {
        case 'whatsapp':
          await launchUrl(Uri.parse(
            'https://wa.me/?text=${Uri.encodeComponent(shareText)}',
          ));
          return;
        case 'instagram':
          // Instagram doesn't support text-only share via URL, use system share
          await SharePlus.instance.share(
            ShareParams(text: shareText, subject: 'enhance.share_subject'.tr()),
          );
          return;
        default:
          await SharePlus.instance.share(
            ShareParams(text: shareText, subject: 'enhance.share_subject'.tr()),
          );
          return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'enhance.your_vibe_card'.tr(),
      ),
      bottomNavigationBar: BottomActionBarSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GhostButton(
              label: _isSaving
                  ? 'common.saving'.tr()
                  : 'enhance.save_to_photos'.tr(),
              onPressed: _isSaving ? null : _saveToPhotos,
              icon: Icon(VIcons.download, size: 18, color: VColors.textLink),
            ),
            SizedBox(height: VSpace.screenDenseGap),
            SecondaryButton(
              label: 'enhance.regenerate_card'.tr(),
              onPressed: _regenerateCard,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: VSpace.screenH,
          child: Column(
            children: [
              SizedBox(height: VSpace.screenTopGap),

              // Vibe card
              RepaintBoundary(
                key: _cardKey,
                child: _VibeCardWidget(
                  username: widget.username,
                  stats: _stats,
                  rarityBadge: _getRarityBadge(),
                ),
              ),

              VSpace.v6,

              // Share label
              Text(
                'enhance.share_vibe_card'.tr(),
                style: VType.screenSectionTitle.copyWith(
                  color: VColors.text(context),
                ),
              ),

              VSpace.v3,

              // Share destinations
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShareButton(
                    icon: VIcons.camera,
                    label: 'Instagram',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                    ),
                    onTap: () => _shareToApp('instagram'),
                  ),
                  VSpace.h3,
                  _ShareButton(
                    icon: VIcons.music,
                    label: 'TikTok',
                    color: Colors.black,
                    onTap: () => _shareToApp('tiktok'),
                  ),
                  VSpace.h3,
                  _ShareButton(
                    icon: VIcons.comment,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => _shareToApp('whatsapp'),
                  ),
                  VSpace.h3,
                  _ShareButton(
                    icon: VIcons.copy,
                    label: 'enhance.copy_link'.tr(),
                    color: VColors.textTer(context),
                    onTap: () {
                      VHaptics.light();
                      final shareText = 'enhance.share_message'.tr(
                        args: [widget.username],
                      );
                      Clipboard.setData(ClipboardData(text: shareText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('common.link_copied'.tr()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: VSpace.screenSectionGap),
            ],
          ),
        ),
      ),
    );
  }
}

class _VibeCardWidget extends StatelessWidget {
  const _VibeCardWidget({
    required this.username,
    required this.stats,
    required this.rarityBadge,
  });

  final String username;
  final Map<String, int> stats;
  final String rarityBadge;

  Color _getStatColor(String stat) {
    switch (stat) {
      case 'MYSTERY':
        return const Color(0xFFA66BFF);
      case 'AESTHETIC':
        return const Color(0xFFFF82B2);
      case 'ENERGY':
        return const Color(0xFF00A1FF);
      case 'CHAOS':
        return const Color(0xFFFFB020);
      case 'WARMTH':
        return const Color(0xFF00C2A8);
      default:
        return VColors.accentPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.5 / 3.5,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0D),
          borderRadius: VRadii.xlRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: VColors.aiGradientStart.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Corner accents
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      VColors.aiGradientStart.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                    colors: [
                      VColors.aiGradientEnd.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // User photo and name
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: VColors.aiGradient,
                      boxShadow: [
                        BoxShadow(
                          color: VColors.aiGradientStart.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0B0B0D),
                      ),
                      child: Icon(
                        VIcons.user,
                        size: 36,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  VSpace.v2,

                  Text(
                    '@$username',
                    style: VType.label.copyWith(color: Colors.white),
                  ),

                  VSpace.v2,

                  // Rarity badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rarityBadge,
                      style: VType.caption.copyWith(
                        color: const Color(0xFFFFD700),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  VSpace.v4,

                  // Stats
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: stats.entries.map((entry) {
                        return _StatBar(
                          label: entry.key,
                          value: entry.value,
                          color: _getStatColor(entry.key),
                        );
                      }).toList(),
                    ),
                  ),

                  VSpace.v2,

                  // Watermark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'vibelytics.com',
                        style: VType.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        VIcons.qrCode,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ],
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

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: VType.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 28,
          child: Text(
            value.toString(),
            style: VType.label.copyWith(
              color: color,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gradient == null ? color : null,
              gradient: gradient,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          VSpace.v1,
          Text(
            label,
            style: VType.caption.copyWith(color: VColors.textSec(context)),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

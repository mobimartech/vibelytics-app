import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:url_launcher/url_launcher.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import 'app_bottom_sheet.dart';

/// Share content bottom sheet
class ShareSheet extends StatelessWidget {
  const ShareSheet({
    super.key,
    required this.shareUrl,
    this.shareText,
    this.shareSubject,
  });

  final String shareUrl;
  final String? shareText;
  final String? shareSubject;

  static Future<void> show({
    required BuildContext context,
    required String shareUrl,
    String? shareText,
    String? shareSubject,
  }) {
    return AppBottomSheet.show(
      context: context,
      showHandle: true,
      child: ShareSheet(
        shareUrl: shareUrl,
        shareText: shareText,
        shareSubject: shareSubject,
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareUrl));
    VHaptics.success();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('share.link_copied'.tr()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: VColors.success,
      ),
    );
  }

  void _shareNative() {
    VHaptics.light();
    SharePlus.instance.share(
      ShareParams(
        text: shareText ?? shareUrl,
        subject: shareSubject,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'share.title'.tr(),
          style: VType.h2.copyWith(color: VColors.text(context)),
        ),
        VSpace.v4,
        // Link preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
            borderRadius: VRadii.lgRadius,
          ),
          child: Row(
            children: [
              Icon(VIcons.link, size: 20, color: VColors.textTer(context)),
              VSpace.h3,
              Expanded(
                child: Text(
                  shareUrl,
                  style: VType.body.copyWith(color: VColors.textSec(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        VSpace.v4,
        // Share options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ShareOption(
              icon: VIcons.copy,
              label: 'share.copy_link'.tr(),
              onTap: () => _copyLink(context),
            ),
            _ShareOption(
              icon: VIcons.share,
              label: 'share.more'.tr(),
              onTap: _shareNative,
            ),
          ],
        ),
        VSpace.v4,
        // Social options
        Text(
          'share.share_to'.tr(),
          style: VType.label.copyWith(color: VColors.textSec(context)),
        ),
        VSpace.v3,
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _SocialButton(
              icon: Icons.message,
              color: const Color(0xFF25D366), // WhatsApp green
              label: 'WhatsApp',
              onTap: () {
                VHaptics.light();
                launchUrl(Uri.parse(
                  'https://wa.me/?text=${Uri.encodeComponent(shareText ?? shareUrl)}',
                ));
              },
            ),
            VSpace.h3,
            _SocialButton(
              icon: Icons.send,
              color: const Color(0xFF0088CC), // Telegram blue
              label: 'Telegram',
              onTap: () {
                VHaptics.light();
                launchUrl(Uri.parse(
                  'https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(shareText ?? '')}',
                ));
              },
            ),
            VSpace.h3,
            _SocialButton(
              icon: Icons.alternate_email,
              color: const Color(0xFF1DA1F2), // Twitter blue
              label: 'Twitter',
              onTap: () {
                VHaptics.light();
                launchUrl(Uri.parse(
                  'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText ?? shareUrl)}',
                ));
              },
            ),
          ],
        ),
        VSpace.v2,
      ],
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: VColors.accentPrimary),
          ),
          VSpace.v2,
          Text(
            label,
            style: VType.caption.copyWith(color: VColors.textSec(context)),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

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
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          VSpace.v1,
          Text(
            label,
            style: VType.caption.copyWith(color: VColors.textSec(context)),
          ),
        ],
      ),
    );
  }
}

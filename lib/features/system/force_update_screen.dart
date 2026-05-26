import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';

/// Force update screen - displayed when app version is below minimum required
///
/// Non-dismissible screen that requires user to update the app:
/// - Cannot be dismissed with back button
/// - Shows update icon and message
/// - "Update Now" button opens app store
class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({
    super.key,
    this.currentVersion,
    this.requiredVersion,
  });

  final String? currentVersion;
  final String? requiredVersion;

  /// App Store URL for iOS
  static const String _appStoreUrl = 'https://vibelytics.org/download';

  /// Play Store URL for Android
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=play.store.vibelytics';

  /// Shows the force update screen as a full-screen replacement
  /// This prevents the user from navigating back
  static void show(BuildContext context, {String? currentVersion, String? requiredVersion}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForceUpdateScreen(
          currentVersion: currentVersion,
          requiredVersion: requiredVersion,
        ),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  String get _storeUrl {
    if (Platform.isIOS) {
      return ForceUpdateScreen._appStoreUrl;
    }
    return ForceUpdateScreen._playStoreUrl;
  }

  Future<void> _openStore() async {
    VHaptics.light();
    final uri = Uri.parse(_storeUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('Could not launch');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _storeUrl));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('system.update_link_copied'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        
        body: SafeArea(
          child: Padding(
            padding: VSpace.screen,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: VColors.aiGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.download,
                    size: 48,
                    color: VColors.textInverse,
                  ),
                ),

                VSpace.v8,

                // Title
                Text(
                  'system.update_required_title'.tr(),
                  style: VType.h1.copyWith(color: VColors.text(context)),
                  textAlign: TextAlign.center,
                ),

                VSpace.v3,

                // Message
                Text(
                  'system.update_required_message'.tr(),
                  style: VType.body.copyWith(color: VColors.textSec(context)),
                  textAlign: TextAlign.center,
                ),

                // Version info (optional)
                if (widget.currentVersion != null || widget.requiredVersion != null) ...[
                  VSpace.v6,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (widget.currentVersion != null)
                          _VersionRow(
                            label: 'system.current_version'.tr(),
                            version: widget.currentVersion!,
                          ),
                        if (widget.currentVersion != null && widget.requiredVersion != null)
                          VSpace.v2,
                        if (widget.requiredVersion != null)
                          _VersionRow(
                            label: 'system.required_version'.tr(),
                            version: widget.requiredVersion!,
                            isRequired: true,
                          ),
                      ],
                    ),
                  ),
                ],

                const Spacer(flex: 3),

                // Update button
                PrimaryButton(
                  label: 'system.update_button'.tr(),
                  onPressed: _openStore,
                  icon: Icon(
                    LucideIcons.externalLink,
                    size: 18,
                    color: VColors.textInverse,
                  ),
                ),

                VSpace.v4,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.version,
    this.isRequired = false,
  });

  final String label;
  final String version;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: VType.bodySm.copyWith(color: VColors.textSec(context)),
        ),
        Text(
          version,
          style: VType.label.copyWith(
            color: isRequired ? VColors.accentPrimary : VColors.text(context),
          ),
        ),
      ],
    );
  }
}

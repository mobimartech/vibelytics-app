import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';

/// Offline screen - displayed when device has no network connection
///
/// Shows a full-screen overlay with:
/// - Cloud-off icon
/// - "You're offline" message
/// - Try again button that rechecks connectivity
/// - Auto-dismisses when connection is restored
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  /// Shows the offline screen as a full-screen modal overlay
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const OfflineScreen(),
          );
        },
      ),
    );
  }

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _isChecking = false;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = ConnectivityService.instance.onConnectivityChanged.listen((isConnected) {
      if (isConnected && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    setState(() => _isChecking = true);
    VHaptics.light();

    final isConnected = await ConnectivityService.instance.checkConnectivity();

    if (!mounted) return;

    if (isConnected) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
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
                  color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.cloudOff,
                  size: 48,
                  color: VColors.textSec(context),
                ),
              ),

              VSpace.v8,

              // Title
              Text(
                'system.offline_title'.tr(),
                style: VType.h1.copyWith(color: VColors.text(context)),
                textAlign: TextAlign.center,
              ),

              VSpace.v3,

              // Subtitle
              Text(
                'system.offline_subtitle'.tr(),
                style: VType.body.copyWith(color: VColors.textSec(context)),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Try Again button
              PrimaryButton(
                label: 'system.offline_retry'.tr(),
                onPressed: _checkConnectivity,
                isLoading: _isChecking,
                icon: Icon(
                  LucideIcons.refreshCw,
                  size: 18,
                  color: VColors.textInverse,
                ),
              ),

              VSpace.v4,
            ],
          ),
        ),
      ),
    );
  }
}

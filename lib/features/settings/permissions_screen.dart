import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../components/navigation/standard_screen_app_bar.dart';
import '../../core/services/permission_coordinator.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/typography.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  List<AppPermissionInfo> _permissions = const [];
  AppPermissionType? _activePermission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
    }
  }

  Future<void> _loadPermissions() async {
    final permissions =
        await PermissionCoordinator.instance.getVisiblePermissions();
    if (!mounted) return;
    setState(() {
      _permissions = permissions;
      _isLoading = false;
      _activePermission = null;
    });
  }

  Future<void> _handlePermissionAction(AppPermissionType type) async {
    setState(() => _activePermission = type);
    await PermissionCoordinator.instance.triggerAction(context, type);
    if (!mounted) return;
    await _loadPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'permissions.title'.tr(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPermissions,
              child: ListView(
                padding: VSpace.screenH,
                children: [
                  VSpace.v4,
                  Text(
                    'permissions.subtitle'.tr(),
                    style: VType.screenBody.copyWith(
                      color: VColors.textSec(context),
                    ),
                  ),
                  VSpace.v6,
                  ..._permissions.map(
                    (info) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PermissionCard(
                        info: info,
                        isBusy: _activePermission == info.type,
                        onPressed: info.isActionEnabled
                            ? () => _handlePermissionAction(info.type)
                            : null,
                      ),
                    ),
                  ),
                  VSpace.v6,
                ],
              ),
            ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.info,
    required this.isBusy,
    required this.onPressed,
  });

  final AppPermissionInfo info;
  final bool isBusy;
  final VoidCallback? onPressed;

  Color _statusColor(BuildContext context) {
    switch (info.status) {
      case AppPermissionUiStatus.granted:
        return VColors.success;
      case AppPermissionUiStatus.limited:
        return VColors.warning;
      case AppPermissionUiStatus.denied:
        return VColors.textTer(context);
      case AppPermissionUiStatus.permanentlyDenied:
      case AppPermissionUiStatus.restricted:
        return VColors.error;
      case AppPermissionUiStatus.notApplicable:
        return VColors.textTer(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Container(
      padding: VSpace.card,
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: VRadii.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: VRadii.mdRadius,
                ),
                child: Icon(info.icon, color: statusColor, size: 20),
              ),
              VSpace.h3,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.titleKey.tr(),
                      style: VType.screenSectionTitle.copyWith(
                        color: VColors.text(context),
                      ),
                    ),
                    VSpace.v1,
                    Text(
                      info.descriptionKey.tr(),
                      style: VType.screenSupporting.copyWith(
                        color: VColors.textSec(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          VSpace.v3,
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: VRadii.fullRadius,
                ),
                child: Text(
                  info.statusKey.tr(),
                  style: VType.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: onPressed == null
                      ? VColors.textTer(context)
                      : VColors.accentPrimary,
                ),
                child: isBusy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VColors.accentPrimary,
                        ),
                      )
                    : Text(info.actionLabelKey.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

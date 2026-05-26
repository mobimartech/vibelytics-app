import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../notifications/notification_service.dart';
import '../tokens/icons.dart';

enum AppPermissionType {
  notifications,
  batteryOptimization,
  photoLibrary,
  gallerySave,
}

enum AppPermissionUiStatus {
  granted,
  denied,
  limited,
  permanentlyDenied,
  restricted,
  notApplicable,
}

class AppPermissionInfo {
  const AppPermissionInfo({
    required this.type,
    required this.status,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
  });

  final AppPermissionType type;
  final AppPermissionUiStatus status;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;

  bool get isVisible => status != AppPermissionUiStatus.notApplicable;

  bool get isAllowed =>
      status == AppPermissionUiStatus.granted ||
      status == AppPermissionUiStatus.limited ||
      status == AppPermissionUiStatus.notApplicable;

  bool get canRequest => status == AppPermissionUiStatus.denied;

  bool get canOpenSettings =>
      status == AppPermissionUiStatus.permanentlyDenied ||
      status == AppPermissionUiStatus.restricted;

  String get statusKey {
    switch (status) {
      case AppPermissionUiStatus.granted:
        return 'permissions.status_allowed';
      case AppPermissionUiStatus.denied:
        return 'permissions.status_denied';
      case AppPermissionUiStatus.limited:
        return 'permissions.status_limited';
      case AppPermissionUiStatus.permanentlyDenied:
        return 'permissions.status_denied';
      case AppPermissionUiStatus.restricted:
        return 'permissions.status_restricted';
      case AppPermissionUiStatus.notApplicable:
        return 'permissions.status_not_applicable';
    }
  }

  String get actionLabelKey {
    if (canOpenSettings) return 'permissions.action_open_settings';
    if (canRequest) return 'permissions.action_allow';
    return 'permissions.action_allowed';
  }

  bool get isActionEnabled => canRequest || canOpenSettings;
}

class PermissionCoordinator {
  PermissionCoordinator._();

  static final PermissionCoordinator instance = PermissionCoordinator._();

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<List<AppPermissionInfo>> getVisiblePermissions() async {
    final infos = await Future.wait([
      getInfo(AppPermissionType.notifications),
      getInfo(AppPermissionType.batteryOptimization),
      getInfo(AppPermissionType.photoLibrary),
      getInfo(AppPermissionType.gallerySave),
    ]);
    return infos.where((info) => info.isVisible).toList();
  }

  Future<AppPermissionInfo> getInfo(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.notifications:
        return _notificationInfo();
      case AppPermissionType.batteryOptimization:
        return _batteryInfo();
      case AppPermissionType.photoLibrary:
        return _photoLibraryInfo();
      case AppPermissionType.gallerySave:
        return _gallerySaveInfo();
    }
  }

  Future<AppPermissionInfo> ensureNotificationPermission(
    BuildContext context, {
    bool allowSettingsRecovery = true,
  }) async {
    return _ensurePermission(
      context,
      AppPermissionType.notifications,
      allowSettingsRecovery: allowSettingsRecovery,
    );
  }

  Future<AppPermissionInfo> ensureBatteryOptimization(
    BuildContext context, {
    bool allowSettingsRecovery = true,
  }) async {
    return _ensurePermission(
      context,
      AppPermissionType.batteryOptimization,
      allowSettingsRecovery: allowSettingsRecovery,
    );
  }

  Future<AppPermissionInfo> ensurePhotoLibraryAccess(
    BuildContext context, {
    bool allowSettingsRecovery = true,
  }) async {
    return _ensurePermission(
      context,
      AppPermissionType.photoLibrary,
      allowSettingsRecovery: allowSettingsRecovery,
    );
  }

  Future<AppPermissionInfo> ensureGallerySaveAccess(
    BuildContext context, {
    bool allowSettingsRecovery = true,
  }) async {
    return _ensurePermission(
      context,
      AppPermissionType.gallerySave,
      allowSettingsRecovery: allowSettingsRecovery,
    );
  }

  Future<AppPermissionInfo> triggerAction(
    BuildContext context,
    AppPermissionType type,
  ) async {
    return _ensurePermission(context, type, allowSettingsRecovery: true);
  }

  Future<AppPermissionInfo> _ensurePermission(
    BuildContext context,
    AppPermissionType type, {
    required bool allowSettingsRecovery,
  }) async {
    final initialInfo = await getInfo(type);
    if (!context.mounted || initialInfo.isAllowed || !initialInfo.isVisible) {
      return initialInfo;
    }

    if (initialInfo.canOpenSettings) {
      if (!allowSettingsRecovery) return initialInfo;
      final shouldOpenSettings = await _showSettingsDialog(
        context,
        title: initialInfo.titleKey.tr(),
        message: initialInfo.descriptionKey.tr(),
      );
      if (shouldOpenSettings && context.mounted) {
        await _openSettings(type);
      }
      return getInfo(type);
    }

    final allowRequest = await _showRequestDialog(
      context,
      title: initialInfo.titleKey.tr(),
      message: initialInfo.descriptionKey.tr(),
    );
    if (!allowRequest || !context.mounted) {
      return initialInfo;
    }

    await _request(type);
    if (!context.mounted) return initialInfo;

    final refreshedInfo = await getInfo(type);
    if (!context.mounted) return refreshedInfo;
    if (allowSettingsRecovery && refreshedInfo.canOpenSettings) {
      final shouldOpenSettings = await _showSettingsDialog(
        context,
        title: refreshedInfo.titleKey.tr(),
        message: refreshedInfo.descriptionKey.tr(),
      );
      if (shouldOpenSettings && context.mounted) {
        await _openSettings(type);
      }
      return getInfo(type);
    }

    return refreshedInfo;
  }

  Future<AppPermissionInfo> _notificationInfo() async {
    final hasPermission =
        await NotificationService.instance.hasNotificationPermission();
    if (hasPermission) {
      return AppPermissionInfo(
        type: AppPermissionType.notifications,
        status: AppPermissionUiStatus.granted,
        titleKey: 'permissions.notifications_title',
        descriptionKey: 'permissions.notifications_desc',
        icon: VIcons.notification,
      );
    }

    final status = await Permission.notification.status;
    return AppPermissionInfo(
      type: AppPermissionType.notifications,
      status: _mapPermissionStatus(status),
      titleKey: 'permissions.notifications_title',
      descriptionKey: 'permissions.notifications_desc',
      icon: VIcons.notification,
    );
  }

  Future<AppPermissionInfo> _batteryInfo() async {
    if (!_isAndroid) {
      return AppPermissionInfo(
        type: AppPermissionType.batteryOptimization,
        status: AppPermissionUiStatus.notApplicable,
        titleKey: 'permissions.battery_title',
        descriptionKey: 'permissions.battery_desc',
        icon: VIcons.zap,
      );
    }

    final status = await Permission.ignoreBatteryOptimizations.status;
    return AppPermissionInfo(
      type: AppPermissionType.batteryOptimization,
      status: _mapPermissionStatus(status),
      titleKey: 'permissions.battery_title',
      descriptionKey: 'permissions.battery_desc',
      icon: VIcons.zap,
    );
  }

  Future<AppPermissionInfo> _photoLibraryInfo() async {
    if (!_isIOS) {
      return AppPermissionInfo(
        type: AppPermissionType.photoLibrary,
        status: AppPermissionUiStatus.notApplicable,
        titleKey: 'permissions.photo_library_title',
        descriptionKey: 'permissions.photo_library_desc',
        icon: VIcons.gallery,
      );
    }

    final status = await Permission.photos.status;
    return AppPermissionInfo(
      type: AppPermissionType.photoLibrary,
      status: _mapPermissionStatus(status),
      titleKey: 'permissions.photo_library_title',
      descriptionKey: 'permissions.photo_library_desc',
      icon: VIcons.gallery,
    );
  }

  Future<AppPermissionInfo> _gallerySaveInfo() async {
    if (!_isAndroid && !_isIOS) {
      return AppPermissionInfo(
        type: AppPermissionType.gallerySave,
        status: AppPermissionUiStatus.notApplicable,
        titleKey: 'permissions.gallery_save_title',
        descriptionKey: 'permissions.gallery_save_desc',
        icon: VIcons.download,
      );
    }

    final hasAccess = await Gal.hasAccess();
    if (hasAccess) {
      return AppPermissionInfo(
        type: AppPermissionType.gallerySave,
        status: AppPermissionUiStatus.granted,
        titleKey: 'permissions.gallery_save_title',
        descriptionKey: 'permissions.gallery_save_desc',
        icon: VIcons.download,
      );
    }

    final fallbackStatus = await _galleryFallbackStatus();
    return AppPermissionInfo(
      type: AppPermissionType.gallerySave,
      status: fallbackStatus,
      titleKey: 'permissions.gallery_save_title',
      descriptionKey: 'permissions.gallery_save_desc',
      icon: VIcons.download,
    );
  }

  Future<AppPermissionUiStatus> _galleryFallbackStatus() async {
    try {
      if (_isIOS) {
        final addOnlyStatus = await Permission.photosAddOnly.status;
        return _mapPermissionStatus(addOnlyStatus);
      }

      if (_isAndroid) {
        final photoStatus = await Permission.photos.status;
        return _mapPermissionStatus(photoStatus);
      }
    } catch (_) {
      // Fall back to a generic denied state if the platform-specific status
      // check is unavailable.
    }
    return AppPermissionUiStatus.denied;
  }

  AppPermissionUiStatus _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted || status.isProvisional) {
      return AppPermissionUiStatus.granted;
    }
    if (status.isLimited) {
      return AppPermissionUiStatus.limited;
    }
    if (status.isPermanentlyDenied) {
      return AppPermissionUiStatus.permanentlyDenied;
    }
    if (status.isRestricted) {
      return AppPermissionUiStatus.restricted;
    }
    return AppPermissionUiStatus.denied;
  }

  Future<void> _request(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.notifications:
        await NotificationService.instance.requestPermission();
        return;
      case AppPermissionType.batteryOptimization:
        await Permission.ignoreBatteryOptimizations.request();
        return;
      case AppPermissionType.photoLibrary:
        if (_isIOS) {
          await Permission.photos.request();
        }
        return;
      case AppPermissionType.gallerySave:
        await Gal.requestAccess();
        return;
    }
  }

  Future<bool> _openSettings(AppPermissionType type) async {
    if (type == AppPermissionType.notifications) {
      return NotificationService.instance.openNotificationSettings();
    }
    return openAppSettings();
  }

  Future<bool> _showRequestDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('permissions.action_not_now'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('permissions.action_allow'.tr()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('permissions.action_open_settings'.tr()),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';

/// Service for showing local notifications
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification channel IDs
  static const String _analysisChannelId = 'analysis_progress';
  static const String _analysisChannelName = 'Analysis Progress';
  static const String _analysisChannelDesc =
      'Notifications for AI analysis progress and completion';

  // Notification IDs — Analysis
  static const int _analysisProgressId = 1000;
  static const int _analysisCompleteId = 1001;
  static const int _analysisFailedId = 1002;

  // Notification IDs — Enhancement
  static const int _enhancementProgressId = 2000;
  static const int _enhancementCompleteId = 2001;
  static const int _enhancementFailedId = 2002;

  /// Initialize the notification plugin (channels, callbacks) without
  /// requesting permission. Call [requestPermission] separately from a
  /// foreground consent flow.
  Future<void> initializePlugin() async {
    if (_initialized) return;

    try {
      // Android initialization
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization — permission flags set to false so the OS prompt
      // is deferred until the user explicitly consents via requestPermission().
      final darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
      );

      // Create Android notification channel
      if (Platform.isAndroid) {
        await _createAndroidChannel();
      }

      _initialized = true;
      AppLogger.i('NotificationService initialized');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to initialize NotificationService',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Request notification permissions using permission_handler.
  /// Call this from a foreground consent flow, not during init.
  Future<bool> requestPermission() async {
    try {
      // Check current status
      final status = await Permission.notification.status;
      AppLogger.d('Notification permission status: $status');

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // Request permission
        final result = await Permission.notification.request();
        AppLogger.d('Notification permission request result: $result');
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // User has permanently denied, they need to enable in settings
        AppLogger.w('Notification permission permanently denied');
        return false;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to request notification permissions',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if notification permissions are granted
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open app settings for user to manually enable notifications
  Future<bool> openNotificationSettings() async {
    return await openAppSettings();
  }

  /// Create Android notification channel
  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _analysisChannelId,
      _analysisChannelName,
      description: _analysisChannelDesc,
      importance: Importance.high,
      showBadge: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show analysis in progress notification
  Future<void> showAnalysisProgress({
    required String jobId,
    required int progress,
    required String message,
  }) async {
    if (!_initialized) await initializePlugin();

    final androidDetails = AndroidNotificationDetails(
      _analysisChannelId,
      _analysisChannelName,
      channelDescription: _analysisChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: _analysisProgressId,
      title: 'Analyzing Profile',
      body: message,
      notificationDetails: details,
      payload: 'progress:$jobId',
    );
  }

  /// Show analysis complete notification
  Future<void> showAnalysisComplete({
    required String jobId,
    required int analysisId,
    required String message,
  }) async {
    if (!_initialized) await initializePlugin();

    // Cancel progress notification
    await _plugin.cancel(id: _analysisProgressId);

    final androidDetails = AndroidNotificationDetails(
      _analysisChannelId,
      _analysisChannelName,
      channelDescription: _analysisChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: '<b>Analysis Complete ✨</b>',
        htmlFormatContentTitle: true,
        htmlFormatBigText: true,
      ),
      color: const Color(0xFF6C63FF),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: _analysisCompleteId,
      title: 'Analysis Complete',
      body: message,
      notificationDetails: details,
      payload: 'complete:$jobId:$analysisId',
    );
  }

  /// Show analysis failed notification
  Future<void> showAnalysisFailed({
    required String jobId,
    required String message,
  }) async {
    if (!_initialized) await initializePlugin();

    // Cancel progress notification
    await _plugin.cancel(id: _analysisProgressId);

    final androidDetails = AndroidNotificationDetails(
      _analysisChannelId,
      _analysisChannelName,
      channelDescription: _analysisChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: '<b>Analysis Failed</b>',
        htmlFormatContentTitle: true,
        htmlFormatBigText: true,
      ),
      color: const Color(0xFFEF4444),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: _analysisFailedId,
      title: 'Analysis Failed',
      body: message,
      notificationDetails: details,
      payload: 'failed:$jobId',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCEMENT NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Show enhancement in progress notification
  Future<void> showEnhancementProgress({
    required String jobId,
    required int progress,
    required String message,
  }) async {
    if (!_initialized) await initializePlugin();

    final androidDetails = AndroidNotificationDetails(
      _analysisChannelId,
      _analysisChannelName,
      channelDescription: _analysisChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: _enhancementProgressId,
      title: 'Enhancing Photos',
      body: message,
      notificationDetails: details,
      payload: 'enhance_progress:$jobId',
    );
  }

  /// Show enhancement complete notification
  Future<void> showEnhancementComplete({
    required String jobId,
    required String message,
  }) async {
    if (!_initialized) await initializePlugin();

    // Cancel progress notification
    await _plugin.cancel(id: _enhancementProgressId);

    final androidDetails = AndroidNotificationDetails(
      _analysisChannelId,
      _analysisChannelName,
      channelDescription: _analysisChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: '<b>Photos Enhanced ✨</b>',
        htmlFormatContentTitle: true,
        htmlFormatBigText: true,
      ),
      color: const Color(0xFF6C63FF),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: _enhancementCompleteId,
      title: 'Photos Enhanced ✨',
      body: message,
      notificationDetails: details,
      payload: 'enhance_complete:$jobId',
    );
  }

  /// Show enhancement failed notification
  Future<void> showEnhancementFailed({
    required String jobId,
    required String message,
  }) async {
    if (!_initialized) await initializePlugin();

    // Cancel progress notification
    await _plugin.cancel(id: _enhancementProgressId);

    final androidDetails = AndroidNotificationDetails(
      _analysisChannelId,
      _analysisChannelName,
      channelDescription: _analysisChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: '<b>Enhancement Failed</b>',
        htmlFormatContentTitle: true,
        htmlFormatBigText: true,
      ),
      color: const Color(0xFFEF4444),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: _enhancementFailedId,
      title: 'Enhancement Failed',
      body: message,
      notificationDetails: details,
      payload: 'enhance_failed:$jobId',
    );
  }

  /// Cancel all enhancement notifications
  Future<void> cancelEnhancementNotifications() async {
    await _plugin.cancel(id: _enhancementProgressId);
    await _plugin.cancel(id: _enhancementCompleteId);
    await _plugin.cancel(id: _enhancementFailedId);
  }

  /// Cancel all analysis notifications
  Future<void> cancelAnalysisNotifications() async {
    await _plugin.cancel(id: _analysisProgressId);
    await _plugin.cancel(id: _analysisCompleteId);
    await _plugin.cancel(id: _analysisFailedId);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Handle notification tap callback reference
  static NotificationTapCallback? onNotificationTap;
  static NotificationTapEvent? _pendingTap;

  /// Deliver a tap captured before the main shell finished wiring navigation.
  static NotificationTapEvent? consumePendingTap() {
    final tap = _pendingTap;
    _pendingTap = null;
    return tap;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    AppLogger.d('Notification tapped: ${response.payload}');
    _handleNotificationPayload(response.payload);
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    AppLogger.d('Background notification tapped: ${response.payload}');
    _handleNotificationPayload(response.payload);
  }

  /// Parse and handle notification payload
  static void _handleNotificationPayload(String? payload) {
    if (payload == null) return;

    final parts = payload.split(':');
    if (parts.isEmpty) return;

    final action = parts[0];
    final jobId = parts.length > 1 ? parts[1] : null;
    final analysisId = parts.length > 2 ? int.tryParse(parts[2]) : null;

    final callback = onNotificationTap;
    if (callback != null) {
      callback(action, jobId, analysisId);
      return;
    }

    _pendingTap = NotificationTapEvent(
      action: action,
      jobId: jobId,
      analysisId: analysisId,
    );
  }
}

class NotificationTapEvent {
  const NotificationTapEvent({
    required this.action,
    required this.jobId,
    required this.analysisId,
  });

  final String action;
  final String? jobId;
  final int? analysisId;
}

/// Callback for notification taps
typedef NotificationTapCallback = void Function(
  String action,
  String? jobId,
  int? analysisId,
);

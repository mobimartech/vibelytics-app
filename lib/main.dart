import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:sizer/sizer.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/connectivity_service.dart';
import 'core/background/background_task_manager.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/purchase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await _initializeServices();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return const VibelyticsApp();
        },
      ),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    // Initialize localization
    await EasyLocalization.ensureInitialized();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set high refresh rate on Android
    if (Platform.isAndroid) {
      await _setHighRefreshRate();
    }

    // Initialize connectivity monitoring (await first check)
    await ConnectivityService.instance.initialize();

    // Initialize deep link handler (referral links)
    await DeepLinkService.instance.initialize();

    // Initialize notification plugin (channels/callbacks only, no permission prompt)
    await NotificationService.instance.initializePlugin();

    // NOTE: Battery optimization and notification permissions are requested
    // with user consent dialogs in MainShell after app loads

    // Initialize background task manager
    await BackgroundTaskManager.instance.initialize();

    // Initialize RevenueCat (skips gracefully on unsupported platforms)
    await PurchaseService.instance.initialize();

    AppLogger.i('App initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.e('Error initializing app', error: e, stackTrace: stackTrace);
  }
}

Future<void> _setHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
    AppLogger.d('High refresh rate enabled');
  } catch (e) {
    AppLogger.w('Could not set high refresh rate: $e');
  }
}

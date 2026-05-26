import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/connectivity_service.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/system/offline_screen.dart';

/// Main application widget
class VibelyticsApp extends StatefulWidget {
  const VibelyticsApp({super.key});

  /// Static theme control — set from anywhere, persisted to SharedPreferences
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);

  /// Change theme from anywhere
  static void setThemeMode(ThemeMode mode) {
    themeNotifier.value = mode;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('theme_mode', mode.name);
    });
  }

  @override
  State<VibelyticsApp> createState() => _VibelyticsAppState();
}

class _VibelyticsAppState extends State<VibelyticsApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOfflineScreenShowing = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _setupConnectivityListener();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('theme_mode');
    if (stored != null) {
      VibelyticsApp.themeNotifier.value = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.system,
      );
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        ConnectivityService.instance.onConnectivityChanged.listen((isConnected) {
      if (!isConnected && !_isOfflineScreenShowing) {
        _showOfflineScreen();
      }
    });
  }

  void _showOfflineScreen() {
    final navigator = _navigatorKey.currentState;
    if (navigator != null && !_isOfflineScreenShowing) {
      _isOfflineScreenShowing = true;
      navigator.push(
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
      ).then((_) {
        _isOfflineScreenShowing = false;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: VibelyticsApp.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Vibelytics',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,

          // Localization
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,

          // Theming
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,

          // Entry point
          home: const SplashScreen(),
        );
      },
    );
  }
}

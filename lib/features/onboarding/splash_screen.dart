import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/durations.dart';
import '../../core/api/token_manager.dart';
import '../../core/services/auth_service.dart';
import '../onboarding/welcome_carousel_screen.dart';
import '../../main_shell.dart';

/// Splash screen - Entry point for the app
///
/// Checks for existing auth tokens and navigates accordingly:
/// - If tokens exist and valid: navigate to MainShell
/// - If no tokens: navigate to WelcomeCarouselScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: VDuration.dramatic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation and minimum splash time
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final hasTokens = await TokenManager.instance.hasTokens();

    if (hasTokens) {
      // Validate token by checking profile (returns null on failure)
      final profile = await AuthService.instance.getProfile();
      if (profile == null) {
        await TokenManager.instance.clearAll();
        if (mounted) _navigateTo(const WelcomeCarouselScreen());
        return;
      }
      if (!mounted) return;
      _navigateTo(const MainShell());
    } else {
      _navigateTo(const WelcomeCarouselScreen());
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: VDuration.normal,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'app_name'.tr(),
                style: VType.display.copyWith(color: VColors.text(context)),
              ),
              const SizedBox(height: 16),
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  gradient: VColors.aiGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

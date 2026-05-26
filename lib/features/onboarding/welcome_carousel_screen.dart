import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/ghost_button.dart';
import 'auth_gate_screen.dart';

class WelcomeCarouselScreen extends StatefulWidget {
  const WelcomeCarouselScreen({super.key});

  @override
  State<WelcomeCarouselScreen> createState() => _WelcomeCarouselScreenState();
}

class _WelcomeCarouselScreenState extends State<WelcomeCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = const [
    _SlideData(
      icon: Icons.psychology_rounded,
      color: VColors.blue50,
      accent: Color(0xFF4F7CFF),
      titleKey: 'onboarding.slide1_title',
      descKey: 'onboarding.slide1_desc',
    ),
    _SlideData(
      icon: Icons.auto_fix_high_rounded,
      color: Color(0xFFF3EAFF),
      accent: Color(0xFF9B5CFF),
      titleKey: 'onboarding.slide2_title',
      descKey: 'onboarding.slide2_desc',
    ),
    _SlideData(
      icon: Icons.star_rounded,
      color: VColors.teal50,
      accent: Color(0xFF14B8A6),
      titleKey: 'onboarding.slide3_title',
      descKey: 'onboarding.slide3_desc',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _slides[_currentPage].color.withOpacity(0.75),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: VSpace.screenH.copyWith(top: 8),
                child: Row(
                  children: [
                    Text(
                      'Vibelytics',
                      style: VType.h2.copyWith(
                        color: VColors.text(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    VGhostButton(
                      label: 'common.skip'.tr(),
                      onPressed: _navigateToAuth,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1;
                        if (_pageController.position.haveDimensions) {
                          value = (_pageController.page! - index).abs();
                          value = (1 - (value * 0.08)).clamp(0.92, 1.0);
                        }

                        return Transform.scale(scale: value, child: child);
                      },
                      child: _SlideWidget(data: _slides[index]),
                    );
                  },
                ),
              ),

              Padding(
                padding: VSpace.screen.copyWith(top: 8),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _slides.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 8,
                        dotHeight: 8,
                        spacing: 8,
                        expansionFactor: 3.2,
                        dotColor: VColors.borderSubtle,
                        activeDotColor: _slides[_currentPage].accent,
                      ),
                    ),
                    VSpace.v6,
                    VPrimaryButton(
                      label: isLastPage
                          ? 'onboarding.get_started'.tr()
                          : 'common.next'.tr(),
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final Color color;
  final Color accent;
  final String titleKey;
  final String descKey;

  const _SlideData({
    required this.icon,
    required this.color,
    required this.accent,
    required this.titleKey,
    required this.descKey,
  });
}

class _SlideWidget extends StatelessWidget {
  const _SlideWidget({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: VSpace.screenH,
      child: Column(
        children: [
          Expanded(
            flex: 58,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 36,
                    right: 28,
                    child: _GlowCircle(color: data.accent.withOpacity(0.18)),
                  ),
                  Positioned(
                    bottom: 42,
                    left: 18,
                    child: _GlowCircle(
                      size: 72,
                      color: data.accent.withOpacity(0.12),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: VRadii.xlRadius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.72),
                          borderRadius: VRadii.xlRadius,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.75),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: data.accent.withOpacity(0.18),
                              blurRadius: 36,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    data.accent.withOpacity(0.92),
                                    data.accent.withOpacity(0.55),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: data.accent.withOpacity(0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Icon(
                                data.icon,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            VSpace.v6,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: data.color,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'AI-powered insights',
                                style: VType.bodySm.copyWith(
                                  color: data.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 42,
            child: Column(
              children: [
                VSpace.v4,
                Text(
                  data.titleKey.tr(),
                  style: VType.h1.copyWith(
                    color: VColors.text(context),
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                  textAlign: TextAlign.center,
                ),
                VSpace.v4,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    data.descKey.tr(),
                    style: VType.bodyLg.copyWith(
                      color: VColors.textSec(context),
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, this.size = 96});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

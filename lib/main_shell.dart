import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/navigation/bottom_nav_bar.dart';
import 'core/api/token_manager.dart';
import 'core/background/analysis_job.dart';
import 'core/background/job_queue_storage.dart';
import 'core/config/feature_flags.dart';
import 'core/services/analysis_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/credits_service.dart';
import 'core/services/activity_service.dart';
import 'core/services/permission_coordinator.dart';
import 'core/services/purchase_service.dart';
import 'core/tokens/colors.dart';
import 'core/tokens/typography.dart';
import 'core/tokens/spacing.dart';
import 'core/tokens/radii.dart';
import 'core/tokens/icons.dart';
import 'core/notifications/notification_service.dart';
import 'core/utils/app_logger.dart';
import 'features/home/home_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/enhance/enhance_hub_screen.dart';
import 'features/enhance/enhance_gallery_screen.dart';
import 'features/enhance/analysis_results_screen.dart';
import 'features/enhance/chat_results_screen.dart';
import 'features/enhance/analysis_processing_screen.dart';
import 'features/enhance/enhance_processing_screen.dart';
import 'features/enhance/analysis_history_screen.dart';
import 'features/activity/activity_screen.dart';
import 'features/profile/my_profile_screen.dart';
import 'features/onboarding/splash_screen.dart';

/// Main application shell with bottom navigation
///
/// Uses IndexedStack to preserve state when switching tabs.
/// Loads credit balance + profile on init and exposes shared
/// [creditNotifier] and [unreadActivityNotifier] that child tabs can listen to.
///
/// Listens to [TokenManager.onSessionExpired] to force-navigate to login
/// when the refresh token is revoked or expired.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Shared credit balance notifier — accessible via [MainShell.of].
  static ValueNotifier<int> creditNotifier = ValueNotifier<int>(0);

  /// Shared unread activity count notifier for badge display.
  static ValueNotifier<int> unreadActivityNotifier = ValueNotifier<int>(0);

  /// Notifies listeners when the active tab changes.
  /// Value is the current tab index.
  static ValueNotifier<int> tabChangeNotifier = ValueNotifier<int>(0);

  /// Convenience accessor from any descendant widget.
  static ValueNotifier<int> of(BuildContext context) => creditNotifier;

  /// Refresh balance from network and update notifier.
  static Future<void> refreshCredits({bool force = false}) async {
    final balance = await CreditsService.instance.getBalance(forceRefresh: force);
    creditNotifier.value = balance;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _unreadPollTimer;
  StreamSubscription<void>? _sessionExpiredSub;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    EnhanceHubScreen(),
    ActivityScreen(),
    MyProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    _startUnreadPolling();

    // Listen for forced logout (refresh token expired/revoked)
    _sessionExpiredSub = TokenManager.onSessionExpired.listen((_) {
      _handleSessionExpired();
    });

    // Wire up notification tap handler
    NotificationService.onNotificationTap = _handleNotificationTap;
    final pendingTap = NotificationService.consumePendingTap();
    if (pendingTap != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleNotificationTap(
          pendingTap.action,
          pendingTap.jobId,
          pendingTap.analysisId,
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unreadPollTimer?.cancel();
    _sessionExpiredSub?.cancel();
    NotificationService.onNotificationTap = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUnreadCount();
      _startUnreadPolling();
      _checkCompletedJobs();
    } else if (state == AppLifecycleState.paused) {
      _unreadPollTimer?.cancel();
    }
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    // Navigate to splash (which checks auth and routes to login)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  Future<void> _loadInitialData() async {
    // Fire-and-forget: load balance + profile + unread count concurrently
    final balanceFuture = CreditsService.instance.getBalance(forceRefresh: true);
    AuthService.instance.getProfile(); // pre-warm cache
    _fetchUnreadCount();

    // Ensure RevenueCat is linked to the current user on app restart
    _linkRevenueCatUser();

    final balance = await balanceFuture;
    MainShell.creditNotifier.value = balance;

    // Request permissions with consent dialogs (deferred to after UI loads)
    _requestPermissionsWithConsent();
  }

  static const String _permissionsAskedKey = 'permissions_asked_v1';

  Future<void> _requestPermissionsWithConsent() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionsAskedKey) == true) return;

    // Wait a moment for the UI to settle
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await PermissionCoordinator.instance.ensureNotificationPermission(
      context,
      allowSettingsRecovery: false,
    );
    if (!mounted) return;

    await PermissionCoordinator.instance.ensureBatteryOptimization(
      context,
      allowSettingsRecovery: false,
    );

    await prefs.setBool(_permissionsAskedKey, true);
  }

  Future<void> _linkRevenueCatUser() async {
    final userId = await AuthService.instance.getCurrentUserId();
    if (userId != null) {
      await PurchaseService.instance.logIn(userId);
    }
  }

  void _startUnreadPolling() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _fetchUnreadCount(),
    );
  }

  Future<void> _fetchUnreadCount() async {
    final count = await ActivityService.instance.getUnreadCount();
    MainShell.unreadActivityNotifier.value = count;
  }

  Future<void> _checkCompletedJobs() async {
    try {
      final completedJobs = await JobQueueStorage.instance.getCompletedJobs();
      final unnotifiedJobs = completedJobs.where(
        (j) => j.isCompleted && j.notifiedAt == null,
      );

      for (final job in unnotifiedJobs) {
        await JobQueueStorage.instance.markJobNotified(job.id);
        if (!mounted) return;

        if (job.type == AnalysisJobType.enhancement &&
            job.resultPhotoUrls != null &&
            job.resultPhotoUrls!.isNotEmpty) {
          // Enhancement job — show gallery snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('enhance.enhanced_photos'.tr()),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'common.see_all'.tr(),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EnhanceGalleryScreen(
                        photos: job.resultPhotoUrls,
                        loadFromApi: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (job.type == AnalysisJobType.profile ||
                   job.type == AnalysisJobType.chat) {
          // Analysis job — navigate to results
          if (job.type == AnalysisJobType.chat &&
              !FeatureFlags.chatAnalysisEnabled) {
            continue;
          }
          final analysisId = job.analysisId;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('enhance.results_title'.tr()),
              behavior: SnackBarBehavior.floating,
              backgroundColor: VColors.success,
              action: analysisId != null
                  ? SnackBarAction(
                      label: 'common.see_all'.tr(),
                      textColor: Colors.white,
                      onPressed: () => _openCompletedAnalysis(analysisId),
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.w('Failed to check completed jobs: $e');
    }
  }

  void _handleNotificationTap(String action, String? jobId, int? analysisId) {
    if (!mounted) return;
    unawaited(_handleNotificationTapAsync(action, jobId, analysisId));
  }

  Future<void> _handleNotificationTapAsync(
    String action,
    String? jobId,
    int? analysisId,
  ) async {
    if (!mounted) return;

    switch (action) {
      case 'complete':
        if (analysisId != null) {
          await _openCompletedAnalysis(analysisId);
        } else {
          await _openAnalysisNotificationTarget(jobId);
        }
        return;
      case 'progress':
        await _openAnalysisNotificationTarget(jobId);
        return;
      case 'failed':
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AnalysisHistoryScreen(),
          ),
        );
        return;
      case 'enhance_complete':
        await _openEnhancementNotificationTarget(jobId);
        return;
      case 'enhance_progress':
      case 'enhance_failed':
        if (!mounted || jobId == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EnhanceProcessingScreen(existingJobId: jobId),
          ),
        );
        return;
    }
  }

  Future<void> _openAnalysisNotificationTarget(String? jobId) async {
    if (jobId == null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AnalysisHistoryScreen(),
        ),
      );
      return;
    }

    final job = await JobQueueStorage.instance.getJob(jobId);
    if (!mounted) return;

    if (job?.type == AnalysisJobType.chat &&
        !FeatureFlags.chatAnalysisEnabled) {
      return;
    }

    final analysisId = job?.analysisId ?? int.tryParse(jobId);
    if (analysisId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnalysisProcessingScreen(
            existingJobId: analysisId.toString(),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AnalysisHistoryScreen(),
      ),
    );
  }

  Future<void> _openEnhancementNotificationTarget(String? jobId) async {
    final job = jobId == null
        ? null
        : await JobQueueStorage.instance.getJob(jobId);
    if (!mounted) return;

    final photos = job?.resultPhotoUrls;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnhanceGalleryScreen(
          photos: photos,
          loadFromApi: photos == null || photos.isEmpty,
        ),
      ),
    );
  }

  Future<void> _openCompletedAnalysis(int analysisId) async {
    final analysis = await AnalysisService.instance.getAnalysis(analysisId);
    if (!mounted || analysis == null || analysis.data == null) return;

    if (analysis.isChatAnalysis) {
      if (!FeatureFlags.chatAnalysisEnabled) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatResultsScreen(
            analysisId: analysisId,
            data: ChatAnalysisData.fromJson(analysis.data!),
            contextUsed: analysis.contextUsed,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnalysisResultsScreen(
            analysisId: analysisId,
            data: ProfileAnalysisData.fromJson(analysis.data!),
            photoPromptsCount: analysis.photoPrompts.length,
          ),
        ),
      );
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    MainShell.tabChangeNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Floating active analysis indicator
          ValueListenableBuilder<Set<int>>(
            valueListenable: AnalysisService.instance.activeAnalysisIds,
            builder: (context, activeIds, _) {
              if (activeIds.isEmpty) return const SizedBox.shrink();
              return Positioned(
                bottom: 16,
                left: VSpace.screenMargin,
                right: VSpace.screenMargin,
                child: _ActiveAnalysisBanner(
                  count: activeIds.length,
                  onTap: () {
                    // Navigate to processing screen for the first active analysis
                    final firstId = activeIds.first;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AnalysisProcessingScreen(
                          existingJobId: firstId.toString(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: VBottomNavBar(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}

class _ActiveAnalysisBanner extends StatelessWidget {
  const _ActiveAnalysisBanner({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: VColors.aiGradient,
          borderRadius: VRadii.lgRadius,
          boxShadow: [
            BoxShadow(
              color: VColors.aiGradientStart.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
            VSpace.h3,
            Expanded(
              child: Text(
                'enhance.processing_title'.tr(),
                style: VType.label.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(VIcons.chevronRight, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/config/feature_flags.dart';
import '../../core/services/analysis_service.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/app_logger.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import 'analysis_results_screen.dart';
import 'chat_results_screen.dart';

/// Screen showing history of past analyses
class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  List<AnalysisSummary> _analyses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AnalysisService.instance.getAnalysisList();
      if (!mounted) return;
      setState(() {
        _analyses = FeatureFlags.chatAnalysisEnabled
            ? result.analyses
            : result.analyses.where((item) => !item.isChatAnalysis).toList();
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Failed to load analysis history', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'enhance.history_load_failed'.tr();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToResults(AnalysisSummary summary) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analysis = await AnalysisService.instance.getAnalysis(summary.id);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (analysis != null && analysis.data != null) {
        if (analysis.isChatAnalysis && !FeatureFlags.chatAnalysisEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('enhance.feature_coming_soon'.tr()),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (analysis.isChatAnalysis) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatResultsScreen(
                analysisId: analysis.id,
                data: ChatAnalysisData.fromJson(analysis.data!),
                contextUsed: analysis.contextUsed,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AnalysisResultsScreen(
                analysisId: analysis.id,
                data: ProfileAnalysisData.fromJson(analysis.data!),
                photoPromptsCount: analysis.photoPrompts.length,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(); // Close loading dialog

      messenger.showSnackBar(
        SnackBar(content: Text('common.error'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'profile.analysis_history'.tr(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: VType.body.copyWith(color: VColors.textSec(context)),
            ),
            VSpace.v4,
            ElevatedButton(
              onPressed: _loadAnalyses,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_analyses.isEmpty) {
      return _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyses,
      child: ListView.separated(
        padding: VSpace.screenH,
        itemCount: _analyses.length,
        separatorBuilder: (context, index) => VSpace.v3,
        itemBuilder: (context, index) {
          return _AnalysisCard(
            item: _analyses[index],
            onTap: () => _navigateToResults(_analyses[index]),
          );
        },
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.item,
    required this.onTap,
  });

  final AnalysisSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: VSpace.card,
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.lgRadius,
          boxShadow: VShadow.level1,
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: VColors.aiGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isProfileAnalysis ? VIcons.aiAnalysis : VIcons.chatAnalysis,
                color: Colors.white,
                size: 28,
              ),
            ),
            VSpace.h4,
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.isProfileAnalysis
                        ? 'enhance.profile_analysis'.tr()
                        : 'enhance.chat_analysis'.tr(),
                    style: VType.label.copyWith(color: VColors.text(context)),
                  ),
                  VSpace.v05,
                  Row(
                    children: [
                      Text(
                        _formatDate(item.createdAt),
                        style: VType.caption.copyWith(color: VColors.textSec(context)),
                      ),
                      if (item.screenshotCount != null) ...[
                        Text(
                          ' · ${item.screenshotCount} ',
                          style: VType.caption.copyWith(color: VColors.textTer(context)),
                        ),
                        Icon(VIcons.image, size: 12, color: VColors.textTer(context)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Credits spent
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                borderRadius: VRadii.smRadius,
              ),
              child: Text(
                '-${item.creditsSpent}',
                style: VType.caption.copyWith(color: VColors.textSec(context)),
              ),
            ),
            VSpace.h2,
            // Chevron
            Icon(
              VIcons.chevronRight,
              color: VColors.textTer(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 24) {
      if (diff.inHours == 0) {
        return 'common.minutes_ago'.tr(args: ['${diff.inMinutes}']);
      }
      return 'common.hours_ago'.tr(args: ['${diff.inHours}']);
    } else if (diff.inDays < 7) {
      return 'common.days_ago'.tr(args: ['${diff.inDays}']);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            VIcons.history,
            size: 64,
            color: VColors.textTer(context),
          ),
          VSpace.v4,
          Text(
            'credits.no_history'.tr(),
            style: VType.h3.copyWith(color: VColors.text(context)),
          ),
        ],
      ),
    );
  }
}

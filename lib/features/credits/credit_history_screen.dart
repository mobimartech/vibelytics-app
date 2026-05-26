import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/services/credits_service.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../components/feedback/shimmer_skeleton.dart';

/// Credit history/transactions screen
class CreditHistoryScreen extends StatefulWidget {
  const CreditHistoryScreen({super.key});

  @override
  State<CreditHistoryScreen> createState() => _CreditHistoryScreenState();
}

class _CreditHistoryScreenState extends State<CreditHistoryScreen> {
  List<CreditTransaction> _transactions = [];
  bool _isLoading = true;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final result = await CreditsService.instance.getHistory();

    if (mounted) {
      setState(() {
        _transactions = result.transactions;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await CreditsService.instance.getHistory(
      offset: _transactions.length,
    );

    if (mounted) {
      setState(() {
        _transactions.addAll(result.transactions);
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'credits.history_title'.tr(),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _transactions.isEmpty
              ? _buildEmptyState()
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.extentAfter < 200) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: VSpace.screenH,
                    itemCount: _transactions.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: VColors.border(context),
                    ),
                    itemBuilder: (context, index) {
                      if (index >= _transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _TransactionRow(transaction: _transactions[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: VSpace.screenH,
      child: Column(
        children: List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerSkeleton(
              height: 60,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            VIcons.receipt,
            size: 64,
            color: VColors.textTer(context),
          ),
          VSpace.v4,
          Text(
            'credits.no_history'.tr(),
            style: VType.body.copyWith(color: VColors.textSec(context)),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final CreditTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBgColor) = _getIconAndColor(context, transaction.type);
    final isPositive = transaction.isPositive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconBgColor),
          ),
          VSpace.h3,
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: VType.body.copyWith(color: VColors.text(context)),
                ),
                VSpace.v05,
                Text(
                  _formatDate(transaction.createdAt),
                  style: VType.caption.copyWith(color: VColors.textTer(context)),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isPositive ? '+' : ''}${transaction.amount}',
            style: VType.label.copyWith(
              color: isPositive ? VColors.success : VColors.error,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getIconAndColor(BuildContext context, String type) {
    switch (type) {
      case 'purchased':
        return (VIcons.add, VColors.success);
      case 'spent':
        return (VIcons.minus, VColors.error);
      case 'referral':
        return (VIcons.gift, VColors.accentSecondary);
      case 'bonus':
        return (VIcons.star, VColors.accentPrimary);
      case 'refund':
        return (VIcons.refresh, VColors.warning);
      default:
        return (VIcons.wallet, VColors.textSec(context));
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) {
      return 'common.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    } else if (diff.inHours < 24) {
      return 'common.hours_ago'.tr(args: ['${diff.inHours}']);
    } else if (diff.inDays < 7) {
      return 'common.days_ago'.tr(args: ['${diff.inDays}']);
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

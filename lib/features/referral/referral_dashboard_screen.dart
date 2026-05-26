import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../../core/utils/haptics.dart';
import '../../core/services/auth_service.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/cards/data_tile.dart';

/// Referral dashboard with stats and invite link
class ReferralDashboardScreen extends StatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  State<ReferralDashboardScreen> createState() =>
      _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState extends State<ReferralDashboardScreen> {
  String? _referralCode;
  ReferralStats? _stats;
  bool _isLoading = true;

  String get _referralLink =>
      _referralCode != null
          ? 'https://vibelytics.org/r/$_referralCode'
          : '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      AuthService.instance.getMyReferralCode(),
      AuthService.instance.getReferralStats(),
    ]);

    if (mounted) {
      setState(() {
        _referralCode = results[0]?.toString();
        _stats = results[1] is ReferralStats ? results[1] as ReferralStats : null;
        _isLoading = false;
      });
    }
  }

  void _copyLink(BuildContext context) {
    if (_referralLink.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _referralLink));
    VHaptics.success();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('referral.link_copied'.tr()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: VColors.success,
      ),
    );
  }

  void _shareLink() {
    if (_referralLink.isEmpty) return;
    SharePlus.instance.share(
      ShareParams(
        text: 'referral.share_message'.tr(args: [_referralLink]),
        subject: 'referral.share_subject'.tr(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: VColors.text(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'referral.title'.tr(),
          style: VType.h2.copyWith(color: VColors.text(context)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: VSpace.screenH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VSpace.v4,

                  // Hero card
                  Container(
                    padding: VSpace.card,
                    decoration: BoxDecoration(
                      gradient: VColors.aiGradient,
                      borderRadius: VRadii.xlRadius,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 48,
                          color: Colors.white,
                        ),
                        VSpace.v4,
                        Text(
                          'referral.hero_title'.tr(),
                          style: VType.h2.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        VSpace.v2,
                        Text(
                          'referral.hero_subtitle'.tr(),
                          style: VType.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  VSpace.v6,

                  // Stats
                  Text(
                    'referral.your_stats'.tr(),
                    style: VType.h3.copyWith(color: VColors.text(context)),
                  ),
                  VSpace.v3,
                  DataTileRow(
                    tiles: [
                      DataTile(
                        label: 'referral.friends_invited'.tr(),
                        value: '${_stats?.totalSignups ?? 0}',
                        icon: Icons.people_outline,
                      ),
                      DataTile(
                        label: 'referral.credits_earned'.tr(),
                        value: '${_stats?.totalEarned.toInt() ?? 0}',
                        icon: Icons.monetization_on_outlined,
                      ),
                    ],
                  ),

                  VSpace.v6,

                  // Referral code
                  Text(
                    'referral.your_code'.tr(),
                    style: VType.h3.copyWith(color: VColors.text(context)),
                  ),
                  VSpace.v3,
                  Container(
                    padding: VSpace.card,
                    decoration: BoxDecoration(
                      color: VColors.card(context),
                      borderRadius: VRadii.lgRadius,
                      boxShadow: VShadow.level1,
                    ),
                    child: Column(
                      children: [
                        // Code display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                            borderRadius: VRadii.mdRadius,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _referralCode ?? '...',
                                style: VType.h2.copyWith(
                                  color: VColors.accentPrimary,
                                  fontFamily: 'JetBrains Mono',
                                  letterSpacing: 4,
                                ),
                              ),
                              VSpace.h3,
                              GestureDetector(
                                onTap: () => _copyLink(context),
                                child: Icon(
                                  Icons.copy,
                                  size: 20,
                                  color: VColors.textSec(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        VSpace.v4,
                        // Share button
                        PrimaryButton(
                          label: 'referral.share_button'.tr(),
                          icon: const Icon(Icons.share, color: Colors.white, size: 20),
                          onPressed: _shareLink,
                        ),
                      ],
                    ),
                  ),

                  VSpace.v6,

                  // How it works
                  Text(
                    'referral.how_it_works'.tr(),
                    style: VType.h3.copyWith(color: VColors.text(context)),
                  ),
                  VSpace.v3,
                  _HowItWorksStep(
                    number: 1,
                    title: 'referral.step_1_title'.tr(),
                    description: 'referral.step_1_desc'.tr(),
                  ),
                  _HowItWorksStep(
                    number: 2,
                    title: 'referral.step_2_title'.tr(),
                    description: 'referral.step_2_desc'.tr(),
                  ),
                  _HowItWorksStep(
                    number: 3,
                    title: 'referral.step_3_title'.tr(),
                    description: 'referral.step_3_desc'.tr(),
                    isLast: true,
                  ),

                  VSpace.v8,
                ],
              ),
            ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: VColors.accentPrimary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: VType.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: VColors.border(context),
              ),
          ],
        ),
        VSpace.h3,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: VType.label.copyWith(color: VColors.text(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                VSpace.v05,
                Text(
                  description,
                  style: VType.bodySm.copyWith(color: VColors.textSec(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

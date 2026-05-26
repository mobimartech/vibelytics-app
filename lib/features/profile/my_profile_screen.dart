import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/services/auth_service.dart';
import '../../components/feedback/credit_badge.dart';
import '../../main_shell.dart';
import '../settings/settings_screen.dart';
import '../credits/buy_credits_screen.dart';
import '../credits/credit_history_screen.dart';
import '../referral/referral_dashboard_screen.dart';
import '../enhance/analysis_history_screen.dart';
import 'enhanced_library_screen.dart';
import 'my_photos_screen.dart';

/// My profile screen - Tab 5
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.instance.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
      if (profile != null) {
        MainShell.creditNotifier.value = profile.creditsBalance;
      }
    }
  }

  String _formatMemberSince(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _displayName() {
    if (_profile == null) return 'profile.default_username'.tr();
    if (_profile!.email != null && _profile!.email!.isNotEmpty) {
      return _profile!.email!.split('@').first;
    }
    if (_profile!.phoneNumber != null && _profile!.phoneNumber!.isNotEmpty) {
      return _profile!.phoneNumber!;
    }
    return 'User #${_profile!.id}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: VColors.accentPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: VSpace.screenH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'profile.title'.tr(),
                        style: VType.screenTitle.copyWith(
                          color: VColors.text(context),
                        ),
                      ),
                      IconButton(
                        icon: Icon(VIcons.settings),
                        color: VColors.text(context),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                VSpace.v6,

                // Avatar
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                    border: Border.all(
                      color: VColors.accentPrimary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: _profile?.profilePhotoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _profile!.profilePhotoUrl!,
                            fit: BoxFit.cover,
                            width: 88,
                            height: 88,
                            placeholder: (_, _) => Icon(
                              VIcons.user,
                              size: 40,
                              color: VColors.textTer(context),
                            ),
                            errorWidget: (_, _, _) => Icon(
                              VIcons.user,
                              size: 40,
                              color: VColors.textTer(context),
                            ),
                          ),
                        )
                      : Icon(
                          VIcons.user,
                          size: 40,
                          color: VColors.textTer(context),
                        ),
                ),

                VSpace.v4,

                // Username
                _isLoading
                    ? SizedBox(
                        width: 100,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )
                    : Text(
                        _displayName(),
                        style: VType.screenSectionTitle.copyWith(
                          color: VColors.text(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                VSpace.v1,
                Text(
                  'profile.member_since'.tr(
                    args: [
                      _profile != null
                          ? _formatMemberSince(_profile!.memberSince)
                          : '...',
                    ],
                  ),
                  style: VType.caption.copyWith(color: VColors.textSec(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                VSpace.v6,

                // Stats row
                Padding(
                  padding: VSpace.screenH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        value: '${_profile?.totalAnalyses ?? 0}',
                        label: 'profile.analyses'.tr(),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: VColors.border(context),
                      ),
                      _StatColumn(
                        value: '${_profile?.totalEnhancedPhotos ?? 0}',
                        label: 'profile.enhanced'.tr(),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: VColors.border(context),
                      ),
                      _StatColumn(
                        value: '${_profile?.totalPostedPhotos ?? 0}',
                        label: 'profile.posted'.tr(),
                      ),
                    ],
                  ),
                ),

                VSpace.v6,

                // Credit card
                Padding(
                  padding: VSpace.screenH,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BuyCreditsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: VSpace.card,
                      decoration: BoxDecoration(
                        color: VColors.accentSecondary.withValues(alpha: 0.1),
                        borderRadius: VRadii.lgRadius,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            VIcons.wallet,
                            color: VColors.accentSecondary,
                          ),
                          VSpace.h3,
                          ValueListenableBuilder<int>(
                            valueListenable: MainShell.creditNotifier,
                            builder: (_, credits, _) => Text(
                              'credits.balance'.tr(args: ['$credits']),
                              style: VType.label
                                  .copyWith(color: creditTierColor(credits)),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'credits.buy_more'.tr(),
                            style:
                                VType.label.copyWith(color: VColors.textLink),
                          ),
                          Icon(
                            VIcons.chevronRight,
                            size: 20,
                            color: VColors.textLink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                VSpace.v6,

                // Quick actions
                Padding(
                  padding: VSpace.screenH,
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: VIcons.history,
                        label: 'profile.analysis_history'.tr(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AnalysisHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: VColors.border(context)),
                      _ActionRow(
                        icon: VIcons.gallery,
                        label: 'profile.my_photos'.tr(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyPhotosScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: VColors.border(context)),
                      _ActionRow(
                        icon: VIcons.photoEnhance,
                        label: 'profile.enhanced_library'.tr(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EnhancedLibraryScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: VColors.border(context)),
                      _ActionRow(
                        icon: VIcons.gift,
                        label: 'profile.referral_dashboard'.tr(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ReferralDashboardScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: VColors.border(context)),
                      _ActionRow(
                        icon: VIcons.receipt,
                        label: 'profile.credit_history'.tr(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreditHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: VType.kpiLarge.copyWith(color: VColors.text(context)),
          maxLines: 1,
        ),
        VSpace.v1,
        Text(
          label,
          style: VType.caption.copyWith(color: VColors.textSec(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: VColors.textSec(context)),
            VSpace.h3,
            Text(
              label,
              style: VType.screenBody.copyWith(color: VColors.text(context)),
            ),
            const Spacer(),
            Icon(
              VIcons.chevronRight,
              color: VColors.textTer(context),
            ),
          ],
        ),
      ),
    );
  }
}

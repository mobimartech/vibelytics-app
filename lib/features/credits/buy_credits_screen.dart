// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import '../../core/tokens/colors.dart';
// import '../../core/tokens/typography.dart';
// import '../../core/tokens/spacing.dart';
// import '../../core/tokens/radii.dart';
// import '../../core/tokens/icons.dart';
// import '../../core/services/credits_service.dart';
// import '../../core/utils/haptics.dart';
// import '../../core/utils/app_logger.dart';
// import '../../components/buttons/primary_button.dart';
// import '../../components/feedback/credit_badge.dart';
// import '../../components/navigation/standard_screen_app_bar.dart';
// import '../../main_shell.dart';

// /// Buy credits screen with coupon redemption
// class BuyCreditsScreen extends StatefulWidget {
//   const BuyCreditsScreen({super.key});

//   @override
//   State<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
// }

// class _BuyCreditsScreenState extends State<BuyCreditsScreen> {
//   final _couponController = TextEditingController();
//   bool _isRedeeming = false;
//   String? _couponError;
//   String? _couponSuccess;

//   @override
//   void dispose() {
//     _couponController.dispose();
//     super.dispose();
//   }

//   Future<void> _redeemCoupon() async {
//     final code = _couponController.text.trim();
//     if (code.isEmpty) {
//       setState(() => _couponError = 'credits.enter_code'.tr());
//       return;
//     }

//     setState(() {
//       _isRedeeming = true;
//       _couponError = null;
//       _couponSuccess = null;
//     });

//     try {
//       final result = await CreditsService.instance.redeemCoupon(code);

//       if (!mounted) return;

//       if (result.isSuccess) {
//         VHaptics.success();
//         await MainShell.refreshCredits(force: true);
//         if (!mounted) return;
//         setState(() {
//           _couponSuccess = 'credits.credits_added'.tr(args: ['${result.creditsGranted}']);
//           _couponController.clear();
//           _isRedeeming = false;
//         });
//       } else {
//         setState(() {
//           _couponError = result.errorKey?.tr() ?? 'credits.invalid_coupon'.tr();
//           _isRedeeming = false;
//         });
//       }
//     } catch (e) {
//       AppLogger.e('Redeem coupon error', error: e);
//       if (mounted) {
//         setState(() {
//           _couponError = 'credits.redeem_failed'.tr();
//           _isRedeeming = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: StandardScreenAppBar(
//         title: 'credits.buy_title'.tr(),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: VSpace.screenH,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               VSpace.v4,

//               // Current balance
//               Container(
//                 padding: VSpace.card,
//                 decoration: BoxDecoration(
//                   color: VColors.accentPrimary.withValues(alpha: 0.1),
//                   borderRadius: VRadii.lgRadius,
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       VIcons.wallet,
//                       color: VColors.accentPrimary,
//                       size: 24,
//                     ),
//                     VSpace.h3,
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'credits.current_balance'.tr(),
//                           style: VType.caption.copyWith(
//                             color: VColors.textSec(context),
//                           ),
//                         ),
//                         ValueListenableBuilder<int>(
//                           valueListenable: MainShell.creditNotifier,
//                           builder: (_, credits, _) => Text(
//                             'credits.balance'.tr(args: ['$credits']),
//                             style: VType.h3.copyWith(
//                               color: creditTierColor(credits),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               VSpace.v8,

//               // Coupon section
//               Text(
//                 'credits.have_coupon'.tr(),
//                 style: VType.screenSectionTitle.copyWith(
//                   color: VColors.text(context),
//                 ),
//               ),
//               VSpace.v2,
//               Text(
//                 'credits.coupon_description'.tr(),
//                 style: VType.bodySm.copyWith(color: VColors.textSec(context)),
//               ),

//               VSpace.v4,

//               // Coupon input
//               TextField(
//                 controller: _couponController,
//                 textCapitalization: TextCapitalization.characters,
//                 style: VType.body.copyWith(color: VColors.text(context)),
//                 decoration: InputDecoration(
//                   hintText: 'credits.enter_coupon_hint'.tr(),
//                   hintStyle: VType.body.copyWith(color: VColors.textTer(context)),
//                   filled: true,
//                   fillColor: VColors.bgSec(context),
//                   border: OutlineInputBorder(
//                     borderRadius: VRadii.lgRadius,
//                     borderSide: BorderSide.none,
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: VRadii.lgRadius,
//                     borderSide: BorderSide(color: VColors.accentPrimary),
//                   ),
//                   contentPadding: const EdgeInsets.all(16),
//                   prefixIcon: Icon(
//                     VIcons.gift,
//                     color: VColors.textTer(context),
//                   ),
//                 ),
//                 onChanged: (_) {
//                   if (_couponError != null || _couponSuccess != null) {
//                     setState(() {
//                       _couponError = null;
//                       _couponSuccess = null;
//                     });
//                   }
//                 },
//               ),

//               // Error / success message
//               if (_couponError != null) ...[
//                 VSpace.v2,
//                 Text(
//                   _couponError!,
//                   style: VType.bodySm.copyWith(color: VColors.error),
//                 ),
//               ],
//               if (_couponSuccess != null) ...[
//                 VSpace.v2,
//                 Text(
//                   _couponSuccess!,
//                   style: VType.bodySm.copyWith(color: VColors.success),
//                 ),
//               ],

//               VSpace.v4,

//               PrimaryButton(
//                 label: _isRedeeming
//                     ? 'common.loading'.tr()
//                     : 'credits.apply_coupon'.tr(),
//                 onPressed: _isRedeeming ? null : _redeemCoupon,
//               ),

//               VSpace.v6,

//               // Info text
//               Container(
//                 padding: VSpace.card,
//                 decoration: BoxDecoration(
//                   color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
//                   borderRadius: VRadii.lgRadius,
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Icon(VIcons.info, size: 18, color: VColors.textTer(context)),
//                     VSpace.h3,
//                     Expanded(
//                       child: Text(
//                         'credits.coupon_info'.tr(),
//                         style: VType.bodySm.copyWith(color: VColors.textSec(context)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               VSpace.v6,

//               // Earn free credits hint
//               Container(
//                 padding: VSpace.card,
//                 decoration: BoxDecoration(
//                   color: VColors.accentSecondary.withValues(alpha: 0.08),
//                   borderRadius: VRadii.lgRadius,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'credits.earn_free_title'.tr(),
//                       style: VType.label.copyWith(color: VColors.text(context)),
//                     ),
//                     VSpace.v2,
//                     Row(
//                       children: [
//                         Icon(VIcons.star, size: 16, color: VColors.accentSecondary),
//                         VSpace.h2,
//                         Expanded(
//                           child: Text(
//                             'credits.per_action'.tr(),
//                             style: VType.bodySm.copyWith(color: VColors.textSec(context)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     VSpace.v1,
//                     Row(
//                       children: [
//                         Icon(VIcons.userPlus, size: 16, color: VColors.accentSecondary),
//                         VSpace.h2,
//                         Expanded(
//                           child: Text(
//                             'credits.per_signup'.tr(),
//                             style: VType.bodySm.copyWith(color: VColors.textSec(context)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               VSpace.v8,
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/purchase_service.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/app_logger.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../../main_shell.dart';

class BuyCreditPacksScreen extends StatefulWidget {
  const BuyCreditPacksScreen({super.key});

  @override
  State<BuyCreditPacksScreen> createState() => _BuyCreditPacksScreenState();
}

class _BuyCreditPacksScreenState extends State<BuyCreditPacksScreen> {
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;
  List<Package> _packages = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await PurchaseService.instance.initialize();

      final packages = await PurchaseService.instance
          .getConsumableCreditPackages();

      if (!mounted) return;

      setState(() {
        _packages = packages;
        _selectedIndex = 0;
        _isLoading = false;

        if (packages.isEmpty) {
          _error = 'Credit packs are temporarily unavailable.';
        }
      });
    } catch (e, stackTrace) {
      AppLogger.e('Load credit packs error', error: e, stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _packages = [];
        _selectedIndex = 0;
        _isLoading = false;
        _error = 'Unable to load credit packs.';
      });
    }
  }

  Future<void> _purchaseSelected() async {
    final packs = _visiblePacks;
    if (packs.isEmpty) return;

    final selectedPack = packs[_selectedIndex];
    final package = selectedPack.package;

    if (package == null) {
      await _loadPackages();
      return;
    }

    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
      _error = null;
    });
    final info = Platform.isIOS
        ? await DeviceInfoPlugin().iosInfo
        : await DeviceInfoPlugin().androidInfo;

    print("infoooo:::: " + info.data.toString());

    final result = await PurchaseService.instance.purchaseConsumablePackage(
      package,
      // deviceId: "deviceId",
    );

    if (!mounted) return;

    if (result.isSuccess) {
      VHaptics.success();

      // Your backend RevenueCat webhook should grant credits.
      await Future.delayed(const Duration(seconds: 2));
      await CreditsService.instance.getBalance(forceRefresh: true);
      await MainShell.refreshCredits(force: true);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isPurchasing = false;
      if (!result.isCancelled) {
        _error = result.errorMessage ?? 'Purchase failed. Please try again.';
      }
    });
  }

  List<_CreditPackViewModel> get _visiblePacks {
    if (_packages.isEmpty) return _fallbackPacks;

    return _packages.map((package) {
      final product = package.storeProduct;
      final title = product.title
          .replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '')
          .trim();

      return _CreditPackViewModel(
        id: package.identifier,
        title: title,
        subtitle: product.description.isNotEmpty
            ? product.description
            : 'One-time credit pack for AI styling.',
        price: product.priceString,
        badge: _badgeForProduct(title, package.identifier),
        package: package,
      );
    }).toList();
  }

  String _badgeForProduct(String title, String identifier) {
    final text = '$title $identifier'.toLowerCase();

    if (text.contains('large') ||
        text.contains('mega') ||
        text.contains('1000')) {
      return 'Best value';
    }

    if (text.contains('medium') ||
        text.contains('popular') ||
        text.contains('500')) {
      return 'Popular';
    }

    return 'One-time';
  }

  @override
  Widget build(BuildContext context) {
    final packs = _visiblePacks;
    final usingFallbackPacks = _packages.isEmpty;
    final selectedPack = packs.isNotEmpty ? packs[_selectedIndex] : null;

    return Scaffold(
      appBar: const StandardScreenAppBar(title: 'Buy credits'),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: VSpace.screenH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VSpace.v4,

                  const _HeaderSection(),

                  VSpace.v4,

                  if (_isLoading)
                    const Expanded(
                      child: Column(
                        children: [
                          Expanded(child: _PackSkeletonCard()),
                          SizedBox(height: 10),
                          Expanded(child: _PackSkeletonCard()),
                          SizedBox(height: 10),
                          Expanded(child: _PackSkeletonCard()),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Column(
                              children: List.generate(
                                packs.take(3).length * 2 - 1,
                                (i) {
                                  if (i.isOdd) {
                                    return const SizedBox(height: 10);
                                  }

                                  final index = i ~/ 2;
                                  final pack = packs[index];

                                  return Expanded(
                                    child: _CreditPackCard(
                                      pack: pack,
                                      selected: index == _selectedIndex,
                                      disabled: _isPurchasing,
                                      onTap: () {
                                        setState(() {
                                          _selectedIndex = index;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          if (usingFallbackPacks) ...[
                            const SizedBox(height: 8),
                            _FallbackNotice(
                              error: _error,
                              onRetry: _isPurchasing ? null : _loadPackages,
                            ),
                          ],
                        ],
                      ),
                    ),

                  VSpace.v3,

                  PrimaryButton(
                    label: selectedPack?.isPurchasable == true
                        ? 'Continue'
                        : 'Reload credit packs',
                    onPressed: _isPurchasing || selectedPack == null
                        ? null
                        : _purchaseSelected,
                  ),

                  VSpace.v2,

                  const _BenefitsCard(),

                  VSpace.v2,

                  const _LegalText(),

                  VSpace.v2,
                ],
              ),
            ),

            if (_isPurchasing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.16),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose credit pack',
          style: VType.screenSectionTitle.copyWith(
            color: VColors.text(context),
          ),
        ),
        VSpace.v1,
        Text(
          'Buy credits with Apple In-App Purchase. Credits are one-time consumable purchases.',
          style: VType.bodySm.copyWith(color: VColors.textSec(context)),
        ),
      ],
    );
  }
}

class _CreditPackCard extends StatelessWidget {
  final _CreditPackViewModel pack;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _CreditPackCard({
    required this.pack,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: VRadii.lgRadius,
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? VColors.accentPrimary.withValues(alpha: 0.08)
              : VColors.bgSec(context),
          borderRadius: VRadii.lgRadius,
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected
                ? VColors.accentPrimary
                : VColors.textTer(context).withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? VColors.accentPrimary
                      : VColors.textTer(context),
                  size: 20,
                ),
                VSpace.h2,
                Expanded(
                  child: Text(
                    pack.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VType.label.copyWith(color: VColors.text(context)),
                  ),
                ),
                _Badge(text: pack.badge),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                pack.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VType.caption.copyWith(color: VColors.textSec(context)),
              ),
            ),
            // const SizedBox(height: 6),
            Spacer(),
            Text(
              pack.price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VType.label.copyWith(
                fontSize: 25,
                color: VColors.accentPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: VColors.accentPrimary.withValues(alpha: 0.12),
        borderRadius: VRadii.fullRadius,
      ),
      child: Text(
        text,
        style: VType.caption.copyWith(
          color: VColors.accentPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FallbackNotice extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;

  const _FallbackNotice({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: VColors.bgSec(context),
        borderRadius: VRadii.mdRadius,
      ),
      child: Row(
        children: [
          Icon(VIcons.info, size: 16, color: VColors.textTer(context)),
          VSpace.h2,
          Expanded(
            child: Text(
              error ??
                  'Credit packs are previews until App Store products load.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: VType.caption.copyWith(color: VColors.textSec(context)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VColors.accentSecondary.withValues(alpha: 0.08),
        borderRadius: VRadii.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you get',
            style: VType.label.copyWith(color: VColors.text(context)),
          ),
          VSpace.v2,
          _BenefitRow(
            icon: VIcons.star,
            text: 'One-time credits for AI outfit generation',
          ),
          _BenefitRow(
            icon: VIcons.wallet,
            text: 'Credits are added after purchase confirmation',
          ),
          _BenefitRow(
            icon: VIcons.info,
            text: 'Secure payment through Apple In-App Purchase',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: VColors.accentSecondary),
          VSpace.h2,
          Expanded(
            child: Text(
              text,
              style: VType.caption.copyWith(color: VColors.textSec(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Payment is charged to your Apple ID. Credit packs are consumable one-time purchases and do not renew.',
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: VType.caption.copyWith(color: VColors.textTer(context)),
    );
  }
}

class _PackSkeletonCard extends StatelessWidget {
  const _PackSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: VColors.bgSec(context),
        borderRadius: VRadii.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: 160, height: 18),
          const SizedBox(height: 8),
          _SkeletonLine(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          _SkeletonLine(width: 210, height: 12),
          const Spacer(),
          _SkeletonLine(width: 100, height: 20),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: VColors.textTer(context).withValues(alpha: 0.12),
        borderRadius: VRadii.smRadius,
      ),
    );
  }
}

class _CreditPackViewModel {
  final String id;
  final String title;
  final String subtitle;
  final String price;
  final String badge;
  final Package? package;

  const _CreditPackViewModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.badge,
    this.package,
  });

  bool get isPurchasable => package != null;
}

const List<_CreditPackViewModel> _fallbackPacks = [
  _CreditPackViewModel(
    id: 'fallback_small',
    title: 'Small Credit Pack',
    subtitle: 'A starter pack for trying AI outfit generation.',
    price: '\$1.99',
    badge: 'One-time',
  ),
  _CreditPackViewModel(
    id: 'fallback_medium',
    title: 'Medium Credit Pack',
    subtitle: 'More credits for styling multiple outfits.',
    price: '\$4.99',
    badge: 'Popular',
  ),
  _CreditPackViewModel(
    id: 'fallback_large',
    title: 'Large Credit Pack',
    subtitle: 'Best value for frequent AI styling.',
    price: '\$9.99',
    badge: 'Best value',
  ),
];

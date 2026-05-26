import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/credits_service.dart';
import '../../components/navigation/standard_screen_app_bar.dart';
import '../onboarding/splash_screen.dart';
import 'permissions_screen.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeModeLabel() {
    switch (VibelyticsApp.themeNotifier.value) {
      case ThemeMode.system:
        return 'settings.theme_system'.tr();
      case ThemeMode.light:
        return 'settings.theme_light'.tr();
      case ThemeMode.dark:
        return 'settings.theme_dark'.tr();
    }
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VColors.adaptive(
        context,
        light: VColors.bgPrimary,
        dark: VColors.bgSecondaryDark,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VSpace.v4,
              Text(
                'settings.appearance'.tr(),
                style: VType.h3.copyWith(color: VColors.text(ctx)),
              ),
              VSpace.v4,
              _ThemeOption(
                label: 'settings.theme_system'.tr(),
                icon: VIcons.themeSystem,
                isSelected:
                    VibelyticsApp.themeNotifier.value == ThemeMode.system,
                onTap: () => _setTheme(ctx, ThemeMode.system),
              ),
              _ThemeOption(
                label: 'settings.theme_light'.tr(),
                icon: VIcons.theme,
                isSelected:
                    VibelyticsApp.themeNotifier.value == ThemeMode.light,
                onTap: () => _setTheme(ctx, ThemeMode.light),
              ),
              _ThemeOption(
                label: 'settings.theme_dark'.tr(),
                icon: VIcons.themeDark,
                isSelected: VibelyticsApp.themeNotifier.value == ThemeMode.dark,
                onTap: () => _setTheme(ctx, ThemeMode.dark),
              ),
              VSpace.v4,
            ],
          ),
        );
      },
    );
  }

  void _setTheme(BuildContext ctx, ThemeMode mode) {
    VibelyticsApp.setThemeMode(mode);
    Navigator.pop(ctx);
    setState(() {});
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.link_open_error'.tr()),
            backgroundColor: VColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(title: 'settings.title'.tr()),
      body: SingleChildScrollView(
        padding: VSpace.screenH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VSpace.v4,

            // Preferences section
            _SectionTitle(title: 'settings.section_preferences'.tr()),
            VSpace.v3,
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: VIcons.language,
                  label: 'settings.language'.tr(),
                  value: context.locale.languageCode.toUpperCase(),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LanguageSettingsScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: VIcons.themeDark,
                  label: 'settings.appearance'.tr(),
                  value: _themeModeLabel(),
                  onTap: _showThemePicker,
                ),
                _SettingsItem(
                  icon: VIcons.lock,
                  label: 'settings.permissions'.tr(),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PermissionsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            VSpace.v6,

            // Legal section
            _SectionTitle(title: 'settings.section_support'.tr()),
            VSpace.v3,
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: VIcons.document,
                  label: 'settings.terms'.tr(),
                  onTap: () => _openUrl('https://vibelytics.org/terms.html'),
                ),
                _SettingsItem(
                  icon: VIcons.privacy,
                  label: 'settings.privacy_policy'.tr(),
                  onTap: () => _openUrl('https://vibelytics.org/privacy.html'),
                ),
                _SettingsItem(
                  icon: VIcons.info,
                  label: 'settings.about'.tr(),
                  value: 'support@vibelytics.org',
                  onTap: () => _openUrl('mailto:support@vibelytics.org'),
                ),
              ],
            ),

            VSpace.v6,

            // Danger zone
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: VIcons.logout,
                  label: 'settings.logout'.tr(),
                  isDestructive: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('settings.logout'.tr()),
                        content: Text('settings.logout_confirm'.tr()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('common.cancel'.tr()),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await AuthService.instance.logout();
                              CreditsService.instance.clearCache();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const SplashScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            child: Text(
                              'settings.logout'.tr(),
                              style: TextStyle(color: VColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: VIcons.trash,
                  label: 'settings.delete_account'.tr(),
                  isDestructive: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('settings.delete_account'.tr()),
                        content: Text('settings.delete_confirm'.tr()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('common.cancel'.tr()),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final success = await AuthService.instance
                                  .deleteAccount();
                              if (!context.mounted) return;
                              if (success) {
                                CreditsService.instance.clearCache();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const SplashScreen(),
                                  ),
                                  (route) => false,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('common.error'.tr()),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: VColors.error,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'settings.delete_account'.tr(),
                              style: TextStyle(color: VColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            VSpace.v6,

            // App version
            Center(
              child: Text(
                'settings.version'.tr(args: ['1.0.0']),
                style: VType.screenMeta.copyWith(
                  color: VColors.textTer(context),
                ),
              ),
            ),

            VSpace.v6,
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: VType.screenMeta.copyWith(
        color: VColors.textTer(context),
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: VRadii.lgRadius,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              item,
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Divider(height: 1, color: VColors.border(context)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? VColors.error : VColors.text(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive ? VColors.error : VColors.textSec(context),
            ),
            VSpace.h3,
            Expanded(
              child: Text(label, style: VType.body.copyWith(color: color)),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: VType.body.copyWith(color: VColors.textTer(context)),
              ),
              VSpace.h1,
            ],
            if (!isDestructive)
              Icon(
                VIcons.chevronRight,
                color: VColors.textTer(context),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? VColors.accentPrimary : VColors.textSec(context),
      ),
      title: Text(
        label,
        style: VType.body.copyWith(
          color: isSelected ? VColors.accentPrimary : VColors.text(context),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? Icon(VIcons.check, color: VColors.accentPrimary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

/// Language settings screen
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    final languages = [('en', 'English'), ('ar', 'العربية')];

    return Scaffold(
      appBar: StandardScreenAppBar(title: 'settings.language'.tr()),
      body: ListView.builder(
        padding: VSpace.screenH,
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final (code, name) = languages[index];
          final isSelected = currentLocale.languageCode == code;

          return GestureDetector(
            onTap: () {
              context.setLocale(Locale(code));
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: VColors.border(context)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: VType.body.copyWith(color: VColors.text(context)),
                    ),
                  ),
                  if (isSelected)
                    Icon(VIcons.check, color: VColors.accentPrimary, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

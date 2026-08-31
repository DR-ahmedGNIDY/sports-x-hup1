import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/locale/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/backend_status_indicator.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_sheet.dart';
import '../../../../core/widgets/mobile/inset_grouped_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../shared/change_email_form.dart';
import '../shared/change_password_form.dart';

/// Settings, rebuilt on the M3 component library.
///
/// What was here before: an untitled `Column` of two always-expanded forms
/// under a hardcoded English `'Signed in as …'`, in an app whose default
/// language is Arabic. Every string it showed — including both forms', which
/// had l10n keys sitting unused — was English.
///
/// What replaced it is the shape a phone settings screen has: grouped rows in
/// inset cards, the account's own details at the top, each change opening in
/// a sheet rather than sprawling down the page, and the destructive action
/// alone at the bottom.
class SettingsPageMobile extends ConsumerWidget {
  const SettingsPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return AppScaffoldMobile(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  l10n.signedInAs(session.user?.email ?? ''),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              InsetGroupedList(
                header: l10n.settingsAccountGroup,
                children: [
                  AppListRow(
                    icon: Icons.alternate_email,
                    label: l10n.emailSectionTitle,
                    value: session.user?.email,
                    onTap: () => AppSheet.show<void>(
                      context: context,
                      title: l10n.emailSectionTitle,
                      builder: (_) => const _SheetForm(child: ChangeEmailForm()),
                    ),
                  ),
                  AppListRow(
                    icon: Icons.lock_outline,
                    label: l10n.changePasswordLabel,
                    onTap: () => AppSheet.show<void>(
                      context: context,
                      title: l10n.changePasswordLabel,
                      builder: (_) =>
                          const _SheetForm(child: ChangePasswordForm()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              InsetGroupedList(
                header: l10n.settingsAppearanceGroup,
                children: [
                  // A switch, not a row that opens something — the setting is
                  // binary and its state is the point, so it's shown and
                  // toggled in place.
                  AppListRow(
                    icon: themeModeToggleIcon(themeMode),
                    label: l10n.themeToggleTooltip,
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                  AppListRow(
                    icon: Icons.language,
                    label: locale == arabicLocale
                        ? l10n.switchToEnglish
                        : l10n.switchToArabic,
                    value: locale == arabicLocale ? 'العربية' : 'English',
                    // Toggles in place rather than opening a picker, so no
                    // chevron promising a screen that never appears.
                    showChevron: false,
                    onTap: () => ref.read(localeProvider.notifier).toggle(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              InsetGroupedList(
                children: [
                  AppListRow(
                    icon: Icons.logout_outlined,
                    label: l10n.logoutTooltip,
                    destructive: true,
                    onTap: () =>
                        ref.read(sessionControllerProvider.notifier).logout(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Center(child: BackendStatusIndicator()),
            ],
          ),
        ),
      ],
    );
  }
}

/// Padding around a form presented in a sheet. The forms themselves are
/// shared with Desktop and shouldn't grow sheet-specific margins.
class _SheetForm extends StatelessWidget {
  const _SheetForm({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: child,
    );
  }
}

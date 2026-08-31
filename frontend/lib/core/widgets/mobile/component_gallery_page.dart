import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../theme/app_blur.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'app_sheet.dart';
import 'inset_grouped_list.dart';

/// A preview of the mobile component library, reachable at `/dev/gallery`.
///
/// It exists because most of these components live on screens behind a login,
/// which makes them impossible to look at without a session — so they were
/// being reviewed as code and as widget tests, and never as pixels. A gallery
/// is the standard answer, and it stays useful past this phase: it is where a
/// component's states get compared side by side, in both themes and both text
/// directions, without hunting for a screen that happens to show all of them.
///
/// The route is compiled in only when the app is built with
/// `--dart-define=SXH_GALLERY=true` (see `app_router.dart`), so it cannot ship
/// to production by accident.
///
/// Deliberately not localized: the labels here name components, and a
/// component's name is not product copy.
class ComponentGalleryPage extends StatelessWidget {
  const ComponentGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Component gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _Section('InsetGroupedList — a settings group'),
          InsetGroupedList(
            header: l10n.dashboardAccountSettings,
            children: [
              AppListRow(
                icon: Icons.alternate_email,
                label: l10n.emailSectionTitle,
                value: 'someone@example.test',
                onTap: () {},
              ),
              AppListRow(
                icon: Icons.lock_outline,
                label: l10n.changePasswordLabel,
                onTap: () {},
              ),
            ],
          ),

          const _Section('Row variants'),
          InsetGroupedList(
            children: [
              AppListRow(
                icon: Icons.dark_mode_outlined,
                label: l10n.themeToggleTooltip,
                trailing: Switch(value: true, onChanged: (_) {}),
                onTap: () {},
              ),
              AppListRow(
                icon: Icons.language,
                label: l10n.switchToEnglish,
                value: 'العربية',
                onTap: () {},
              ),
              const AppListRow(
                icon: Icons.info_outline,
                label: 'A row with no action — no chevron',
              ),
              AppListRow(
                icon: Icons.logout_outlined,
                label: l10n.logoutTooltip,
                destructive: true,
                onTap: () {},
              ),
            ],
          ),

          const _Section('AppSheet'),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilledButton(
                onPressed: () => AppSheet.show<void>(
                  context: context,
                  title: 'A titled sheet',
                  builder: (_) => const _SheetSample(),
                ),
                child: const Text('Open sheet'),
              ),
              OutlinedButton(
                onPressed: () => AppSheet.show<void>(
                  context: context,
                  title: 'A full-height sheet',
                  fullHeight: true,
                  builder: (_) => const _SheetSample(),
                ),
                child: const Text('Open tall sheet'),
              ),
            ],
          ),

          const _Section('BlurredSurface — the bar treatment'),
          // Stacked over content so the blur has something to blur; a blurred
          // bar over a flat background looks like a flat bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: 8,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        'Content scrolling under the bar — line $i',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: BlurredSurface(
                      color: theme.colorScheme.surface,
                      child: SizedBox(
                        height: kToolbarHeight,
                        child: Center(
                          child: Text(
                            'Blurred bar',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.md),
      child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _SheetSample extends StatelessWidget {
  const _SheetSample();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TextField(decoration: InputDecoration(labelText: 'A field')),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

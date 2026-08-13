import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import 'locale_provider.dart';

/// Shared so Desktop and Mobile presentation trees don't each re-derive the
/// same icon/tooltip decision independently — same rationale as
/// themeModeToggleIcon (core/theme/theme_mode_provider.dart). Placed
/// immediately beside the theme toggle everywhere that button appears.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final switchingToEnglish = locale == arabicLocale;
    return IconButton(
      tooltip: switchingToEnglish ? l10n.switchToEnglish : l10n.switchToArabic,
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      icon: const Icon(Icons.language_outlined),
    );
  }
}

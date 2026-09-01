import 'app_install.dart';

/// Non-web: a packaged Android or iOS build is already installed, so there is
/// nothing to offer and nothing to prompt.
InstallOffer resolveInstallOffer() => InstallOffer.none;

Future<bool> runInstallPrompt() async => false;

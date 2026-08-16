import 'package:flutter/widgets.dart';

import '../../../core/widgets/responsive_layout.dart';
import 'desktop/edit_club_player_page_desktop.dart';
import 'mobile/edit_club_player_page_mobile.dart';

/// A Club editing a player it created — reuses the Player feature's own
/// [ProfileDetailsForm]/[ProfilePhotoSection] (see those files for how)
/// instead of a parallel editing implementation.
class EditClubPlayerPage extends StatelessWidget {
  const EditClubPlayerPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: (_) => EditClubPlayerPageDesktop(userId: userId),
      mobile: (_) => EditClubPlayerPageMobile(userId: userId),
    );
  }
}

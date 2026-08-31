import 'package:flutter/material.dart';

import '../shared/add_club_player_form.dart';

class AddClubPlayerPageMobile extends StatelessWidget {
  const AddClubPlayerPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      // No heading or back button here: the shell's app bar names this screen
      // and owns its back affordance (see AppRouteMeta), so repeating either
      // would be two titles and two ways back on one screen.
      children: const [AddClubPlayerForm(isDesktop: false)],
    );
  }
}

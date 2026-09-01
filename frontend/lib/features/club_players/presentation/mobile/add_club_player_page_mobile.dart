import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../shared/add_club_player_form.dart';

class AddClubPlayerPageMobile extends StatelessWidget {
  const AddClubPlayerPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffoldMobile(
      // No heading and no back button in the content: the page's own app bar
      // names this screen and owns its back affordance (see AppRouteMeta), so
      // repeating either would be two titles and two ways back on one screen.
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(child: AddClubPlayerForm(isDesktop: false)),
        ),
      ],
    );
  }
}

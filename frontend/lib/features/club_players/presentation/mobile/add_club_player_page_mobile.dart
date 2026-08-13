import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/add_club_player_form.dart';

class AddClubPlayerPageMobile extends StatelessWidget {
  const AddClubPlayerPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('إضافة لاعب', style: Theme.of(context).textTheme.headlineSmall),
            IconButton(
              onPressed: () => context.go('/club/players'),
              icon: const Icon(Icons.arrow_back_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const AddClubPlayerForm(),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/add_club_player_form.dart';

class AddClubPlayerPageDesktop extends StatelessWidget {
  const AddClubPlayerPageDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('إضافة لاعب', style: Theme.of(context).textTheme.headlineSmall),
                  TextButton.icon(
                    onPressed: () => context.go('/club/players'),
                    icon: const Icon(Icons.arrow_back_outlined),
                    label: const Text('رجوع'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: const AddClubPlayerForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

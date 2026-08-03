import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/health_check_provider.dart';
import '../theme/app_colors.dart';

/// Small diagnostic dot + label showing whether the Flutter app can reach
/// the backend `/health` endpoint. Foundation verification only.
class BackendStatusIndicator extends ConsumerWidget {
  const BackendStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthCheckProvider);

    final (Color color, String label) = health.when(
      data: (status) => status.isOk
          ? (AppColors.success, 'Backend connected')
          : (AppColors.warning, 'Backend unreachable'),
      loading: () => (AppColors.grey, 'Checking backend...'),
      error: (_, _) => (AppColors.error, 'Backend unreachable'),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

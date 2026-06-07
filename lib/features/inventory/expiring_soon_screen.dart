import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../home/widgets/expiring_section.dart';

class ExpiringSoonScreen extends ConsumerWidget {
  const ExpiringSoonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiring = ref.watch(expiringSoonListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Validade próxima')),
      body: expiring.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
              itemCount: expiring.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final item = expiring[i];
                return ExpiringTile(
                  item: item,
                  onTap: () => context.push('/item/${item.id}'),
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 48, color: AppColors.green),
          SizedBox(height: AppSpacing.md),
          Text('Nenhum produto vencendo nos próximos 7 dias',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

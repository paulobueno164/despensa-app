import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../home/widgets/low_stock_section.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final low = ref.watch(lowStockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Está acabando')),
      body: low.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
              itemCount: low.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final item = low[i];
                return LowStockTile(
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
          Text('Nada acabando agora 🎉',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

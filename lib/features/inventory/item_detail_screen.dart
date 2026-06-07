import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/category_icons.dart';
import '../../core/format/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/providers.dart';
import '../movements/register_movement_sheet.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemProvider(itemId)).value;
    final categories = ref.watch(categoriesProvider).value ?? const [];

    if (item == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final category =
        categories.where((c) => c.id == item.categoryId).firstOrNull;
    final color =
        category != null ? colorFromHex(category.colorHex) : AppColors.green;
    final isLow = item.quantity <= item.minQuantity;
    final full = item.fullQuantity ?? item.minQuantity;
    final fraction = full <= 0 ? 0.0 : (item.quantity / full).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/item/${item.id}/editar'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Excluir item?'),
                  content: Text('Remover "${item.name}" do estoque?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Excluir')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(databaseProvider).deleteItem(item.id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(categoryIcon(category?.iconKey ?? 'dots'),
                    size: 32, color: color),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(category?.name ?? 'Sem categoria',
                        style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Em estoque',
                        style: TextStyle(color: AppColors.textMuted)),
                    Text(
                      formatQuantity(item.quantity, item.unit,
                          lowLabel: item.lowLabel),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isLow ? AppColors.warning : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(
                        isLow ? AppColors.warning : AppColors.green),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Mínimo: ${formatQuantity(item.minQuantity, item.unit)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (item.expiresAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            SoftCard(
              child: Row(
                children: [
                  Icon(Icons.event_rounded,
                      color: daysUntil(item.expiresAt!) <= 3
                          ? AppColors.danger
                          : AppColors.green),
                  const SizedBox(width: AppSpacing.md),
                  Text(expiryLabel(item.expiresAt!),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      showRegisterMovementSheet(context, itemId: item.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Entrada'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      showRegisterMovementSheet(context, itemId: item.id),
                  icon: const Icon(Icons.remove),
                  label: const Text('Saída'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

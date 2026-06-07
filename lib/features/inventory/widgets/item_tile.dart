import 'package:flutter/material.dart';

import '../../../core/db/database.dart';
import '../../../core/format/category_icons.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';

/// Linha de item no estoque: ícone da categoria, nome, qtd, validade, barra.
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    this.category,
    this.onTap,
  });

  final Item item;
  final Category? category;
  final VoidCallback? onTap;

  bool get _isLow => item.quantity <= item.minQuantity;

  @override
  Widget build(BuildContext context) {
    final color =
        category != null ? colorFromHex(category!.colorHex) : AppColors.green;
    final expiresAt = item.expiresAt;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(categoryIcon(category?.iconKey ?? 'dots'),
                size: 22, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_isLow) ...[
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      const Text('Acabando',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.warning)),
                    ] else if (expiresAt != null) ...[
                      Icon(Icons.schedule_rounded,
                          size: 14,
                          color: daysUntil(expiresAt) <= 0
                              ? AppColors.danger
                              : AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(expiryLabel(expiresAt),
                          style: TextStyle(
                              fontSize: 12,
                              color: daysUntil(expiresAt) <= 0
                                  ? AppColors.danger
                                  : AppColors.textMuted)),
                    ] else
                      Text(category?.name ?? 'Sem categoria',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatQuantity(item.quantity, item.unit, lowLabel: item.lowLabel),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _isLow ? AppColors.warning : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

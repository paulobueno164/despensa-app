import 'package:flutter/material.dart';

import '../../../core/db/database.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';

/// Linha de item com validade próxima ou vencida.
class ExpiringTile extends StatelessWidget {
  const ExpiringTile({super.key, required this.item, this.onTap});

  final Item item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final expiresAt = item.expiresAt!;
    final days = daysUntil(expiresAt);
    final urgent = days <= 0;
    final soon = days <= 3;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (urgent ? AppColors.danger : AppColors.warning)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              urgent ? Icons.error_outline_rounded : Icons.schedule_rounded,
              size: 22,
              color: urgent ? AppColors.danger : AppColors.warning,
            ),
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
                Text(
                  expiryLabel(expiresAt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: urgent
                        ? AppColors.danger
                        : soon
                            ? AppColors.warning
                            : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

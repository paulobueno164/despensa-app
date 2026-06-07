import 'package:flutter/material.dart';

import '../../../core/db/database.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';

/// Lista "Últimas movimentações": entrada (verde ↙) ou saída (vermelho ↗).
class MovementsList extends StatelessWidget {
  const MovementsList({super.key, required this.movements});

  final List<MovementWithItem> movements;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 64, endIndent: 16),
            _MovementTile(data: movements[i]),
          ],
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.data});

  final MovementWithItem data;

  @override
  Widget build(BuildContext context) {
    final isInflow = data.movement.type == 'in';
    final color = isInflow ? AppColors.inflow : AppColors.danger;
    final bg = isInflow ? AppColors.inflowSoft : AppColors.dangerSoft;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(
              isInflow ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMovementDate(data.movement.createdAt),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatSignedQuantity(
                data.movement.quantity, data.movement.unit, isInflow),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

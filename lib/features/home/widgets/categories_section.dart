import 'package:flutter/material.dart';

import '../../../core/db/database.dart';
import '../../../core/format/category_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/soft_card.dart';

/// Grid de categorias (3 colunas) com ícone e contagem de itens.
class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({super.key, required this.categories, this.onTap});

  final List<CategoryWithCount> categories;
  final void Function(CategoryWithCount)? onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.92,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final c = categories[index];
        return _CategoryTile(data: c, onTap: () => onTap?.call(c));
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.data, this.onTap});

  final CategoryWithCount data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(data.category.colorHex);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon(data.category.iconKey),
                size: 24, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${data.itemCount} ${data.itemCount == 1 ? 'item' : 'itens'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

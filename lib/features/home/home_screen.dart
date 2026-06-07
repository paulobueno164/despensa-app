import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/format/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import 'widgets/categories_section.dart';
import 'widgets/expiring_section.dart';
import 'widgets/hero_card.dart';
import 'widgets/low_stock_section.dart';
import 'widgets/movements_section.dart';
import 'widgets/stats_row.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).value;
    final stats = ref.watch(dashboardStatsProvider);
    final lowStock = ref.watch(lowStockProvider);
    final expiring = ref.watch(expiringSoonListProvider);
    final categories =
        ref.watch(categoriesWithCountsProvider).value ?? const [];
    final movements =
        ref.watch(recentMovementsProvider).value ?? const [];

    // As 6 primeiras categorias (ordem definida no cadastro) para a home.
    final homeCategories = categories.take(6).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
          children: [
            _Header(
              name: household?.displayName ?? kDefaultHouseholdName,
              alertCount: stats.expiring,
              onAlertsTap: () => context.push('/vencendo'),
            ),
            const SizedBox(height: AppSpacing.lg),
            HeroCard(
              attentionCount: stats.attention,
              totalItems: stats.total,
            ),
            const SizedBox(height: AppSpacing.xl),
            StatsRow(
              total: stats.total,
              low: stats.low,
              categories: stats.categories,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (lowStock.isNotEmpty) ...[
              SectionHeader(
                title: 'Está acabando',
                actionLabel: 'Ver tudo',
                onAction: () => context.push('/acabando'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final item in lowStock.take(4)) ...[
                LowStockTile(
                  item: item,
                  onTap: () => context.push('/item/${item.id}'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
            if (expiring.isNotEmpty) ...[
              SectionHeader(
                title: 'Validade próxima',
                actionLabel: 'Ver tudo',
                onAction: () => context.push('/vencendo'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final item in expiring.take(4)) ...[
                ExpiringTile(
                  item: item,
                  onTap: () => context.push('/item/${item.id}'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
            const SectionHeader(title: 'Categorias'),
            const SizedBox(height: AppSpacing.md),
            if (homeCategories.isEmpty)
              SoftCard(
                onTap: () => context.push('/categorias'),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.category_outlined,
                          color: AppColors.green),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'Nenhuma categoria ainda. Toque para criar a primeira.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              CategoriesGrid(
                categories: homeCategories,
                onTap: (c) => context.push('/category/${c.category.id}'),
              ),
            const SizedBox(height: AppSpacing.xl),
            if (movements.isNotEmpty) ...[
              const SectionHeader(title: 'Últimas movimentações'),
              const SizedBox(height: AppSpacing.md),
              MovementsList(movements: movements),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.alertCount,
    required this.onAlertsTap,
  });
  final String name;
  final int alertCount;
  final VoidCallback onAlertsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.greenDark,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco, color: Colors.white, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting(),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAlertsTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: AppColors.textDark, size: 24),
                if (alertCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: alertCount > 9
                          ? const EdgeInsets.symmetric(horizontal: 4)
                          : null,
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: alertCount > 9
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius:
                            alertCount > 9 ? BorderRadius.circular(99) : null,
                        border: Border.all(
                            color: AppColors.surface, width: 1.5),
                      ),
                      child: Text(
                        alertCount > 9 ? '9+' : '$alertCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

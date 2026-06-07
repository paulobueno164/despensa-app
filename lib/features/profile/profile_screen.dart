import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/utils/save_feedback.dart';
import '../../data/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider).value;
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
        children: [
          SoftCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.greenDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 28),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(household?.displayName ?? kDefaultHouseholdName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text('${stats.total} itens • ${stats.categories} categorias',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editName(
                      context, ref, household?.displayName ?? kDefaultHouseholdName),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Inteligência artificial',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: AppSpacing.md),
          _MenuTile(
            icon: Icons.restaurant_menu_rounded,
            color: AppColors.green,
            title: 'Receitas com IA',
            subtitle: 'O que dá pra cozinhar com a sua despensa',
            onTap: () => context.push('/receitas'),
          ),
          const SizedBox(height: AppSpacing.md),
          _MenuTile(
            icon: Icons.receipt_long_rounded,
            color: AppColors.warning,
            title: 'Escanear nota fiscal',
            subtitle: 'Tire foto do cupom e dê entrada automática',
            onTap: () => context.push('/nota'),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Geral',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: AppSpacing.md),
          _MenuTile(
            icon: Icons.category_outlined,
            color: AppColors.green,
            title: 'Categorias',
            subtitle: '${stats.categories} categorias',
            onTap: () => context.push('/categorias'),
          ),
          const SizedBox(height: AppSpacing.md),
          const _MenuTile(
            icon: Icons.info_outline_rounded,
            color: AppColors.textMuted,
            title: 'Sobre',
            subtitle: 'Despensa • dados salvos no aparelho',
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nome da despensa'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await runSave(context, () async {
        await ref.read(databaseProvider).setHouseholdName(name);
      }, successMessage: 'Nome atualizado.');
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

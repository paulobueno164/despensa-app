import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/utils/save_feedback.dart';
import '../../data/providers.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context);
    if (name == null || name.isEmpty) return;
    int? listId;
    final ok = await runSave(context, () async {
      listId = await ref.read(databaseProvider).createList(name);
    }, successMessage: 'Lista criada.');
    if (ok && listId != null && context.mounted) {
      context.push('/lista/$listId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeListsProvider).value ?? const [];
    final templates = ref.watch(templateListsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _createList(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
        children: [
          const SectionHeader(title: 'Minhas listas'),
          const SizedBox(height: AppSpacing.md),
          if (active.isEmpty)
            _Hint(
              text: 'Crie uma lista de compras e marque o que pegar no mercado. '
                  'Ao concluir, tudo entra automático na despensa.',
              onTap: () => _createList(context, ref),
            )
          else
            for (final l in active) ...[
              _ListTile(
                list: l,
                icon: Icons.shopping_cart_outlined,
                onTap: () => context.push('/lista/${l.id}'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          const SizedBox(height: AppSpacing.lg),
          if (templates.isNotEmpty) ...[
            const SectionHeader(title: 'Modelos salvos'),
            const SizedBox(height: AppSpacing.md),
            for (final l in templates) ...[
              _ListTile(
                list: l,
                icon: Icons.bookmark_outline_rounded,
                subtitle: 'Modelo • toque para usar',
                onTap: () => context.push('/lista/${l.id}'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ],
      ),
    );
  }

  static Future<String?> _promptName(BuildContext context,
      {String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova lista'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex.: Compra do mês'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.list,
    required this.icon,
    this.subtitle,
    this.onTap,
  });
  final ShoppingList list;
  final IconData icon;
  final String? subtitle;
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
            decoration: const BoxDecoration(
              color: AppColors.greenSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.green),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(list.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.green),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

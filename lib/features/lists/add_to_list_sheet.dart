import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';

/// Mostra uma folha para escolher (ou criar) a lista de compras onde os
/// [names] serão adicionados.
Future<void> showAddToListSheet(
  BuildContext context,
  WidgetRef ref,
  List<String> names,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => _AddToListSheet(names: names),
  );
}

class _AddToListSheet extends ConsumerWidget {
  const _AddToListSheet({required this.names});
  final List<String> names;

  Future<void> _addTo(
      BuildContext context, WidgetRef ref, int listId, String listName) async {
    final added = await ref.read(databaseProvider).addNamesToList(listId, names);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.green,
        content: Text(added == 0
            ? 'Os itens já estavam em "$listName".'
            : '$added ${added == 1 ? 'item adicionado' : 'itens adicionados'} a "$listName".'),
      ),
    );
  }

  Future<void> _createAndAdd(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: 'Compras');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova lista'),
        content: TextField(controller: controller, autofocus: true),
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
    if (name == null || name.isEmpty || !context.mounted) return;
    final id = await ref.read(databaseProvider).createList(name);
    if (context.mounted) await _addTo(context, ref, id, name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(activeListsProvider).value ?? const [];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Adicionar ${names.length} ${names.length == 1 ? 'item' : 'itens'} à lista',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              names.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final l in lists)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.greenSoft,
                  child: Icon(Icons.shopping_cart_outlined,
                      color: AppColors.green),
                ),
                title: Text(l.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _addTo(context, ref, l.id, l.name),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.greenSoft,
                child: Icon(Icons.add, color: AppColors.green),
              ),
              title: const Text('Nova lista',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.green)),
              onTap: () => _createAndAdd(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

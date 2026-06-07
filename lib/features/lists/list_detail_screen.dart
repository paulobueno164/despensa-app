import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/format/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/save_feedback.dart';
import '../../data/providers.dart';

class ListDetailScreen extends ConsumerWidget {
  const ListDetailScreen({super.key, required this.listId});
  final int listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(listProvider(listId)).value;
    final items = ref.watch(listItemsProvider(listId)).value ?? const [];
    final db = ref.read(databaseProvider);

    final checkedCount = items.where((i) => i.checked).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.name ?? 'Lista'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'low') {
                await db.fillListWithLowStock(listId);
              } else if (value == 'delete') {
                await db.deleteList(listId);
                if (context.mounted) context.pop();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'low',
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 20, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text('Incluir o que está acabando'),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Excluir lista'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: items.isEmpty
          ? _Empty(onAdd: () => _addItem(context, ref))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final it = items[index];
                return _ListItemRow(
                  item: it,
                  onToggle: (v) => db.setChecked(it.id, v),
                  onDelete: () => db.deleteListItem(it.id),
                );
              },
            ),
      floatingActionButton: items.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'addListItem',
              onPressed: () => _addItem(context, ref),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.green,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: FilledButton(
                  onPressed: checkedCount == 0
                      ? null
                      : () => _complete(context, ref, checkedCount),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text(
                    checkedCount == 0
                        ? 'Marque os itens que pegou'
                        : 'Concluir compra ($checkedCount) → despensa',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _complete(
      BuildContext context, WidgetRef ref, int count) async {
    final n = await ref.read(databaseProvider).completeList(listId);
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$n ${n == 1 ? 'item foi' : 'itens foram'} '
              'para a despensa. ✅'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_NewItem>(
      context: context,
      builder: (_) => const _AddItemDialog(),
    );
    if (result == null) return;
    await runSave(context, () async {
      await ref.read(databaseProvider).addListItem(
            ShoppingListItemsCompanion.insert(
              listId: listId,
              name: result.name,
              quantity: Value(result.quantity),
              unit: Value(result.unit),
            ),
          );
    }, successMessage: 'Item adicionado à lista.');
  }
}

class _ListItemRow extends StatelessWidget {
  const _ListItemRow({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });
  final ShoppingListItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => onToggle(!item.checked),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            child: Row(
              children: [
                Checkbox(
                  value: item.checked,
                  activeColor: AppColors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  onChanged: (v) => onToggle(v ?? false),
                ),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: item.checked
                          ? AppColors.textMuted
                          : AppColors.textDark,
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                Text(
                  formatQuantity(item.quantity, item.unit),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.checklist_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          const Text('Lista vazia',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar item'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
          ),
        ],
      ),
    );
  }
}

class _NewItem {
  _NewItem(this.name, this.quantity, this.unit);
  final String name;
  final double quantity;
  final String unit;
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  String _unit = 'un';

  static const _units = ['un', 'kg', 'g', 'L', 'ml', 'caixas', 'pacotes', 'rolos'];

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Produto'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Qtd'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                  items: [
                    for (final u in _units)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (v) => setState(() => _unit = v ?? 'un'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            final qty =
                double.tryParse(_qty.text.replaceAll(',', '.')) ?? 1;
            Navigator.pop(context, _NewItem(name, qty, _unit));
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

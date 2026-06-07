import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/format/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/utils/save_feedback.dart';
import '../../data/providers.dart';

const _palette = [
  '3C6E5C', '4C8C74', '5AA6CC', 'C98A3C',
  '9B6BCC', 'D15A3C', 'CC6BA0', '8A938B',
];

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(categoriesWithCountsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          final c = categories[i];
          final color = colorFromHex(c.category.colorHex);
          return SoftCard(
            onTap: () => _edit(context, ref, c.category),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(categoryIcon(c.category.iconKey), color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.category.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('${c.itemCount} ${c.itemCount == 1 ? 'item' : 'itens'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => _delete(context, ref, c),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, CategoryWithCount c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir categoria?'),
        content: Text(c.itemCount == 0
            ? 'Remover "${c.category.name}"?'
            : 'Os ${c.itemCount} itens de "${c.category.name}" ficarão sem categoria.'),
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
    if (ok == true) {
      await ref.read(databaseProvider).deleteCategory(c.category.id);
    }
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, Category? category) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _CategoryEditor(category: category),
    );
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({this.category});
  final Category? category;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _name;
  late String _icon;
  late String _color;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _icon = widget.category?.iconKey ?? 'basket';
    _color = widget.category?.colorHex ?? _palette.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome à categoria.')),
      );
      return;
    }
    final ok = await runSave(context, () async {
      await ref.read(databaseProvider).saveCategory(
            id: widget.category?.id,
            name: name,
            iconKey: _icon,
            colorHex: _color,
          );
    }, successMessage:
        widget.category == null ? 'Categoria criada.' : 'Categoria atualizada.');
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(_color);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, bottomInset + AppSpacing.xl),
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
                  borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(widget.category == null ? 'Nova categoria' : 'Editar categoria',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(categoryIcon(_icon), color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: widget.category == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Nome', hintText: 'Ex.: Padaria'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Ícone',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in categoryIconKeys)
                GestureDetector(
                  onTap: () => setState(() => _icon = key),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _icon == key
                          ? color.withValues(alpha: 0.15)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: _icon == key ? color : AppColors.border,
                          width: _icon == key ? 2 : 1),
                    ),
                    child: Icon(categoryIcon(key),
                        color: _icon == key ? color : AppColors.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Cor',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final hex in _palette)
                GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorFromHex(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _color == hex
                              ? AppColors.textDark
                              : Colors.transparent,
                          width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Salvar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/save_feedback.dart';
import '../../data/providers.dart';

const _units = ['un', 'kg', 'g', 'L', 'ml', 'caixas', 'pacotes', 'rolos'];

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.item});
  final Item? item;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _min;
  late final TextEditingController _full;
  late String _unit;
  int? _categoryId;
  DateTime? _expiresAt;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?.name ?? '');
    _quantity = TextEditingController(text: i != null ? _fmt(i.quantity) : '');
    _min = TextEditingController(text: i != null ? _fmt(i.minQuantity) : '1');
    _full = TextEditingController(
        text: i?.fullQuantity != null ? _fmt(i!.fullQuantity!) : '');
    _unit = i?.unit ?? 'un';
    _categoryId = i?.categoryId;
    _expiresAt = i?.expiresAt;
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toString().replaceAll('.', ',');

  double? _parse(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _min.dispose();
    _full.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final qty = _parse(_quantity.text) ?? 0;
    final min = _parse(_min.text) ?? 0;
    final full = _parse(_full.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome ao produto.')),
      );
      return;
    }
    final ok = await runSave(context, () async {
      await ref.read(databaseProvider).saveItem(
            id: widget.item?.id,
            name: name,
            categoryId: _categoryId,
            quantity: qty,
            unit: _unit,
            minQuantity: min,
            fullQuantity: full,
            expiresAt: _expiresAt,
          );
    }, successMessage: _isEditing ? 'Item atualizado.' : 'Item criado.');
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar item' : 'Novo item')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _label('Nome'),
          TextField(
            controller: _name,
            decoration: _dec('Ex.: Arroz branco'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.lg),
          _label('Categoria'),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            isExpanded: true,
            decoration: _dec('Sem categoria'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sem categoria')),
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Quantidade'),
                    TextField(
                      controller: _quantity,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('0'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Unidade'),
                    DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: _dec(''),
                      items: [
                        for (final u in _units)
                          DropdownMenuItem(value: u, child: Text(u)),
                      ],
                      onChanged: (v) => setState(() => _unit = v ?? 'un'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Mínimo (alerta)'),
                    TextField(
                      controller: _min,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('1'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Cheio (100%)'),
                    TextField(
                      controller: _full,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('opcional'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _label('Validade'),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _expiresAt == null
                        ? 'Sem validade'
                        : DateFormat('dd/MM/yyyy', 'pt_BR').format(_expiresAt!),
                    style: TextStyle(
                        color: _expiresAt == null
                            ? AppColors.textMuted
                            : AppColors.textDark),
                  ),
                  const Spacer(),
                  if (_expiresAt != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _expiresAt = null),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_isEditing ? 'Salvar alterações' : 'Criar item',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      );
}

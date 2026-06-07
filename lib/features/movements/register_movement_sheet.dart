import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/format/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/save_feedback.dart';
import '../../data/providers.dart';

Future<void> showRegisterMovementSheet(BuildContext context, {int? itemId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _RegisterMovementSheet(initialItemId: itemId),
  );
}

class _RegisterMovementSheet extends ConsumerStatefulWidget {
  const _RegisterMovementSheet({this.initialItemId});
  final int? initialItemId;

  @override
  ConsumerState<_RegisterMovementSheet> createState() =>
      _RegisterMovementSheetState();
}

class _RegisterMovementSheetState
    extends ConsumerState<_RegisterMovementSheet> {
  bool _isInflow = true;
  int? _itemId;
  final _qtyController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _itemId = widget.initialItemId;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _save(List<Item> items) async {
    if (_itemId == null) return;
    final item = items.where((i) => i.id == _itemId).firstOrNull;
    if (item == null) return;
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.'));
    if (qty == null || qty <= 0) return;

    final ok = await runSave(context, () async {
      await ref.read(databaseProvider).registerMovement(
            itemId: item.id,
            type: _isInflow ? 'in' : 'out',
            quantity: qty,
            unit: item.unit,
          );
    }, successMessage: _isInflow
        ? 'Entrada registrada em ${item.name}.'
        : 'Saída registrada em ${item.name}.');
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(allItemsProvider).value ?? const [];
    final selected =
        _itemId == null ? null : items.where((i) => i.id == _itemId).firstOrNull;
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
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Registrar movimentação',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SegmentedToggle(
            isInflow: _isInflow,
            onChanged: (v) => setState(() => _isInflow = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Produto',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty) ...[
            const Text(
              'Cadastre um produto no estoque antes de registrar movimentação.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/item/novo');
                },
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar produto'),
              ),
            ),
          ] else ...[
            DropdownButtonFormField<int>(
              initialValue: _itemId,
              isExpanded: true,
              decoration: _fieldDecoration(hint: 'Selecione um produto'),
              items: [
                for (final i in items)
                  DropdownMenuItem(
                    value: i.id,
                    child: Text(
                        '${i.name}  ·  ${formatQuantity(i.quantity, i.unit)}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _itemId = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Quantidade${selected != null ? ' (${selected.unit})' : ''}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _qtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _fieldDecoration(hint: '0'),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _itemId == null ? null : () => _save(items),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _isInflow ? AppColors.green : AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: Text(
                    _isInflow ? 'Registrar entrada' : 'Registrar saída',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceAlt,
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
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({required this.isInflow, required this.onChanged});
  final bool isInflow;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _seg('Compra (entrada)', true),
          _seg('Retirada (saída)', false),
        ],
      ),
    );
  }

  Widget _seg(String label, bool inflow) {
    final active = isInflow == inflow;
    final color = inflow ? AppColors.green : AppColors.danger;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(inflow),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

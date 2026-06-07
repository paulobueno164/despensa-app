import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ai/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/providers.dart';

class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  bool _loading = false;
  String? _error;
  List<ScannedProduct>? _products;

  Future<void> _pick(ImageSource source) async {
    final ai = ref.read(aiServiceProvider);
    if (!ai.isConfigured) {
      setState(() => _error = _noKeyMessage);
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _products = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final lower = file.path.toLowerCase();
      final mediaType = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      final products = await ai.scanReceipt(bytes, mediaType: mediaType);
      setState(() => _products = products);
    } on AiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não consegui ler a nota. Tente outra foto.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final products = _products ?? const [];
    final db = ref.read(databaseProvider);
    for (final p in products) {
      await db.addStockEntryByName(
        name: p.name,
        quantity: p.quantity,
        unit: p.unit,
        note: 'Nota fiscal',
      );
    }
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${products.length} produtos deram entrada. ✅'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear nota fiscal')),
      body: _loading
          ? const _Loading(text: 'Lendo a nota fiscal...')
          : products != null
              ? _ResultList(
                  products: products,
                  onConfirm: _confirm,
                  onRemove: (i) => setState(() => products.removeAt(i)),
                )
              : _Intro(error: _error, onPick: _pick),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.error, required this.onPick});
  final String? error;
  final void Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SoftCard(
          child: Column(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 48, color: AppColors.warning),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Tire uma foto do cupom do mercado e a IA reconhece os '
                'produtos e quantidades para dar entrada na despensa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          SoftCard(
            color: AppColors.dangerSoft,
            child: Text(error!,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => onPick(ImageSource.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Tirar foto'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => onPick(ImageSource.gallery),
          icon: const Icon(Icons.image_outlined),
          label: const Text('Escolher da galeria'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green,
            side: const BorderSide(color: AppColors.green),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.products,
    required this.onConfirm,
    required this.onRemove,
  });
  final List<ScannedProduct> products;
  final VoidCallback onConfirm;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Text('Nenhum produto reconhecido.',
                      style: TextStyle(color: AppColors.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return SoftCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          Text('${p.quantity.toStringAsFixed(p.quantity % 1 == 0 ? 0 : 2)} ${p.unit}',
                              style: const TextStyle(color: AppColors.textMuted)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => onRemove(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FilledButton(
              onPressed: products.isEmpty ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Dar entrada (${products.length}) na despensa',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.green),
          const SizedBox(height: AppSpacing.lg),
          Text(text, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

const _noKeyMessage =
    'Recurso de IA não configurado. Rode o app com --dart-define=ANTHROPIC_API_KEY=sua_chave para ativar a leitura da nota.';

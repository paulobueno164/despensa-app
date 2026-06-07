import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/providers.dart';
import '../lists/add_to_list_sheet.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  bool _loading = false;
  String? _error;
  List<RecipeSuggestion>? _recipes;

  Future<void> _generate() async {
    final ai = ref.read(aiServiceProvider);
    if (!ai.isConfigured) {
      setState(() => _error = _noKeyMessage);
      return;
    }
    final items = ref.read(allItemsProvider).value ?? const [];
    final names = items
        .where((i) => i.quantity > 0)
        .map((i) => i.name)
        .take(40)
        .toList();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipes = await ai.suggestRecipes(names);
      setState(() => _recipes = recipes);
    } on AiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não consegui gerar receitas agora.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receitas com IA')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (_recipes == null)
                  SoftCard(
                    child: Column(
                      children: [
                        const Icon(Icons.restaurant_menu_rounded,
                            size: 48, color: AppColors.green),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'A IA olha o que você tem na despensa e sugere '
                          'receitas, mostrando o que falta comprar.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppColors.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  SoftCard(
                    color: AppColors.dangerSoft,
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ),
                ],
                if (_recipes != null)
                  for (final r in _recipes!) ...[
                    _RecipeCard(
                      recipe: r,
                      onAddMissing: r.missing.isEmpty
                          ? null
                          : () => showAddToListSheet(context, ref, r.missing),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_recipes == null
                      ? 'Gerar receitas'
                      : 'Gerar de novo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, this.onAddMissing});
  final RecipeSuggestion recipe;
  final VoidCallback? onAddMissing;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recipe.title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(recipe.description,
              style: const TextStyle(
                  color: AppColors.textMuted, height: 1.4, fontSize: 13)),
          if (recipe.uses.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _ChipsRow(label: 'Você tem', items: recipe.uses, color: AppColors.green),
          ],
          if (recipe.missing.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ChipsRow(
                label: 'Falta', items: recipe.missing, color: AppColors.warning),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onAddMissing,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: const Text('Adicionar o que falta à lista'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow(
      {required this.label, required this.items, required this.color});
  final String label;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$label:',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        for (final i in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(i, style: TextStyle(fontSize: 12, color: color)),
          ),
      ],
    );
  }
}

const _noKeyMessage =
    'Recurso de IA não configurado. Rode o app com --dart-define=ANTHROPIC_API_KEY=sua_chave para ativar as receitas.';

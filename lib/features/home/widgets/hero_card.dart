import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Card verde "SUA DESPENSA HOJE" com a contagem de itens em atenção.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.attentionCount,
    required this.totalItems,
  });

  final int attentionCount;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    final isEmpty = totalItems == 0;
    final hasAttention = attentionCount > 0;

    final headline = isEmpty
        ? 'Sua despensa está vazia.'
        : hasAttention
            ? 'Você tem $attentionCount ${attentionCount == 1 ? 'item que precisa' : 'itens que precisam'} de atenção.'
            : 'Tudo certo na sua despensa hoje. 🎉';

    final subtitle = isEmpty
        ? 'Toque em + para registrar sua primeira compra ou adicione produtos no estoque.'
        : 'Toque em + para registrar uma compra ou retirada.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greenHero, AppColors.greenDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x223C6E5C),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUA DESPENSA HOJE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

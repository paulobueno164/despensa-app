import 'package:flutter/material.dart';

/// Paleta extraída das telas de referência da Despensa.
abstract final class AppColors {
  // Verdes (marca / CTA)
  static const Color green = Color(0xFF3C6E5C); // verde primário
  static const Color greenDark = Color(0xFF2E5848); // avatar / hero escuro
  static const Color greenHero = Color(0xFF3B6B5A); // card hero
  static const Color greenSoft = Color(0xFFE4EDE7); // fundo de ícone/realce
  static const Color greenSofter = Color(0xFFEFF4F0);

  // Fundo / superfícies
  static const Color background = Color(0xFFEFF3EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF7F9F5);

  // Texto
  static const Color textDark = Color(0xFF1F2A24);
  static const Color textMuted = Color(0xFF7E8A82);
  static const Color textOnGreen = Color(0xFFFFFFFF);

  // Estados
  static const Color warning = Color(0xFFE5862A); // "está acabando" (laranja)
  static const Color warningSoft = Color(0xFFFBEAD6);
  static const Color danger = Color(0xFFD15A3C); // saída / vencido (vermelho)
  static const Color dangerSoft = Color(0xFFF7E1DA);
  static const Color inflow = Color(0xFF3C6E5C); // entrada (verde)
  static const Color inflowSoft = Color(0xFFE1EEE6);

  // Linhas / sombras
  static const Color border = Color(0xFFE7EBE5);
  static const Color shadow = Color(0x14000000);
}

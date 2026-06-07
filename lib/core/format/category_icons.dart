import 'package:flutter/material.dart';

/// Mapeia a chave de ícone da categoria para um ícone do Material.
IconData categoryIcon(String key) {
  switch (key) {
    case 'basket':
      return Icons.shopping_basket_outlined;
    case 'sparkles':
      return Icons.auto_awesome_outlined;
    case 'drop':
      return Icons.water_drop_outlined;
    case 'cup':
      return Icons.local_cafe_outlined;
    case 'paw':
      return Icons.pets_outlined;
    case 'bread':
      return Icons.bakery_dining_outlined;
    case 'leaf':
      return Icons.eco_outlined;
    case 'snow':
      return Icons.ac_unit_outlined;
    case 'spice':
      return Icons.restaurant_outlined;
    case 'cake':
      return Icons.cake_outlined;
    case 'box':
      return Icons.inventory_2_outlined;
    case 'dots':
    default:
      return Icons.more_horiz;
  }
}

/// Converte "3C6E5C" (hex sem #) em Color.
Color colorFromHex(String hex) {
  final clean = hex.replaceAll('#', '');
  final value = int.tryParse('FF$clean', radix: 16) ?? 0xFF3C6E5C;
  return Color(value);
}

/// Ícones disponíveis para escolher ao criar/editar categoria.
const categoryIconKeys = <String>[
  'basket', 'sparkles', 'drop', 'cup', 'paw', 'bread',
  'leaf', 'snow', 'spice', 'cake', 'box', 'dots',
];

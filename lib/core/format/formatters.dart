import 'package:intl/intl.dart';

final _qtyFormat = NumberFormat('#,##0.##', 'pt_BR');

const _noSpaceUnits = {'g', 'ml'};

/// "500g", "1,2 kg", "2 rolos" — ou o rótulo qualitativo ("Quase vazio").
String formatQuantity(double quantity, String unit, {String? lowLabel}) {
  if (lowLabel != null && lowLabel.isNotEmpty) return lowLabel;
  final number = _qtyFormat.format(quantity);
  if (_noSpaceUnits.contains(unit)) return '$number$unit';
  return '$number $unit';
}

/// "+6 caixas", "− 1 pacote", "+1,2 kg".
String formatSignedQuantity(double quantity, String unit, bool isInflow) {
  final number = _qtyFormat.format(quantity);
  final sign = isInflow ? '+' : '−';
  return '$sign$number $unit';
}

/// "Hoje, 09:24" · "Ontem, 18:10" · "12/05, 14:30".
String formatMovementDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  final diff = today.difference(that).inDays;
  final time = DateFormat('HH:mm', 'pt_BR').format(date);
  if (diff == 0) return 'Hoje, $time';
  if (diff == 1) return 'Ontem, $time';
  return '${DateFormat('dd/MM', 'pt_BR').format(date)}, $time';
}

/// "Bom dia" · "Boa tarde" · "Boa noite".
String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

/// Dias até a validade (negativo = vencido).
int daysUntil(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  return that.difference(today).inDays;
}

/// Texto curto de validade: "Vence hoje", "Vence em 3 dias", "Vencido".
String expiryLabel(DateTime date) {
  final d = daysUntil(date);
  if (d < 0) return 'Vencido';
  if (d == 0) return 'Vence hoje';
  if (d == 1) return 'Vence amanhã';
  return 'Vence em $d dias';
}

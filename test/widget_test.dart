import 'package:flutter_test/flutter_test.dart';

import 'package:pantry/core/format/formatters.dart';

void main() {
  test('formatQuantity formata unidades pt-BR', () {
    expect(formatQuantity(500, 'g'), '500g');
    expect(formatQuantity(1.2, 'kg'), '1,2 kg');
    expect(formatQuantity(2, 'rolos'), '2 rolos');
    expect(formatQuantity(0.1, 'un', lowLabel: 'Quase vazio'), 'Quase vazio');
  });

  test('formatSignedQuantity usa sinal correto', () {
    expect(formatSignedQuantity(6, 'caixas', true), '+6 caixas');
    expect(formatSignedQuantity(1, 'pacote', false), '−1 pacote');
  });
}

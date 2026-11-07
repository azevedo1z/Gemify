import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/names.dart';

void main() {
  group('Names.clean', () {
    test('trims and collapses spaces', () {
      expect(Names.clean('  Compras   no\tmercado  '), 'Compras no mercado');
    });
  });

  group('Names.key', () {
    test('ignores case, accents and extra spaces', () {
      expect(Names.key(' Pão '), Names.key('pao'));
      expect(Names.key('ÁGUA'), 'agua');
      expect(Names.key('Ação  Especial'), 'acao especial');
    });

    test('drops combining accent marks', () {
      expect(Names.key('Pão'), 'pao');
    });

    test('keeps other characters', () {
      expect(Names.key('Café + Pão Doce'), 'cafe + pao doce');
    });
  });
}

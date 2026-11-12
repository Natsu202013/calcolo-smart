import 'package:calcolo_smart/services/calc_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalcEngine.evaluate', () {
    test('operazioni di base', () {
      expect(CalcEngine.evaluate('2+3'), 5);
      expect(CalcEngine.evaluate('10-4'), 6);
      expect(CalcEngine.evaluate('6×7'), 42);
      expect(CalcEngine.evaluate('8÷2'), 4);
    });

    test('precedenza degli operatori', () {
      expect(CalcEngine.evaluate('2+3×4'), 14);
      expect(CalcEngine.evaluate('(2+3)×4'), 20);
      expect(CalcEngine.evaluate('2^3^2'), 512);
    });

    test('numeri negativi e decimali', () {
      expect(CalcEngine.evaluate('-5+3'), -2);
      expect(CalcEngine.evaluate('1.5×2'), 3);
      expect(CalcEngine.evaluate('2×(3+4)'), 14);
    });

    test('percentuale relativa', () {
      expect(CalcEngine.evaluate('200+10%'), 220);
      expect(CalcEngine.evaluate('200-10%'), 180);
      expect(CalcEngine.evaluate('50%'), 0.5);
    });

    test('funzioni trigonometriche in gradi', () {
      expect(CalcEngine.evaluate('sin(30)'), closeTo(0.5, 1e-9));
      expect(CalcEngine.evaluate('cos(60)'), closeTo(0.5, 1e-9));
      expect(CalcEngine.evaluate('tan(45)'), closeTo(1, 1e-9));
    });

    test('funzioni trigonometriche in radianti', () {
      expect(
        CalcEngine.evaluate('sin(π÷2)', mode: AngleMode.radians),
        closeTo(1, 1e-9),
      );
    });

    test('logaritmi e radici', () {
      expect(CalcEngine.evaluate('log(100)'), closeTo(2, 1e-9));
      expect(CalcEngine.evaluate('ln(e)'), closeTo(1, 1e-9));
      expect(CalcEngine.evaluate('√(81)'), closeTo(9, 1e-9));
    });

    test('moltiplicazione implicita', () {
      expect(CalcEngine.evaluate('2(3+4)'), 14);
      expect(CalcEngine.evaluate('3√(16)'), 12);
    });

    test('errori gestiti', () {
      expect(() => CalcEngine.evaluate('5÷0'), throwsA(isA<CalcException>()));
      expect(
        () => CalcEngine.evaluate('log(-1)'),
        throwsA(isA<CalcException>()),
      );
      expect(() => CalcEngine.evaluate('2+'), throwsA(isA<CalcException>()));
      expect(CalcEngine.tryEvaluate('2+'), isNull);
    });
  });

  group('CalcEngine.formatNumber', () {
    test('formattazione italiana', () {
      expect(CalcEngine.formatNumber(1234.5), '1.234,5');
      expect(CalcEngine.formatNumber(1000), '1.000');
      expect(CalcEngine.formatNumber(-0.25), '-0,25');
      expect(CalcEngine.formatNumber(0), '0');
    });
  });
}

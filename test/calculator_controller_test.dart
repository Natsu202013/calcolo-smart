import 'package:calcolo_smart/state/calculator_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<CalculatorController> _controller() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return CalculatorController(prefs);
}

void main() {
  group('CalculatorController input', () {
    test('somma semplice', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['1', '2', '+', '3', '=']) {
        c.input(k);
      }
      expect(c.displayText, '15');
      expect(c.history.length, 1);
      expect(c.history.first.result, '15');
    });

    test('decimali con virgola', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['1', ',', '5', '×', '2', '=']) {
        c.input(k);
      }
      expect(c.displayText, '3');
    });

    test('non accetta due virgole nella stessa cifra', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['1', ',', ',', '5']) {
        c.input(k);
      }
      expect(c.expression, '1.5');
    });

    test('sostituisce un operatore consecutivo', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['5', '+', '×', '2', '=']) {
        c.input(k);
      }
      expect(c.displayText, '10');
    });

    test('backspace rimuove un carattere', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['1', '2', '3', '⌫']) {
        c.input(k);
      }
      expect(c.expression, '12');
    });

    test('backspace rimuove intera funzione', () async {
      final CalculatorController c = await _controller();
      c.input('sin');
      for (final String k in <String>['3', '0']) {
        c.input(k);
      }
      expect(c.expression, 'sin(30');
      c.input('⌫');
      c.input('⌫');
      expect(c.expression, 'sin(');
      c.input('⌫');
      expect(c.expression, '');
    });

    test('AC azzera tutto', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['9', '×', '9', '=']) {
        c.input(k);
      }
      c.input('AC');
      expect(c.expression, '');
      expect(c.displayText, '0');
    });

    test('divisione per zero mostra errore', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['5', '÷', '0', '=']) {
        c.input(k);
      }
      expect(c.errorMessage, isNotNull);
      expect(c.displayText, 'Errore');
    });

    test('percentuale relativa su addizione', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['2', '0', '0', '+', '1', '0', '%', '=']) {
        c.input(k);
      }
      expect(c.displayText, '220');
    });

    test('cambio segno', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['5', '±']) {
        c.input(k);
      }
      expect(c.expression, '-5');
      c.input('±');
      expect(c.expression, '5');
    });

    test('memoria: MS, MC', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['4', '2', 'MS']) {
        c.input(k);
      }
      expect(c.hasMemory, isTrue);
      expect(c.memoryLabel, '42');
      c.input('AC');
      c.input('MR');
      expect(c.expression, '42');
      c.input('MC');
      expect(c.hasMemory, isFalse);
    });

    test('il risultato continua il calcolo', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['2', '+', '3', '=', '+', '5', '=']) {
        c.input(k);
      }
      expect(c.displayText, '10');
    });

    test('parentesi automatiche con moltiplicazione implicita', () async {
      final CalculatorController c = await _controller();
      for (final String k in <String>['2', '(', '3', '+', '4', ')', '=']) {
        c.input(k);
      }
      expect(c.displayText, '14');
    });

    test('salva la cronologia e la ripristina dalle preferenze', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final CalculatorController first = CalculatorController(prefs);
      for (final String k in <String>['6', '×', '7', '=']) {
        first.input(k);
      }
      final CalculatorController second = CalculatorController(prefs);
      expect(second.history.length, 1);
      expect(second.history.first.result, '42');
    });

    test('tema scuro/chiaro persistente', () async {
      final CalculatorController c = await _controller();
      expect(c.isDark, isTrue);
      c.toggleTheme();
      expect(c.isDark, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/calc_engine.dart';
import '../state/calculator_controller.dart';
import '../theme/app_theme.dart';
import 'calc_button.dart';

/// Tastierino standard (4 colonne) e scientifico (5 colonne).
class CalcKeypad extends StatelessWidget {
  const CalcKeypad({super.key});

  @override
  Widget build(BuildContext context) {
    final CalculatorController c = context.watch<CalculatorController>();
    final bool scientific = c.keypadMode == KeypadMode.scientific;

    if (scientific) {
      return _buildScientific(context, c);
    }
    return _buildStandard(context, c);
  }

  Widget _row(List<Widget> children) =>
      Expanded(child: Row(children: children));

  CalcKey _k(String label, String value, CalcKeyKind kind, {int flex = 1}) =>
      CalcKey(label, value, kind, flex: flex);

  Widget _buildStandard(BuildContext context, CalculatorController c) {
    final List<List<CalcKey>> layout = <List<CalcKey>>[
      <CalcKey>[
        _k('AC', 'AC', CalcKeyKind.function),
        const CalcKey(
          '',
          '⌫',
          CalcKeyKind.function,
          icon: Icons.backspace_outlined,
        ),
        _k('%', '%', CalcKeyKind.function),
        _k('÷', '÷', CalcKeyKind.operator),
      ],
      <CalcKey>[
        _k('7', '7', CalcKeyKind.number),
        _k('8', '8', CalcKeyKind.number),
        _k('9', '9', CalcKeyKind.number),
        _k('×', '×', CalcKeyKind.operator),
      ],
      <CalcKey>[
        _k('4', '4', CalcKeyKind.number),
        _k('5', '5', CalcKeyKind.number),
        _k('6', '6', CalcKeyKind.number),
        _k('−', '-', CalcKeyKind.operator),
      ],
      <CalcKey>[
        _k('1', '1', CalcKeyKind.number),
        _k('2', '2', CalcKeyKind.number),
        _k('3', '3', CalcKeyKind.number),
        _k('+', '+', CalcKeyKind.operator),
      ],
      <CalcKey>[
        _k('±', '±', CalcKeyKind.number),
        _k('0', '0', CalcKeyKind.number),
        _k(',', '.', CalcKeyKind.number),
        _k('=', '=', CalcKeyKind.equals),
      ],
    ];

    return Column(
      children: <Widget>[
        for (final List<CalcKey> row in layout)
          _row(<Widget>[
            for (final CalcKey key in row)
              CalcButton(keyData: key, onPressed: c.input),
          ]),
      ],
    );
  }

  Widget _buildScientific(BuildContext context, CalculatorController c) {
    final String degLabel = c.angleMode == AngleMode.degrees ? 'DEG' : 'RAD';
    final List<List<CalcKey>> layout = <List<CalcKey>>[
      <CalcKey>[
        _k(degLabel, 'ANGLE', CalcKeyKind.function),
        _k('sin', 'sin', CalcKeyKind.function),
        _k('cos', 'cos', CalcKeyKind.function),
        _k('tan', 'tan', CalcKeyKind.function),
        _k('(', '(', CalcKeyKind.function),
      ],
      <CalcKey>[
        _k('ln', 'ln', CalcKeyKind.function),
        _k('log', 'log', CalcKeyKind.function),
        _k('√', '√', CalcKeyKind.function),
        _k('x²', 'x²', CalcKeyKind.function),
        _k(')', ')', CalcKeyKind.function),
      ],
      <CalcKey>[
        _k('1/x', '1/x', CalcKeyKind.function),
        _k('π', 'π', CalcKeyKind.function),
        _k('e', 'e', CalcKeyKind.function),
        _k('^', '^', CalcKeyKind.operator),
        _k('÷', '÷', CalcKeyKind.operator),
      ],
      <CalcKey>[
        _k('7', '7', CalcKeyKind.number),
        _k('8', '8', CalcKeyKind.number),
        _k('9', '9', CalcKeyKind.number),
        _k('AC', 'AC', CalcKeyKind.function),
        _k('×', '×', CalcKeyKind.operator),
      ],
      <CalcKey>[
        _k('4', '4', CalcKeyKind.number),
        _k('5', '5', CalcKeyKind.number),
        _k('6', '6', CalcKeyKind.number),
        const CalcKey(
          '',
          '⌫',
          CalcKeyKind.function,
          icon: Icons.backspace_outlined,
        ),
        _k('−', '-', CalcKeyKind.operator),
      ],
      <CalcKey>[
        _k('1', '1', CalcKeyKind.number),
        _k('2', '2', CalcKeyKind.number),
        _k('3', '3', CalcKeyKind.number),
        _k('%', '%', CalcKeyKind.function),
        _k('+', '+', CalcKeyKind.operator),
      ],
      <CalcKey>[
        _k('±', '±', CalcKeyKind.number),
        _k('0', '0', CalcKeyKind.number),
        _k(',', '.', CalcKeyKind.number),
        _k('=', '=', CalcKeyKind.equals, flex: 2),
      ],
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double scale = constraints.maxHeight < 400 ? 0.85 : 1.0;
        return Column(
          children: <Widget>[
            for (final List<CalcKey> row in layout)
              Expanded(
                child: Row(
                  children: <Widget>[
                    for (final CalcKey key in row)
                      CalcButton(
                        keyData: key,
                        onPressed: (String v) {
                          if (v == 'ANGLE') {
                            c.toggleAngleMode();
                            return;
                          }
                          c.input(v);
                        },
                        fontScale: scale,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Riga memoria + indicatori di stato sopra il tastierino.
class MemoryBar extends StatelessWidget {
  const MemoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final CalculatorController c = context.watch<CalculatorController>();
    final CalcPalette p = context.calc;

    final List<CalcKey> keys = <CalcKey>[
      const CalcKey('MC', 'MC', CalcKeyKind.function),
      const CalcKey('MR', 'MR', CalcKeyKind.function),
      const CalcKey('M+', 'M+', CalcKeyKind.function),
      const CalcKey('M−', 'M-', CalcKeyKind.function),
      const CalcKey('MS', 'MS', CalcKeyKind.function),
    ];

    return Row(
      children: <Widget>[
        if (c.hasMemory)
          Padding(
            padding: const EdgeInsets.only(right: 6, left: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'M ${c.memoryLabel}',
                style: const TextStyle(
                  color: AppColors.mint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        for (final CalcKey key in keys)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _MemoryKeyButton(
                label: key.label,
                enabled: key.value == 'MC' || key.value == 'MR' ? true : true,
                onTap: () => c.input(key.value),
                palette: p,
              ),
            ),
          ),
      ],
    );
  }
}

class _MemoryKeyButton extends StatelessWidget {
  const _MemoryKeyButton({
    required this.label,
    required this.onTap,
    required this.palette,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final CalcPalette palette;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: palette.operatorFg.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

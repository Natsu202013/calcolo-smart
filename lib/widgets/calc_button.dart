import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Tipo visivo del tasto.
enum CalcKeyKind { number, function, operator, equals }

/// Descrizione dichiarativa di un tasto del tastierino.
class CalcKey {
  final String label;
  final String value;
  final CalcKeyKind kind;
  final IconData? icon;
  final int flex;
  const CalcKey(this.label, this.value, this.kind, {this.icon, this.flex = 1});
}

/// Singolo tasto con animazione di pressione e feedback aptico.
class CalcButton extends StatefulWidget {
  const CalcButton({
    super.key,
    required this.keyData,
    required this.onPressed,
    this.fontScale = 1,
  });

  final CalcKey keyData;
  final ValueChanged<String> onPressed;
  final double fontScale;

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final CalcPalette p = context.calc;
    final CalcKey k = widget.keyData;

    late final Color bg;
    late final Color fg;
    Gradient? gradient;
    switch (k.kind) {
      case CalcKeyKind.number:
        bg = p.numberBg;
        fg = p.numberFg;
        break;
      case CalcKeyKind.function:
        bg = p.functionBg;
        fg = p.functionFg;
        break;
      case CalcKeyKind.operator:
        bg = p.operatorBg;
        fg = p.operatorFg;
        break;
      case CalcKeyKind.equals:
        bg = AppColors.indigo;
        fg = p.accentFg;
        gradient = const LinearGradient(
          colors: AppColors.equalsGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
    }

    final bool isEquals = k.kind == CalcKeyKind.equals;
    final bool isOperator = k.kind == CalcKeyKind.operator;
    final double baseFont =
        (k.label.length > 2 ? 15.0 : (isOperator ? 30.0 : 23.0)) *
        widget.fontScale;

    return Expanded(
      flex: k.flex,
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) {
            _setPressed(false);
            HapticFeedback.selectionClick();
            widget.onPressed(k.value);
          },
          child: AnimatedScale(
            scale: _pressed ? 0.93 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                color: gradient == null ? bg : null,
                gradient: gradient,
                borderRadius: BorderRadius.circular(isEquals ? 22 : 18),
                border: Border.all(
                  color: isEquals
                      ? Colors.transparent
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.045)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: <BoxShadow>[
                  if (isEquals)
                    BoxShadow(
                      color: AppColors.indigo.withValues(
                        alpha: _pressed ? 0.20 : 0.45,
                      ),
                      blurRadius: _pressed ? 10 : 20,
                      offset: const Offset(0, 6),
                    ),
                  if (!isEquals &&
                      Theme.of(context).brightness == Brightness.light)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: k.icon != null
                  ? Icon(k.icon, size: 24 * widget.fontScale, color: fg)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          k.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: fg,
                            fontSize: baseFont,
                            fontWeight: k.kind == CalcKeyKind.function
                                ? FontWeight.w500
                                : (isOperator
                                      ? FontWeight.w500
                                      : FontWeight.w600),
                            letterSpacing: k.kind == CalcKeyKind.function
                                ? 0.2
                                : 0,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

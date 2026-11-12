import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/calculator_controller.dart';
import '../theme/app_theme.dart';

/// Display della calcolatrice: espressione + risultato live.
class CalcDisplay extends StatelessWidget {
  const CalcDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final CalculatorController c = context.watch<CalculatorController>();
    final CalcPalette p = context.calc;
    final bool hasError = c.errorMessage != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      decoration: BoxDecoration(
        color: p.displayBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.28
                  : 0.06,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // riga espressione con tasto copia
          SizedBox(
            height: 34,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      c.secondaryText.isEmpty ? ' ' : c.secondaryText,
                      style: TextStyle(
                        color: hasError ? AppColors.coral : p.expressionFg,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                if (!c.isEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copia risultato',
                    onPressed: () async {
                      final String text = c.displayText;
                      await ClipboardHelper.copy(text);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Risultato copiato'),
                          duration: Duration(milliseconds: 1200),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: p.expressionFg,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // risultato
          SizedBox(
            height: 66,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  c.displayText,
                  key: ValueKey<String>(c.displayText),
                  maxLines: 1,
                  style: TextStyle(
                    color: hasError ? AppColors.coral : p.resultFg,
                    fontSize: 58,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.4,
                    height: 1.05,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Piccolo wrapper per gli appunti, così il display resta disaccoppiato.
class ClipboardHelper {
  const ClipboardHelper._();
  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}

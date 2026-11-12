import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/calc_engine.dart';
import '../state/calculator_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/calc_display.dart';
import '../widgets/calc_keypad.dart';
import 'history_screen.dart';

/// Schermata principale della calcolatrice.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Supporto tastiera fisica (utile su Web/desktop).
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final CalculatorController c = context.read<CalculatorController>();
    final String? ch = event.character;
    if (ch != null) {
      if (RegExp(r'^[0-9]$').hasMatch(ch)) {
        c.input(ch);
        return KeyEventResult.handled;
      }
      switch (ch) {
        case '.':
        case ',':
          c.input('.');
          return KeyEventResult.handled;
        case '+':
          c.input('+');
          return KeyEventResult.handled;
        case '-':
          c.input('-');
          return KeyEventResult.handled;
        case '*':
          c.input('×');
          return KeyEventResult.handled;
        case '/':
          c.input('÷');
          return KeyEventResult.handled;
        case '%':
          c.input('%');
          return KeyEventResult.handled;
        case '^':
          c.input('^');
          return KeyEventResult.handled;
        case '(':
          c.input('(');
          return KeyEventResult.handled;
        case ')':
          c.input(')');
          return KeyEventResult.handled;
        case '=':
        case '\n':
          c.input('=');
          return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      c.input('⌫');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      c.input('AC');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      c.input('AC');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CalculatorController c = context.watch<CalculatorController>();

    return Scaffold(
      body: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxHeight < 720;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: <Widget>[
                        _Header(compact: compact),
                        SizedBox(height: compact ? 6 : 10),
                        _ModeSwitch(
                          scientific: c.keypadMode == KeypadMode.scientific,
                          controller: c,
                        ),
                        SizedBox(height: compact ? 8 : 12),
                        CalcDisplay(),
                        SizedBox(height: compact ? 8 : 12),
                        MemoryBar(),
                        SizedBox(height: compact ? 6 : 10),
                        Expanded(child: const CalcKeypad()),
                        SizedBox(height: compact ? 0 : 4),
                        _BrandFooter(visible: !compact),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final CalculatorController c = context.watch<CalculatorController>();
    final CalcPalette p = context.calc;
    final bool scientific = c.keypadMode == KeypadMode.scientific;

    return Row(
      children: <Widget>[
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.equalsGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.indigo.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.calculate_rounded,
            color: Colors.white,
            size: compact ? 19 : 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Calcolo Smart',
                style: TextStyle(
                  color: p.resultFg,
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                scientific ? 'Scientifica' : 'Standard',
                style: TextStyle(
                  color: p.expressionFg,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        _HeaderIcon(
          icon: c.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          tooltip: c.isDark ? 'Tema chiaro' : 'Tema scuro',
          onTap: c.toggleTheme,
        ),
        const SizedBox(width: 6),
        _HeaderIcon(
          icon: Icons.history_rounded,
          tooltip: 'Cronologia',
          badge: c.history.isEmpty ? null : '${c.history.length}',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final CalcPalette p = context.calc;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: p.chipBg.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.55
                    : 0.7,
              ),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(icon, size: 19, color: p.functionFg),
                if (badge != null)
                  Positioned(
                    right: 5,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.scientific, required this.controller});

  final bool scientific;
  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    final CalcPalette p = context.calc;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.chipBg.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.65,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          _segment(
            context: context,
            label: 'Standard',
            icon: Icons.grid_view_rounded,
            selected: !scientific,
            onTap: () => controller.setKeypadMode(KeypadMode.standard),
            palette: p,
          ),
          _segment(
            context: context,
            label: 'Scientifica',
            icon: Icons.functions_rounded,
            selected: scientific,
            onTap: () => controller.setKeypadMode(KeypadMode.scientific),
            palette: p,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required CalcPalette palette,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurfaceHigh
                      : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 15,
                color: selected
                    ? palette.operatorFg
                    : palette.functionFg.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? palette.operatorFg
                      : palette.functionFg.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final CalcPalette p = context.calc;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.keyboard_rounded,
            size: 12,
            color: p.expressionFg.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 5),
          Text(
            'Usa anche la tastiera: 0-9  + − × ÷  Invio  Backspace',
            style: TextStyle(
              fontSize: 10,
              color: p.expressionFg.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Utile per mostrare la modalità angolare corrente in altri punti.
String angleLabel(AngleMode mode) => mode == AngleMode.degrees ? 'DEG' : 'RAD';

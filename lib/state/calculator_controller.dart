import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';
import '../services/calc_engine.dart';

/// Tipo di tastierino attivo.
enum KeypadMode { standard, scientific }

/// Stato e logica della calcolatrice.
class CalculatorController extends ChangeNotifier {
  CalculatorController(this._prefs) {
    _restore();
  }

  final SharedPreferences _prefs;

  static const String _kExpression = 'calc.expression';
  static const String _kHistory = 'calc.history';
  static const String _kDark = 'calc.dark';
  static const String _kKeypad = 'calc.keypad';
  static const String _kAngle = 'calc.angle';
  static const String _kMemory = 'calc.memory';

  String _expression = '';
  List<HistoryEntry> _history = <HistoryEntry>[];
  bool _isDark = true;
  KeypadMode _keypadMode = KeypadMode.standard;
  AngleMode _angleMode = AngleMode.degrees;
  double _memory = 0;
  bool _hasMemory = false;

  /// Ultimo risultato calcolato con "=" (null se non ancora calcolato).
  String? _lastResultText;
  String? _errorMessage;
  bool _justEvaluated = false;

  // ---------------------------------------------------------------- getters

  String get expression => _expression;
  String get prettyExpression => CalcEngine.prettify(_expression);
  List<HistoryEntry> get history => List<HistoryEntry>.unmodifiable(_history);
  bool get isDark => _isDark;
  KeypadMode get keypadMode => _keypadMode;
  AngleMode get angleMode => _angleMode;
  bool get hasMemory => _hasMemory;
  double get memory => _memory;
  String get memoryLabel => hasMemory ? CalcEngine.formatNumber(_memory) : '';
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _expression.isEmpty && _lastResultText == null;

  /// Testo grande mostrato nel display.
  String get displayText {
    if (_errorMessage != null) return 'Errore';
    if (_justEvaluated && _lastResultText != null) return _lastResultText!;
    final String trimmed = _stripTrailingOperators(_expression);
    if (trimmed.isEmpty) return '0';
    final double? live = CalcEngine.tryEvaluate(
      _autoClose(trimmed),
      mode: _angleMode,
    );
    if (live != null) return CalcEngine.formatNumber(live);
    final String? trailing = _trailingNumber(_expression);
    return CalcEngine.formatNumber(double.tryParse(trailing ?? '') ?? 0);
  }

  /// Riga piccola in alto: espressione in corso oppure "risultato precedente".
  String get secondaryText {
    if (_errorMessage != null) return _errorMessage!;
    if (_justEvaluated && _lastResultText != null) {
      return _prettyOf(_expression);
    }
    return CalcEngine.prettify(_expression);
  }

  // ------------------------------------------------------------- persistence

  void _restore() {
    _expression = _prefs.getString(_kExpression) ?? '';
    _history = HistoryEntry.decodeList(_prefs.getString(_kHistory));
    _isDark = _prefs.getBool(_kDark) ?? true;
    const String startMode = String.fromEnvironment('startMode');
    final String? savedKeypad = _prefs.getString(_kKeypad);
    _keypadMode =
        (savedKeypad == null && startMode == 'scientific') ||
            savedKeypad == 'scientific'
        ? KeypadMode.scientific
        : KeypadMode.standard;
    _angleMode = (_prefs.getString(_kAngle) == 'rad')
        ? AngleMode.radians
        : AngleMode.degrees;
    _memory = _prefs.getDouble(_kMemory) ?? 0;
    _hasMemory = _memory != 0;
    if (_expression.isNotEmpty) {
      _lastResultText = null;
    }
  }

  void _persistExpression() {
    _prefs.setString(_kExpression, _expression);
  }

  void _persistHistory() {
    _prefs.setString(_kHistory, HistoryEntry.encodeList(_history));
  }

  // ------------------------------------------------------------- ui actions

  void toggleTheme() {
    _isDark = !_isDark;
    _prefs.setBool(_kDark, _isDark);
    notifyListeners();
  }

  void setDark(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    _prefs.setBool(_kDark, value);
    notifyListeners();
  }

  void toggleKeypadMode() {
    _keypadMode = _keypadMode == KeypadMode.standard
        ? KeypadMode.scientific
        : KeypadMode.standard;
    _prefs.setString(
      _kKeypad,
      _keypadMode == KeypadMode.scientific ? 'scientific' : 'standard',
    );
    notifyListeners();
  }

  void setKeypadMode(KeypadMode mode) {
    if (_keypadMode == mode) return;
    _keypadMode = mode;
    _prefs.setString(
      _kKeypad,
      mode == KeypadMode.scientific ? 'scientific' : 'standard',
    );
    notifyListeners();
  }

  void toggleAngleMode() {
    _angleMode = _angleMode == AngleMode.degrees
        ? AngleMode.radians
        : AngleMode.degrees;
    _prefs.setString(_kAngle, _angleMode == AngleMode.radians ? 'rad' : 'deg');
    notifyListeners();
  }

  // ------------------------------------------------------------ input logic

  void input(String key) {
    _errorMessage = null;
    switch (key) {
      case 'AC':
        clearAll();
        return;
      case '⌫':
        backspace();
        return;
      case '=':
        evaluate();
        return;
      case '±':
        toggleSign();
        return;
      case 'M+':
        _memoryOp(add: true);
        return;
      case 'M-':
        _memoryOp(add: false);
        return;
      case 'MR':
        recallMemory();
        return;
      case 'MC':
        clearMemory();
        return;
      case 'MS':
        storeMemory();
        return;
    }
    if (_isFunctionToken(key)) {
      _insertFunction(key);
      return;
    }
    switch (key) {
      case '.':
      case ',':
        _insertDecimal();
        return;
      case '×':
      case '÷':
      case '+':
      case '-':
      case '^':
        _insertOperator(key);
        return;
      case '%':
        _insertPercent();
        return;
      case '(':
      case ')':
        _insertParen(key);
        return;
      case 'π':
      case 'e':
        _insertConstant(key);
        return;
      case '√':
        _insertFunction('√');
        return;
      default:
        if (RegExp(r'^[0-9]$').hasMatch(key)) {
          _insertDigit(key);
        }
    }
  }

  static const Set<String> _functions = <String>{
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'log',
    'ln',
    '√',
    'x²',
    '1/x',
    'x!',
  };

  bool _isFunctionToken(String key) => _functions.contains(key);

  void _afterEvaluateReset() {
    if (_justEvaluated) {
      _justEvaluated = false;
      _expression = '';
      _lastResultText = null;
    }
  }

  void _insertDigit(String digit) {
    _afterEvaluateReset();
    // impedisce zeri iniziali tipo "007"
    final String? last = _trailingNumber(_expression);
    if (last == '0' && digit != '0') {
      _expression = _expression.substring(0, _expression.length - 1) + digit;
    } else if (last == '0' && digit == '0') {
      // ignora
    } else {
      _expression += digit;
    }
    _persistExpression();
    notifyListeners();
  }

  void _insertDecimal() {
    _afterEvaluateReset();
    final String? last = _trailingNumber(_expression);
    if (last == null) {
      _expression += '0.';
    } else if (last.contains('.')) {
      return;
    } else {
      _expression += '.';
    }
    _persistExpression();
    notifyListeners();
  }

  void _insertOperator(String op) {
    _errorMessage = null;
    if (_justEvaluated && _lastResultText != null) {
      // continua il calcolo dal risultato
      final double? value = _lastEvaluatedValue;
      _justEvaluated = false;
      _expression = '${value != null ? CalcEngine.plainNumber(value) : '0'}$op';
      _lastResultText = null;
      _persistExpression();
      notifyListeners();
      return;
    }
    if (_expression.isEmpty) {
      if (op == '-') {
        _expression = '-';
        _persistExpression();
        notifyListeners();
      }
      return;
    }
    final String last = _expression[_expression.length - 1];
    if ('+×÷^'.contains(last)) {
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else if (last == '-') {
      // gestisce "5×-" -> "5×" sostituendo il segno
      if (_expression.length >= 2 &&
          '×÷^'.contains(_expression[_expression.length - 2])) {
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else {
        _expression += op;
      }
    } else if (last == '(') {
      if (op == '-') _expression += op;
    } else if (last == '.') {
      _expression += '0$op';
    } else {
      _expression += op;
    }
    _persistExpression();
    notifyListeners();
  }

  void _insertPercent() {
    if (_expression.isEmpty) return;
    final String last = _expression[_expression.length - 1];
    if (RegExp(r'[0-9)%πe]').hasMatch(last)) {
      _expression += '%';
      _persistExpression();
      notifyListeners();
    }
  }

  void _insertParen(String paren) {
    if (paren == '(') {
      _afterEvaluateReset();
      if (_expression.isEmpty) {
        _expression = '(';
      } else {
        final String last = _expression[_expression.length - 1];
        if (RegExp(r'[0-9)πe%]').hasMatch(last)) {
          // moltiplicazione implicita
          _expression += '×(';
        } else {
          _expression += '(';
        }
      }
      _persistExpression();
      notifyListeners();
      return;
    }
    // ')'
    final int open = '('.allMatches(_expression).length;
    final int close = ')'.allMatches(_expression).length;
    if (open <= close) return;
    if (_expression.isEmpty) return;
    final String last = _expression[_expression.length - 1];
    if (!RegExp(r'[0-9)πe%]').hasMatch(last)) return;
    _expression += ')';
    _persistExpression();
    notifyListeners();
  }

  void _insertConstant(String constant) {
    _afterEvaluateReset();
    if (_expression.isNotEmpty) {
      final String last = _expression[_expression.length - 1];
      if (RegExp(r'[0-9)πe%]').hasMatch(last)) {
        _expression += '×';
      }
    }
    _expression += constant;
    _persistExpression();
    notifyListeners();
  }

  void _insertFunction(String key) {
    _afterEvaluateReset();
    switch (key) {
      case 'x²':
        if (_expression.isEmpty ||
            !RegExp(r'[0-9)πe%]$').hasMatch(_expression)) {
          return;
        }
        _expression += '^2';
        _persistExpression();
        notifyListeners();
        return;
      case '1/x':
        if (_expression.isEmpty) return;
        _expression = '1÷($_expression)';
        _persistExpression();
        notifyListeners();
        return;
      case 'x!':
        final String? lastNum = _trailingNumber(_expression);
        if (lastNum == null) return;
        final double? n = double.tryParse(lastNum);
        if (n == null || n < 0 || n != n.roundToDouble() || n > 170) return;
        int fact = 1;
        for (int i = 2; i <= n.toInt(); i++) {
          fact *= i;
        }
        _expression =
            '${_expression.substring(0, _expression.length - lastNum.length)}$fact';
        _persistExpression();
        notifyListeners();
        return;
      case '√':
        if (_expression.isNotEmpty) {
          final String last = _expression[_expression.length - 1];
          if (RegExp(r'[0-9)πe%]').hasMatch(last)) _expression += '×';
        }
        _expression += '√(';
        _persistExpression();
        notifyListeners();
        return;
      default:
        if (_expression.isNotEmpty) {
          final String last = _expression[_expression.length - 1];
          if (RegExp(r'[0-9)πe%]').hasMatch(last)) _expression += '×';
        }
        _expression += '$key(';
        _persistExpression();
        notifyListeners();
    }
  }

  void toggleSign() {
    if (_justEvaluated && _lastResultText != null) {
      final double? value = _lastEvaluatedValue;
      _justEvaluated = false;
      _expression = value == null ? '-' : CalcEngine.plainNumber(-value);
      _lastResultText = null;
      _persistExpression();
      notifyListeners();
      return;
    }
    if (_expression.isEmpty) {
      _expression = '-';
      _persistExpression();
      notifyListeners();
      return;
    }
    final RegExpMatch? match = RegExp(r'(\d+\.?\d*)$').firstMatch(_expression);
    if (match == null) {
      final String last = _expression[_expression.length - 1];
      if (RegExp(r'[)πe%]').hasMatch(last)) {
        _expression = '-($_expression)';
        _persistExpression();
        notifyListeners();
      }
      return;
    }
    final int start = match.start;
    final bool negativeBefore =
        start > 0 &&
        _expression[start - 1] == '-' &&
        (start == 1 || '+×÷^('.contains(_expression[start - 2]));
    if (negativeBefore) {
      _expression =
          _expression.substring(0, start - 1) + _expression.substring(start);
    } else {
      _expression =
          '${_expression.substring(0, start)}-${_expression.substring(start)}';
    }
    _persistExpression();
    notifyListeners();
  }

  void backspace() {
    _errorMessage = null;
    if (_justEvaluated) {
      _justEvaluated = false;
      _lastResultText = null;
      _expression = '';
      _persistExpression();
      notifyListeners();
      return;
    }
    if (_expression.isEmpty) return;
    // rimuove intere funzioni quando presenti in coda
    for (final String fn in <String>[
      'asin(',
      'acos(',
      'atan(',
      'sin(',
      'cos(',
      'tan(',
      'log(',
      'ln(',
      '√(',
    ]) {
      if (_expression.endsWith(fn)) {
        _expression = _expression.substring(0, _expression.length - fn.length);
        _persistExpression();
        notifyListeners();
        return;
      }
    }
    _expression = _expression.substring(0, _expression.length - 1);
    _persistExpression();
    notifyListeners();
  }

  void clearAll() {
    _expression = '';
    _lastResultText = null;
    _errorMessage = null;
    _justEvaluated = false;
    _persistExpression();
    notifyListeners();
  }

  double? _lastEvaluatedValue;

  // -------------------------------------------------------------- evaluation

  void evaluate() {
    if (_expression.trim().isEmpty) return;
    final String candidate = _autoClose(_stripTrailingOperators(_expression));
    final String? error = CalcEngine.errorOf(candidate, mode: _angleMode);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return;
    }
    final double value = CalcEngine.evaluate(candidate, mode: _angleMode);
    final String resultText = CalcEngine.formatNumber(value);
    final String pretty = CalcEngine.prettify(_expression);
    _lastEvaluatedValue = value;
    _lastResultText = resultText;
    _expression = candidate;
    _justEvaluated = true;
    _errorMessage = null;
    _addHistory(
      HistoryEntry(
        expression: pretty,
        result: resultText,
        createdAt: DateTime.now(),
      ),
    );
    _persistExpression();
    notifyListeners();
  }

  void _addHistory(HistoryEntry entry) {
    if (_history.isNotEmpty &&
        _history.first.expression == entry.expression &&
        _history.first.result == entry.result) {
      return;
    }
    _history = <HistoryEntry>[entry, ..._history].take(200).toList();
    _persistHistory();
  }

  void removeHistoryAt(int index) {
    if (index < 0 || index >= _history.length) return;
    _history = List<HistoryEntry>.from(_history)..removeAt(index);
    _persistHistory();
    notifyListeners();
  }

  void clearHistory() {
    _history = <HistoryEntry>[];
    _persistHistory();
    notifyListeners();
  }

  /// Reinserisce nel display il risultato di una voce di cronologia.
  void useHistoryResult(HistoryEntry entry) {
    final String plain = entry.result
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '');
    final double? value = double.tryParse(plain);
    _justEvaluated = false;
    _errorMessage = null;
    _lastResultText = null;
    if (value == null) {
      _expression = entry.expression.replaceAll(',', '.').replaceAll(' ', '');
    } else {
      _expression = CalcEngine.plainNumber(value);
    }
    _persistExpression();
    notifyListeners();
  }

  /// Copia l'espressione completa (usata dalla schermata cronologia).
  void restoreExpression(String prettyExpression) {
    String raw = prettyExpression
        .replaceAll('×', '×')
        .replaceAll('÷', '÷')
        .replaceAll('−', '-')
        .replaceAll(',', '.')
        .replaceAll(' ', '');
    _expression = raw;
    _justEvaluated = false;
    _lastResultText = null;
    _errorMessage = null;
    _persistExpression();
    notifyListeners();
  }

  // ------------------------------------------------------------------ memory

  void _memoryOp({required bool add}) {
    final double current =
        (CalcEngine.tryEvaluate(
          _autoClose(_stripTrailingOperators(_expression)),
          mode: _angleMode,
        ) ??
        (double.tryParse(
              displayText.replaceAll('.', '').replaceAll(',', '.'),
            ) ??
            0));
    _memory = add ? _memory + current : _memory - current;
    _hasMemory = true;
    _prefs.setDouble(_kMemory, _memory);
    notifyListeners();
  }

  void storeMemory() {
    final double current =
        (CalcEngine.tryEvaluate(
          _autoClose(_stripTrailingOperators(_expression)),
          mode: _angleMode,
        ) ??
        (double.tryParse(
              displayText.replaceAll('.', '').replaceAll(',', '.'),
            ) ??
            0));
    _memory = current;
    _hasMemory = true;
    _prefs.setDouble(_kMemory, _memory);
    notifyListeners();
  }

  void recallMemory() {
    if (!_hasMemory) return;
    _afterEvaluateReset();
    if (_expression.isNotEmpty) {
      final String last = _expression[_expression.length - 1];
      if (RegExp(r'[0-9)πe%]').hasMatch(last)) {
        _expression += '×';
      }
    }
    _expression += CalcEngine.plainNumber(_memory);
    _persistExpression();
    notifyListeners();
  }

  void clearMemory() {
    _memory = 0;
    _hasMemory = false;
    _prefs.remove(_kMemory);
    notifyListeners();
  }

  // ----------------------------------------------------------------- helpers

  String? _trailingNumber(String source) {
    final RegExpMatch? m = RegExp(r'(\d+\.?\d*)$').firstMatch(source);
    return m?.group(1);
  }

  String _stripTrailingOperators(String source) {
    String s = source;
    while (s.isNotEmpty && '+×÷^'.contains(s[s.length - 1])) {
      s = s.substring(0, s.length - 1);
    }
    if (s == '-' || s.endsWith('(')) return s;
    return s;
  }

  String _autoClose(String source) {
    String s = source;
    final int open = '('.allMatches(s).length;
    final int close = ')'.allMatches(s).length;
    if (open > close) s = s + (')' * (open - close));
    return s;
  }

  String _prettyOf(String raw) => CalcEngine.prettify(raw);
}

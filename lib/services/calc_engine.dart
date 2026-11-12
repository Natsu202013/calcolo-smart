import 'dart:math' as math;

/// Modalita' angolare usata dalle funzioni trigonometriche.
enum AngleMode { degrees, radians }

/// Errore di calcolo mostrabile all'utente.
class CalcException implements Exception {
  final String message;
  const CalcException(this.message);
  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

enum _TokenType { number, op, func, lparen, rparen }

class _Token {
  final _TokenType type;
  final String text;
  final double? value;
  const _Token(this.type, this.text, [this.value]);
  @override
  String toString() => '${type.name}($text)';
}

const List<String> _functionNames = <String>[
  'asin',
  'acos',
  'atan',
  'sin',
  'cos',
  'tan',
  'log',
  'ln',
];

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

List<_Token> _tokenize(String source) {
  final List<_Token> tokens = <_Token>[];
  int i = 0;
  while (i < source.length) {
    final String c = source[i];
    if (c == ' ') {
      i++;
      continue;
    }
    if (_isDigit(c) || c == '.') {
      final int start = i;
      int dots = 0;
      while (i < source.length && (_isDigit(source[i]) || source[i] == '.')) {
        if (source[i] == '.') dots++;
        i++;
      }
      final String text = source.substring(start, i);
      if (dots > 1) {
        throw const CalcException('Numero non valido');
      }
      final double? parsed = double.tryParse(
        text.endsWith('.') ? '${text}0' : text,
      );
      if (parsed == null) {
        throw const CalcException('Numero non valido');
      }
      tokens.add(_Token(_TokenType.number, text, parsed));
      continue;
    }
    if (c == ',') {
      // tolleranza: la virgola viene trattata come separatore decimale
      final int start = i;
      i++;
      while (i < source.length && _isDigit(source[i])) {
        i++;
      }
      final String text = source.substring(start, i);
      final double? parsed = double.tryParse(text.replaceFirst(',', '.'));
      if (parsed == null) {
        throw const CalcException('Numero non valido');
      }
      tokens.add(_Token(_TokenType.number, text, parsed));
      continue;
    }
    if (c == 'π') {
      tokens.add(_Token(_TokenType.number, c, math.pi));
      i++;
      continue;
    }
    if (c == 'e') {
      tokens.add(_Token(_TokenType.number, c, math.e));
      i++;
      continue;
    }
    if (c == '(') {
      tokens.add(const _Token(_TokenType.lparen, '('));
      i++;
      continue;
    }
    if (c == ')') {
      tokens.add(const _Token(_TokenType.rparen, ')'));
      i++;
      continue;
    }
    if (c == '√') {
      tokens.add(const _Token(_TokenType.func, '√'));
      i++;
      continue;
    }
    if ('+-×÷*/^%'.contains(c)) {
      final String op = c == '*' ? '×' : (c == '/' ? '÷' : c);
      tokens.add(_Token(_TokenType.op, op));
      i++;
      continue;
    }
    String? matched;
    for (final String fn in _functionNames) {
      if (source.startsWith(fn, i)) {
        matched = fn;
        break;
      }
    }
    if (matched != null) {
      tokens.add(_Token(_TokenType.func, matched));
      i += matched.length;
      continue;
    }
    throw CalcException('Carattere non valido: $c');
  }
  return tokens;
}

// ---------------------------------------------------------------------------
// AST
// ---------------------------------------------------------------------------

abstract class _Node {
  const _Node();
  double eval(AngleMode mode);
}

class _Num extends _Node {
  final double value;
  const _Num(this.value);
  @override
  double eval(AngleMode mode) => value;
}

class _Group extends _Node {
  final _Node child;
  const _Group(this.child);
  @override
  double eval(AngleMode mode) => child.eval(mode);
}

class _Neg extends _Node {
  final _Node child;
  const _Neg(this.child);
  @override
  double eval(AngleMode mode) => -child.eval(mode);
}

class _Percent extends _Node {
  final _Node child;
  const _Percent(this.child);
  @override
  double eval(AngleMode mode) => child.eval(mode) / 100;
}

class _Bin extends _Node {
  final String op;
  final _Node left;
  final _Node right;
  const _Bin(this.op, this.left, this.right);

  @override
  double eval(AngleMode mode) {
    final double l = left.eval(mode);
    final double r = right.eval(mode);
    switch (op) {
      case '+':
        // percentuale relativa: 200 + 10% -> 220
        if (right is _Percent) return l + l * r;
        return l + r;
      case '-':
        if (right is _Percent) return l - l * r;
        return l - r;
      case '×':
        return l * r;
      case '÷':
        if (r == 0) throw const CalcException('Divisione per zero');
        return l / r;
      case '^':
        final double res = math.pow(l, r).toDouble();
        if (res.isNaN) throw const CalcException('Potenza non valida');
        return res;
    }
    throw const CalcException('Operazione non valida');
  }
}

class _Call extends _Node {
  final String name;
  final _Node arg;
  const _Call(this.name, this.arg);

  double _toRad(double v, AngleMode mode) =>
      mode == AngleMode.degrees ? v * math.pi / 180 : v;

  double _fromRad(double v, AngleMode mode) =>
      mode == AngleMode.degrees ? v * 180 / math.pi : v;

  @override
  double eval(AngleMode mode) {
    final double a = arg.eval(mode);
    switch (name) {
      case 'sin':
        return _clean(math.sin(_toRad(a, mode)));
      case 'cos':
        return _clean(math.cos(_toRad(a, mode)));
      case 'tan':
        final double rad = _toRad(a, mode);
        final double c = math.cos(rad);
        if (c.abs() < 1e-12) {
          throw const CalcException('Tangente non definita');
        }
        return _clean(math.sin(rad) / c);
      case 'asin':
        if (a < -1 || a > 1) throw const CalcException('Dominio non valido');
        return _fromRad(math.asin(a), mode);
      case 'acos':
        if (a < -1 || a > 1) throw const CalcException('Dominio non valido');
        return _fromRad(math.acos(a), mode);
      case 'atan':
        return _fromRad(math.atan(a), mode);
      case 'log':
        if (a <= 0) throw const CalcException('Dominio non valido');
        return _clean(math.log(a) / math.ln10);
      case 'ln':
        if (a <= 0) throw const CalcException('Dominio non valido');
        return _clean(math.log(a));
      case '√':
        if (a < 0) throw const CalcException('Radice di un negativo');
        return _clean(math.sqrt(a));
    }
    throw const CalcException('Funzione non valida');
  }

  /// Elimina il rumore numerico tipico delle funzioni trigonometriche
  /// (es. sin(30) -> 0.49999999999999994 diventa 0.5).
  static double _clean(double v) {
    final double rounded = double.parse(v.toStringAsPrecision(12));
    return rounded;
  }
}

// ---------------------------------------------------------------------------
// Parser ricorsivo discendente
// ---------------------------------------------------------------------------

class _Parser {
  final List<_Token> tokens;
  int pos = 0;

  _Parser(this.tokens);

  _Token? get _current => pos < tokens.length ? tokens[pos] : null;

  bool get _atEnd => pos >= tokens.length;

  bool _isOp(String op) {
    final _Token? t = _current;
    return t != null && t.type == _TokenType.op && t.text == op;
  }

  _Node parse() {
    if (tokens.isEmpty) throw const CalcException('Espressione vuota');
    final _Node node = _parseAdditive();
    if (!_atEnd) {
      throw const CalcException('Espressione incompleta');
    }
    return node;
  }

  _Node _parseAdditive() {
    _Node left = _parseMultiplicative();
    while (_isOp('+') || _isOp('-')) {
      final String op = tokens[pos].text;
      pos++;
      final _Node right = _parseMultiplicative();
      left = _Bin(op, left, right);
    }
    return left;
  }

  _Node _parseMultiplicative() {
    _Node left = _parseUnary();
    while (true) {
      if (_isOp('×') || _isOp('÷')) {
        final String op = tokens[pos].text;
        pos++;
        final _Node right = _parseUnary();
        left = _Bin(op, left, right);
        continue;
      }
      // moltiplicazione implicita: 2(3+4), 2π, 3√9 ...
      final _Token? t = _current;
      if (t != null &&
          (t.type == _TokenType.number ||
              t.type == _TokenType.lparen ||
              t.type == _TokenType.func)) {
        final _Node right = _parseUnary();
        left = _Bin('×', left, right);
        continue;
      }
      break;
    }
    return left;
  }

  _Node _parseUnary() {
    if (_isOp('-')) {
      pos++;
      return _Neg(_parseUnary());
    }
    if (_isOp('+')) {
      pos++;
      return _parseUnary();
    }
    return _parsePower();
  }

  _Node _parsePower() {
    final _Node base = _parsePostfix();
    if (_isOp('^')) {
      pos++;
      final _Node exponent = _parseUnary();
      return _Bin('^', base, exponent);
    }
    return base;
  }

  _Node _parsePostfix() {
    _Node node = _parsePrimary();
    while (_isOp('%')) {
      pos++;
      node = _Percent(node);
    }
    return node;
  }

  _Node _parsePrimary() {
    final _Token? t = _current;
    if (t == null) {
      throw const CalcException('Espressione incompleta');
    }
    if (t.type == _TokenType.number) {
      pos++;
      return _Num(t.value ?? 0);
    }
    if (t.type == _TokenType.lparen) {
      pos++;
      final _Node inner = _parseAdditive();
      if (_current?.type != _TokenType.rparen) {
        throw const CalcException('Parentesi non chiuse');
      }
      pos++;
      return _Group(inner);
    }
    if (t.type == _TokenType.func) {
      pos++;
      final _Node arg = _parseFuncArgument();
      return _Call(t.text, arg);
    }
    throw const CalcException('Espressione incompleta');
  }

  _Node _parseFuncArgument() {
    final _Token? t = _current;
    if (t == null) {
      throw const CalcException('Espressione incompleta');
    }
    if (t.type == _TokenType.lparen) {
      pos++;
      final _Node inner = _parseAdditive();
      if (_current?.type != _TokenType.rparen) {
        throw const CalcException('Parentesi non chiuse');
      }
      pos++;
      return _Group(inner);
    }
    return _parseUnary();
  }
}

// ---------------------------------------------------------------------------
// Facade
// ---------------------------------------------------------------------------

class CalcEngine {
  const CalcEngine._();

  /// Valuta un'espressione. Lancia [CalcException] in caso di errore.
  static double evaluate(
    String expression, {
    AngleMode mode = AngleMode.degrees,
  }) {
    final List<_Token> tokens = _tokenize(expression);
    final _Node ast = _Parser(tokens).parse();
    final double result = ast.eval(mode);
    if (result.isNaN) throw const CalcException('Risultato non valido');
    if (result.isInfinite) throw const CalcException('Risultato troppo grande');
    return result;
  }

  /// Valuta senza lanciare eccezioni: restituisce `null` se non e' calcolabile.
  static double? tryEvaluate(
    String expression, {
    AngleMode mode = AngleMode.degrees,
  }) {
    try {
      return evaluate(expression, mode: mode);
    } on CalcException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Valuta e restituisce l'eventuale messaggio di errore.
  static String? errorOf(
    String expression, {
    AngleMode mode = AngleMode.degrees,
  }) {
    try {
      evaluate(expression, mode: mode);
      return null;
    } on CalcException catch (e) {
      return e.message;
    } catch (_) {
      return 'Errore';
    }
  }

  /// Formattazione "italiana": migliaia con '.', decimali con ','.
  static String formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return 'Errore';
    final double abs = value.abs();
    if (abs != 0 && (abs >= 1e13 || abs < 1e-9)) {
      String s = value.toStringAsExponential(8);
      // rimuove gli zeri superflui della mantissa
      final int eIdx = s.indexOf('e');
      if (eIdx > 0) {
        String mantissa = s.substring(0, eIdx);
        final String exp = s.substring(eIdx);
        if (mantissa.contains('.')) {
          mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '');
          mantissa = mantissa.replaceFirst(RegExp(r'\.$'), '');
        }
        s = '$mantissa$exp';
      }
      return s.replaceFirst('.', ',');
    }
    String s = value.toStringAsFixed(10);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    if (s == '-0') s = '0';
    bool negative = s.startsWith('-');
    if (negative) s = s.substring(1);
    final List<String> parts = s.split('.');
    final String intPart = parts[0];
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) sb.write('.');
      sb.write(intPart[i]);
    }
    String out = sb.toString();
    if (parts.length > 1 && parts[1].isNotEmpty) {
      out = '$out,${parts[1]}';
    }
    return negative ? '-$out' : out;
  }

  /// Rappresentazione compatta usata per riusare un risultato in una nuova
  /// espressione (punto decimale, nessun separatore di migliaia).
  static String plainNumber(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    String s = value.toStringAsPrecision(14);
    if (s.contains('e')) {
      return value.toString();
    }
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Versione leggibile dell'espressione per il display.
  static String prettify(String expression) {
    if (expression.isEmpty) return '';
    String s = expression;
    s = s.replaceAll(' ', '');
    s = s.replaceAll('×', ' × ');
    s = s.replaceAll('÷', ' ÷ ');
    s = s.replaceAll('+', ' + ');
    s = s.replaceAll('-', ' − ');
    s = s.replaceAll('^', ' ^ ');
    s = s.replaceAll('.', ',');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

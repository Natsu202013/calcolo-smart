import 'dart:convert';

/// Una voce della cronologia calcoli.
class HistoryEntry {
  final String expression;
  final String result;
  final DateTime createdAt;

  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'expression': expression,
    'result': result,
    'createdAt': createdAt.toIso8601String(),
  };

  static HistoryEntry? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? expression = raw['expression'];
    final Object? result = raw['result'];
    final Object? createdAt = raw['createdAt'];
    if (expression is! String || result is! String) return null;
    return HistoryEntry(
      expression: expression,
      result: result,
      createdAt:
          DateTime.tryParse(createdAt is String ? createdAt : '') ??
          DateTime.now(),
    );
  }

  static List<HistoryEntry> decodeList(String? source) {
    if (source == null || source.isEmpty) return <HistoryEntry>[];
    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! List) return <HistoryEntry>[];
      final List<HistoryEntry> out = <HistoryEntry>[];
      for (final Object? item in decoded) {
        final HistoryEntry? entry = tryFromJson(item);
        if (entry != null) out.add(entry);
      }
      return out;
    } catch (_) {
      return <HistoryEntry>[];
    }
  }

  static String encodeList(List<HistoryEntry> entries) =>
      jsonEncode(entries.map((HistoryEntry e) => e.toJson()).toList());
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/history_entry.dart';
import '../state/calculator_controller.dart';
import '../theme/app_theme.dart';

/// Schermata con la cronologia dei calcoli.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime d) {
    final DateTime now = DateTime.now();
    final DateTime day = DateTime(d.year, d.month, d.day);
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int diff = today.difference(day).inDays;
    final String time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Oggi · $time';
    if (diff == 1) return 'Ieri · $time';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final CalculatorController c = context.watch<CalculatorController>();
    final CalcPalette p = context.calc;
    final List<HistoryEntry> entries = c.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronologia'),
        actions: <Widget>[
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _confirmClear(context, c),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Svuota'),
                style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: entries.isEmpty
                ? _EmptyState(palette: p)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int i) {
                      final HistoryEntry e = entries[i];
                      return _HistoryTile(
                        entry: e,
                        dateLabel: _formatDate(e.createdAt),
                        onUseResult: () {
                          c.useHistoryResult(e);
                          Navigator.of(context).pop();
                        },
                        onRestoreExpression: () {
                          c.restoreExpression(e.expression);
                          Navigator.of(context).pop();
                        },
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: '${e.expression} = ${e.result}',
                            ),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Calcolo copiato'),
                              duration: Duration(milliseconds: 1200),
                            ),
                          );
                        },
                        onDelete: () => c.removeHistoryAt(i),
                        palette: p,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    CalculatorController c,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Svuotare la cronologia?'),
        content: const Text(
          'Tutti i calcoli salvati verranno eliminati definitivamente.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Svuota'),
          ),
        ],
      ),
    );
    if (ok == true) c.clearHistory();
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.dateLabel,
    required this.onUseResult,
    required this.onRestoreExpression,
    required this.onCopy,
    required this.onDelete,
    required this.palette,
  });

  final HistoryEntry entry;
  final String dateLabel;
  final VoidCallback onUseResult;
  final VoidCallback onRestoreExpression;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final CalcPalette palette;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onUseResult,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: palette.surfaceBg.withValues(alpha: dark ? 0.85 : 1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.expression.isEmpty ? '—' : entry.expression,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.expressionFg,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '= ${entry.result}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.resultFg,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: palette.expressionFg.withValues(alpha: 0.7),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Azioni',
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: palette.functionFg,
                ),
                color: palette.surfaceBg,
                onSelected: (String value) {
                  switch (value) {
                    case 'result':
                      onUseResult();
                      break;
                    case 'expression':
                      onRestoreExpression();
                      break;
                    case 'copy':
                      onCopy();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'result',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.input_rounded, size: 18),
                      title: Text('Usa il risultato'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'expression',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_note_rounded, size: 18),
                      title: Text('Modifica espressione'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'copy',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.copy_rounded, size: 18),
                      title: Text('Copia'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.coral,
                      ),
                      title: const Text(
                        'Elimina',
                        style: TextStyle(color: AppColors.coral),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});

  final CalcPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.chipBg.withValues(alpha: 0.6),
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 40,
                color: palette.functionFg,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nessun calcolo salvato',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: palette.resultFg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'I calcoli che esegui con "=" compariranno qui, pronti da riutilizzare.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: palette.expressionFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:offmoney/domain/reference_month.dart';
import 'package:offmoney/domain/reference_window.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/shared/formatters.dart';

Future<ReferenceMonth?> pickReference(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required ReferenceMonth initial,
  required ReferenceWindow window,
}) => showDialog<ReferenceMonth>(
  context: context,
  builder: (_) => _ReferencePicker(
    title: title,
    confirmLabel: confirmLabel,
    initial: initial,
    window: window,
  ),
);

class _ReferencePicker extends StatefulWidget {
  const _ReferencePicker({
    required this.title,
    required this.confirmLabel,
    required this.initial,
    required this.window,
  });

  final String title;
  final String confirmLabel;
  final ReferenceMonth initial;
  final ReferenceWindow window;

  @override
  State<_ReferencePicker> createState() => _ReferencePickerState();
}

class _ReferencePickerState extends State<_ReferencePicker> {
  late int _year = widget.initial.year.clamp(_firstYear, _lastYear);
  late ReferenceMonth? _selected = widget.window.contains(widget.initial)
      ? widget.initial
      : null;

  int get _firstYear => widget.window.first.year;
  int get _lastYear => widget.window.last.year;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selected;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_firstYear != _lastYear)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: l10n.previousYear,
                  onPressed: _year > _firstYear
                      ? () => setState(() => _year--)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_year', style: theme.textTheme.titleLarge),
                IconButton(
                  tooltip: l10n.nextYear,
                  onPressed: _year < _lastYear
                      ? () => setState(() => _year++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reference in _monthsOfYear())
                ChoiceChip(
                  label: Text(formatReference(reference, l10n)),
                  selected: reference == selected,
                  onSelected: (_) => setState(() => _selected = reference),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: selected == null
              ? null
              : () => Navigator.of(context).pop(selected),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  Iterable<ReferenceMonth> _monthsOfYear() sync* {
    for (var month = 1; month <= ReferenceMonth.monthsInYear; month++) {
      final reference = ReferenceMonth(_year, month);
      if (widget.window.contains(reference)) yield reference;
    }
  }
}

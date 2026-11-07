import 'package:flutter/material.dart';
import 'package:gemify/domain/reference_month.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';
import 'package:gemify/presentation/shared/formatters.dart';

Future<ReferenceMonth?> pickReference(
  BuildContext context, {
  required ReferenceMonth initial,
}) => showDialog<ReferenceMonth>(
  context: context,
  builder: (_) => _ReferencePicker(initial: initial),
);

class _ReferencePicker extends StatefulWidget {
  const _ReferencePicker({required this.initial});

  final ReferenceMonth initial;

  @override
  State<_ReferencePicker> createState() => _ReferencePickerState();
}

class _ReferencePickerState extends State<_ReferencePicker> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.referenceDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: l10n.previousYear,
                onPressed: _year > ReferenceMonth.firstYear
                    ? () => setState(() => _year--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_year', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                tooltip: l10n.nextYear,
                onPressed: _year < ReferenceMonth.lastYear
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
              for (var month = 1; month <= ReferenceMonth.monthsInYear; month++)
                ChoiceChip(
                  label: Text(
                    formatReference(ReferenceMonth(_year, month), l10n),
                  ),
                  selected: ReferenceMonth(_year, month) == widget.initial,
                  onSelected: (_) => Navigator.of(
                    context,
                  ).pop(ReferenceMonth(_year, month)),
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
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/shared/action_row.dart';
import 'package:offmoney/presentation/shared/labels.dart';

Future<ExpenseCategory?> pickExpenseCategory(BuildContext context) =>
    showModalBottomSheet<ExpenseCategory>(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final category in ExpenseCategory.values)
                ActionRow(
                  label: newExpenseTitle(category, l10n),
                  onTap: () => Navigator.of(sheetContext).pop(category),
                ),
            ],
          ),
        );
      },
    );

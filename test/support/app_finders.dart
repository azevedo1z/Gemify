import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder field(String label) => find.widgetWithText(TextField, label);

Finder button(String label) => find.widgetWithText(FilledButton, label);

Finder textButton(String label) => find.widgetWithText(TextButton, label);

final Finder dialogField = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);

Finder iconLabeled(String label) => find.byWidgetPredicate(
  (widget) => widget is Icon && widget.semanticLabel == label,
);

String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data ?? '';

bool isEnabled(WidgetTester tester, Finder finder) =>
    tester.widget<ButtonStyleButton>(finder).onPressed != null;

Finder row(String title, String value) => find.descendant(
  of: find.widgetWithText(ListTile, title),
  matching: find.text(value),
);

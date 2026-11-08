import 'package:flutter/widgets.dart';

void popIfCurrent(BuildContext context) {
  if (context.mounted && (ModalRoute.isCurrentOf(context) ?? false)) {
    Navigator.of(context).pop();
  }
}

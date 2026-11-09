import 'package:flutter/material.dart';

void reportFailure(
  ScaffoldMessengerState messenger,
  String message,
  Object error,
  StackTrace stack,
) {
  FlutterError.reportError(
    FlutterErrorDetails(exception: error, stack: stack, library: 'offmoney'),
  );
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

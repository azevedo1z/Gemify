import 'package:flutter/material.dart';
import 'package:offmoney/presentation/theme/theme_preference.dart';

final class FakeThemeModeStore implements ThemeModeStore {
  FakeThemeModeStore(this.stored);

  ThemeMode stored;
  bool failsToWrite = false;

  @override
  ThemeMode read() => stored;

  @override
  Future<void> write(ThemeMode mode) async {
    if (failsToWrite) throw Exception('The theme cannot be saved');
    stored = mode;
  }
}

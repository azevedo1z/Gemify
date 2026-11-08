import 'package:flutter/material.dart';
import 'package:gemify/presentation/theme/theme_preference.dart';

final class FakeThemeModeStore implements ThemeModeStore {
  FakeThemeModeStore(this.stored);

  ThemeMode stored;

  @override
  ThemeMode read() => stored;

  @override
  Future<void> write(ThemeMode mode) async => stored = mode;
}

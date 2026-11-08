import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemeModeStore {
  ThemeMode read();

  Future<void> write(ThemeMode mode);
}

final class PreferencesThemeModeStore implements ThemeModeStore {
  PreferencesThemeModeStore._(this._preferences);

  static const _key = 'themeMode';

  static Future<PreferencesThemeModeStore> open() async =>
      PreferencesThemeModeStore._(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {_key},
          ),
        ),
      );

  final SharedPreferencesWithCache _preferences;

  @override
  ThemeMode read() =>
      ThemeMode.values.asNameMap()[_preferences.getString(_key)] ??
      ThemeMode.system;

  @override
  Future<void> write(ThemeMode mode) => _preferences.setString(_key, mode.name);
}

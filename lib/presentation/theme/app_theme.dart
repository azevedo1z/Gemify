import 'package:flutter/material.dart';
import 'package:gemify/presentation/theme/metrics.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF2A6E45);

  static const _tabular = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const _textTheme = TextTheme(
    displayLarge: _tabular,
    displayMedium: _tabular,
    displaySmall: _tabular,
    headlineLarge: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    headlineMedium: _tabular,
    headlineSmall: _tabular,
    titleLarge: _tabular,
    titleMedium: TextStyle(
      fontWeight: FontWeight.w600,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    titleSmall: _tabular,
    bodyLarge: _tabular,
    bodyMedium: _tabular,
    bodySmall: _tabular,
    labelLarge: _tabular,
    labelMedium: _tabular,
    labelSmall: _tabular,
  );

  static final ThemeData light = _build(Brightness.light);

  static final ThemeData dark = _build(Brightness.dark);

  static ButtonStyle destructive(ColorScheme scheme) => FilledButton.styleFrom(
    backgroundColor: scheme.error,
    foregroundColor: scheme.onError,
  );

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final isLight = brightness == Brightness.light;
    final background = isLight
        ? scheme.surfaceContainer
        : scheme.surfaceContainerLowest;
    final cell = isLight
        ? scheme.surfaceContainerLowest
        : scheme.surfaceContainerHigh;
    final base = ThemeData(
      colorScheme: scheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: background,
      splashFactory: NoSplash.splashFactory,
    );
    final text = base.textTheme;
    const rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Metrics.radius)),
    );
    const buttonSize = Size(64, Metrics.buttonHeight);
    final hairline = BorderSide(
      color: scheme.outlineVariant,
      width: Metrics.hairline,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.primary),
        actionsIconTheme: IconThemeData(color: scheme.primary),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(color: cell, elevation: 0),
      cardTheme: CardThemeData(
        color: cell,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: Metrics.hairline,
        space: Metrics.hairline,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Metrics.inset),
        minTileHeight: Metrics.rowHeight,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: text.bodyLarge?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Metrics.inset,
          vertical: 12,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: rounded,
          textStyle: text.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          shape: rounded,
          textStyle: text.titleMedium,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cell,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(Metrics.dialogRadius),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cell,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: rounded.copyWith(side: hairline),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: rounded,
      ),
    );
  }
}

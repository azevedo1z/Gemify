import 'package:flutter/material.dart';
import 'package:offmoney/presentation/theme/metrics.dart';

abstract final class AppTheme {
  static const displayFontFamily = 'BarlowCondensed';

  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);
  static const _brandRed = Color(0xFFD52822);
  static const _brandRedOnDark = Color(0xFFFF4F47);
  static const _outlineWidth = 1.5;

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _brandRed,
    onPrimary: _white,
    primaryContainer: Color(0xFFFFDAD6),
    onPrimaryContainer: Color(0xFF410002),
    secondary: _black,
    onSecondary: _white,
    secondaryContainer: _black,
    onSecondaryContainer: _white,
    tertiary: _black,
    onTertiary: _white,
    error: Color(0xFF9E1A15),
    onError: _white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: _white,
    onSurface: _black,
    onSurfaceVariant: Color(0xFF5C5C5C),
    surfaceDim: Color(0xFFDEDEDE),
    surfaceBright: _white,
    surfaceContainerLowest: _white,
    surfaceContainerLow: Color(0xFFF7F7F7),
    surfaceContainer: Color(0xFFF2F2F2),
    surfaceContainerHigh: Color(0xFFEBEBEB),
    surfaceContainerHighest: Color(0xFFE3E3E3),
    outline: Color(0xFF767676),
    outlineVariant: Color(0xFFD9D9D9),
    shadow: _black,
    scrim: _black,
    inverseSurface: _black,
    onInverseSurface: _white,
    inversePrimary: _brandRedOnDark,
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _brandRedOnDark,
    onPrimary: _black,
    primaryContainer: Color(0xFF5C0F0C),
    onPrimaryContainer: Color(0xFFFFDAD6),
    secondary: _white,
    onSecondary: _black,
    secondaryContainer: _white,
    onSecondaryContainer: _black,
    tertiary: _white,
    onTertiary: _black,
    error: Color(0xFFFFB0A8),
    onError: _black,
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: _black,
    onSurface: _white,
    onSurfaceVariant: Color(0xFFA6A6A6),
    surfaceDim: _black,
    surfaceBright: Color(0xFF2E2E2E),
    surfaceContainerLowest: _black,
    surfaceContainerLow: Color(0xFF0E0E0E),
    surfaceContainer: Color(0xFF141414),
    surfaceContainerHigh: Color(0xFF1C1C1C),
    surfaceContainerHighest: Color(0xFF262626),
    outline: Color(0xFF8C8C8C),
    outlineVariant: Color(0xFF333333),
    shadow: _black,
    scrim: _black,
    inverseSurface: _white,
    onInverseSurface: _black,
    inversePrimary: _brandRed,
    surfaceTint: Colors.transparent,
  );

  static const _tabular = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const _display = TextStyle(
    fontFamily: displayFontFamily,
    fontWeight: FontWeight.w900,
  );

  static const _textTheme = TextTheme(
    displayLarge: _tabular,
    displayMedium: _tabular,
    displaySmall: _tabular,
    headlineLarge: TextStyle(
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

  static final ThemeData light = _build(_lightScheme);

  static final ThemeData dark = _build(_darkScheme);

  static ButtonStyle destructive(ColorScheme scheme) => FilledButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: scheme.error,
    side: BorderSide(color: scheme.error, width: _outlineWidth),
  );

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
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
    final readable = base.textTheme;
    final text = readable.copyWith(
      headlineLarge: readable.headlineLarge?.merge(_display),
      headlineSmall: readable.headlineSmall?.merge(_display),
    );
    const rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Metrics.radius)),
    );
    const buttonSize = Size(64, Metrics.buttonHeight);
    final hairline = BorderSide(
      color: scheme.outlineVariant,
      width: Metrics.hairline,
    );
    return base.copyWith(
      textTheme: text,
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
        titleTextStyle: readable.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Metrics.dialogRadius)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        modalBackgroundColor: cell,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Metrics.dialogRadius),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: cell,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        headerHeadlineStyle: readable.headlineLarge,
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

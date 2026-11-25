import 'package:flutter/material.dart';

import '../models/canteen_order.dart';
import 'tokens.dart';

const _fontFamily = 'PlusJakartaSans';
const _seed = Color(0xFFF7941D); // orange

/// Foreground/background colors for each order status, light and dark.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.pending,
    required this.ready,
    required this.pickedUp,
    required this.cancelled,
  });

  final (Color fg, Color bg) pending;
  final (Color fg, Color bg) ready;
  final (Color fg, Color bg) pickedUp;
  final (Color fg, Color bg) cancelled;

  static const light = StatusColors(
    pending: (Color(0xFF8A4B00), Color(0xFFFFE8C7)),
    ready: (Color(0xFF1E6B2F), Color(0xFFD5F2D8)),
    pickedUp: (Color(0xFF4A5560), Color(0xFFE6EBEF)),
    cancelled: (Color(0xFFA1261B), Color(0xFFFDE1DD)),
  );

  static const dark = StatusColors(
    pending: (Color(0xFFFFCB80), Color(0xFF4A2E05)),
    ready: (Color(0xFF9BE3A5), Color(0xFF123D1C)),
    pickedUp: (Color(0xFFC3CDD6), Color(0xFF2B3338)),
    cancelled: (Color(0xFFFFB3A8), Color(0xFF5A1610)),
  );

  (Color fg, Color bg) of(OrderStatus s) => switch (s) {
    OrderStatus.pending => pending,
    OrderStatus.ready => ready,
    OrderStatus.pickedUp => pickedUp,
    OrderStatus.cancelled => cancelled,
  };

  static StatusColors read(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    (Color, Color) l((Color, Color) a, (Color, Color) b) =>
        (Color.lerp(a.$1, b.$1, t)!, Color.lerp(a.$2, b.$2, t)!);
    return StatusColors(
      pending: l(pending, other.pending),
      ready: l(ready, other.ready),
      pickedUp: l(pickedUp, other.pickedUp),
      cancelled: l(cancelled, other.cancelled),
    );
  }
}

abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: _seed,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      primary: _seed,
      onPrimary: Colors.white,
      surface: const Color(0xFFF6F6F6),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFFF7EE),
      surfaceContainer: const Color(0xFFFFF1E0),
    ),
    StatusColors.light,
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ),
    StatusColors.dark,
  );

  static ThemeData _build(ColorScheme colors, StatusColors status) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: _fontFamily,
    );
    final text = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.smAll);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: colors.surface,
      extensions: [status],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: pillShape,
          textStyle: text.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: pillShape,
        side: BorderSide(color: colors.outlineVariant),
        selectedColor: colors.primary,
        secondarySelectedColor: colors.primary,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: colors.onPrimary),
        checkmarkColor: colors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLowest),
        side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
        shape: WidgetStatePropertyAll(buttonShape),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.primaryContainer,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
    );
  }
}

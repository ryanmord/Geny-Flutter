import 'package:flutter/material.dart';

// MARK: - Design Tokens

class AppColors {
  AppColors._();

  // Primary accent - a warm indigo
  static const accent = Colors.indigo;
  static final accentSubtle = Colors.indigo.withValues(alpha: 0.08);
  static final accentMedium = Colors.indigo.withValues(alpha: 0.15);

  // Semantic colors
  static final userBubble = Colors.indigo.withValues(alpha: 0.06);
  static const assistantAvatar = Colors.indigo;
  static const userAvatar = Colors.grey;

  // Surface colors - light mode
  static const _surfaceRaisedLight = Color(0xFFFFFFFF);
  static const _surfaceOverlayLight = Color(0xFFF5F5F5);
  static final _surfaceSubtleLight = Colors.black.withValues(alpha: 0.03);

  // Surface colors - dark mode
  static const _surfaceRaisedDark = Color(0xFF2C2C2E);
  static const _surfaceOverlayDark = Color(0xFF1C1C1E);
  static final _surfaceSubtleDark = Colors.white.withValues(alpha: 0.03);

  // Code surface (always dark)
  static const surfaceCode = Color(0xFF212328);
  static const codeText = Color(0xFFE8EBED);

  // Border colors
  static final border = Colors.white.withValues(alpha: 0.08);
  static final borderSubtle = Colors.white.withValues(alpha: 0.05);
  static final borderLight = Colors.black.withValues(alpha: 0.08);
  static final borderSubtleLight = Colors.black.withValues(alpha: 0.05);

  // Status
  static const success = Colors.green;
  static const error = Colors.red;
  static const warning = Colors.orange;

  // Dynamic surface colors
  static Color surfaceRaised(Brightness brightness) =>
      brightness == Brightness.dark ? _surfaceRaisedDark : _surfaceRaisedLight;

  static Color surfaceOverlay(Brightness brightness) =>
      brightness == Brightness.dark ? _surfaceOverlayDark : _surfaceOverlayLight;

  static Color surfaceSubtle(Brightness brightness) =>
      brightness == Brightness.dark ? _surfaceSubtleDark : _surfaceSubtleLight;

  static Color borderForBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? border : borderLight;

  static Color borderSubtleForBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? borderSubtle : borderSubtleLight;

  // Tool colors
  static Color toolColor(String name) {
    return switch (name) {
      'Read' => Colors.blue,
      'Write' || 'Edit' => Colors.orange,
      'Bash' => Colors.green,
      'Glob' || 'Grep' => Colors.purple,
      'WebSearch' || 'WebFetch' => Colors.cyan,
      'Agent' => Colors.pink,
      _ => Colors.grey,
    };
  }
}

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double full = 999;
}

class AppTypography {
  AppTypography._();

  static const sidebarHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const conversationTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const conversationDate = TextStyle(
    fontSize: 11,
  );

  static const inputText = TextStyle(
    fontSize: 14,
  );

  static const codeFont = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New'],
  );

  static const toolName = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const toolDetail = TextStyle(
    fontSize: 11,
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New'],
  );
}

class AppIcons {
  AppIcons._();

  static const sparkles = Icons.auto_awesome;
  static const person = Icons.person;
  static const settings = Icons.settings;
  static const send = Icons.arrow_upward;
  static const add = Icons.add;
  static const close = Icons.close;
  static const chevronDown = Icons.keyboard_arrow_down;
  static const chevronUp = Icons.keyboard_arrow_up;
  static const chevronRight = Icons.chevron_right;
  static const copy = Icons.copy;
  static const check = Icons.check;
  static const error = Icons.error;
  static const warning = Icons.warning;
  static const search = Icons.search;
  static const globe = Icons.language;
  static const terminal = Icons.terminal;
  static const document = Icons.description;
  static const documentAdd = Icons.note_add;
  static const edit = Icons.edit;
  static const folder = Icons.folder;
  static const people = Icons.people;
  static const tool = Icons.build;

  /// Map SF Symbol-style names to Flutter icons
  static IconData toolIcon(String toolName) {
    return switch (toolName) {
      'Read' => document,
      'Write' => documentAdd,
      'Edit' => edit,
      'Bash' => terminal,
      'Glob' => search,
      'Grep' => Icons.manage_search,
      'WebSearch' => globe,
      'WebFetch' => Icons.download,
      'Agent' => people,
      _ => tool,
    };
  }
}

// MARK: - ThemeData Extension

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: brightness,
    fontFamily: '.AppleSystemUIFont',
    scaffoldBackgroundColor: isDark
        ? AppColors.surfaceOverlay(brightness)
        : colorScheme.surface,
    dividerTheme: DividerThemeData(
      color: AppColors.borderForBrightness(brightness),
      thickness: 0.5,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceRaised(brightness),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: AppColors.borderForBrightness(brightness),
          width: 0.5,
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFFF857A6);
  static const accent = Color(0xFF00D2FF);

  // Status
  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFFAB40);
  static const danger = Color(0xFFFF5252);

  // Difficulty
  static const easy = Color(0xFF00E676);
  static const medium = Color(0xFFFFAB40);
  static const hard = Color(0xFFFF5252);

  // Dark Theme
  static const darkBg = Color(0xFF0F0F1A);
  static const darkCard = Color(0xFF1E1E35);
  static const darkBorder = Color(0x266C63FF);
  static const darkText = Color(0xFFE0E0F0);
  static const darkTextSecondary = Color(0xFF9090B0);
  static const darkSurface = Color(0xFF16162A);

  // Light Theme
  static const lightBg = Color(0xFFF0F0F8);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1A1A2E);
  static const lightTextSecondary = Color(0xFF6E6E8A);

  // Platforms
  static const leetcode = Color(0xFFFFA116);
  static const gfg = Color(0xFF2F8D46);
  static const codeforces = Color(0xFF1F8ACB);
  static const codechef = Color(0xFF8B4513);
  static const github = Color(0xFF333333);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF9C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [accent, Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF1E1E35), Color(0xFF0F0F1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const dangerGradient = LinearGradient(
    colors: [danger, Color(0xFFFF8A80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get dark => _buildTheme(isDark: true);
  static ThemeData get light => _buildTheme(isDark: false);

  static ThemeData _buildTheme({required bool isDark}) {
    final colors = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.darkCard,
            onSurface: AppColors.darkText,
            error: AppColors.danger,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.lightCard,
            onSurface: AppColors.lightText,
            error: AppColors.danger,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      textTheme: GoogleFonts.interTextTheme(
        isDark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme,
      ).apply(
        bodyColor: isDark ? AppColors.darkText : AppColors.lightText,
        displayColor: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightText,
        contentTextStyle: GoogleFonts.inter(color: isDark ? AppColors.darkText : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Design tokens ────────────────────────────────────────────────
class AppRadius {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const round = 100.0;
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppShadow {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Palette officielle TradeTrackz inspirée du logo (candlestick violet sur fond sombre)
class AppColors {
  // Fond sombre (niveau de gris profond comme l'icône carrée de l'app)
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF161A23);
  static const Color surfaceLight = Color(0xFF1E2430);
  static const Color border = Color(0xFF2A3142);

  // Couleurs de marque
  static const Color primaryPurple = Color(0xFFA26BFA);
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryOrange = Color(0xFFFF7A1A);

  // Violet dégradé présent dans le logo
  static const Color purpleLight = Color(0xFFB98CFF);
  static const Color purpleDark = Color(0xFF7A48E0);

  // Trading
  static const Color up = Color(0xFF22C55E);
  static const Color down = Color(0xFFEF4444);
  static const Color upLight = Color(0xFF22C55E);
  static const Color downLight = Color(0xFFEF4444);

  // Typographie
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
}

// Thème sombre TradeTrackz centralisé
class AppTheme {
  static ThemeData get darkTheme => dark();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurple,
        secondary: AppColors.primaryBlue,
        surface: AppColors.surface,
        error: AppColors.down,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.bold,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.bold,
          color: AppColors.textPrimary, letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),
    );
  }

  // Transition slide de gauche à droite (utilisée pour naviguer entre pages)
  static PageRouteBuilder slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }

  // Transition fade (alternative)
  static PageRouteBuilder fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Gradients de marque (pour cartes, boutons)
  static const depositGradient = LinearGradient(
    colors: [AppColors.primaryBlue, Color(0xFF2563EB)],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const withdrawGradient = LinearGradient(
    colors: [AppColors.primaryPurple, AppColors.purpleDark],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const tradeGradient = LinearGradient(
    colors: [AppColors.primaryOrange, Color(0xFFEA580C)],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const heroGradient = LinearGradient(
    colors: [AppColors.primaryPurple, AppColors.primaryBlue],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

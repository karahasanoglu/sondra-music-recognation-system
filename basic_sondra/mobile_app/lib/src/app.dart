import 'package:flutter/material.dart';

import 'features/home/song_finder_page.dart';
import 'features/splash/splash_screen_page.dart';

class SondraApp extends StatelessWidget {
  const SondraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C5CFF),
        brightness: Brightness.dark,
      ),
    );
    final colorScheme = baseTheme.colorScheme.copyWith(
      primary: const Color(0xFF22C55E),
      secondary: const Color(0xFF4ADE80),
      tertiary: const Color(0xFF16A34A),
      surface: const Color(0xFF101425),
      surfaceContainerHighest: const Color(0xFF1B2238),
      onPrimary: const Color(0xFF0A0E1B),
      onSecondary: const Color(0xFF0A0E1B),
      onSurface: const Color(0xFFF3F5FF),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sondra Mobile',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF090B14),
        colorScheme: colorScheme,
        splashFactory: InkRipple.splashFactory,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xCC0E1322),
          selectedItemColor: colorScheme.secondary,
          unselectedItemColor: const Color(0xFF7D88A8),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: baseTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: baseTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            textStyle: baseTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ),
        chipTheme: baseTheme.chipTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          side: BorderSide.none,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF12182A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          margin: EdgeInsets.zero,
        ),
        textTheme: baseTheme.textTheme.copyWith(
          displayMedium: baseTheme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFF6F7FF),
            letterSpacing: -1.8,
          ),
          displaySmall: baseTheme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFF6F7FF),
            letterSpacing: -1.2,
          ),
          headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFF6F7FF),
            letterSpacing: -1.1,
          ),
          headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF6F7FF),
          ),
          titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF6F7FF),
            letterSpacing: -0.3,
          ),
          titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFFE6EAFF),
          ),
          bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFC8D0F0),
            height: 1.45,
          ),
          bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFA6B0D0),
            height: 1.42,
          ),
          bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF8C97B8),
            height: 1.4,
          ),
          labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF0F3FF),
          ),
        ),
      ),
      home: const SplashScreenPage(),
    );
  }
}

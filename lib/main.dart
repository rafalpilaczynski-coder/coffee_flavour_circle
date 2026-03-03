// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants.dart'; // Upewnij się, że ten import istnieje, by czytać kolory
// Importy ekranów - edytor podświetli je na czerwono, dopóki nie utworzymy tych plików
import 'screens/welcome_screen.dart';
import 'screens/brew_parameters_screen.dart';
import 'screens/fragrance_notes_screen.dart';
import 'screens/flavor_wheel_screen.dart';
import 'screens/final_evaluation_screen.dart';
import 'screens/history_screen.dart';
import 'screens/personal_settings_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CoffeeApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/brew', builder: (context, state) => const BrewParametersScreen()),
    GoRoute(path: '/fragrance', builder: (context, state) => const FragranceNotesScreen()),
    GoRoute(path: '/wheel', builder: (context, state) => const FlavorWheelScreen()),
    GoRoute(path: '/evaluation', builder: (context, state) => const FinalEvaluationScreen()),
    GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
    GoRoute(path: '/settings',builder: (context, state) => const PersonalSettingsScreen()),
  ],
);

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Flavour Circle',
      theme: ThemeData(
        // 1. Ustawienie jasności i głównych kolorów tła
        brightness: Brightness.dark,
        scaffoldBackgroundColor: appBackground,
        primaryColor: appPrimary,
        colorScheme: const ColorScheme.dark(
          primary: appPrimary,
          surface: appSurface,
        ),
        
        // 2. Nadpisanie globalnej typografii na Google Fonts (Montserrat)
        textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyMedium: const TextStyle(color: appTextPrimary),
          bodyLarge: const TextStyle(color: appTextPrimary),
          titleMedium: const TextStyle(color: appTextSecondary),
        ),

        // 3. Globalny styl dla Paska Górnego (AppBar)
        appBarTheme: AppBarTheme(
          backgroundColor: appBackground,
          elevation: 0, // Płaski, nowoczesny wygląd
          centerTitle: true,
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 20, 
            fontWeight: FontWeight.w600, 
            color: appTextPrimary,
            letterSpacing: 1.2, // Delikatne rozstrzelenie liter dla elegancji
          ),
          iconTheme: const IconThemeData(color: appPrimary), // Miedziane ikony nawigacji
        ),

        // 4. Globalny styl dla Kart (Surface)
        cardTheme: CardThemeData(
          color: appSurface,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),

        // 5. Globalny styl dla Sliderów (Suwaków)
        sliderTheme: SliderThemeData(
          activeTrackColor: appPrimary,
          inactiveTrackColor: appPrimary.withValues(alpha: 0.2),
          thumbColor: appPrimary,
          overlayColor: appPrimary.withValues(alpha: 0.1),
        ),
      ),
      routerConfig: _router,
    );
  }
}
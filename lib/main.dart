// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Importy ekranów - edytor podświetli je na czerwono, dopóki nie utworzymy tych plików
import 'screens/welcome_screen.dart';
import 'screens/brew_parameters_screen.dart';
import 'screens/fragrance_notes_screen.dart';
import 'screens/flavor_wheel_screen.dart';
import 'screens/final_evaluation_screen.dart';
import 'screens/history_screen.dart';

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
  ],
);

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Flavour Circle',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      routerConfig: _router,
    );
  }
}
// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           Image.asset(
            'assets/images/logo.png',
            height: 160, // Rozmiar optymalny dla proporcji ekranu
            fit: BoxFit.contain,
            ),
            const SizedBox(height: 50),
            
            // 1. Akcja główna (Primary)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: PrimaryActionButton(
                label: 'START TASTING',
                onPressed: () => context.push('/brew'),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // 2. Akcja poboczna (Secondary)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('VIEW HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => context.push('/history'),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 3. Ustawienia personalne (Tertiary)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.tune, size: 20), // Ikona suwaków (inżynieryjny vibe)
                  label: const Text('PERSONAL SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC27D56), // Nasz miedziany akcent
                  ),
                  onPressed: () => context.push('/settings'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
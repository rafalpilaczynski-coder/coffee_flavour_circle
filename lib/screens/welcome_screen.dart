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
            const Text(
              'COFFEE FLAVOUR CIRCLE', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 50),
            
            // Użycie naszego nowego, uniwersalnego komponentu!
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: PrimaryActionButton(
                label: 'START TASTING',
                onPressed: () => context.go('/brew'),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Przycisk historii
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('VIEW HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => context.go('/history'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
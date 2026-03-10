// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/primary_button.dart';
import '../providers/tasting_provider.dart'; // Wymagane dla dostępu do zasobów

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // INŻYNIERIA WYDAJNOŚCI: Inicjalizacja zasobów w tle.
    // addPostFrameCallback odpala się dokładnie po narysowaniu pierwszej klatki tego ekranu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wymusza pobranie i zdekodowanie obrazów do RAM (ui.Image)
      ref.read(iconCacheProvider);
      // Wymusza parsowanie plików JSON z assets
      ref.read(grindersDatabaseProvider);
      ref.read(staticRoasteriesProvider); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 160, 
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
                  icon: const Icon(Icons.tune, size: 20),
                  label: const Text('PERSONAL SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC27D56), 
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
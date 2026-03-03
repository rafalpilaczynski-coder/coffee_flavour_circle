import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_preferences_provider.dart';

class PersonalSettingsScreen extends ConsumerStatefulWidget {
  const PersonalSettingsScreen({super.key});

  // Kompletna lista metod referencyjnych
  static const List<String> allMethods = [
    'V60', 'AeroPress', 'Chemex', 'French Press', 'Moka Pot', 
    'Espresso', 'Clever Dripper', 'Kalita Wave', 'Phin', 'Cold Brew'
  ];

  @override
  ConsumerState<PersonalSettingsScreen> createState() => _PersonalSettingsScreenState();
}

class _PersonalSettingsScreenState extends ConsumerState<PersonalSettingsScreen> {
  // Lokalne bufory stanu
  late List<String> _localActiveMethods;
  late List<TextEditingController> _grinderControllers;

  @override
  void initState() {
    super.initState();
    // 1. Inicjalizacja bufora na podstawie aktualnego stanu z pamięci
    final prefs = ref.read(userPreferencesProvider);
    _localActiveMethods = List<String>.from(prefs.activeMethods);
    
    _grinderControllers = List.generate(
      3,
      (index) => TextEditingController(text: prefs.grinders[index]),
    );
  }

  @override
  void dispose() {
    // Sprzątanie kontrolerów po zamknięciu ekranu
    for (var controller in _grinderControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleMethod(String method, bool isActive) {
    setState(() {
      if (isActive && !_localActiveMethods.contains(method)) {
        _localActiveMethods.add(method);
      } else if (!isActive) {
        _localActiveMethods.remove(method);
      }
    });
  }

void _saveChanges() {
    final notifier = ref.read(userPreferencesProvider.notifier);
    
    // Zbieramy wpisane nazwy młynków, usuwając białe znaki na brzegach
    final newGrinders = _grinderControllers.map((c) => c.text.trim()).toList();
    
    // Wypychamy bufor do głównego Providera i SharedPreferences
    notifier.saveAllPreferences(_localActiveMethods, newGrinders);
    
    // Wymuszenie powrotu do Menu Głównego (Ekranu Powitalnego)
    context.push('/'); 
  }

  void _discardChanges() {
    // Wymuszenie powrotu do Menu Głównego bez zapisu stanu
    context.push('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0), // Zapas na przyciski na dole
        children: [
          const Text('YOUR GRINDERS (MAX 3)', style: TextStyle(color: Color(0xFFC27D56), fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                controller: _grinderControllers[index],
                decoration: InputDecoration(
                  labelText: 'Grinder ${index + 1}',
                  hintText: 'e.g. Comandante C40',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          const Text('ACTIVE BREWING METHODS', style: TextStyle(color: Color(0xFFC27D56), fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: PersonalSettingsScreen.allMethods.map((method) {
                // Czytamy z LOKALNEGO bufora, a nie z Providera
                final isActive = _localActiveMethods.contains(method);
                return CheckboxListTile(
                  title: Text(method, style: const TextStyle(color: Colors.white)),
                  value: isActive,
                  activeColor: const Color(0xFFC27D56),
                  onChanged: (bool? value) {
                    if (value != null) {
                      _toggleMethod(method, value);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      // Kontener z przyciskami przypięty do dołu ekranu
// Kontener z przyciskami przypięty do dołu ekranu
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).scaffoldBackgroundColor, // Zlewa się z tłem
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _discardChanges,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12), // Zmniejszony padding pionowy dla 2 linii tekstu
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'DISCARD\n& GO TO MAIN MENU', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11, height: 1.2),
                ),
              ),
            ),
            const SizedBox(width: 12), // Delikatnie węższy odstęp
            Expanded(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC27D56), // Nasz akcent
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'SAVE\n& GO TO MAIN MENU', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, height: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),    );
  }
}
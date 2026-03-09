// lib/screens/personal_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_preferences_provider.dart';
import '../providers/tasting_provider.dart';

class PersonalSettingsScreen extends ConsumerStatefulWidget {
  const PersonalSettingsScreen({super.key});

  static const List<String> allMethods = [
    'V60', 'AeroPress', 'Chemex', 'French Press', 'Moka Pot', 
    'Espresso', 'Clever Dripper', 'Kalita Wave', 'Phin', 'Cold Brew'
  ];

  @override
  ConsumerState<PersonalSettingsScreen> createState() => _PersonalSettingsScreenState();
}

class _PersonalSettingsScreenState extends ConsumerState<PersonalSettingsScreen> {
  late List<String> _localActiveMethods;
  late List<String> _localGrinders;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(userPreferencesProvider);
    _localActiveMethods = List<String>.from(prefs.activeMethods);
    
    _localGrinders = List<String>.from(prefs.grinders);
    while (_localGrinders.length < 3) {
      _localGrinders.add('');
    }
    if (_localGrinders.length > 3) {
      _localGrinders = _localGrinders.sublist(0, 3);
    }
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
    final newGrinders = _localGrinders.map((g) => g.trim()).toList();
    notifier.saveAllPreferences(_localActiveMethods, newGrinders);
    context.push('/'); 
  }

  void _discardChanges() {
    context.push('/');
  }

  @override
  Widget build(BuildContext context) {
    final grindersAsync = ref.watch(grindersDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0), 
        children: [
          const Text('YOUR GRINDERS (MAX 3)', style: TextStyle(color: Color(0xFFC27D56), fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: grindersAsync.when(
                loading: () => const LinearProgressIndicator(color: Color(0xFFC27D56)),
                error: (err, stack) => Text('Error loading DB: $err', style: const TextStyle(color: Colors.red)),
                data: (grinders) {
                  return Autocomplete<GrinderModel>(
                    initialValue: TextEditingValue(text: _localGrinders[index]),
                    displayStringForOption: (option) => option.fullName,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return grinders;
                      return grinders.where((g) => g.fullName.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (selection) {
                      _localGrinders[index] = selection.fullName;
                      FocusManager.instance.primaryFocus?.unfocus(); 
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Grinder ${index + 1}',
                          hintText: 'Click to select or type...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC27D56), width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E1A18),
                          prefixIcon: const Icon(Icons.hardware, color: Colors.grey, size: 20),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFFC27D56), size: 28),
                        ),
                        onChanged: (val) {
                          _localGrinders[index] = val;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      final optionsList = options.toList();
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF231F1C),
                          // INŻYNIERIA BŁĘDU: Sztywne ograniczenie wysokości zapobiega awarii renderowania
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 32, 
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: optionsList.length,
                                itemBuilder: (context, i) {
                                  final option = optionsList[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(option.fullName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    subtitle: Text('${option.stepMicron} µm / click', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  );
                }
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
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).scaffoldBackgroundColor, 
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _discardChanges,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12), 
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'DISCARD\n& GO TO MAIN MENU', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11, height: 1.2),
                ),
              ),
            ),
            const SizedBox(width: 12), 
            Expanded(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC27D56), 
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
      ),
    );
  }
}
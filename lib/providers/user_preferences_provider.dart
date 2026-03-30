// lib/providers/user_preferences_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart'; // INŻYNIERIA BAZY: Wymagany import stałych

class UserPreferencesState {
  final List<String> activeMethods;
  final List<String> grinders; // Max 3
  final Map<String, String> lastGrinderSettings;

  const UserPreferencesState({
    this.activeMethods = const [], // Domyślnie puste, ładujemy dynamicznie z constants
    this.grinders = const ['', '', ''],
    this.lastGrinderSettings = const {},
  });

  UserPreferencesState copyWith({
    List<String>? activeMethods,
    List<String>? grinders,
    Map<String, String>? lastGrinderSettings,
  }) {
    return UserPreferencesState(
      activeMethods: activeMethods ?? this.activeMethods,
      grinders: grinders ?? this.grinders,
      lastGrinderSettings: lastGrinderSettings ?? this.lastGrinderSettings,
    );
  }
}

class UserPreferencesNotifier extends Notifier<UserPreferencesState> {
  static const _methodsKey = 'user_active_methods';
  static const _grindersKey = 'user_grinders';
  static const _lastSettingsKey = 'user_last_grinder_settings';
  static const _knownMethodsKey = 'user_known_methods'; // NOWY KLUCZ: Śledzenie wersji bazy

  @override
  UserPreferencesState build() {
    _loadPreferences();
    return const UserPreferencesState();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Odczyt zapisanych metod aktywowania. Fallback korzysta z constants.dart
    List<String> activeMethods = prefs.getStringList(_methodsKey) ?? List.from(brewMethods);
    
    // 2. INŻYNIERIA MIGRACJI: Porównanie bazy
    // Pobieramy listę metod, które aplikacja już "widziała" w przeszłości
    final knownMethods = prefs.getStringList(_knownMethodsKey) ?? List.from(brewMethods);
    
    // Filtrujemy nowości (np. dodane "V30" w nowej wersji kodu)
    final newMethodsFromUpdate = brewMethods.where((m) => !knownMethods.contains(m)).toList();
    
    if (newMethodsFromUpdate.isNotEmpty) {
      // Automatycznie włączamy nowe metody dla użytkownika
      activeMethods.addAll(newMethodsFromUpdate);
      
      // Aktualizujemy pamięć podręczną, aby nie powtarzać tego przy kolejnym uruchomieniu
      await prefs.setStringList(_knownMethodsKey, brewMethods);
      await prefs.setStringList(_methodsKey, activeMethods);
    }

    final grinders = prefs.getStringList(_grindersKey) ?? ['', '', ''];
    while (grinders.length < 3) { grinders.add(''); }

    final settingsString = prefs.getString(_lastSettingsKey);
    Map<String, String> lastSettings = {};
    if (settingsString != null) {
      lastSettings = Map<String, String>.from(jsonDecode(settingsString));
    }

    state = state.copyWith(
      activeMethods: activeMethods,
      grinders: grinders.take(3).toList(),
      lastGrinderSettings: lastSettings,
    );
  }

  Future<void> toggleMethod(String method, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    final newMethods = List<String>.from(state.activeMethods);
    
    if (isActive && !newMethods.contains(method)) newMethods.add(method);
    if (!isActive) newMethods.remove(method);

    await prefs.setStringList(_methodsKey, newMethods);
    state = state.copyWith(activeMethods: newMethods);
  }

  Future<void> updateGrinder(int index, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final newGrinders = List<String>.from(state.grinders);
    newGrinders[index] = name.trim();

    await prefs.setStringList(_grindersKey, newGrinders);
    state = state.copyWith(grinders: newGrinders);
  }

  Future<void> saveLastGrinderSetting(String grinderName, String setting) async {
    if (grinderName.isEmpty || setting.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final newSettings = Map<String, String>.from(state.lastGrinderSettings);
    newSettings[grinderName] = setting;

    await prefs.setString(_lastSettingsKey, jsonEncode(newSettings));
    state = state.copyWith(lastGrinderSettings: newSettings);
  }

  Future<void> saveAllPreferences(List<String> methods, List<String> grinders) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setStringList(_methodsKey, methods);
    await prefs.setStringList(_grindersKey, grinders);
    
    state = state.copyWith(activeMethods: methods, grinders: grinders);
  }
}

final userPreferencesProvider = NotifierProvider<UserPreferencesNotifier, UserPreferencesState>(() {
  return UserPreferencesNotifier();
});
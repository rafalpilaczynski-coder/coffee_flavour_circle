// lib/providers/tasting_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tasting_state.dart';

class TastingNotifier extends Notifier<TastingState> {
  @override
  TastingState build() => const TastingState();

  void updateMethod(String val) => state = state.copyWith(method: val);
  void updateCoffeeName(String val) => state = state.copyWith(coffeeName: val);
  void updateTemperature(double val) => state = state.copyWith(temperature: val);
  void updateDose(double val) => state = state.copyWith(dose: val);
  void updateWaterVolume(double val) => state = state.copyWith(waterVolume: val);
  void updateGrinderName(String val) => state = state.copyWith(grinderName: val);
  void updateGrinderSetting(String val) => state = state.copyWith(grinderSetting: val);
  void updateSweetness(double val) => state = state.copyWith(sweetness: val);
  void updateAcidity(double val) => state = state.copyWith(acidity: val);
  void updateBitterness(double val) => state = state.copyWith(bitterness: val);
  void updateEnjoyment(double val) => state = state.copyWith(enjoyment: val);

  void toggleDryNote(String note) {
    final newNotes = Set<String>.from(state.dryNotes);
    newNotes.contains(note) ? newNotes.remove(note) : newNotes.add(note);
    state = state.copyWith(dryNotes: newNotes);
  }

  void toggleWetNote(String note) {
    final newNotes = Set<String>.from(state.wetNotes);
    newNotes.contains(note) ? newNotes.remove(note) : newNotes.add(note);
    state = state.copyWith(wetNotes: newNotes);
  }

  void setPrimaryFlavor(String main, String sub) {
    state = state.copyWith(primaryFlavorMain: main, primaryFlavorSub: sub);
  }

  void setSecondaryFlavor(String main, String sub) {
    state = state.copyWith(secondaryFlavorMain: main, secondaryFlavorSub: sub);
  }

  void clearAllFlavors() {
    state = TastingState(
      method: state.method, coffeeName: state.coffeeName, temperature: state.temperature, 
      dose: state.dose, waterVolume: state.waterVolume, grinderName: state.grinderName, 
      grinderSetting: state.grinderSetting, dryNotes: state.dryNotes, wetNotes: state.wetNotes,
      sweetness: state.sweetness, acidity: state.acidity, bitterness: state.bitterness, enjoyment: state.enjoyment,
    );
  }

  Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedSessions = prefs.getStringList('coffee_sessions_history') ?? [];
    savedSessions.add(jsonEncode(state.toMap()));
    await prefs.setStringList('coffee_sessions_history', savedSessions);
    state = const TastingState(); 
  }
}

final tastingProvider = NotifierProvider<TastingNotifier, TastingState>(() => TastingNotifier());

// System odczytu historii
final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> savedSessions = prefs.getStringList('coffee_sessions_history') ?? [];
  return savedSessions.reversed.map((sessionJson) {
    return jsonDecode(sessionJson) as Map<String, dynamic>;
  }).toList();
});
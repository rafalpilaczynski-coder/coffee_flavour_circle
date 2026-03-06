import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../core/constants.dart'; // Upewnij się, że ten import istnieje na górze
// ==========================================
// 1. MODEL DANYCH (STAN)
// ==========================================
class TastingState {
  // Parametry wejściowe
  final String method;
  final String coffeeName;
  final String beanDetails; // NOWE POLE: Ziarno i pochodzenie

  final double dose;
  final double waterVolume;
  final double temperature;
  final String grinderName;
  final String grinderSetting;

  // Profil smakowy (SCA Flavor Wheel)
  final String primaryFlavorMain;
  final String primaryFlavorSub;
  final String secondaryFlavorMain;
  final String secondaryFlavorSub;

  // Ewaluacja końcowa (Skale absolutne: smak 0-10, ocena ogólna 1-5)
  final double sweetness;
  final double acidity;
  final double bitterness;
  final double enjoyment;

  // Notatki i defekty
  final String notes;
  final List<String> defects;
  final List<String> dryNotes;
  final List<String> wetNotes;

  const TastingState({
    this.method = '',
    this.coffeeName = '',
    this.beanDetails = '', // 2. Konstruktor

    this.dose = 15.0,
    this.waterVolume = 250.0,
    this.temperature = 96.0,
    this.grinderName = '',
    this.grinderSetting = '',
    
    this.primaryFlavorMain = '',
    this.primaryFlavorSub = '',
    this.secondaryFlavorMain = '',
    this.secondaryFlavorSub = '',
    
    this.sweetness = 5.0,
    this.acidity = 5.0,
    this.bitterness = 5.0,
    this.enjoyment = 3.0,

    this.notes = '',
    this.defects = const [],
    this.dryNotes = const [],
    this.wetNotes = const [],
  });

  TastingState copyWith({
    String? method,
    String? coffeeName,
    String? beanDetails, // 3. Parametr copyWith

    double? dose,
    double? waterVolume,
    double? temperature,
    String? grinderName,
    String? grinderSetting,
    
    String? primaryFlavorMain,
    String? primaryFlavorSub,
    String? secondaryFlavorMain,
    String? secondaryFlavorSub,
    
    double? sweetness,
    double? acidity,
    double? bitterness,
    double? enjoyment,

    String? notes,
    List<String>? defects,
    List<String>? dryNotes, 
    List<String>? wetNotes,
  }) {
    return TastingState(
      method: method ?? this.method,
      coffeeName: coffeeName ?? this.coffeeName,
      beanDetails: beanDetails ?? this.beanDetails, // Przypisanie w copyWith

      dose: dose ?? this.dose,
      waterVolume: waterVolume ?? this.waterVolume,
      temperature: temperature ?? this.temperature,
      grinderName: grinderName ?? this.grinderName,
      grinderSetting: grinderSetting ?? this.grinderSetting,
      
      primaryFlavorMain: primaryFlavorMain ?? this.primaryFlavorMain,
      primaryFlavorSub: primaryFlavorSub ?? this.primaryFlavorSub,
      secondaryFlavorMain: secondaryFlavorMain ?? this.secondaryFlavorMain,
      secondaryFlavorSub: secondaryFlavorSub ?? this.secondaryFlavorSub,
      
      sweetness: sweetness ?? this.sweetness,
      acidity: acidity ?? this.acidity,
      bitterness: bitterness ?? this.bitterness,
      enjoyment: enjoyment ?? this.enjoyment,

      notes: notes ?? this.notes,
      defects: defects ?? this.defects,
      dryNotes: dryNotes ?? this.dryNotes,
      wetNotes: wetNotes ?? this.wetNotes,
    );
  }

  // Serializacja danych do zapisu
  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'coffeeName': coffeeName,
      'beanDetails': beanDetails, // 4. Serializacja do bazy (Historii)
      'dose': dose,
      'waterVolume': waterVolume,
      'temperature': temperature,
      'grinderName': grinderName,
      'grinderSetting': grinderSetting,
      'primaryFlavorMain': primaryFlavorMain,
      'primaryFlavorSub': primaryFlavorSub,
      'secondaryFlavorMain': secondaryFlavorMain,
      'secondaryFlavorSub': secondaryFlavorSub,
      'sweetness': sweetness,
      'acidity': acidity,
      'bitterness': bitterness,
      'enjoyment': enjoyment,
      'notes': notes,
      'defects': defects,
      'dryNotes': dryNotes,
      'wetNotes': wetNotes,
    };
  }
}

// ==========================================
// 2. LOGIKA BIZNESOWA (NOTIFIER)
// ==========================================
class TastingNotifier extends Notifier<TastingState> {
  @override
  TastingState build() {
    return const TastingState();
  }

  // Akcje modyfikacji parametrów fizycznych
  void updateMethod(String value) => state = state.copyWith(method: value);
  void updateCoffeeName(String value) => state = state.copyWith(coffeeName: value);
  void updateBeanDetails(String value) => state = state.copyWith(beanDetails: value);
  void updateDose(double value) => state = state.copyWith(dose: value);
  void updateWaterVolume(double value) => state = state.copyWith(waterVolume: value);
  void updateTemperature(double value) => state = state.copyWith(temperature: value);
  void updateGrinderName(String value) => state = state.copyWith(grinderName: value);
  void updateGrinderSetting(String value) => state = state.copyWith(grinderSetting: value);

void toggleDryNote(String note) {
    final currentNotes = List<String>.from(state.dryNotes);
    if (currentNotes.contains(note)) {
      currentNotes.remove(note);
    } else {
      currentNotes.add(note);
    }
    state = state.copyWith(dryNotes: currentNotes);
  }

  void toggleWetNote(String note) {
    final currentNotes = List<String>.from(state.wetNotes);
    if (currentNotes.contains(note)) {
      currentNotes.remove(note);
    } else {
      currentNotes.add(note);
    }
    state = state.copyWith(wetNotes: currentNotes);
  }
  void updateDryNotes(List<String> value) => state = state.copyWith(dryNotes: value);
  void updateWetNotes(List<String> value) => state = state.copyWith(wetNotes: value);
  // Akcje modyfikacji Koła Smaków
  void setPrimaryFlavor(String main, String sub) {
    state = state.copyWith(primaryFlavorMain: main, primaryFlavorSub: sub);
  }
  
  void setSecondaryFlavor(String main, String sub) {
    state = state.copyWith(secondaryFlavorMain: main, secondaryFlavorSub: sub);
  }
  
  void updatePrimaryFlavor(String main, String sub) {
    state = state.copyWith(primaryFlavorMain: main, primaryFlavorSub: sub);
  }

  void clearAllFlavors() {
    state = state.copyWith(
      primaryFlavorMain: '',
      primaryFlavorSub: '',
      secondaryFlavorMain: '',
      secondaryFlavorSub: '',
    );
  }

  // Akcje ewaluacji końcowej
  void updateSweetness(double value) => state = state.copyWith(sweetness: value);
  void updateAcidity(double value) => state = state.copyWith(acidity: value);
  void updateBitterness(double value) => state = state.copyWith(bitterness: value);
  void updateEnjoyment(double value) => state = state.copyWith(enjoyment: value);
  
  void updateNotes(String value) => state = state.copyWith(notes: value);

  void toggleDefect(String defect) {
    final currentDefects = List<String>.from(state.defects);
    if (currentDefects.contains(defect)) {
      currentDefects.remove(defect);
    } else {
      currentDefects.add(defect);
    }
    state = state.copyWith(defects: currentDefects);
  }

  // Zapis sesji do lokalnej bazy (SharedPreferences)
  Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('tasting_history');
    
    List<dynamic> history = [];
    if (historyJson != null) {
      history = jsonDecode(historyJson);
    }

    final sessionData = state.toMap();
    sessionData['timestamp'] = DateTime.now().toIso8601String();
    
    // Nowa sesja ląduje zawsze na górze listy
    history.insert(0, sessionData);
    
    await prefs.setString('tasting_history', jsonEncode(history));

    // Resetowanie stanu gotowe na kolejne parzenie
    state = const TastingState();
  }
}

// Główny provider obsługujący formularz parzenia
final tastingProvider = NotifierProvider<TastingNotifier, TastingState>(() {
  return TastingNotifier();
});

// ==========================================
// 3. DOSTAWCY DANYCH HISTORYCZNYCH I FILTRÓW
// ==========================================

// Dostarcza całą zapisaną historię
final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final historyJson = prefs.getString('tasting_history');
  
  if (historyJson == null) return [];
  
  final List<dynamic> decoded = jsonDecode(historyJson);
  return decoded.cast<Map<String, dynamic>>();
});

// Zwraca unikalną listę wszystkich wpisanych wcześniej kaw (do autouzupełniania)
final staticRoasteriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final String response = await rootBundle.loadString('assets/roasteries.json');
    final List<dynamic> data = jsonDecode(response);
    
    // Zakładając, że Twój JSON to lista obiektów np. [{"name": "La Cabra"}, ...]
    // Jeśli JSON to po prostu płaska lista ["La Cabra", "Onyx"], zmień to na: return List<String>.from(data);
    return data.map((e) => e['name'].toString()).toList();
  } catch (e) {
    debugPrint('Błąd ładowania bazy palarni: $e');
    return [];
  }
});

// 2. Fuzja: Baza JSON + Własna historia użytkownika
final combinedRoasteriesProvider = FutureProvider<List<String>>((ref) async {
  final history = ref.watch(historyProvider).value ?? [];
  final staticList = ref.watch(staticRoasteriesProvider).value ?? [];

  // Użycie Set gwarantuje absolutną deduplikację przy minimalnym koszcie obliczeniowym
  final Set<String> unique = {...staticList};
  
  for (var s in history) {
    if (s['coffeeName']?.toString().isNotEmpty ?? false) {
      unique.add(s['coffeeName']);
    }
  }
  
  return unique.toList()..sort(); // Zwracamy posortowaną alfabetycznie listę
});

// Zwraca unikalną listę historycznie użytych młynków (do autouzupełniania)
final uniqueGrindersProvider = Provider<List<String>>((ref) {
  final history = ref.watch(historyProvider).value ?? [];
  final Set<String> uniqueGrinders = {};
  
  for (var session in history) {
    final grinderName = session['grinderName']?.toString().trim();
    if (grinderName != null && grinderName.isNotEmpty) {
      uniqueGrinders.add(grinderName);
    }
  }
  
  final sortedList = uniqueGrinders.toList()..sort();
  return sortedList;
});

final iconCacheProvider = FutureProvider<Map<String, ui.Image>>((ref) async {
  final Map<String, ui.Image> cache = {};

  for (var cat in mainFlavorCategories) {
    if (cat.containsKey('icon')) {
      final path = cat['icon'] as String;
      try {
        final ByteData data = await rootBundle.load(path);
        // Wymuszamy rozmiar 18x18 bezpośrednio w fazie dekodowania
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(), 
          targetWidth: 18, 
          targetHeight: 18
        );
        final ui.FrameInfo fi = await codec.getNextFrame();
        cache[path] = fi.image;
        debugPrint('Cache hit: $path');
      } catch (e) {
        debugPrint('Cache miss/error for $path: $e');
      }
    }
  }
  return cache;
});
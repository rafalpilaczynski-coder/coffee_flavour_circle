import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../core/constants.dart';
import 'package:file_picker/file_picker.dart'; // Opcja B
import 'package:share_plus/share_plus.dart';   // Opcja B

// ==========================================
// 1. MODEL DANYCH (STAN)
// ==========================================
class TastingState {
  final String method;
  final String coffeeName;
  final String beanDetails;

  final double dose;
  final double waterVolume;
  final double temperature;
  final String grinderName;
  final String grinderSetting;

  final String primaryFlavorMain;
  final String primaryFlavorSub;
  final String secondaryFlavorMain;
  final String secondaryFlavorSub;

  final double sweetness;
  final double acidity;
  final double bitterness;
  final double enjoyment;

  final String notes;
  final List<String> defects;
  final List<String> dryNotes;
  final List<String> wetNotes;

  const TastingState({
    this.method = '',
    this.coffeeName = '',
    this.beanDetails = '',

    this.dose = 15.0,
    this.waterVolume = 250.0,
    this.temperature = 96.0,
    this.grinderName = '',
    this.grinderSetting = '',
    
    this.primaryFlavorMain = '',
    this.primaryFlavorSub = '',
    this.secondaryFlavorMain = '',
    this.secondaryFlavorSub = '',
    
    this.sweetness = 3.0, // Zmieniono domyślne na środek skali 1-5
    this.acidity = 3.0,
    this.bitterness = 3.0,
    this.enjoyment = 3.0,

    this.notes = '',
    this.defects = const [],
    this.dryNotes = const [],
    this.wetNotes = const [],
  });

  TastingState copyWith({
    String? method,
    String? coffeeName,
    String? beanDetails,

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
      beanDetails: beanDetails ?? this.beanDetails,

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

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'coffeeName': coffeeName,
      'beanDetails': beanDetails,
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

  Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('tasting_history');
    
    List<dynamic> history = [];
    if (historyJson != null) {
      history = jsonDecode(historyJson);
    }

    final sessionData = state.toMap();
    sessionData['timestamp'] = DateTime.now().toIso8601String();
    
    history.insert(0, sessionData);
    
    await prefs.setString('tasting_history', jsonEncode(history));
    state = const TastingState();
  }
}

final tastingProvider = NotifierProvider<TastingNotifier, TastingState>(() {
  return TastingNotifier();
});

// ==========================================
// 3. DOSTAWCY DANYCH HISTORYCZNYCH I FILTRÓW
// ==========================================

// ZMODYFIKOWANY DOSTAWCA: Implementacja Safe Parsing i migracji w locie
final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('tasting_history');
    
    if (historyJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(historyJson);
    
    // Normalizacja potoku danych wejściowych
    final List<Map<String, dynamic>> sanitizedHistory = decoded.map((item) {
      final map = Map<String, dynamic>.from(item);
      
      // 1. Zabezpieczenie brakujących węzłów struktury
      map['beanDetails'] ??= '';
      map['notes'] ??= '';
      map['defects'] ??= [];
      map['dryNotes'] ??= [];
      map['wetNotes'] ??= [];
      
      // 2. Normalizacja współrzędnych przestrzeni smaku
      for (var key in ['sweetness', 'acidity', 'bitterness']) {
        double val = (map[key] ?? 3.0).toDouble();
        if (val > 5.0) {
          val = val / 2.0; 
        }
        map[key] = val.clamp(1.0, 5.0);
      }

      // Normalizacja oceny ogólnej
      double enjoyment = (map['enjoyment'] ?? 3.0).toDouble();
      if (enjoyment > 5.0) enjoyment = enjoyment / 2.0;
      map['enjoyment'] = enjoyment.clamp(1.0, 5.0);
      
      return map;
    }).toList();

    return sanitizedHistory;
  } catch (e) {
    // Graceful degradation - zamiast białego ekranu, zwracamy czystą kartę
    debugPrint('Błąd parsowania układu historii: $e');
    return [];
  }
});

final staticRoasteriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final String response = await rootBundle.loadString('assets/roasteries.json');
    final List<dynamic> data = jsonDecode(response);
    
    return data.map((e) => e['name'].toString()).toList();
  } catch (e) {
    debugPrint('Błąd ładowania bazy palarni: $e');
    return [];
  }
});

final combinedRoasteriesProvider = FutureProvider<List<String>>((ref) async {
  final history = ref.watch(historyProvider).value ?? [];
  final staticList = ref.watch(staticRoasteriesProvider).value ?? [];

  final Set<String> unique = {...staticList};
  
  for (var s in history) {
    if (s['coffeeName']?.toString().isNotEmpty ?? false) {
      unique.add(s['coffeeName']);
    }
  }
  
  return unique.toList()..sort();
});

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

// ==========================================
// 4. MODUŁ ZARZĄDZANIA KOPIAMI ZAPASOWYMI
// ==========================================
class BackupService {
  static Future<void> exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('tasting_history');
    
    if (historyJson != null && historyJson.isNotEmpty) {
      await Share.share(historyJson, subject: 'Coffee_Tasting_Backup_${DateTime.now().toIso8601String().substring(0, 10)}.json');
    }
  }

  static Future<bool> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result != null && result.files.single.bytes != null) {
        final String importedJson = utf8.decode(result.files.single.bytes!);
        final List<dynamic> importedList = jsonDecode(importedJson);
        
        final prefs = await SharedPreferences.getInstance();
        final String? currentJson = prefs.getString('tasting_history');
        
        List<dynamic> currentList = [];
        if (currentJson != null) {
          currentList = jsonDecode(currentJson);
        }

        final combinedList = [...importedList, ...currentList];
        
        await prefs.setString('tasting_history', jsonEncode(combinedList));
        return true; 
      }
    } catch (e) {
      debugPrint('Błąd importu struktury JSON: $e');
    }
    return false; 
  }
}
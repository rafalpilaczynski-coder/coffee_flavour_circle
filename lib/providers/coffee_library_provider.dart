// lib/providers/coffee_library_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. MODEL DANYCH PACZKI KAWY
class CoffeeBean {
  final String id;
  final String roaster;
  final String name;
  final String origin;
  final String process;
  final double initialWeight;
  final double remainingWeight;
  final double price;
  final DateTime? openDate;

  CoffeeBean({
    required this.id,
    required this.roaster,
    required this.name,
    this.origin = '',
    this.process = '',
    required this.initialWeight,
    required this.remainingWeight,
    required this.price,
    this.openDate,
  });

  CoffeeBean copyWith({
    String? id, String? roaster, String? name, String? origin, String? process,
    double? initialWeight, double? remainingWeight, double? price, DateTime? openDate,
  }) {
    return CoffeeBean(
      id: id ?? this.id,
      roaster: roaster ?? this.roaster,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      process: process ?? this.process,
      initialWeight: initialWeight ?? this.initialWeight,
      remainingWeight: remainingWeight ?? this.remainingWeight,
      price: price ?? this.price,
      openDate: openDate ?? this.openDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'roaster': roaster, 'name': name, 'origin': origin,
    'process': process, 'initialWeight': initialWeight, 'remainingWeight': remainingWeight,
    'price': price, 'openDate': openDate?.toIso8601String(),
  };

  factory CoffeeBean.fromMap(Map<String, dynamic> map) => CoffeeBean(
    id: map['id'] ?? '',
    roaster: map['roaster'] ?? 'Unknown',
    name: map['name'] ?? 'Unknown',
    origin: map['origin'] ?? '',
    process: map['process'] ?? '',
    initialWeight: (map['initialWeight'] ?? 250.0).toDouble(),
    remainingWeight: (map['remainingWeight'] ?? 250.0).toDouble(),
    price: (map['price'] ?? 0.0).toDouble(),
    openDate: map['openDate'] != null ? DateTime.tryParse(map['openDate']) : null,
  );
}

// 2. NOTIFIER ZARZĄDZAJĄCY BIBLIOTEKĄ
class CoffeeLibraryNotifier extends AsyncNotifier<List<CoffeeBean>> {
  @override
  Future<List<CoffeeBean>> build() async {
    return _loadLibrary();
  }

  Future<List<CoffeeBean>> _loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('coffee_library');
    if (jsonStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((item) => CoffeeBean.fromMap(item)).toList();
  }

  Future<void> _saveLibrary(List<CoffeeBean> library) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(library.map((e) => e.toMap()).toList());
    await prefs.setString('coffee_library', encoded);
  }

  Future<void> addCoffee(CoffeeBean bean) async {
    final current = state.value ?? [];
    final newList = [bean, ...current]; // Dodajemy na początek
    state = AsyncData(newList);
    await _saveLibrary(newList);
  }

  Future<void> deleteCoffee(String id) async {
    final current = state.value ?? [];
    final newList = current.where((b) => b.id != id).toList();
    state = AsyncData(newList);
    await _saveLibrary(newList);
  }

  Future<void> updateRemainingWeight(String id, double usedAmount) async {
    final current = state.value ?? [];
    final newList = current.map((bean) {
      if (bean.id == id) {
        final newWeight = (bean.remainingWeight - usedAmount).clamp(0.0, bean.initialWeight);
        return bean.copyWith(remainingWeight: newWeight);
      }
      return bean;
    }).toList();
    
    state = AsyncData(newList);
    await _saveLibrary(newList);
  }

  Future<void> updateCoffeePrice(String id, double newPrice) async {
    final current = state.value ?? [];
    final newList = current.map((bean) {
      if (bean.id == id) {
        return bean.copyWith(price: newPrice);
      }
      return bean;
    }).toList();
    
    state = AsyncData(newList);
    await _saveLibrary(newList);
  }
}

final coffeeLibraryProvider = AsyncNotifierProvider<CoffeeLibraryNotifier, List<CoffeeBean>>(() {
  return CoffeeLibraryNotifier();
});
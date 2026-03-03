// lib/core/constants.dart
import 'package:flutter/material.dart';

// ==========================================
// GLOBALNY SYSTEM DESIGNU (PALETA KAWOWA)
// ==========================================
const Color appBackground = Color(0xFF14110F);    // Głębokie Espresso (Zamiast czerni)
const Color appSurface = Color(0xFF231F1C);       // Ciepła, ciemna szarość (Na karty i panele)
const Color appPrimary = Color(0xFFD97706);       // Miedziany / Karmelowy akcent (Główne akcje)
const Color appTextPrimary = Color(0xFFF3F2F1);   // Złamana biel (Czytelność bez oślepiania)
const Color appTextSecondary = Color(0xFFA09B96); // Szary tekst pomocniczy

// (Reszta Twoich stałych, np. brewMethods, aromaCategories, pozostaje bez zmian poniżej...)

const List<String> brewMethods = [
  'V60', 'Kalita', 'Aeropress', 'Hario Switch', 
  'Chemex', 'Clever', 'Orea', 'Gabi'
];

const Map<String, List<String>> aromaCategories = {
  'Fruity': ['Berry', 'Citrus', 'Stone Fruit', 'Apple'],
  'Sweet': ['Chocolate', 'Caramel', 'Brown Sugar', 'Vanilla'],
  'Nutty/Cocoa': ['Peanut', 'Hazelnut', 'Cocoa', 'Dark Chocolate'],
  'Floral': ['Jasmine', 'Rose', 'Black Tea'],
};

// lib/core/constants.dart

final List<Map<String, dynamic>> mainFlavorCategories = [
  {'name': 'FRUITY', 'color': const Color(0xFFDD0033), 'icon': 'assets/images/flavors/fruity.png'},
  {'name': 'SOUR/FERMENTED', 'color': const Color(0xFFEDC800), 'icon': 'assets/images/flavors/sour.png'},
  {'name': 'GREEN/VEGETATIVE', 'color': const Color(0xFF107A3B), 'icon': 'assets/images/flavors/green.png'},
  {'name': 'OTHER', 'color': const Color(0xFF129CB6), 'icon': 'assets/images/flavors/other.png'},
  {'name': 'ROASTED', 'color': const Color(0xFFC24F35), 'icon': 'assets/images/flavors/roasted.png'},
  {'name': 'SPICES', 'color': const Color(0xFFAC1D36), 'icon': 'assets/images/flavors/spices.png'},
  {'name': 'NUTTY/COCOA', 'color': const Color(0xFFA56C4A), 'icon': 'assets/images/flavors/nutty.png'},
  {'name': 'SWEET', 'color': const Color(0xFFDE6E5E), 'icon': 'assets/images/flavors/sweet.png'},
  {'name': 'FLORAL', 'color': const Color(0xFFD01968), 'icon': 'assets/images/flavors/floral.png'},
];

final Map<String, Map<String, dynamic>> flavorTree = {
  'FRUITY': {'color': const Color(0xFFDD0033), 'sub': ['Berry', 'Dried fruit', 'Other fruit', 'Citrus fruit']},
  'SOUR/FERMENTED': {'color': const Color(0xFFEDC800), 'sub': ['Sour', 'Alcohol/Fermented']},
  'GREEN/VEGETATIVE': {'color': const Color(0xFF107A3B), 'sub': ['Olive oil', 'Raw', 'Green/Vegetative', 'Beany']},
  'OTHER': {'color': const Color(0xFF129CB6), 'sub': ['Papery/Musty', 'Chemical']},
  'ROASTED': {'color': const Color(0xFFC24F35), 'sub': ['Pipe tobacco', 'Tobacco', 'Burnt', 'Cereal']},
  'SPICES': {'color': const Color(0xFFAC1D36), 'sub': ['Pungent', 'Pepper', 'Brown spice']},
  'NUTTY/COCOA': {'color': const Color(0xFFA56C4A), 'sub': ['Nutty', 'Cocoa']},
  'SWEET': {'color': const Color(0xFFDE6E5E), 'sub': ['Brown sugar', 'Vanilla', 'Vanillin', 'Overall sweet', 'Sweet aromatics']},
  'FLORAL': {'color': const Color(0xFFD01968), 'sub': ['Black Tea', 'Floral']},
};
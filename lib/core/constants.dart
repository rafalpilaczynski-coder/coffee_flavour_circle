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

const List<Map<String, dynamic>> mainFlavorCategories = [
  {'name': 'FRUITY', 'color': Color(0xFFE22D30)},
  {'name': 'SWEET', 'color': Color(0xFFE87123)},
  {'name': 'NUTTY/COCOA', 'color': Color(0xFF905E41)},
  {'name': 'FLORAL', 'color': Color(0xFFE557A1)},
  {'name': 'SPICES', 'color': Color(0xFFAD2226)},
  {'name': 'ROASTED', 'color': Color(0xFFC08953)},
  {'name': 'GREEN/VEGETAL', 'color': Color(0xFF197A3E)},
  {'name': 'SOUR/FERMENTED', 'color': Color(0xFFE2B026)},
];

const Map<String, Map<String, dynamic>> flavorTree = {
  'FRUITY': {'color': Color(0xFFE22D30), 'sub': ['Berry', 'Citrus', 'Stone Fruit', 'Apple']},
  'SWEET': {'color': Color(0xFFE87123), 'sub': ['Chocolate', 'Caramel', 'Brown Sugar', 'Vanilla', 'Honey']},
  'NUTTY/COCOA': {'color': Color(0xFF905E41), 'sub': ['Peanut', 'Hazelnut', 'Almond', 'Dark Choc']},
  'FLORAL': {'color': Color(0xFFE557A1), 'sub': ['Jasmine', 'Rose', 'Chamomile', 'Black Tea']},
  'SPICES': {'color': Color(0xFFAD2226), 'sub': ['Cinnamon', 'Clove', 'Nutmeg', 'Pepper']},
  'ROASTED': {'color': Color(0xFFC08953), 'sub': ['Tobacco', 'Pipe', 'Burnt', 'Cereal']},
  'GREEN/VEGETAL': {'color': Color(0xFF197A3E), 'sub': ['Olive', 'Undergrowth', 'Peas', 'Hay']},
  'SOUR/FERMENTED': {'color': Color(0xFFE2B026), 'sub': ['Winey', 'Whiskey', 'Fermented', 'Balsamic']},
};
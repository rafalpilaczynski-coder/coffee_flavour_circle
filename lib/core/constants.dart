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

// ==========================================
// SENSORYKA: BAZA DANYCH SCA FLAVOR WHEEL
// ==========================================

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

// INŻYNIERIA DANYCH: Trzypoziomowe drzewo smaków (Main -> Sub -> Specific)
final Map<String, Map<String, dynamic>> flavorTree = {
  'FRUITY': {
    'color': const Color(0xFFDD0033),
    'sub': <String, List<String>>{
      'Berry': ['Blackberry', 'Raspberry', 'Blueberry', 'Strawberry'],
      'Dried fruit': ['Raisin', 'Prune'],
      'Other fruit': ['Coconut', 'Cherry', 'Pomegranate', 'Pineapple', 'Grape', 'Apple', 'Peach', 'Pear'],
      'Citrus fruit': ['Grapefruit', 'Orange', 'Lemon', 'Lime'],
    }
  },
  'SOUR/FERMENTED': {
    'color': const Color(0xFFEDC800),
    'sub': <String, List<String>>{
      'Sour': ['Sour Aromatics', 'Acetic Acid', 'Butyric Acid', 'Isovaleric Acid', 'Citric Acid', 'Malic Acid'],
      'Alcohol/Fermented': ['Winey', 'Whiskey', 'Fermented', 'Overripe'],
    }
  },
  'GREEN/VEGETATIVE': {
    'color': const Color(0xFF107A3B),
    'sub': <String, List<String>>{
      'Olive oil': [],
      'Raw': [],
      'Green/Vegetative': ['Under-ripe', 'Peapod', 'Fresh', 'Dark Green', 'Vegetative', 'Hay-like', 'Herb-like'],
      'Beany': [],
    }
  },
  'OTHER': {
    'color': const Color(0xFF129CB6),
    'sub': <String, List<String>>{
      'Papery/Musty': ['Stale', 'Cardboard', 'Papery', 'Woody', 'Moldy/Damp', 'Musty/Dusty', 'Musty/Earthy', 'Animalic', 'Meaty Brothy', 'Phenolic'],
      'Chemical': ['Bitter', 'Salty', 'Medicinal', 'Petroleum', 'Skunky', 'Rubber'],
    }
  },
  'ROASTED': {
    'color': const Color(0xFFC24F35),
    'sub': <String, List<String>>{
      'Pipe tobacco': [],
      'Tobacco': [],
      'Burnt': ['Acrid', 'Ashy', 'Smoky', 'Brown Roast'],
      'Cereal': ['Grain', 'Malt'],
    }
  },
  'SPICES': {
    'color': const Color(0xFFAC1D36),
    'sub': <String, List<String>>{
      'Pungent': [],
      'Pepper': [],
      'Brown spice': ['Anise', 'Nutmeg', 'Cinnamon', 'Clove'],
    }
  },
  'NUTTY/COCOA': {
    'color': const Color(0xFFA56C4A),
    'sub': <String, List<String>>{
      'Nutty': ['Peanuts', 'Hazelnut', 'Almond'],
      'Cocoa': ['Chocolate', 'Dark Chocolate'],
    }
  },
  'SWEET': {
    'color': const Color(0xFFDE6E5E),
    'sub': <String, List<String>>{
      'Brown sugar': ['Molasses', 'Maple Syrup', 'Caramel', 'Honey'],
      'Vanilla': [],
      'Vanillin': [],
      'Sweet aromatics': [],
    }
  },
  'FLORAL': {
    'color': const Color(0xFFD01968),
    'sub': <String, List<String>>{
      'Black Tea': [],
      'Floral': ['Chamomile', 'Rose', 'Jasmine'],
    }
  },
};
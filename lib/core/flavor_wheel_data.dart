// lib/core/flavor_wheel_data.dart
import 'package:flutter/material.dart';

class FlavorNode {
  final String name;
  final Color color;
  final String iconPath; // <--- ZMIANA: Ścieżka do pliku, nie emoji
  final List<String> subcategories;

  const FlavorNode({
    required this.name,
    required this.color,
    required this.iconPath,
    this.subcategories = const [],
  });
}

// Precyzyjne odwzorowanie kolorów i struktury SCA Flavor Wheel
const List<FlavorNode> scaFlavorWheel = [
  FlavorNode(
    name: 'Fruity', 
    color: Color(0xFFDD0033), 
    // <--- ZMIANA ŚCIEŻEK DLA WSZYSTKICH KATEGORII:
    iconPath: 'assets/images/flavors/fruity.png', 
    subcategories: ['Berry', 'Dried fruit', 'Other fruit', 'Citrus fruit']
  ),
  FlavorNode(
    name: 'Sour/Fermented', 
    color: Color(0xFFEDC800), 
    iconPath: 'assets/images/flavors/sour.png', 
    subcategories: ['Sour', 'Alcohol/Fermented']
  ),
  FlavorNode(
    name: 'Green/Vegetative', 
    color: Color(0xFF107A3B), 
    iconPath: 'assets/images/flavors/green.png', 
    subcategories: ['Olive oil', 'Raw', 'Green/Vegetative', 'Beany']
  ),
  FlavorNode(
    name: 'Other', 
    color: Color(0xFF129CB6), 
    iconPath: 'assets/images/flavors/other.png', 
    subcategories: ['Papery/Musty', 'Chemical']
  ),
  FlavorNode(
    name: 'Roasted', 
    color: Color(0xFFC24F35), 
    iconPath: 'assets/images/flavors/roasted.png', 
    subcategories: ['Pipe tobacco', 'Tobacco', 'Burnt', 'Cereal']
  ),
  FlavorNode(
    name: 'Spices', 
    color: Color(0xFFAC1D36), 
    iconPath: 'assets/images/flavors/spices.png', 
    subcategories: ['Pungent', 'Pepper', 'Brown spice']
  ),
  FlavorNode(
    name: 'Nutty/Cocoa', 
    color: Color(0xFFA56C4A), 
    iconPath: 'assets/images/flavors/nutty.png', 
    subcategories: ['Nutty', 'Cocoa']
  ),
  FlavorNode(
    name: 'Sweet', 
    color: Color(0xFFDE6E5E), 
    iconPath: 'assets/images/flavors/sweet.png', 
    subcategories: ['Brown sugar', 'Vanilla', 'Vanillin', 'Overall sweet', 'Sweet aromatics']
  ),
  FlavorNode(
    name: 'Floral', 
    color: Color(0xFFD01968), 
    iconPath: 'assets/images/flavors/floral.png', 
    subcategories: ['Black Tea', 'Floral']
  ),
];
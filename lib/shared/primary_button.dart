// lib/shared/primary_button.dart
import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color; // Opcjonalny kolor nadpisujący

  const PrimaryActionButton({
    super.key, 
    required this.label, 
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Jeśli nie podano koloru, używamy globalnego appPrimary z motywu
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          child: Text(
            label, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)
          ),
        ),
      ),
    );
  }
}
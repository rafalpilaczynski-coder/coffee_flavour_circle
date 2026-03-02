// lib/shared/primary_button.dart
import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const PrimaryActionButton({
    super.key, 
    required this.label, 
    required this.onPressed,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            label, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class FondoDecorativo extends StatelessWidget {
  final Widget child;

  const FondoDecorativo({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 🔥 CAMBIADO: Ahora reaccionará al instante en TODAS las pantallas
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esOscuro
              ? const [
                  Color(0xFF0F172A), 
                  Color(0xFF1E293B), 
                ]
              : const [
                  Color(0xFFF8FAFC), 
                  Color(0xFFE2E8F0), 
                ],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
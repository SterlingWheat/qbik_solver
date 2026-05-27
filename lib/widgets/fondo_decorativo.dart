import 'package:flutter/material.dart';

class FondoDecorativo extends StatelessWidget {
  final Widget child;

  const FondoDecorativo({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Detectamos el brillo del tema actual
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esOscuro
              ? [
                  const Color(0xFF0F172A), // Azul noche muy oscuro
                  const Color(0xFF1E293B), // Gris azulado oscuro
                ]
              : [
                  const Color(0xFFF8FAFC), // Blanco tiza
                  const Color(0xFFE2E8F0), // Gris claro sutil
                ],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
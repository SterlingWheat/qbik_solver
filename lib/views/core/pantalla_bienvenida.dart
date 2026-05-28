import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/comunes/logo_animado.dart';

class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _EstadoPantallaBienvenida();
}

class _EstadoPantallaBienvenida extends State<PantallaBienvenida> {
  @override
  void initState() {
    super.initState();
    _navegarAlMenuPrincipal();
  }

  void _navegarAlMenuPrincipal() async {
    // Esperamos 3 segundos para que la animación se aprecie
    await Future.delayed(const Duration(seconds: 3));
    
    // Validación de seguridad por si el widget se desmontó antes del timer
    if (!mounted) return;

    // Transición limpia utilizando el enrutamiento de GetX
    Get.offNamed('/menu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoAnimado(),
            const SizedBox(height: 40),
            Text(
              'QBIK IA', // Título minimalista
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Get.theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resolvedor Inteligente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
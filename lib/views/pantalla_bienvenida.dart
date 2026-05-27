import 'package:flutter/material.dart';
import 'pantalla_menu_principal.dart';
import '../widgets/logo_animado.dart';

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

    // Transición suave por opacidad hacia el menú principal
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animacion, animacionSecundaria) => const PantallaMenuPrincipal(),
        transitionsBuilder: (context, animacion, animacionSecundaria, hijo) {
          return FadeTransition(opacity: animacion, child: hijo);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resolvedor Inteligente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
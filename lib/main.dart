import 'package:flutter/material.dart';
import 'views/pantalla_bienvenida.dart';
import 'gestores/gestor_configuracion.dart';

void main() {
  runApp(const AplicacionCubo());
}

class AplicacionCubo extends StatelessWidget {
  const AplicacionCubo({super.key});

  @override
  Widget build(BuildContext context) {
    final gestorConfig = GestorConfiguracion();

    return ListenableBuilder(
      listenable: gestorConfig,
      builder: (context, _) {
        return MaterialApp(
          title: 'Resolvedor IA',
          debugShowCheckedModeBanner: false,
          
          // Configuración dinámica del tema basada en el gestor
          themeMode: gestorConfig.esTemaOscuro ? ThemeMode.dark : ThemeMode.light,
          
          // Esquema de Colores Claro
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
          ),
          
          // Esquema de Colores Oscuro
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          
          home: const PantallaBienvenida(),
        );
      },
    );
  }
}
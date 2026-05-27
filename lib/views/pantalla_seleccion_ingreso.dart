import 'package:flutter/material.dart';
import 'package:qbik_solver/views/pantalla_ingreso_manual_2x2.dart';
import 'package:qbik_solver/views/pantalla_ingreso_manual_3x3.dart';
import 'package:qbik_solver/views/pantalla_escaner_2x2.dart';
import '../gestores/gestor_configuracion.dart';
import '../widgets/fondo_decorativo.dart';
import '../widgets/tarjeta_metodo_ingreso.dart';

class PantallaSeleccionIngreso extends StatelessWidget {
  final String tipoCubo; // Ej: "Cubo 3x3", "Cubo 2x2", "Pyraminx"

  const PantallaSeleccionIngreso({
    super.key,
    required this.tipoCubo,
  });

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = esOscuro ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoDecorativo(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto),
                    onPressed: () {
                      GestorConfiguracion().ejecutarVibracion();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tipoCubo, // Muestra el cubo seleccionado (3x3, 2x2, etc.)
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Método de ingreso',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colorTexto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¿Cómo deseas ingresar el estado actual de tu $tipoCubo?',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorTexto.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Opción 1: Escáner IA (Cámara)
                    TarjetaMetodoIngreso(
                      indice: 0,
                      titulo: 'Escáner Inteligente',
                      subtitulo: 'Usa la cámara y la IA para detectar las piezas automáticamente.',
                      icono: Icons.document_scanner_rounded, 
                      alPresionar: () {
                        if (tipoCubo == 'Cubo 2x2') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PantallaEscaner2x2()),
                          );
                        }
                        _mostrarSnack(context, 'Abriendo cámara para $tipoCubo...');
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // Opción 2: Ingreso Manual (Pintar)
                    TarjetaMetodoIngreso(
                      indice: 1,
                      titulo: 'Ingreso Manual',
                      subtitulo: 'Pinta los colores de cada cara usando una paleta digital.',
                      icono: Icons.format_paint_rounded, 
                      alPresionar: () {
                        if (tipoCubo == 'Cubo 2x2') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PantallaIngresoManual2x2()),
                          );
                        } else if (tipoCubo == 'Cubo 3x3') { 
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PantallaIngresoManual3x3()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSnack(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }
}
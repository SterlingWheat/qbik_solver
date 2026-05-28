import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../gestores/globales/gestor_configuracion.dart';
import '../../widgets/comunes/fondo_decorativo.dart';
import '../../widgets/comunes/tarjeta_metodo_ingreso.dart';

class PantallaSeleccionIngreso extends StatelessWidget {
  final String tipoCubo;

  const PantallaSeleccionIngreso({super.key, required this.tipoCubo});

  @override
  Widget build(BuildContext context) {
    // Obtenemos colores basados en el tema directamente de GetX
    final esOscuro = Get.isDarkMode;
    final colorTexto = esOscuro ? Colors.white : Colors.black87;
    final colorPrimario = Get.theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoDecorativo(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- CABECERA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto),
                    onPressed: () {
                      Get.find<GestorConfiguracion>().ejecutarVibracion();
                      Get.back();
                    },
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Método de Ingreso',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorTexto,
                        ),
                      ),
                      Text(
                        tipoCubo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorPrimario,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- CONTENIDO (OPCIONES DE INGRESO) ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    '¿Cómo quieres ingresar el estado de tu cubo?',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorTexto.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // OPCIÓN 1: ESCÁNER INTELIGENTE
                  TarjetaMetodoIngreso(
                    indice: 0,
                    titulo: 'Cámara Inteligente',
                    subtitulo: 'Escanea tu cubo usando la cámara de tu dispositivo y nuestra IA.',
                    icono: Icons.document_scanner_rounded,
                    alPresionar: () {
                      if (tipoCubo == 'Cubo 2x2') {
                        Get.toNamed('/escaner-2x2');
                      } else {
                        // Reemplazo del ScaffoldMessenger por Get.snackbar
                        Get.snackbar(
                          'En desarrollo',
                          'El escáner IA para el cubo 3x3 estará disponible en la próxima actualización.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: esOscuro ? Colors.grey[800] : Colors.grey[200],
                          colorText: colorTexto,
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  // OPCIÓN 2: INGRESO MANUAL
                  TarjetaMetodoIngreso(
                    indice: 1,
                    titulo: 'Ingreso Manual',
                    subtitulo: 'Pinta los colores de tu cubo manualmente en un mapa 2D interactivo.',
                    icono: Icons.touch_app_rounded,
                    alPresionar: () {
                      if (tipoCubo == 'Cubo 2x2') {
                        Get.toNamed('/ingreso-manual-2x2');
                      } else if (tipoCubo == 'Cubo 3x3') {
                        Get.toNamed('/ingreso-manual-3x3');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
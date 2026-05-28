import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/comunes/tarjeta_menu_animada.dart';
import '../../widgets/comunes/fondo_decorativo.dart';

class PantallaMenuPrincipal extends StatelessWidget {
  const PantallaMenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    // Detectamos el tema con GetX para adaptar los colores
    final esOscuro = Get.isDarkMode;
    final colorTextoPrincipal = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorTextoSecundario = esOscuro ? Colors.white.withOpacity(0.7) : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: FondoDecorativo(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera con colores adaptativos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido,',
                    style: TextStyle(fontSize: 16, color: colorTextoSecundario),
                  ),
                  Text(
                    '¿Qué resolveremos hoy?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorTextoPrincipal),
                  ),
                ],
              ),
            ),
            
            // Panel de tarjetas flexible y centrado
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double anchoTarjeta = (constraints.maxWidth - 20) / 2;
                    final double altoTarjeta = anchoTarjeta / 0.85; 

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Fila 1: Cubo 3x3 y Cubo 2x2
                          Row(
                            children: [
                              SizedBox(
                                width: anchoTarjeta, height: altoTarjeta,
                                child: TarjetaMenuAnimada(
                                  indice: 0, titulo: 'Cubo 3x3', icono: Icons.grid_on_rounded,
                                  // Pasamos el tipo de cubo como argumento de la ruta
                                  alPresionar: () => Get.toNamed('/seleccion-ingreso', arguments: 'Cubo 3x3'),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: anchoTarjeta, height: altoTarjeta,
                                child: TarjetaMenuAnimada(
                                  indice: 1, titulo: 'Cubo 2x2', icono: Icons.grid_view_rounded,
                                  // Pasamos el tipo de cubo como argumento de la ruta
                                  alPresionar: () => Get.toNamed('/seleccion-ingreso', arguments: 'Cubo 2x2'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20), 

                          // Fila 2: Cronómetro y Estadísticas
                          Row(
                            children: [
                              SizedBox(
                                width: anchoTarjeta, height: altoTarjeta,
                                child: TarjetaMenuAnimada(
                                  indice: 2, titulo: 'Cronómetro', icono: Icons.timer_outlined,
                                  alPresionar: () => Get.toNamed('/cronometro'),
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: anchoTarjeta, height: altoTarjeta,
                                child: TarjetaMenuAnimada(
                                  indice: 3, titulo: 'Estadísticas', icono: Icons.insights_rounded,
                                  alPresionar: () => Get.toNamed('/estadisticas'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Fila 3: Configuración 
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: anchoTarjeta, height: altoTarjeta,
                                child: TarjetaMenuAnimada(
                                  indice: 4, titulo: 'Configuración', icono: Icons.settings_outlined,
                                  alPresionar: () => Get.toNamed('/configuracion'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24), 
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
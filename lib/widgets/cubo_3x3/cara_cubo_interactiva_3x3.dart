import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../gestores/cubo_3x3/gestor_ingreso_3x3.dart';
import '../../gestores/globales/gestor_configuracion.dart';

class CaraCuboInteractiva3x3 extends StatelessWidget {
  final GestorIngreso3x3 gestor;

  const CaraCuboInteractiva3x3({super.key, required this.gestor});

  @override
  Widget build(BuildContext context) {
    final piezas = gestor.caras[gestor.caraActual];
    final esOscuro = Get.isDarkMode;

    return AspectRatio(
      aspectRatio: 1.0, // Mantiene la cara perfectamente cuadrada
      child: Container(
        decoration: BoxDecoration(
          color: esOscuro ? Colors.grey[900] : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            )
          ],
        ),
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columnas para el 3x3
            crossAxisSpacing: 6, // Espaciado ligeramente menor que el 2x2 para que quepa bien
            mainAxisSpacing: 6,
          ),
          itemCount: 9, // 9 piezas por cara
          itemBuilder: (context, index) {
            final colorPieza = piezas[index];
            final esCentro = index == 4; // El índice 4 siempre es el centro en una grilla de 3x3
            
            return GestureDetector(
              // Si es el centro, el onTap es nulo (desactivado). Si no, permite pintar.
              onTap: esCentro ? null : () {
                if (gestor.colorSeleccionado != null) {
                  Get.find<GestorConfiguracion>().ejecutarVibracion();
                  gestor.pintarPieza(index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: colorPieza ?? (esOscuro ? Colors.black54 : Colors.white54),
                  borderRadius: BorderRadius.circular(8),
                  // Borde un poco más grueso para resaltar el centro fijo
                  border: Border.all(
                    color: esOscuro ? Colors.white24 : Colors.black12,
                    width: esCentro ? 3 : 2, 
                  ),
                ),
                child: _construirContenidoPieza(esCentro, colorPieza, esOscuro),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construye el ícono de "agregar" o el punto del centro fijo
  Widget? _construirContenidoPieza(bool esCentro, Color? colorPieza, bool esOscuro) {
    if (esCentro) {
      // Indicador visual de que este bloque es inamovible (Centro del 3x3)
      return Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    
    // Si la pieza está vacía (y no es el centro), mostramos un "+"
    if (colorPieza == null) {
      return Icon(
        Icons.add, 
        color: esOscuro ? Colors.white24 : Colors.black.withOpacity(0.24),
      );
    }
    
    // Si la pieza ya está pintada, no mostramos nada dentro
    return null; 
  }
}
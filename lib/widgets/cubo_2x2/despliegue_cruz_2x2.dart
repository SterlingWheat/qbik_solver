import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget interactivo que muestra el cubo 2x2 desdoblado en 2D (Cruz).
/// Mapeo oficial:
/// Arriba(U): 0-3, Derecha(R): 4-7, Frente(F): 8-11,
/// Abajo(D): 12-15, Izquierda(L): 16-19, Atrás(B): 20-23
class DespliegueCruz2x2 extends StatelessWidget {
  final List<Color?> pegatinas;
  final Function(int indice) alTocarPegatina;

  const DespliegueCruz2x2({
    super.key,
    required this.pegatinas,
    required this.alTocarPegatina,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos Get.width en lugar de MediaQuery para obtener el ancho de la pantalla de forma directa
    final anchoPantalla = Get.width;
    final tamanoCara = (anchoPantalla * 0.85) / 4; 

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fila 1: [Vacío] - [Arriba U] - [Vacío] - [Vacío]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: tamanoCara),
            _construirCara(0, "U", tamanoCara),
            SizedBox(width: tamanoCara),
            SizedBox(width: tamanoCara),
          ],
        ),
        
        // Fila 2: [Izquierda L] - [Frente F] - [Derecha R] - [Atrás B]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _construirCara(16, "L", tamanoCara),
            _construirCara(8, "F", tamanoCara),
            _construirCara(4, "R", tamanoCara),
            _construirCara(20, "B", tamanoCara),
          ],
        ),

        // Fila 3: [Vacío] - [Abajo D] - [Vacío] - [Vacío]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: tamanoCara),
            _construirCara(12, "D", tamanoCara),
            SizedBox(width: tamanoCara),
            SizedBox(width: tamanoCara),
          ],
        ),
      ],
    );
  }

  /// Construye una cara individual de 2x2 pegatinas
  Widget _construirCara(int indiceBase, String etiqueta, double tamano) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        children: [
          // Cuadrícula 2x2
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _construirPegatina(indiceBase + 0),
                    _construirPegatina(indiceBase + 1),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    _construirPegatina(indiceBase + 2),
                    _construirPegatina(indiceBase + 3),
                  ],
                ),
              ),
            ],
          ),
          // Etiqueta semitransparente en el centro de la cara para guiar al usuario
          Center(
            child: IgnorePointer( // Para no bloquear los toques
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  etiqueta,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un solo cuadrito (sticker) clickeable
  Widget _construirPegatina(int indice) {
    Color? colorActual = pegatinas[indice];

    return Expanded(
      child: GestureDetector(
        onTap: () => alTocarPegatina(indice),
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: colorActual ?? Colors.grey.shade800, // Gris si está vacío
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colorActual != null ? Colors.black38 : Colors.black12,
              width: 1,
            ),
            boxShadow: colorActual != null
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    )
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}
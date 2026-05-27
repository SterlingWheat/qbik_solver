import 'package:flutter/material.dart';

class MinimapaCaras extends StatelessWidget {
  final int caraActual;
  final String nombreCaraActual;

  const MinimapaCaras({
    super.key,
    required this.caraActual,
    required this.nombreCaraActual,
  });

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // Texto dinámico: Ej: "Cara 2: Derecha"
        Text(
          'CARA ${caraActual + 1}: ${nombreCaraActual.toUpperCase()}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: colorPrimario,
          ),
        ),
        const SizedBox(height: 12),
        // Fila de 6 puntitos indicadores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final estaActivo = index == caraActual;
            final yaPaso = index < caraActual;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: estaActivo ? 24 : 8, // Se estira si es la cara actual
              decoration: BoxDecoration(
                color: estaActivo 
                    ? colorPrimario 
                    : (yaPaso ? colorPrimario.withOpacity(0.5) : Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
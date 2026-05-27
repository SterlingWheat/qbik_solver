import 'package:flutter/material.dart';
import '../gestores/gestor_ingreso_3x3.dart';

class PaletaColores3x3 extends StatelessWidget {
  final GestorIngreso3x3 gestor;

  const PaletaColores3x3({super.key, required this.gestor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withOpacity(0.05) 
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: GestorIngreso3x3.coloresOficiales.map((color) {
          final cantidadUsada = gestor.obtenerCantidadColor(color);
          // Límite máximo de 9 piezas por cada color en un 3x3
          final disponibles = 9 - cantidadUsada; 
          final estaSeleccionado = gestor.colorSeleccionado == color;
          final agotado = disponibles == 0;

          return GestureDetector(
            onTap: agotado && !estaSeleccionado ? null : () => gestor.seleccionarColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: estaSeleccionado 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey.withOpacity(0.5),
                  width: estaSeleccionado ? 4 : 1,
                ),
                boxShadow: estaSeleccionado ? [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                ] : [],
                // Efecto de oscurecimiento si ya usamos las 9 piezas
                gradient: agotado && !estaSeleccionado ? LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.6)]
                ) : null,
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$disponibles',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
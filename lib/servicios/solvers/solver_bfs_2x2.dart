import 'package:flutter/foundation.dart';
import '../../modelos/estado_cubo_2x2.dart';

/// Servicio de resolución óptima para el Cubo Rubik 2x2.
/// ALGORITMO: IDA* (Iterative Deepening A*) Optimizado
class SolverBFS2x2 {

  /// Ejecuta el algoritmo en un hilo secundario (Isolate) para no congelar la UI de Flutter.
  static Future<List<String>> resolver(EstadoCubo2x2 inicial) async {
    return await compute(_resolverIsolate, inicial.pegatinas);
  }

  static List<String> _resolverIsolate(List<int> pegatinasIniciales) {
    debugPrint("=== [SOLVER 2x2] INICIANDO IDA* OPTIMIZADO ===");
    final EstadoCubo2x2 estado = EstadoCubo2x2(pegatinasIniciales);

    // Cortocircuito: si ya está resuelto, devolvemos lista vacía
    if (estado.estaResuelto) {
      return [];
    }

    // 🔥 OPTIMIZACIÓN CRÍTICA:
    // En lugar de usar las 6 caras (18 movimientos), usamos solo U, R y F (9 movimientos).
    // Esto ancla la esquina inferior-izquierda-trasera y reduce los cálculos masivamente.
    // Como 'estaResuelto' revisa las caras sin importar la orientación global, funcionará perfecto.
    final List<String> movimientosOptimos = [
      'U', "U'", 'U2',
      'R', "R'", 'R2',
      'F', "F'", 'F2'
    ];

    int umbral = _heuristica(estado);
    const int LIMITE_ABSOLUTO = 12; // El máximo de movimientos necesarios (God's Number) para un 2x2 es 11.
    List<String> ruta = [];

    for (int iteracion = 0; umbral <= LIMITE_ABSOLUTO; iteracion++) {
      debugPrint("[SOLVER] Buscando solución a profundidad máxima de $umbral movimientos...");
      int resultado = _buscar(estado, 0, umbral, ruta, movimientosOptimos, '');

      if (resultado == _ENCONTRADO) {
        debugPrint("✅ [SOLVER] Solución óptima encontrada en ${ruta.length} movimientos: $ruta");
        return ruta;
      }

      if (resultado == _INFINITO) break;

      umbral = resultado;
    }

    throw Exception(
      "Mezcla inalcanzable. Revisa los colores en pantalla; tu cubo podría estar mal ensamblado físicamente."
    );
  }

  static const int _ENCONTRADO = -1;
  static const int _INFINITO = 999999;

  static int _buscar(EstadoCubo2x2 estado, int g, int umbral, List<String> ruta, List<String> movimientos, String caraAnterior) {
    final int f = g + _heuristica(estado);
    if (f > umbral) return f;
    if (estado.estaResuelto) return _ENCONTRADO;

    int minimo = _INFINITO;

    for (final String mov in movimientos) {
      final String cara = mov[0];

      // Poda estricta: No girar la misma cara dos veces seguidas en la misma rama
      if (cara == caraAnterior) continue;

      final EstadoCubo2x2 siguiente = estado.aplicarMovimiento(mov);
      ruta.add(mov);

      final int resultado = _buscar(siguiente, g + 1, umbral, ruta, movimientos, cara);

      if (resultado == _ENCONTRADO) return _ENCONTRADO;
      if (resultado < minimo) minimo = resultado;

      ruta.removeLast();
    }
    return minimo;
  }

  static int _heuristica(EstadoCubo2x2 estado) {
    int carasNoUniformes = 0;
    for (int cara = 0; cara < 6; cara++) {
      final int base = cara * 4;
      final int color = estado.pegatinas[base];
      
      // Si alguna pegatina de la cara no coincide con la primera, no es uniforme
      if (estado.pegatinas[base + 1] != color ||
          estado.pegatinas[base + 2] != color ||
          estado.pegatinas[base + 3] != color) {
        carasNoUniformes++;
      }
    }
    return carasNoUniformes == 0 ? 0 : ((carasNoUniformes + 3) ~/ 4);
  }
}
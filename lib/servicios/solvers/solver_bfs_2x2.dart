import 'package:flutter/foundation.dart';
import '../../modelos/estado_cubo_2x2.dart';

/// Servicio de resolución óptima para el Cubo Rubik 2x2.
/// ALGORITMO: IDA* (Iterative Deepening A*)
class SolverBFS2x2 {

  /// Ejecuta el algoritmo en un hilo secundario (Isolate) para no congelar la UI de Flutter.
  static Future<List<String>> resolver(EstadoCubo2x2 inicial) async {
    return await compute(_resolverIsolate, inicial.pegatinas);
  }

  static List<String> _resolverIsolate(List<int> pegatinasIniciales) {
    debugPrint("=== [SOLVER 2x2] INICIANDO IDA* ===");
    debugPrint("[SOLVER] Estado inicial: $pegatinasIniciales");

    final EstadoCubo2x2 estado = EstadoCubo2x2(pegatinasIniciales);

    // Cortocircuito: cubo ya resuelto (cualquier orientación)
    if (estado.estaResuelto) {
      debugPrint("[SOLVER] Cubo ya resuelto. Devolviendo solución vacía.");
      return [];
    }

    final List<String> todosLosMovimientos = [];
    for (var c in ['U', 'D', 'R', 'L', 'F', 'B']) {
      for (var m in ['', "'", '2']) {
        todosLosMovimientos.add(c + m);
      }
    }

    int umbral = _heuristica(estado);
    debugPrint("[SOLVER] Heurística inicial: $umbral");

    const int LIMITE_ABSOLUTO = 20;
    List<String> ruta = [];

    for (int iteracion = 0; umbral <= LIMITE_ABSOLUTO; iteracion++) {
      debugPrint("[SOLVER] IDA* iteración $iteracion, umbral=$umbral");

      int resultado = _buscar(estado, 0, umbral, ruta, todosLosMovimientos, '');

      if (resultado == _ENCONTRADO) {
        debugPrint("✅ [SOLVER] Solución encontrada en ${ruta.length} movimientos: $ruta");
        return ruta;
      }

      if (resultado == _INFINITO) break;

      umbral = resultado;
    }

    debugPrint("❌ [SOLVER] Sin solución. Estado físicamente imposible.");
    throw Exception(
      "Mezcla inalcanzable. Revisa físicamente tu cubo; podría tener una esquina mal ensamblada."
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

      if (cara == caraAnterior) continue;
      if (_esCandidatoRedundante(cara, caraAnterior)) continue;

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
      if (estado.pegatinas[base + 1] != color ||
          estado.pegatinas[base + 2] != color ||
          estado.pegatinas[base + 3] != color) {
        carasNoUniformes++;
      }
    }
    return (carasNoUniformes + 3) ~/ 4;
  }

  static bool _esCandidatoRedundante(String caraActual, String caraAnterior) {
    if (caraAnterior.isEmpty) return false;
    if (caraAnterior == 'D' && caraActual == 'U') return true;
    if (caraAnterior == 'L' && caraActual == 'R') return true;
    if (caraAnterior == 'B' && caraActual == 'F') return true;
    return false;
  }
}
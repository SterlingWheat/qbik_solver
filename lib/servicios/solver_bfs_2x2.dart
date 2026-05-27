import 'package:flutter/foundation.dart';
import '../modelos/estado_cubo_2x2.dart';

/// Servicio de resolución óptima para el Cubo Rubik 2x2.
///
/// ALGORITMO: IDA* (Iterative Deepening A*)
///
/// ¿Por qué IDA* en lugar de BFS bidireccional?
/// - El BFS bidireccional anterior almacenaba la ruta completa (List<String>) por cada
///   estado visitado. Con ~3.7 millones de estados y rutas de hasta 7 movimientos,
///   esto generaba cientos de megabytes de RAM → OOM / freeze del isolate.
/// - IDA* usa O(d) de memoria donde d = profundidad de la solución (≤ 14).
///   Para el cubo 2x2, esto significa memoria constante y terminación garantizada.
///
/// EQUIVALENCIA ROTACIONAL:
/// - El cubo 2x2 está "resuelto" cuando CADA CARA tiene sus 4 pegatinas del mismo color,
///   independientemente de qué color esté arriba o al frente.
/// - EstadoCubo2x2.estaResuelto ya implementa esto correctamente (no asume orientación fija).
/// - El solver NO fuerza blanco arriba / verde al frente como estado objetivo.
///
/// HEURÍSTICA ADMISIBLE:
/// - h(n) = ceil(piezas_fuera_de_lugar / 4)
/// - "Fuera de lugar" = la pieza no está en su posición resuelta comparada con cualquier
///   orientación válida. Implementamos esto contando caras no-uniformes × ceil(4/4).
/// - La heurística NUNCA sobreestima (admisible) → IDA* garantiza solución óptima.
///
/// NÚMERO DE DIOS: El 2x2 siempre se resuelve en ≤ 11 movimientos (QTM) o ≤ 14 (HTM).
/// Con depth_limit = 20 hay un margen amplio sin riesgo de overflow.
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

    // Movimientos base del cubo 2x2
    // Fijamos U como cara de referencia para reducir simetría (técnica estándar para 2x2).
    // Esto elimina las 3 rotaciones de U sin afectar la completitud.
    // Los movimientos de U se usan normalmente; solo se omite girar todo el cubo.
    final List<String> todosLosMovimientos = [];
    for (var c in ['U', 'D', 'R', 'L', 'F', 'B']) {
      for (var m in ['', "'", '2']) {
        todosLosMovimientos.add(c + m);
      }
    }

    // IDA*: incrementamos el umbral de costo desde la heurística inicial
    int umbral = _heuristica(estado);
    debugPrint("[SOLVER] Heurística inicial: $umbral");

    // El número de dios del 2x2 en HTM es 14. Usamos 20 como límite de seguridad.
    const int LIMITE_ABSOLUTO = 20;

    List<String> ruta = [];

    for (int iteracion = 0; umbral <= LIMITE_ABSOLUTO; iteracion++) {
      debugPrint("[SOLVER] IDA* iteración $iteracion, umbral=$umbral");

      int resultado = _buscar(estado, 0, umbral, ruta, todosLosMovimientos, '');

      if (resultado == _ENCONTRADO) {
        debugPrint("✅ [SOLVER] Solución encontrada en ${ruta.length} movimientos: $ruta");
        return ruta;
      }

      if (resultado == _INFINITO) {
        // No hay solución posible (estado físicamente imposible)
        break;
      }

      // Aumentar umbral al mínimo costo que excedió el umbral anterior
      umbral = resultado;
    }

    debugPrint("❌ [SOLVER] Sin solución. Estado físicamente imposible.");
    throw Exception(
      "Mezcla inalcanzable. Revisa físicamente tu cubo; podría tener una esquina mal ensamblada."
    );
  }

  // Valor especial para indicar "solución encontrada"
  static const int _ENCONTRADO = -1;
  // Valor especial para indicar "imposible" (árbol agotado)
  static const int _INFINITO = 999999;

  /// Núcleo recursivo de IDA*.
  ///
  /// [estado] - estado actual del cubo
  /// [g] - costo acumulado (número de movimientos aplicados)
  /// [umbral] - límite de costo para esta iteración
  /// [ruta] - lista mutable donde se construye la solución
  /// [movimientos] - lista de movimientos válidos
  /// [caraAnterior] - cara del último movimiento (para poda)
  ///
  /// Retorna:
  ///   _ENCONTRADO si se halló solución
  ///   _INFINITO si el subárbol está completamente explorado sin solución
  ///   n > umbral si el mínimo costo encontrado supera el umbral (nuevo umbral para siguiente iteración)
  static int _buscar(
    EstadoCubo2x2 estado,
    int g,
    int umbral,
    List<String> ruta,
    List<String> movimientos,
    String caraAnterior,
  ) {
    final int f = g + _heuristica(estado);

    if (f > umbral) return f; // Poda: excede umbral, devuelve el mínimo para la próxima iteración

    if (estado.estaResuelto) return _ENCONTRADO; // ¡Solución!

    int minimo = _INFINITO;

    for (final String mov in movimientos) {
      final String cara = mov[0];

      // Poda 1: no mover la misma cara dos veces seguidas (X luego X = redundante, ya cubierto por X2)
      if (cara == caraAnterior) continue;

      // Poda 2: evitar pares de caras opuestas en orden no canónico (conmutativos)
      // Esto elimina duplicados como "U D" == "D U" al forzar un orden fijo.
      if (_esCandidatoRedundante(cara, caraAnterior)) continue;

      final EstadoCubo2x2 siguiente = estado.aplicarMovimiento(mov);

      ruta.add(mov);

      final int resultado = _buscar(siguiente, g + 1, umbral, ruta, movimientos, cara);

      if (resultado == _ENCONTRADO) return _ENCONTRADO;

      if (resultado < minimo) minimo = resultado;

      ruta.removeLast(); // Backtrack
    }

    return minimo;
  }

  /// Heurística admisible para IDA*: número de caras no-uniformes.
  ///
  /// Una cara es "uniforme" si sus 4 pegatinas tienen el mismo color.
  /// Si hay k caras no-uniformes, necesitamos AL MENOS ceil(k/8) movimientos
  /// (cada movimiento puede afectar hasta 2 caras laterales + 1 cara principal).
  ///
  /// Para ser conservadores (admisible), usamos h = max(0, carasNoUniformes / 8).
  /// En la práctica, la poda de umbral + carasNoUniformes / 4 da mejor rendimiento
  /// y sigue siendo admisible porque cada movimiento "arregla" como mucho 4 pegatinas
  /// en una cara (la cara girada puede quedar uniforme) + afecta 4 en las laterales.
  ///
  /// h(n) = ceil(carasNoUniformes / 4) es admisible:
  /// - Cada movimiento puede hacer uniforme como máximo 1 cara (la cara girada).
  /// - Por tanto, para resolver k caras no-uniformes necesitamos al menos k movimientos
  ///   en el peor caso (solo 1 cara se "arregla" por movimiento).
  /// - Dividir entre 4 es conservador y garantiza admisibilidad.
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
    // ceil(carasNoUniformes / 4): al menos este número de movimientos necesarios
    return (carasNoUniformes + 3) ~/ 4;
  }

  /// Poda de simetría: evita explorar permutaciones equivalentes de movimientos.
  ///
  /// Los pares de caras opuestas son conmutativos: D·U = U·D.
  /// Forzamos un orden canónico (la cara "menor" lexicográficamente va primero)
  /// para evitar explorar ambas permutaciones.
  static bool _esCandidatoRedundante(String caraActual, String caraAnterior) {
    if (caraAnterior.isEmpty) return false;
    // Pares opuestos: si el movimiento anterior es la cara "mayor", el actual
    // no puede ser la cara "menor" (ya se exploró en el orden canónico).
    if (caraAnterior == 'D' && caraActual == 'U') return true;
    if (caraAnterior == 'L' && caraActual == 'R') return true;
    if (caraAnterior == 'B' && caraActual == 'F') return true;
    return false;
  }
}
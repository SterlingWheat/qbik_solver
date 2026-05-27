import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../modelos/estado_cubo_2x2.dart';

/// Servicio de resolución basado en Inteligencia Artificial Clásica (Búsqueda en Grafos).
/// Utiliza Búsqueda Bidireccional en Anchura (Bidirectional BFS).
class SolverBFS2x2 {
  
  /// Ejecuta el algoritmo en un hilo secundario (Isolate) para no congelar la UI de Flutter.
  static Future<List<String>> resolver(EstadoCubo2x2 inicial) async {
    return await compute(_resolverBidireccionalIsolate, inicial.pegatinas);
  }

  /// NÚCLEO MATEMÁTICO: BFS Bidireccional
  /// El estado objetivo es SIEMPRE el cubo resuelto perfecto (Blanco Arriba, Verde Frente).
  /// 
  /// CORRECCIÓN CRÍTICA: Las colas forward y backward ahora tienen control de profundidad
  /// independiente. Cada cola se expande hasta profundidad MAX_PROF_POR_LADO (7).
  /// Antes, un único contador global maxProfundidad se incrementaba una vez por iteración
  /// aunque solo expandiera UNA de las dos colas. Esto hacía que cada cola solo llegara a
  /// profundidad ~4, cubriendo un total de ~8 movimientos cuando el número de dios del 2x2
  /// es 14 (Half-Turn Metric). Eso provocaba rechazar ~80% de los estados válidos.
  static List<String> _resolverBidireccionalIsolate(List<int> pegatinasIniciales) {
    debugPrint("=== [SOLVER 2x2] INICIANDO BFS BIDIRECCIONAL ===");
    debugPrint("[SOLVER] Estado inicial: $pegatinasIniciales");

    EstadoCubo2x2 inicial = EstadoCubo2x2(pegatinasIniciales);
    EstadoCubo2x2 objetivo = EstadoCubo2x2.resuelto();

    if (inicial.estaResuelto || inicial.hashEstado == objetivo.hashEstado) {
      debugPrint("[SOLVER] Cubo ya resuelto. Cortocircuito.");
      return [];
    }

    // Movimientos posibles del cubo 2x2 (6 caras × 3 tipos = 18 movimientos)
    final List<String> todosLosMovimientos = [];
    for (var c in ['U', 'D', 'R', 'L', 'F', 'B']) {
      for (var m in ['', "'", '2']) {
        todosLosMovimientos.add(c + m);
      }
    }

    // --- COLAS Y MAPAS DE VISITADOS ---
    Queue<EstadoCubo2x2> qForward = Queue();
    Queue<EstadoCubo2x2> qBackward = Queue();

    qForward.add(inicial);
    qBackward.add(objetivo);

    Map<String, List<String>> visitadosF = {inicial.hashEstado: []};
    Map<String, List<String>> visitadosB = {objetivo.hashEstado: []};

    // CORRECCIÓN: Contadores de profundidad INDEPENDIENTES por cola.
    // El número de dios del 2x2 es 11 (QTM) o 14 (HTM).
    // Con BFS bidireccional, cada lado necesita llegar hasta depth 7 para garantizar
    // que cualquier estado a distancia <= 14 sea alcanzable (7+7=14).
    const int maxProfPorLado = 7;
    int profForward = 0;
    int profBackward = 0;

    debugPrint("[SOLVER] Profundidad máxima por lado: $maxProfPorLado (total: ${maxProfPorLado * 2})");

    List<String> resultadoFinal = [];

    // El loop continúa mientras alguna cola no haya alcanzado la profundidad máxima
    // y ambas colas tengan estados por explorar.
    while (qForward.isNotEmpty && qBackward.isNotEmpty) {
      bool hayInterseccion;

      // Expandimos la cola más pequeña para minimizar uso de RAM.
      // Solo expandimos una cola si no ha alcanzado su profundidad máxima.
      if (profForward <= profBackward && profForward < maxProfPorLado) {
        debugPrint("[SOLVER] Expandiendo FORWARD, depth: ${profForward + 1}, cola size: ${qForward.length}");
        hayInterseccion = _expandirNivel(
          qForward, visitadosF, visitadosB,
          todosLosMovimientos, resultadoFinal, true
        );
        profForward++;
      } else if (profBackward < maxProfPorLado) {
        debugPrint("[SOLVER] Expandiendo BACKWARD, depth: ${profBackward + 1}, cola size: ${qBackward.length}");
        hayInterseccion = _expandirNivel(
          qBackward, visitadosB, visitadosF,
          todosLosMovimientos, resultadoFinal, false
        );
        profBackward++;
      } else {
        // Ambas colas llegaron al máximo sin encontrar solución.
        break;
      }

      if (hayInterseccion) {
        debugPrint("✅ [SOLVER] Solución encontrada. Pasos: ${resultadoFinal.length}");
        debugPrint("[SOLVER] Solución: $resultadoFinal");
        return _optimizarSolucion(resultadoFinal);
      }
    }

    // Si el árbol se agota completamente sin solución, el estado es físicamente imposible.
    // (Ejemplo: pieza desmontada y recolocada con giro de esquina)
    debugPrint("❌ [SOLVER] Sin solución a profundidad ${maxProfPorLado * 2}. Estado inválido.");
    debugPrint("[SOLVER] Visitados forward: ${visitadosF.length}, backward: ${visitadosB.length}");
    throw Exception(
      "Mezcla inalcanzable. Revisa físicamente tu cubo, podría tener una esquina mal ensamblada."
    );
  }

  static bool _expandirNivel(
    Queue<EstadoCubo2x2> cola,
    Map<String, List<String>> visitados,
    Map<String, List<String>> visitadosOtroLado,
    List<String> todosLosMovimientos,
    List<String> resultadoFinal,
    bool esHaciaAdelante,
  ) {
    int tamanoNivel = cola.length;

    for (int i = 0; i < tamanoNivel; i++) {
      EstadoCubo2x2 actual = cola.removeFirst();
      List<String> rutaActual = visitados[actual.hashEstado]!;

      // Para la poda, usamos la cara del último movimiento en la ruta actual.
      // Para backward, la ruta almacena movimientos del objetivo hacia el estado,
      // que cuando se invierten para la solución siguen siendo válidos para la poda.
      String caraAnterior = rutaActual.isNotEmpty ? rutaActual.last[0] : '';

      for (String mov in todosLosMovimientos) {
        String caraMovimiento = mov[0];

        // Poda de árbol: elimina movimientos redundantes consecutivos
        if (_esMovimientoRedundante(caraMovimiento, caraAnterior)) continue;

        EstadoCubo2x2 vecino = actual.aplicarMovimiento(mov);
        String hashVecino = vecino.hashEstado;

        // ¡Colisión! Las dos búsquedas se encontraron
        if (visitadosOtroLado.containsKey(hashVecino)) {
          List<String> rutaOtro = visitadosOtroLado[hashVecino]!;

          if (esHaciaAdelante) {
            // La solución = ruta forward + movimiento actual + inversa de ruta backward
            resultadoFinal.addAll(rutaActual);
            resultadoFinal.add(mov);
            resultadoFinal.addAll(rutaOtro.reversed.map(_invertirMovimiento));
          } else {
            // La solución = ruta forward + inversa del movimiento actual + inversa de ruta backward
            resultadoFinal.addAll(rutaOtro);
            resultadoFinal.add(_invertirMovimiento(mov));
            resultadoFinal.addAll(rutaActual.reversed.map(_invertirMovimiento));
          }
          return true;
        }

        if (!visitados.containsKey(hashVecino)) {
          visitados[hashVecino] = List.from(rutaActual)..add(mov);
          cola.add(vecino);
        }
      }
    }
    return false;
  }

  /// Poda del árbol de búsqueda: evita mover la misma cara dos veces seguidas (R R = R2)
  /// y evita pares de caras opuestas que son conmutativos (D U = U D, etc.)
  static bool _esMovimientoRedundante(String caraActual, String caraAnterior) {
    if (caraAnterior.isEmpty) return false;
    // Misma cara consecutiva (ya cubierto por el historial de movimientos, pero por seguridad)
    if (caraActual == caraAnterior) return true;
    // Pares de caras opuestas en orden no canónico (evitar estados duplicados)
    if (caraAnterior == 'U' && caraActual == 'D') return true;
    if (caraAnterior == 'R' && caraActual == 'L') return true;
    if (caraAnterior == 'F' && caraActual == 'B') return true;
    return false;
  }

  /// Inversión de movimientos usando teoría de grupos:
  /// X  -> X'  (inversa de horario es antihorario)
  /// X' -> X   (inversa de antihorario es horario)
  /// X2 -> X2  (doble giro es su propia inversa)
  static String _invertirMovimiento(String mov) {
    if (mov.length == 1) return mov + "'";
    if (mov[1] == "'") return mov[0];
    return mov; // X2 es su propia inversa
  }

  /// Limpia posibles redundancias en el empalme de las dos rutas BFS.
  /// Ejemplo: si la ruta forward termina en R y la backward empieza con R', se cancelan.
  static List<String> _optimizarSolucion(List<String> solucion) {
    List<String> limpia = List.from(solucion);
    bool huboCambio = true;

    while (huboCambio) {
      huboCambio = false;
      for (int i = 0; i < limpia.length - 1; i++) {
        String a = limpia[i];
        String b = limpia[i + 1];
        // Dos movimientos de la misma cara que se cancelan: X X' o X' X
        if (a[0] == b[0]) {
          String combinado = _combinarMovimientos(a, b);
          if (combinado.isEmpty) {
            // Se cancelan completamente (X X' = identidad)
            limpia.removeAt(i + 1);
            limpia.removeAt(i);
            huboCambio = true;
            break;
          } else if (combinado != a + b) {
            // Se reducen (X X = X2, X2 X = X', etc.)
            limpia[i] = combinado;
            limpia.removeAt(i + 1);
            huboCambio = true;
            break;
          }
        }
      }
    }

    return limpia;
  }

  /// Combina dos movimientos de la misma cara.
  /// Retorna el movimiento resultante, o cadena vacía si se cancelan.
  static String _combinarMovimientos(String a, String b) {
    String cara = a[0];
    // Contar cuartos de vuelta (1=horario, 2=doble, 3=antihorario)
    int girosA = a.length == 1 ? 1 : (a[1] == "'" ? 3 : 2);
    int girosB = b.length == 1 ? 1 : (b[1] == "'" ? 3 : 2);
    int total = (girosA + girosB) % 4;
    if (total == 0) return ''; // Se cancelan
    if (total == 1) return cara;
    if (total == 2) return cara + '2';
    return cara + "'"; // total == 3
  }
}

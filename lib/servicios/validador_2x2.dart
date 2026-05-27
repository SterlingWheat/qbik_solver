import 'package:flutter/material.dart';
import '../modelos/estado_cubo_2x2.dart';

class ResultadoValidacion2x2 {
  final bool esValido;
  final String? mensajeError;
  final EstadoCubo2x2? estadoCubo;

  ResultadoValidacion2x2.exito(this.estadoCubo)
      : esValido = true,
        mensajeError = null;

  ResultadoValidacion2x2.error(this.mensajeError)
      : esValido = false,
        estadoCubo = null;
}

class Validador2x2 {
  /// Mapeo oficial (Estándar WCA con Blanco Arriba, Verde Frente):
  /// 0: Blanco (U), 1: Rojo (R), 2: Verde (F)
  /// 3: Amarillo (D), 4: Naranja (L), 5: Azul (B)
  ///
  /// Pares de colores opuestos (nunca pueden tocarse en la misma pieza):
  /// Blanco(0) ↔ Amarillo(3), Rojo(1) ↔ Naranja(4), Verde(2) ↔ Azul(5)
  static bool _sonOpuestos(int c1, int c2) {
    if ((c1 == 0 && c2 == 3) || (c1 == 3 && c2 == 0)) return true; // Blanco - Amarillo
    if ((c1 == 1 && c2 == 4) || (c1 == 4 && c2 == 1)) return true; // Rojo - Naranja
    if ((c1 == 2 && c2 == 5) || (c1 == 5 && c2 == 2)) return true; // Verde - Azul
    return false;
  }

  /// Valida un arreglo plano de 24 colores (representación en cruz 2D).
  ///
  /// Convención del arreglo plano:
  ///   Índices 0-3:   Cara U (Arriba)
  ///   Índices 4-7:   Cara R (Derecha)
  ///   Índices 8-11:  Cara F (Frente)
  ///   Índices 12-15: Cara D (Abajo)
  ///   Índices 16-19: Cara L (Izquierda)
  ///   Índices 20-23: Cara B (Atrás)
  ///   Cada cara: [0=sup-izq, 1=sup-der, 2=inf-izq, 3=inf-der] visto desde fuera.
  static ResultadoValidacion2x2 validarArregloPlano(List<Color?> pegatinasUI) {
    // --- DEBUG: Imprimir estado recibido ---
    debugPrint("=== [VALIDADOR 2x2] INICIANDO VALIDACIÓN ===");

    // 1. Verificar que no faltan stickers
    int faltantes = pegatinasUI.where((c) => c == null).length;
    if (faltantes > 0) {
      debugPrint("[VALIDADOR] FALLO: Faltan $faltantes stickers.");
      return ResultadoValidacion2x2.error(
        "Faltan pintar $faltantes piezas. Revisa el mapa en cruz."
      );
    }

    // 2. Convertir colores a enteros matemáticos
    List<int> pegatinas = [];
    try {
      for (Color? c in pegatinasUI) {
        pegatinas.add(_colorAEntero(c!));
      }
    } catch (e) {
      debugPrint("[VALIDADOR] FALLO: Color inválido detectado.");
      return ResultadoValidacion2x2.error("Se ha detectado un color inválido.");
    }

    debugPrint("[VALIDADOR] Pegatinas convertidas (U/R/F/D/L/B):");
    debugPrint("  U: ${pegatinas.sublist(0, 4)}");
    debugPrint("  R: ${pegatinas.sublist(4, 8)}");
    debugPrint("  F: ${pegatinas.sublist(8, 12)}");
    debugPrint("  D: ${pegatinas.sublist(12, 16)}");
    debugPrint("  L: ${pegatinas.sublist(16, 20)}");
    debugPrint("  B: ${pegatinas.sublist(20, 24)}");

    // 3. Verificar conteo: exactamente 4 de cada color (0-5)
    Map<int, int> conteo = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (int p in pegatinas) {
      if (!conteo.containsKey(p)) {
        debugPrint("[VALIDADOR] FALLO: Color inválido en arreglo: $p");
        return ResultadoValidacion2x2.error("Se detectó un color inválido en el cubo.");
      }
      conteo[p] = conteo[p]! + 1;
    }

    for (var entry in conteo.entries) {
      if (entry.value != 4) {
        String nombreColor = _obtenerNombreColor(entry.key);
        debugPrint("[VALIDADOR] FALLO: Color $nombreColor tiene ${entry.value} stickers (necesita 4).");
        return ResultadoValidacion2x2.error(
          "Error de cantidad: Tienes ${entry.value} piezas de color $nombreColor.\n"
          "En un cubo 2x2 debe haber exactamente 4 de cada color."
        );
      }
    }
    debugPrint("[VALIDADOR] Conteo de colores: OK (4 de cada uno).");

    // 4. Verificar integridad física de las 8 esquinas
    //
    // Las 8 esquinas del cubo 2x2, definidas por los índices de sus 3 stickers:
    //   Esquina      = [sticker_cara1, sticker_cara2, sticker_cara3]
    //   Orden: [U_o_D, cara_lateral_1, cara_lateral_2]
    //
    // Mapeo validado:
    //   Cara 0 (U): [0=sup-izq, 1=sup-der, 2=inf-izq, 3=inf-der]
    //   Cara 1 (R): [4=sup-izq, 5=sup-der, 6=inf-izq, 7=inf-der]
    //   Cara 2 (F): [8=sup-izq, 9=sup-der, 10=inf-izq, 11=inf-der]
    //   Cara 3 (D): [12=sup-izq, 13=sup-der, 14=inf-izq, 15=inf-der]
    //   Cara 4 (L): [16=sup-izq, 17=sup-der, 18=inf-izq, 19=inf-der]
    //   Cara 5 (B): [20=sup-izq, 21=sup-der, 22=inf-izq, 23=inf-der]
    //   (Todo "visto desde fuera de esa cara")
    final List<List<int>> esquinas = [
      [2,  8,  17], // UFL: U[inf-izq]=2,   F[sup-izq]=8,   L[sup-der]=17
      [3,  9,   4], // UFR: U[inf-der]=3,   F[sup-der]=9,   R[sup-izq]=4
      [1,  5,  20], // URB: U[sup-der]=1,   R[sup-der]=5,   B[sup-izq]=20
      [0, 16,  21], // ULB: U[sup-izq]=0,   L[sup-izq]=16,  B[sup-der]=21
      [12, 10, 19], // DFL: D[sup-izq]=12,  F[inf-izq]=10,  L[inf-der]=19
      [13, 11,  6], // DFR: D[sup-der]=13,  F[inf-der]=11,  R[inf-izq]=6
      [15,  7, 22], // DRB: D[inf-der]=15,  R[inf-der]=7,   B[inf-izq]=22
      [14, 18, 23], // DLB: D[inf-izq]=14,  L[inf-izq]=18,  B[inf-der]=23
    ];

    debugPrint("[VALIDADOR] Verificando 8 esquinas físicas:");
    for (int i = 0; i < esquinas.length; i++) {
      int c1 = pegatinas[esquinas[i][0]];
      int c2 = pegatinas[esquinas[i][1]];
      int c3 = pegatinas[esquinas[i][2]];

      String nombreEsquina = _nombreEsquina(i);
      String colores =
          "${_obtenerNombreColor(c1)}, ${_obtenerNombreColor(c2)}, ${_obtenerNombreColor(c3)}";
      debugPrint("  $nombreEsquina (idx ${esquinas[i]}): $colores");

      // Regla 1: Los 3 stickers de una esquina deben ser de colores diferentes
      if (c1 == c2 || c1 == c3 || c2 == c3) {
        debugPrint("  ❌ FALLO: Colores repetidos en esquina $nombreEsquina.");
        return ResultadoValidacion2x2.error(
          "Error en esquina $nombreEsquina:\n"
          "Pintaste [$colores].\n"
          "¡Una pieza real no puede tener colores repetidos!"
        );
      }

      // Regla 2: Ninguno de los 3 pares puede ser de colores opuestos
      if (_sonOpuestos(c1, c2) || _sonOpuestos(c1, c3) || _sonOpuestos(c2, c3)) {
        debugPrint("  ❌ FALLO: Colores opuestos en esquina $nombreEsquina.");
        return ResultadoValidacion2x2.error(
          "Error en esquina $nombreEsquina:\n"
          "Pintaste [$colores].\n"
          "Los colores opuestos (Blanco/Amarillo, Verde/Azul, Rojo/Naranja)\n"
          "nunca pueden tocarse en la misma pieza."
        );
      }

      debugPrint("  ✅ OK");
    }

    debugPrint("[VALIDADOR] Todas las esquinas físicas son válidas.");
    debugPrint("[VALIDADOR] Estado del cubo: VÁLIDO para resolver.");

    return ResultadoValidacion2x2.exito(EstadoCubo2x2(pegatinas));
  }

  static int _colorAEntero(Color color) {
    if (color == Colors.white) return 0;   // U = Blanco
    if (color == Colors.red) return 1;     // R = Rojo
    if (color == Colors.green) return 2;   // F = Verde
    if (color == Colors.yellow) return 3;  // D = Amarillo
    if (color == Colors.orange) return 4;  // L = Naranja
    if (color == Colors.blue) return 5;    // B = Azul
    throw Exception("Color desconocido: $color");
  }

  static String _obtenerNombreColor(int colorEntero) {
    const nombres = ['Blanco', 'Rojo', 'Verde', 'Amarillo', 'Naranja', 'Azul'];
    if (colorEntero >= 0 && colorEntero < nombres.length) return nombres[colorEntero];
    return 'Desconocido';
  }

  static String _nombreEsquina(int indice) {
    const nombres = [
      'Superior-Frente-Izquierda',
      'Superior-Frente-Derecha',
      'Superior-Atrás-Derecha',
      'Superior-Atrás-Izquierda',
      'Inferior-Frente-Izquierda',
      'Inferior-Frente-Derecha',
      'Inferior-Atrás-Derecha',
      'Inferior-Atrás-Izquierda',
    ];
    if (indice >= 0 && indice < nombres.length) return nombres[indice];
    return 'Desconocida';
  }
}

import 'package:flutter/material.dart';
import '../../modelos/estado_cubo_3x3.dart';

class ResultadoValidacion3x3 {
  final bool esValido;
  final String? mensajeError;
  final EstadoCubo3x3? estadoCubo;

  ResultadoValidacion3x3.exito(this.estadoCubo)
      : esValido = true,
        mensajeError = null;

  ResultadoValidacion3x3.error(this.mensajeError)
      : esValido = false,
        estadoCubo = null;
}

/// Validador riguroso de integridad física y matemática para el Cubo Rubik 3x3.
/// 
/// Convención WCA (World Cube Association):
///   Cara 0 = U (Arriba)   → Color: Blanco
///   Cara 1 = R (Derecha)  → Color: Rojo
///   Cara 2 = F (Frente)   → Color: Verde
///   Cara 3 = D (Abajo)    → Color: Amarillo
///   Cara 4 = L (Izquierda)→ Color: Naranja
///   Cara 5 = B (Atrás)    → Color: Azul
/// 
/// MAPEO UI → MODELO:
///   GestorIngreso3x3 almacena: caras[0]=U, caras[1]=F, caras[2]=R,
///                               caras[3]=D, caras[4]=B, caras[5]=L
///   El validador reordena al arreglo WCA: [U, R, F, D, L, B]
///   = [caras[0], caras[2], caras[1], caras[3], caras[5], caras[4]]
class Validador3x3 {
  // Pares de colores opuestos en WCA (nunca pueden tocarse en la misma pieza)
  static bool _sonOpuestos(int c1, int c2) {
    if ((c1 == 0 && c2 == 3) || (c1 == 3 && c2 == 0)) return true; // Blanco↔Amarillo
    if ((c1 == 1 && c2 == 4) || (c1 == 4 && c2 == 1)) return true; // Rojo↔Naranja
    if ((c1 == 2 && c2 == 5) || (c1 == 5 && c2 == 2)) return true; // Verde↔Azul
    return false;
  }

  /// Valida la matriz 2D del GestorIngreso3x3 y construye el estado matemático.
  static ResultadoValidacion3x3 validarIngresoUI(List<List<Color?>> carasUI) {
    debugPrint("=== [VALIDADOR 3x3] INICIANDO VALIDACIÓN ===");

    // 1. Verificar que las 6 caras estén completamente pintadas (54 stickers)
    for (int i = 0; i < carasUI.length; i++) {
      int faltantes = carasUI[i].where((c) => c == null).length;
      if (faltantes > 0) {
        return ResultadoValidacion3x3.error(
            "Faltan pintar $faltantes piezas en la Cara ${i + 1}.");
      }
    }

    // 2. Remapeo al orden WCA: [U, R, F, D, L, B]
    List<Color> pegatinasOrdenadas = [];
    pegatinasOrdenadas.addAll(carasUI[0].cast<Color>()); // U (Blanco)
    pegatinasOrdenadas.addAll(carasUI[2].cast<Color>()); // R (Rojo)
    pegatinasOrdenadas.addAll(carasUI[1].cast<Color>()); // F (Verde)
    pegatinasOrdenadas.addAll(carasUI[3].cast<Color>()); // D (Amarillo)
    pegatinasOrdenadas.addAll(carasUI[5].cast<Color>()); // L (Naranja)
    pegatinasOrdenadas.addAll(carasUI[4].cast<Color>()); // B (Azul)

    List<int> pegatinas;
    try {
      pegatinas = pegatinasOrdenadas.map((c) => _colorAEntero(c)).toList();
    } catch (e) {
      debugPrint("[VALIDADOR 3x3] FALLO: Color no reconocido: $e");
      return ResultadoValidacion3x3.error(
          "Se ha detectado un color no reconocido en el cubo.");
    }

    debugPrint("[VALIDADOR 3x3] Pegatinas WCA generadas:");
    debugPrint("  U: ${pegatinas.sublist(0, 9)}");
    debugPrint("  R: ${pegatinas.sublist(9, 18)}");
    debugPrint("  F: ${pegatinas.sublist(18, 27)}");
    debugPrint("  D: ${pegatinas.sublist(27, 36)}");
    debugPrint("  L: ${pegatinas.sublist(36, 45)}");
    debugPrint("  B: ${pegatinas.sublist(45, 54)}");

    // 3. Verificar exactamente 9 stickers por color (0..5)
    final Map<int, int> conteo = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (int p in pegatinas) {
      if (!conteo.containsKey(p)) {
        return ResultadoValidacion3x3.error(
            "Se detectó un color inválido en el cubo.");
      }
      conteo[p] = conteo[p]! + 1;
    }
    for (var entry in conteo.entries) {
      if (entry.value != 9) {
        String colorDesc = _obtenerNombreColor(entry.key);
        debugPrint(
            "[VALIDADOR 3x3] FALLO: ${entry.value} piezas de $colorDesc (necesita 9)");
        return ResultadoValidacion3x3.error(
          "Error: Tienes ${entry.value} piezas de color $colorDesc.\n"
          "Deben ser exactamente 9 de cada uno.",
        );
      }
    }
    debugPrint("[VALIDADOR 3x3] Conteo de 9x6: OK");

    // 4. Verificar que los centros sean los correctos (0=U, 1=R, 2=F, 3=D, 4=L, 5=B)
    final centrosEsperados = [0, 1, 2, 3, 4, 5];
    for (int i = 0; i < 6; i++) {
      int centroReal = pegatinas[i * 9 + 4];
      if (centroReal != centrosEsperados[i]) {
        debugPrint(
            "[VALIDADOR 3x3] FALLO: Centro cara $i tiene $centroReal, esperado ${centrosEsperados[i]}");
        return ResultadoValidacion3x3.error(
            "Los centros del cubo tienen un color incorrecto. "
            "Verifica que usaste el color correcto para cada cara.");
      }
    }
    debugPrint("[VALIDADOR 3x3] Centros correctos: OK");

    // 5. Mapeo de aristas (12 piezas de 2 stickers cada una).
    final List<List<int>> aristas = [
      [1, 46],  // UB
      [3, 37],  // UL
      [5, 10],  // UR
      [7, 19],  // UF
      [21, 41], // FL
      [23, 12], // FR
      [50, 39], // BL
      [48, 14], // BR
      [28, 25], // DF
      [30, 43], // DL
      [32, 16], // DR
      [34, 52], // DB
    ];

    // 6. Mapeo de esquinas (8 piezas de 3 stickers cada una).
    final List<List<int>> esquinas = [
      [0, 47, 36],  // UBL
      [2, 45, 11],  // UBR
      [6, 18, 38],  // UFL
      [8, 20, 9],   // UFR
      [27, 24, 44], // DFL
      [29, 26, 15], // DFR
      [33, 53, 42], // DBL
      [35, 51, 17], // DBR
    ];

    // 7. Validar las 12 ARISTAS
    debugPrint("[VALIDADOR 3x3] Verificando aristas:");
    final Set<String> aristasEncontradas = {};
    for (var idx in aristas) {
      int c1 = pegatinas[idx[0]];
      int c2 = pegatinas[idx[1]];
      String cn1 = _obtenerNombreColor(c1);
      String cn2 = _obtenerNombreColor(c2);

      if (c1 == c2) {
        return ResultadoValidacion3x3.error(
            "Una arista no puede tener el mismo color en ambos lados ($cn1).");
      }
      if (_sonOpuestos(c1, c2)) {
        return ResultadoValidacion3x3.error(
            "Imposible físico: una arista tiene colores opuestos ($cn1 y $cn2).");
      }

      final List<int> firma = [c1, c2]..sort();
      final String hash = firma.join('-');
      if (aristasEncontradas.contains(hash)) {
        return ResultadoValidacion3x3.error(
            "Pieza duplicada: hay más de una arista [$cn1, $cn2].");
      }
      aristasEncontradas.add(hash);
    }
    debugPrint("[VALIDADOR 3x3] Aristas OK");

    // 8. Validar las 8 ESQUINAS
    debugPrint("[VALIDADOR 3x3] Verificando esquinas:");
    final Set<String> esquinasEncontradas = {};
    for (var idx in esquinas) {
      int c1 = pegatinas[idx[0]];
      int c2 = pegatinas[idx[1]];
      int c3 = pegatinas[idx[2]];
      String cn1 = _obtenerNombreColor(c1);
      String cn2 = _obtenerNombreColor(c2);
      String cn3 = _obtenerNombreColor(c3);

      if (c1 == c2 || c1 == c3 || c2 == c3) {
        return ResultadoValidacion3x3.error(
            "Una esquina tiene colores repetidos: [$cn1, $cn2, $cn3].");
      }
      if (_sonOpuestos(c1, c2) || _sonOpuestos(c1, c3) || _sonOpuestos(c2, c3)) {
        return ResultadoValidacion3x3.error(
            "Imposible físico: una esquina contiene colores opuestos.");
      }

      final List<int> firma = [c1, c2, c3]..sort();
      final String hash = firma.join('-');
      if (esquinasEncontradas.contains(hash)) {
        return ResultadoValidacion3x3.error(
            "Pieza duplicada: hay más de una esquina [$cn1, $cn2, $cn3].");
      }
      esquinasEncontradas.add(hash);
    }
    debugPrint("[VALIDADOR 3x3] Esquinas OK");

    debugPrint("[VALIDADOR 3x3] ✅ CUBO VÁLIDO. Listo para resolver.");
    return ResultadoValidacion3x3.exito(EstadoCubo3x3(pegatinas));
  }

  static int _colorAEntero(Color color) {
    if (color == Colors.white) return 0;
    if (color == Colors.red) return 1;
    if (color == Colors.green) return 2;
    if (color == Colors.yellow) return 3;
    if (color == Colors.orange) return 4;
    if (color == Colors.blue) return 5;
    throw Exception("Color desconocido: $color");
  }

  static String _obtenerNombreColor(int colorEntero) {
    const nombres = ['Blanco', 'Rojo', 'Verde', 'Amarillo', 'Naranja', 'Azul'];
    if (colorEntero >= 0 && colorEntero < nombres.length) return nombres[colorEntero];
    return 'Desconocido($colorEntero)';
  }
}
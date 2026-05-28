import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Gestor de estado para el Escáner Inteligente del Cubo 2x2.
/// Maneja el estado de las 6 caras detectadas por la cámara y su conversión
/// al arreglo plano matemático requerido por el Validador y Solver.
class GestorEscaner2x2 extends GetxController {
  // Almacena las 6 caras del cubo. Cada cara tiene 4 colores (si ya fue escaneada) o null.
  // Índices WCA mapeados: 
  // 0:U (Arriba), 1:R (Derecha), 2:F (Frente), 3:D (Abajo), 4:L (Izquierda), 5:B (Atrás)
  final List<List<Color>?> _caras = List.filled(6, null);

  /// Verifica si una cara específica ya fue capturada por la cámara y la IA
  bool caraEstaEscaneada(int indiceCara) {
    return _caras[indiceCara] != null;
  }

  /// Retorna los 4 colores de una cara específica (o una lista vacía si aún no se escanea)
  List<Color> obtenerColoresCara(int indiceCara) {
    return _caras[indiceCara] ?? [];
  }

  /// Guarda los 4 colores detectados por la cámara en la cara correspondiente
  /// y notifica a la UI para que actualice la miniatura en la cruz 2D.
  void guardarCaraEscaneada(int indiceCara, List<Color> colores) {
    if (colores.length != 4) {
      throw Exception("Error del Escáner: Una cara de 2x2 debe detectar exactamente 4 colores.");
    }
    _caras[indiceCara] = List.from(colores); // Clonamos la lista por seguridad
    update(); // Reemplaza notifyListeners()
  }

  /// Verifica si el usuario ya escaneó las 6 caras necesarias para resolver el cubo
  bool estaCompleto() {
    return !_caras.contains(null);
  }

  /// Reinicia todo el escáner borrando las caras guardadas (Botón de refresh en la UI)
  void reiniciarEscaner() {
    for (int i = 0; i < 6; i++) {
      _caras[i] = null;
    }
    update(); // Reemplaza notifyListeners()
  }

  /// Convierte las 6 caras (24 stickers en total) a un solo arreglo plano
  /// en el formato oficial WCA que espera el [Validador2x2] y el [SolverBFS2x2].
  /// 
  /// Formato de salida: [ U0..U3, R0..R3, F0..F3, D0..D3, L0..L3, B0..B3 ]
  List<Color?> obtenerPegatinasPlanas() {
    List<Color?> pegatinasPlanas = [];
    
    // Como los índices de PantallaEscaner2x2 (0 a 5) ya coinciden exactamente 
    // con el orden WCA (U, R, F, D, L, B), solo tenemos que iterar en orden.
    for (int i = 0; i < 6; i++) {
      if (_caras[i] != null) {
        pegatinasPlanas.addAll(_caras[i]!);
      } else {
        // Rellenar con nulls si la cara no está escaneada 
        // (el validador se encargará de lanzar el error correspondiente si esto ocurre)
        pegatinasPlanas.addAll([null, null, null, null]);
      }
    }
    
    return pegatinasPlanas;
  }
}
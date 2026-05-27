import 'package:flutter/material.dart';

class GestorIngreso3x3 extends ChangeNotifier {
  // 6 caras, cada una con 9 piezas (3x3).
  late List<List<Color?>> caras;
  
  int caraActual = 0;
  Color? colorSeleccionado;

  // Paleta de colores base disponibles para pintar
  static const List<Color> coloresOficiales = [
    Colors.white, Colors.yellow, Colors.red,
    Colors.orange, Colors.green, Colors.blue,
  ];

  // Nombres adaptados a tu secuencia para que el minimapa sea muy claro
  final List<String> nombresCaras = [
    'Blanco', 'Verde', 'Rojo', 'Amarillo', 'Azul', 'Naranja'
  ];

  // Centros fijos exactamente en el orden de tu secuencia
  final List<Color> centrosFijos = [
    Colors.white,   // 0: Cara Inicial
    Colors.green,   // 1: Tras girar a la derecha
    Colors.red,     // 2: Tras girar arriba
    Colors.yellow,  // 3: Tras girar a la derecha
    Colors.blue,    // 4: Tras girar arriba
    Colors.orange,  // 5: Tras girar a la derecha
  ];

  GestorIngreso3x3() {
    _inicializarCaras();
  }

  void _inicializarCaras() {
    caras = List.generate(6, (indexCara) {
      List<Color?> cara = List.filled(9, null);
      cara[4] = centrosFijos[indexCara]; // La pieza central es inamovible
      return cara;
    });
  }

  void seleccionarColor(Color color) {
    colorSeleccionado = color;
    notifyListeners();
  }

  void pintarPieza(int indicePieza) {
    if (colorSeleccionado == null) return;
    
    // Regla de Oro del 3x3: Los centros NO se pueden pintar ni borrar manualmente
    if (indicePieza == 4) return; 

    // Si la pieza ya tiene el color seleccionado, actuamos como borrador
    if (caras[caraActual][indicePieza] == colorSeleccionado) {
      caras[caraActual][indicePieza] = null;
      notifyListeners();
      return;
    }

    // En un 3x3 el límite máximo es de 9 piezas por color
    if (obtenerCantidadColor(colorSeleccionado!) >= 9) return; 

    caras[caraActual][indicePieza] = colorSeleccionado;
    notifyListeners();
  }

  int obtenerCantidadColor(Color color) {
    int contador = 0;
    for (var cara in caras) {
      for (var pieza in cara) {
        if (pieza == color) contador++;
      }
    }
    return contador;
  }

  bool get estaCompletamentePintado {
    for (var cara in caras) {
      if (cara.contains(null)) return false;
    }
    return true;
  }

  // --- NUEVOS MÉTODOS AÑADIDOS PARA LA UI ---
  
  /// Borra todas las pegatinas respetando los centros fijos
  void limpiarTodo() {
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 9; j++) {
        if (j != 4) caras[i][j] = null;
      }
    }
    notifyListeners();
  }

  /// Llena el cubo en su estado resuelto (ideal para testing)
  void llenarResuelto() {
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 9; j++) {
        caras[i][j] = centrosFijos[i];
      }
    }
    notifyListeners();
  }

  // --- NAVEGACIÓN Y CONTEXTO VISUAL ---
  
  bool get movimientoActualEsHorizontal => caraActual % 2 == 0; 
  String get nombreCaraActual => nombresCaras[caraActual];
  String get textoDireccionSiguiente => movimientoActualEsHorizontal ? 'Girar a Derecha' : 'Girar Arriba';
  IconData get iconoSiguiente => movimientoActualEsHorizontal ? Icons.arrow_forward_rounded : Icons.arrow_upward_rounded;
  IconData get iconoAnterior => (caraActual - 1) % 2 == 0 ? Icons.arrow_back_rounded : Icons.arrow_downward_rounded;

  void avanzarCara() {
    if (caraActual < 5) {
      caraActual++;
      notifyListeners();
    }
  }

  void retrocederCara() {
    if (caraActual > 0) {
      caraActual--;
      notifyListeners();
    }
  }
}
import 'package:flutter/material.dart';

/// Gestor de estado para el ingreso manual del cubo 2x2.
/// Maneja la lógica de la paleta de colores y el estado de las 24 pegatinas en formato lineal.
class GestorIngreso2x2 extends ChangeNotifier {
  // Arreglo lineal de 24 posiciones para el cubo en formato cruz (Net 2D).
  final List<Color?> _pegatinas = List.filled(24, null);

  List<Color?> get pegatinas => List.unmodifiable(_pegatinas);

  // El color que el usuario tiene actualmente seleccionado en la paleta inferior
  Color? _colorSeleccionado;
  Color? get colorSeleccionado => _colorSeleccionado;

  /// Cambia el color activo en el "pincel" del usuario
  void seleccionarColor(Color color) {
    _colorSeleccionado = color;
    notifyListeners();
  }

  /// Pinta una pegatina específica en el índice [0-23] con límite de 4 colores
  void pintarPegatina(int indice) {
    if (_colorSeleccionado != null) {
      
      // Comportamiento de borrador: Si tocas una pieza que ya tiene el color seleccionado, la despinta
      if (_pegatinas[indice] == _colorSeleccionado) {
        _pegatinas[indice] = null;
        notifyListeners();
        return;
      }

      // Validar límite máximo de 4 pegatinas por color
      int cantidadActual = _pegatinas.where((c) => c == _colorSeleccionado).length;
      
      if (cantidadActual >= 4) {
        return; // Ignora el toque porque ya hay 4 piezas de este color
      }

      _pegatinas[indice] = _colorSeleccionado;
      notifyListeners();
    }
  }

  /// Borra todas las pegatinas (botón de reinicio)
  void limpiarTodo() {
    for (int i = 0; i < 24; i++) {
      _pegatinas[i] = null;
    }
    notifyListeners();
  }

  /// Función didáctica/de pruebas: Llena el cubo en su estado resuelto perfecto
  void llenarResuelto() {
    // Orden WCA: U=Blanco, R=Rojo, F=Verde, D=Amarillo, L=Naranja, B=Azul
    final colores = [
      Colors.white, Colors.red, Colors.green,
      Colors.yellow, Colors.orange, Colors.blue
    ];
    
    for (int cara = 0; cara < 6; cara++) {
      for (int i = 0; i < 4; i++) {
        _pegatinas[cara * 4 + i] = colores[cara];
      }
    }
    notifyListeners();
  }

  /// Verifica si el usuario ya llenó los 24 cuadros
  bool estaCompleto() {
    return !_pegatinas.contains(null);
  }
}
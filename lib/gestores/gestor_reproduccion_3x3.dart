import 'dart:async';
import 'package:flutter/material.dart';
import '../modelos/estado_cubo_3x3.dart';

/// Controlador de estado para manejar la "Línea de Tiempo" de la resolución del 3x3.
/// Actúa como el motor lógico detrás de los controles de Play/Pause/Avanzar/Retroceder.
class GestorReproduccion3x3 extends ChangeNotifier {
  final EstadoCubo3x3 _estadoInicial;
  
  /// La lista de movimientos calculada por el Solver (Ej: ['R', 'U', 'R''])
  final List<String> algoritmoSolucion;
  
  /// Línea de tiempo pre-calculada con el estado exacto (matemático) del cubo en cada paso.
  /// Esto permite que el usuario pueda saltar del paso 2 al 40 instantáneamente (O(1)).
  late final List<EstadoCubo3x3> _historialEstados;

  int _pasoActual = 0;
  bool _estaReproduciendo = false;
  Timer? _timerReproduccion;

  GestorReproduccion3x3({
    required EstadoCubo3x3 estadoInicial,
    required this.algoritmoSolucion,
  }) : _estadoInicial = estadoInicial {
    _precalcularLineaDeTiempo();
  }

  @override
  void dispose() {
    _timerReproduccion?.cancel();
    super.dispose();
  }

  /// Procesa todo el algoritmo en milisegundos durante la inicialización
  /// para tener los fotogramas listos para la UI.
  void _precalcularLineaDeTiempo() {
    _historialEstados = [_estadoInicial];
    EstadoCubo3x3 estadoTemporal = _estadoInicial;

    for (String movimiento in algoritmoSolucion) {
      estadoTemporal = estadoTemporal.aplicarMovimiento(movimiento);
      _historialEstados.add(estadoTemporal);
    }
  }

  // --- GETTERS PARA LA UI ---

  /// Retorna el estado matemático del cubo en el fotograma exacto actual.
  EstadoCubo3x3 get estadoActual => _historialEstados[_pasoActual];

  int get pasoActual => _pasoActual;
  int get totalPasos => algoritmoSolucion.length;
  bool get estaReproduciendo => _estaReproduciendo;

  /// Retorna el movimiento exacto que se debe aplicar en este momento (Ej: "R'")
  String get movimientoActualStr {
    if (_pasoActual == 0) return "Inicio";
    return algoritmoSolucion[_pasoActual - 1];
  }

  // --- CONTROLES DEL REPRODUCTOR ---

  /// Botón principal de Play/Pause
  void alternarReproduccion() {
    if (_estaReproduciendo) {
      pausar();
    } else {
      // Si el usuario presiona Play pero ya estamos en el final, reiniciamos desde cero.
      if (_pasoActual >= totalPasos) {
        _pasoActual = 0;
      }
      _reproducir();
    }
  }

  void _reproducir() {
    _estaReproduciendo = true;
    notifyListeners();

    // Reproducción a 1 movimiento por segundo. 
    // Ideal para que el usuario pueda seguir los pasos con su cubo físico.
    _timerReproduccion = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_pasoActual < totalPasos) {
        _pasoActual++;
        notifyListeners();
      } else {
        pausar(); // Auto-stop al terminar el algoritmo
      }
    });
  }

  void pausar() {
    _timerReproduccion?.cancel();
    _estaReproduciendo = false;
    notifyListeners();
  }

  void avanzar() {
    pausar(); // Pausar siempre la reproducción automática al interactuar manualmente
    if (_pasoActual < totalPasos) {
      _pasoActual++;
      notifyListeners();
    }
  }

  void retroceder() {
    pausar();
    if (_pasoActual > 0) {
      _pasoActual--;
      notifyListeners();
    }
  }

  /// Conecta el Slider (barra de progreso) de la UI con el estado del gestor.
  void saltarA(int paso) {
    pausar();
    if (paso >= 0 && paso <= totalPasos) {
      _pasoActual = paso;
      notifyListeners();
    }
  }
}
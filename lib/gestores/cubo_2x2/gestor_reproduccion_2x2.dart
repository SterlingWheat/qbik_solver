import 'dart:async';
import 'package:get/get.dart';
import '../../modelos/estado_cubo_2x2.dart';

/// Controlador de estado para manejar la "Línea de Tiempo" de la resolución.
/// Actúa como el motor lógico detrás de los botones de un reproductor de video.
class GestorReproduccion2x2 extends GetxController {
  final EstadoCubo2x2 _estadoInicial;
  final List<String> algoritmoSolucion;
  
  // Línea de tiempo pre-calculada con el estado exacto del cubo en cada paso
  late final List<EstadoCubo2x2> _historialEstados;

  int _pasoActual = 0;
  bool _estaReproduciendo = false;
  Timer? _timerReproduccion;

  GestorReproduccion2x2({
    required EstadoCubo2x2 estadoInicial,
    required this.algoritmoSolucion,
  }) : _estadoInicial = estadoInicial {
    _precalcularLineaDeTiempo();
  }

  // En GetX, dispose() se cambia por onClose()
  @override
  void onClose() {
    _timerReproduccion?.cancel();
    super.onClose();
  }

  /// Calcula matemáticamente cómo se ve el cubo en el paso 0, 1, 2... N
  /// Esto hace que navegar por la interfaz gráfica sea O(1) e instantáneo.
  void _precalcularLineaDeTiempo() {
    _historialEstados = [_estadoInicial];
    EstadoCubo2x2 estadoTemporal = _estadoInicial;

    for (String movimiento in algoritmoSolucion) {
      estadoTemporal = estadoTemporal.aplicarMovimiento(movimiento);
      _historialEstados.add(estadoTemporal);
    }
  }

  // --- GETTERS ---

  /// Retorna el estado matemático del cubo en el fotograma actual.
  EstadoCubo2x2 get estadoActual => _historialEstados[_pasoActual];

  int get pasoActual => _pasoActual;
  int get totalPasos => algoritmoSolucion.length;
  bool get estaReproduciendo => _estaReproduciendo;

  /// Retorna el movimiento exacto que se debe aplicar en este momento (Ej: "R'")
  String get movimientoActualStr {
    if (_pasoActual == 0) return "Inicio";
    return algoritmoSolucion[_pasoActual - 1];
  }

  // --- CONTROLES DEL REPRODUCTOR ---

  void alternarReproduccion() {
    if (_estaReproduciendo) {
      pausar();
    } else {
      // Si ya terminó, reinicia desde cero al presionar Play
      if (_pasoActual >= totalPasos) {
        _pasoActual = 0;
      }
      _reproducir();
    }
  }

  void _reproducir() {
    _estaReproduciendo = true;
    update(); // Reemplaza notifyListeners()

    _timerReproduccion = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_pasoActual < totalPasos) {
        _pasoActual++;
        update(); // Reemplaza notifyListeners()
      } else {
        pausar(); // Se detiene automáticamente al llegar al final
      }
    });
  }

  void pausar() {
    _timerReproduccion?.cancel();
    _estaReproduciendo = false;
    update(); // Reemplaza notifyListeners()
  }

  void avanzar() {
    pausar();
    if (_pasoActual < totalPasos) {
      _pasoActual++;
      update(); // Reemplaza notifyListeners()
    }
  }

  void retroceder() {
    pausar();
    if (_pasoActual > 0) {
      _pasoActual--;
      update(); // Reemplaza notifyListeners()
    }
  }

  void saltarA(int paso) {
    pausar();
    if (paso >= 0 && paso <= totalPasos) {
      _pasoActual = paso;
      update(); // Reemplaza notifyListeners()
    }
  }
}
import 'dart:async';
import 'package:get/get.dart';
import '../../modelos/estado_cubo_2x2.dart';
import '../../gestores/globales/gestor_configuracion.dart';
import '../../gestores/globales/gestor_voz.dart';

/// Controlador de estado para manejar la "Línea de Tiempo" de la resolución.
/// Actúa como el motor lógico detrás de los botones de un reproductor de video.
class GestorReproduccion2x2 extends GetxController {
  final EstadoCubo2x2 _estadoInicial;
  final List<String> algoritmoSolucion;
  
  // Línea de tiempo pre-calculada con el estado exacto del cubo en cada paso
  late final List<EstadoCubo2x2> _historialEstados;

  int _pasoActual = 0;
  bool _estaReproduciendo = false;
  
  // Reemplazamos el Timer por un ID de ciclo para cancelar bucles asíncronos al pausar
  int _idReproduccionActual = 0; 

  GestorReproduccion2x2({
    required EstadoCubo2x2 estadoInicial,
    required this.algoritmoSolucion,
  }) : _estadoInicial = estadoInicial {
    _precalcularLineaDeTiempo();
  }

  @override
  void onClose() {
    _estaReproduciendo = false;
    _idReproduccionActual++;
    try {
      Get.find<GestorVoz>().detener();
    } catch (e) {
      // Ignorar si el gestor no está disponible
    }
    super.onClose();
  }

  void _precalcularLineaDeTiempo() {
    _historialEstados = [_estadoInicial];
    EstadoCubo2x2 estadoTemporal = _estadoInicial;

    for (String movimiento in algoritmoSolucion) {
      estadoTemporal = estadoTemporal.aplicarMovimiento(movimiento);
      _historialEstados.add(estadoTemporal);
    }
  }

  // --- GETTERS ---

  EstadoCubo2x2 get estadoActual => _historialEstados[_pasoActual];
  int get pasoActual => _pasoActual;
  int get totalPasos => algoritmoSolucion.length;
  bool get estaReproduciendo => _estaReproduciendo;

  String get movimientoActualStr {
    if (_pasoActual == 0) return "Inicio";
    return algoritmoSolucion[_pasoActual - 1];
  }

  // --- LÓGICA DE NARRACIÓN DE VOZ ---
  
  Future<void> _narrarPasoActual() async {
    try {
      final gestorConfig = Get.find<GestorConfiguracion>();
      if (gestorConfig.narracionVozActiva.value && _pasoActual > 0) {
        // Al usar await aquí, pausamos la ejecución hasta que la voz termine
        await Get.find<GestorVoz>().narrarMovimiento(movimientoActualStr);
      }
    } catch (e) {
      // Prevenir cuelgues si el gestor de voz no existe
    }
  }

  // --- CONTROLES DEL REPRODUCTOR ---

  void alternarReproduccion() {
    if (_estaReproduciendo) {
      pausar();
    } else {
      if (_pasoActual >= totalPasos) {
        _pasoActual = 0;
      }
      _reproducir();
    }
  }

  void _reproducir() async {
    _estaReproduciendo = true;
    _idReproduccionActual++;
    final int idCiclo = _idReproduccionActual; // Guardamos el ID de este bucle específico
    update();

    // Narramos el paso en el que estamos antes de empezar a avanzar
    if (_pasoActual > 0) {
      await _narrarPasoActual();
    }

    // Bucle asíncrono: avanza solo si seguimos reproduciendo y es el mismo clic de Play
    while (_estaReproduciendo && _pasoActual < totalPasos && _idReproduccionActual == idCiclo) {
      
      // Pequeña pausa natural antes del siguiente giro
      await Future.delayed(const Duration(milliseconds: 400));
      if (!_estaReproduciendo || _idReproduccionActual != idCiclo) break;

      _pasoActual++;
      update();

      final bool vozActiva = Get.find<GestorConfiguracion>().narracionVozActiva.value;
      
      if (vozActiva) {
        // El bucle se detiene automáticamente aquí hasta que la IA termine de hablar
        await _narrarPasoActual();
      } else {
        // Si no hay voz, aplicamos un temporizador estándar de 1 segundo
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    // Al terminar el algoritmo, auto-pausar
    if (_pasoActual >= totalPasos && _idReproduccionActual == idCiclo) {
      pausar();
    }
  }

  void pausar() {
    _estaReproduciendo = false;
    _idReproduccionActual++; // Esto "rompe" instantáneamente el bucle while superior
    
    try {
      Get.find<GestorVoz>().detener();
    } catch (e) {
      // Ignorar
    }
    
    update(); 
  }

  void avanzar() {
    pausar(); 
    if (_pasoActual < totalPasos) {
      _pasoActual++;
      _narrarPasoActual(); 
      update(); 
    }
  }

  void retroceder() {
    pausar(); 
    if (_pasoActual > 0) {
      _pasoActual--;
      _narrarPasoActual(); 
      update(); 
    }
  }

  void saltarA(int paso) {
    pausar(); 
    if (paso >= 0 && paso <= totalPasos) {
      _pasoActual = paso;
      _narrarPasoActual(); 
      update(); 
    }
  }
}
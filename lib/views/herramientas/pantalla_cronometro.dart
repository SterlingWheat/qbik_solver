import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../gestores/globales/gestor_configuracion.dart';
import '../../gestores/globales/gestor_estadisticas.dart';
import '../../widgets/comunes/fondo_decorativo.dart';
import '../../widgets/dialogos/dialogo_disciplina.dart';
import '../../widgets/dialogos/dialogo_guardar_tiempo.dart';

/// Controlador local para aislar la lógica temporal de la interfaz gráfica.
class CronometroController extends GetxController {
  String disciplinaActual = "Cubo 3x3"; 
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timerRenderizado;
  
  String tiempoMostrado = "00.000";
  bool estaCorriendo = false;

  @override
  void onReady() {
    super.onReady();
    // Se lanza automáticamente al terminar de dibujar la pantalla
    _preguntarDisciplina();
  }

  @override
  void onClose() {
    _timerRenderizado?.cancel();
    super.onClose();
  }

  Future<void> _preguntarDisciplina() async {
    final resultado = await Get.dialog<String>(
      const DialogoDisciplina(),
      barrierDismissible: false,
    );

    if (resultado != null) {
      disciplinaActual = resultado;
      update(['cabecera']); // Solo redibuja la zona con el ID 'cabecera'
    } else {
      Get.back(); // Regresa si el usuario presiona el botón físico de atrás
    }
  }

  void manejarToquePantalla() {
    Get.find<GestorConfiguracion>().ejecutarVibracion();
    if (estaCorriendo) {
      _detenerCronometro();
    } else {
      _iniciarCronometro();
    }
  }

  void _iniciarCronometro() {
    _stopwatch.reset();
    _stopwatch.start();
    estaCorriendo = true;
    update(['instruccion']); // Oculta el texto de ayuda
    
    // Timer a 60 FPS aprox (cada 16ms)
    _timerRenderizado = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _actualizarTiempoMostrado();
    });
  }

  Future<void> _detenerCronometro() async {
    _stopwatch.stop();
    _timerRenderizado?.cancel();
    estaCorriendo = false;
    _actualizarTiempoMostrado(); 
    update(['instruccion']); // Muestra de nuevo el texto de ayuda

    final guardar = await Get.dialog<bool>(
      DialogoGuardarTiempo(tiempo: tiempoMostrado, disciplina: disciplinaActual),
      barrierDismissible: false,
    );

    if (guardar == true) {
      // Guardar en el gestor global y navegar usando GetX
      final milisegundos = _stopwatch.elapsedMilliseconds;
      Get.find<GestorEstadisticas>().guardarTiempo(disciplinaActual, milisegundos);
      
      Get.offNamed('/estadisticas'); 
    } else {
      // Descartar tiempo
      _stopwatch.reset();
      tiempoMostrado = "00.000";
      update(['cronometro']);
    }
  }

  void _actualizarTiempoMostrado() {
    final msTotales = _stopwatch.elapsedMilliseconds;
    final minutos = (msTotales / 60000).floor();
    final segundos = ((msTotales % 60000) / 1000).floor();
    final ms = msTotales % 1000;

    String formateado = "";
    if (minutos > 0) {
      formateado += "$minutos:${segundos.toString().padLeft(2, '0')}.";
    } else {
      formateado += "${segundos.toString().padLeft(2, '0')}.";
    }
    formateado += ms.toString().padLeft(3, '0');

    tiempoMostrado = formateado;
    update(['cronometro']); // Actualización ultra-rápida solo del número
  }
}

class PantallaCronometro extends StatelessWidget {
  const PantallaCronometro({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el controlador para esta pantalla
    final controlador = Get.put(CronometroController());
    final colorTexto = Get.isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoDecorativo(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controlador.manejarToquePantalla,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CABECERA ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto),
                      onPressed: () {
                        Get.find<GestorConfiguracion>().ejecutarVibracion();
                        Get.back();
                      },
                    ),
                    GetBuilder<CronometroController>(
                      id: 'cabecera', // Solo se actualiza cuando cambia la disciplina
                      builder: (ctrl) => Text(
                        ctrl.disciplinaActual,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Get.theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // --- ÁREA CENTRAL DEL CRONÓMETRO ---
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Texto de instrucción
                      GetBuilder<CronometroController>(
                        id: 'instruccion',
                        builder: (ctrl) => AnimatedOpacity(
                          opacity: ctrl.estaCorriendo ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            'Toca en cualquier lugar para iniciar',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorTexto.withOpacity(0.5),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Texto del Tiempo Gigante (Optimizado a 60 FPS)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: GetBuilder<CronometroController>(
                            id: 'cronometro',
                            builder: (ctrl) => Text(
                              ctrl.tiempoMostrado,
                              style: TextStyle(
                                fontSize: 120,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: -2.0,
                                color: colorTexto,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
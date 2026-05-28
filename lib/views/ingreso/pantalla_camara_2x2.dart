import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../../servicios/ia/servicio_ia_vision.dart';
import '../../gestores/globales/gestor_configuracion.dart';

/// Controlador local para aislar toda la lógica compleja de la cámara y la IA
class Camara2x2Controller extends GetxController with WidgetsBindingObserver {
  CameraController? controlador;
  bool camaraInicializada = false;
  
  // Guardará los 4 colores detectados en el fotograma actual
  List<Color>? coloresDetectados; 
  
  bool _procesandoFotograma = false;
  int _ultimoFrameProcesado = 0;

  @override
  void onInit() {
    super.onInit();
    // Observamos el ciclo de vida de la app (para cuando se minimiza)
    WidgetsBinding.instance.addObserver(this);
    _inicializarCamara();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _cerrarCamaraSegura();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controlador == null || !controlador!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controlador?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _inicializarCamara();
    }
  }

  Future<void> _inicializarCamara() async {
    try {
      final cameras = await availableCameras();
      
      final cameraTrasera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      controlador = CameraController(
        cameraTrasera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, 
      );

      await controlador!.initialize();
      
      camaraInicializada = true;
      update(['camara']); // Redibuja toda la vista de la cámara

      controlador!.startImageStream(_enviarFotogramaAIA);
    } catch (e) {
      debugPrint("Error al inicializar la cámara: $e");
    }
  }

  void _enviarFotogramaAIA(CameraImage imagen) async {
    if (_procesandoFotograma) return;

    final tiempoActual = DateTime.now().millisecondsSinceEpoch;
    if (tiempoActual - _ultimoFrameProcesado < 800) return;

    _procesandoFotograma = true;
    _ultimoFrameProcesado = tiempoActual;

    try {
      // Usamos el servicio global inyectado por GetX
      final servicioIA = Get.find<ServicioIAVision>();
      final colores = await servicioIA.procesarFrame2x2(imagen);
      
      if (colores != null && colores.length == 4) {
        coloresDetectados = colores;
        update(['resultados']); // Solo actualiza el panel inferior de colores
      }
    } catch (e) {
      debugPrint("Error ignorado en feed: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      _procesandoFotograma = false; 
    }
  }

  Future<void> _cerrarCamaraSegura() async {
    try {
      if (controlador != null && controlador!.value.isStreamingImages) {
        await controlador!.stopImageStream();
      }
      await controlador?.dispose();
      controlador = null;
    } catch (e) {
      debugPrint("Cierre de cámara: $e");
    }
  }

  void aceptarLectura() async {
    Get.find<GestorConfiguracion>().ejecutarVibracion();
    
    if (coloresDetectados != null && coloresDetectados!.length == 4) {
      _procesandoFotograma = true; 
      await _cerrarCamaraSegura();
      
      // Retornamos los colores a la pantalla de escáner usando GetX
      Get.back(result: coloresDetectados);
    }
  }

  void cancelarYVolver() async {
    Get.find<GestorConfiguracion>().ejecutarVibracion();
    _procesandoFotograma = true;
    await _cerrarCamaraSegura();
    Get.back();
  }
}


class PantallaCamara2x2 extends StatelessWidget {
  final String nombreCara;

  const PantallaCamara2x2({super.key, required this.nombreCara});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el controlador de la cámara
    final ctrl = Get.put(Camara2x2Controller());
    final esOscuro = Get.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GetBuilder<Camara2x2Controller>(
        id: 'camara',
        builder: (_) {
          if (!ctrl.camaraInicializada || ctrl.controlador == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  Text("Iniciando IA Visión...", style: TextStyle(color: Colors.white.withOpacity(0.8))),
                ],
              ),
            );
          }

          final anchoPantalla = Get.width;
          final tamanoEncuadre = anchoPantalla * 0.7; 

          return Stack(
            children: [
              // 1. Feed de la Cámara en pantalla completa
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CameraPreview(ctrl.controlador!),
              ),

              // 2. Overlay del Escáner
              CustomPaint(
                size: Size.infinite,
                painter: _PintorOverlayEscaner(tamanoEncuadre),
              ),

              // 3. Guía Visual: Cuadrícula 2x2
              Center(
                child: Container(
                  width: tamanoEncuadre,
                  height: tamanoEncuadre,
                  decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent, width: 2)),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent.withOpacity(0.5))))),
                            Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent.withOpacity(0.5)))))
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent.withOpacity(0.5))))),
                            Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent.withOpacity(0.5)))))
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Botón de retroceso
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: ctrl.cancelarYVolver,
                    ),
                  ),
                ),
              ),

              // 5. Panel Inferior: Resultados
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: esOscuro ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "ESCANEANDO CARA",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nombreCara,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 24),

                      // Miniatura 2x2 en tiempo real (Actualizada selectivamente)
                      GetBuilder<Camara2x2Controller>(
                        id: 'resultados',
                        builder: (_) {
                          return Container(
                            width: 100,
                            height: 100,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: esOscuro ? Colors.black26 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ctrl.coloresDetectados == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(strokeWidth: 2),
                                      const SizedBox(height: 8),
                                      Text("Buscando...", style: TextStyle(fontSize: 10, color: Colors.grey[600]))
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            _construirMiniSticker(ctrl.coloresDetectados![0]),
                                            _construirMiniSticker(ctrl.coloresDetectados![1]),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            _construirMiniSticker(ctrl.coloresDetectados![2]),
                                            _construirMiniSticker(ctrl.coloresDetectados![3]),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        }
                      ),
                      const SizedBox(height: 24),

                      // Botón Aceptar
                      GetBuilder<Camara2x2Controller>(
                        id: 'resultados',
                        builder: (_) {
                          return SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: FilledButton.icon(
                              onPressed: ctrl.coloresDetectados == null ? null : ctrl.aceptarLectura,
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text("ACEPTAR LECTURA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _construirMiniSticker(Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black26, width: 1),
        ),
      ),
    );
  }
}

class _PintorOverlayEscaner extends CustomPainter {
  final double tamanoEncuadre;

  _PintorOverlayEscaner(this.tamanoEncuadre);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final innerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: tamanoEncuadre,
      height: tamanoEncuadre,
    );

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outerRect)
      ..addRRect(RRect.fromRectAndRadius(innerRect, const Radius.circular(16)));

    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img; // 🔥 IMPORTANTE PARA RECORTAR LA IMAGEN
import '../../servicios/ia/servicio_ia_vision.dart';
import '../../servicios/ia/servicio_gemini_vision.dart';
import '../../gestores/globales/gestor_configuracion.dart';

class Camara2x2Controller extends GetxController with WidgetsBindingObserver {
  CameraController? controlador;
  bool camaraInicializada = false;
  List<Color>? coloresDetectados; 
  bool _procesandoFotograma = false;
  int _ultimoFrameProcesado = 0;

  bool get esModoGemini => Get.find<GestorConfiguracion>().usarGeminiAPI.value;
  bool get estaProcesando => _procesandoFotograma;

  @override
  void onInit() {
    super.onInit();
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
        esModoGemini ? ResolutionPreset.high : ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, 
      );

      await controlador!.initialize();
      camaraInicializada = true;
      update(['camara']); 

      if (!esModoGemini) {
        controlador!.startImageStream(_enviarFotogramaAIA);
      }
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
      final servicioIA = Get.find<ServicioIAVision>();
      final colores = await servicioIA.procesarFrame2x2(imagen);
      
      if (colores != null && colores.length == 4) {
        coloresDetectados = colores;
        update(['resultados']); 
      }
    } catch (e) {
      // Ignorar errores del feed continuo
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      _procesandoFotograma = false; 
    }
  }

  // 🔥 NUEVA LÓGICA DE CAPTURA CON RECORTE PARA GEMINI
  Future<void> capturarFotoParaGemini() async {
    if (_procesandoFotograma || controlador == null || !controlador!.value.isInitialized) return;
    
    Get.find<GestorConfiguracion>().ejecutarVibracion();
    _procesandoFotograma = true;
    coloresDetectados = null;
    update(['resultados']);

    try {
      // 1. Tomar foto original
      final XFile archivoFoto = await controlador!.takePicture();
      final bytesOriginales = await archivoFoto.readAsBytes();

      // 2. RECORTAR LA IMAGEN AL CENTRO (Para mejorar la precisión)
      // Esto simula el cuadro verde de la interfaz
      img.Image? imagenOriginal = img.decodeImage(bytesOriginales);
      
      if (imagenOriginal != null) {
        // Calculamos un recorte del 70% del ancho/alto
        int ladoMenor = imagenOriginal.width < imagenOriginal.height ? imagenOriginal.width : imagenOriginal.height;
        int tamanoRecorte = (ladoMenor * 0.7).toInt(); 
        int offsetX = (imagenOriginal.width - tamanoRecorte) ~/ 2;
        int offsetY = (imagenOriginal.height - tamanoRecorte) ~/ 2;

        img.Image imagenRecortada = img.copyCrop(
          imagenOriginal, 
          x: offsetX, 
          y: offsetY, 
          width: tamanoRecorte, 
          height: tamanoRecorte
        );

        // Convertir la imagen recortada de nuevo a bytes para enviarla
        final bytesParaGemini = img.encodeJpg(imagenRecortada);
        
        // 3. Enviar a Gemini
        final servicioGemini = Get.find<ServicioGeminiVision>();
        final colores = await servicioGemini.procesarFoto2x2(bytesParaGemini);

        if (colores != null && colores.length == 4) {
          coloresDetectados = colores;
        } else {
          _mostrarErrorGemini();
        }
      } else {
         _mostrarErrorGemini();
      }

    } catch (e) {
      debugPrint("Error en captura Gemini: $e");
      _mostrarErrorGemini();
    } finally {
      _procesandoFotograma = false;
      update(['resultados']);
    }
  }

  void _mostrarErrorGemini() {
     Get.snackbar(
        'Análisis fallido',
        'Intenta acercar más el cubo al cuadro verde y evita reflejos de luz.',
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
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
      Get.back(result: coloresDetectados);
    }
  }

  void cancelarYVolver() async {
    Get.find<GestorConfiguracion>().ejecutarVibracion();
    _procesandoFotograma = true;
    await _cerrarCamaraSegura();
    Get.back();
  }

  void limpiarLectura() {
    Get.find<GestorConfiguracion>().ejecutarVibracion();
    coloresDetectados = null;
    update(['resultados']);
  }
}

// ═══════════════════════════════════════════════════════════════
// VISTA INTERFAZ GRÁFICA (Sin cambios, se mantiene igual)
// ═══════════════════════════════════════════════════════════════

class PantallaCamara2x2 extends StatelessWidget {
  final String nombreCara;

  const PantallaCamara2x2({super.key, required this.nombreCara});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(Camara2x2Controller());
    final esOscuro = Get.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GetBuilder<Camara2x2Controller>(
        id: 'camara',
        builder: (_) {
          if (!ctrl.camaraInicializada || ctrl.controlador == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text("Iniciando Cámara...", style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }

          final anchoPantalla = Get.width;
          final tamanoEncuadre = anchoPantalla * 0.7; 

          return Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CameraPreview(ctrl.controlador!),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: _PintorOverlayEscaner(tamanoEncuadre),
              ),
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
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ctrl.esModoGemini ? Icons.cloud_sync_rounded : Icons.bolt_rounded, 
                            color: ctrl.esModoGemini ? Colors.blueAccent : Colors.yellowAccent, 
                            size: 16
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ctrl.esModoGemini ? "Motor Gemini (Nube)" : "Motor Rápido (Local)",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                      GetBuilder<Camara2x2Controller>(
                        id: 'resultados',
                        builder: (_) {
                          if (ctrl.coloresDetectados != null) {
                            return Column(
                              children: [
                                Container(
                                  width: 100, height: 100,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: esOscuro ? Colors.black26 : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
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
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: OutlinedButton(
                                        onPressed: ctrl.limpiarLectura,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Icon(Icons.refresh_rounded),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 3,
                                      child: FilledButton.icon(
                                        onPressed: ctrl.aceptarLectura,
                                        icon: const Icon(Icons.check_circle_rounded),
                                        label: const Text("ACEPTAR", style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          backgroundColor: Colors.green.shade600,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            );
                          } else if (ctrl.estaProcesando) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 3),
                                  const SizedBox(height: 16),
                                  Text(
                                    ctrl.esModoGemini ? "Gemini analizando la imagen..." : "Buscando cubo...", 
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)
                                  )
                                ],
                              ),
                            );
                          } else if (ctrl.esModoGemini) {
                            return SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: FilledButton.icon(
                                onPressed: ctrl.capturarFotoParaGemini,
                                icon: const Icon(Icons.camera_alt_rounded, size: 28),
                                label: const Text("CAPTURAR FOTO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 3),
                                  const SizedBox(height: 16),
                                  Text("Centra el cubo en el recuadro...", style: TextStyle(fontSize: 14, color: Colors.grey[600]))
                                ],
                              ),
                            );
                          }
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
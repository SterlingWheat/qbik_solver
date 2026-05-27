import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../servicios/servicio_ia_vision.dart';
import '../gestores/gestor_configuracion.dart';

class PantallaCamara2x2 extends StatefulWidget {
  final String nombreCara;

  const PantallaCamara2x2({super.key, required this.nombreCara});

  @override
  State<PantallaCamara2x2> createState() => _EstadoPantallaCamara2x2();
}

class _EstadoPantallaCamara2x2 extends State<PantallaCamara2x2> with WidgetsBindingObserver {
  CameraController? _controlador;
  bool _camaraInicializada = false;
  
  // Guardará los 4 colores detectados en el fotograma actual [SupIzq, SupDer, InfIzq, InfDer]
  List<Color>? _coloresDetectados; 
  
  // Semáforo para no saturar la CPU con inferencias asíncronas superpuestas
  bool _procesandoFotograma = false;

  int _ultimoFrameProcesado = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inicializarCamara();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Como ya cerramos en _aceptarLectura, esto actúa como red de seguridad
    if (_controlador != null) {
      _controlador?.dispose();
    }
    super.dispose();
  }

  /// Manejo del ciclo de vida para cuando la app se va a segundo plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controlador;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _inicializarCamara();
    }
  }

  Future<void> _inicializarCamara() async {
    try {
      // Obtenemos la lista de cámaras del dispositivo
      final cameras = await availableCameras();
      
      // Buscamos la cámara trasera
      final cameraTrasera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Configuramos en resolución media para que YOLO procese rápido sin lag
      _controlador = CameraController(
        cameraTrasera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Formato estándar ultra rápido
      );

      await _controlador!.initialize();
      if (!mounted) return;

      setState(() => _camaraInicializada = true);

      // Iniciamos el feed en tiempo real
      _controlador!.startImageStream(_enviarFotogramaAIA);

    } catch (e) {
      debugPrint("Error al inicializar la cámara: $e");
    }
  }

  void _enviarFotogramaAIA(CameraImage imagen) async {
    if (_procesandoFotograma) return;

    // LIMITADOR: Solo procesamos 1 frame cada 800 milisegundos
    final tiempoActual = DateTime.now().millisecondsSinceEpoch;
    if (tiempoActual - _ultimoFrameProcesado < 800) return;

    _procesandoFotograma = true;
    _ultimoFrameProcesado = tiempoActual;

    try {
      final colores = await ServicioIAVision.procesarFrame2x2(imagen);
      
      if (mounted && colores != null && colores.length == 4) {
        setState(() {
          _coloresDetectados = colores;
        });
      }
    } catch (e) {
      debugPrint("Error ignorado en feed: $e");
    } finally {
      // Le damos un micro-respiro extra al procesador antes de liberar el semáforo
      await Future.delayed(const Duration(milliseconds: 50));
      _procesandoFotograma = false; 
    }
  }

  void _aceptarLectura() async {
    GestorConfiguracion().ejecutarVibracion();
    
    if (_coloresDetectados != null && _coloresDetectados!.length == 4) {
      // 1. Bloqueamos el análisis de frames de la IA
      _procesandoFotograma = true; 
      
      try {
        // 2. Liberamos la cámara de forma 100% segura ANTES de salir
        if (_controlador != null && _controlador!.value.isStreamingImages) {
          await _controlador!.stopImageStream();
        }
        await _controlador?.dispose();
        _controlador = null;
      } catch (e) {
        debugPrint("Cierre de cámara: $e");
      }

      // 3. Ahora sí, regresamos seguros a la pantalla anterior
      if (mounted) {
        Navigator.pop(context, _coloresDetectados);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    
    if (!_camaraInicializada || _controlador == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 16),
              Text("Iniciando IA Visión...", style: TextStyle(color: Colors.white.withOpacity(0.8))),
            ],
          ),
        ),
      );
    }

    final anchoPantalla = MediaQuery.of(context).size.width;
    // Cuadrado central de encuadre
    final tamanoEncuadre = anchoPantalla * 0.7; 

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Feed de la Cámara en pantalla completa
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controlador!),
          ),

          // 2. Overlay del Escáner (Fondo oscuro con agujero cuadrado)
          CustomPaint(
            size: Size.infinite,
            painter: _PintorOverlayEscaner(tamanoEncuadre),
          ),

          // 3. Guía Visual: Cuadrícula 2x2 sobre el agujero
          Center(
            child: Container(
              width: tamanoEncuadre,
              height: tamanoEncuadre,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
              ),
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

          // 4. Botón de retroceso (Arriba Izquierda)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () async {
                    GestorConfiguracion().ejecutarVibracion();
                    
                    // Cierre seguro al cancelar
                    if (_controlador != null && _controlador!.value.isStreamingImages) {
                      await _controlador!.stopImageStream();
                    }
                    await _controlador?.dispose();
                    _controlador = null;
                    
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),

          // 5. Panel Inferior: Resultados de la IA y Botón Aceptar
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
                    widget.nombreCara,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 24),

                  // Miniatura 2x2 en tiempo real
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: esOscuro ? Colors.black26 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _coloresDetectados == null
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
                                    _construirMiniSticker(_coloresDetectados![0]),
                                    _construirMiniSticker(_coloresDetectados![1]),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    _construirMiniSticker(_coloresDetectados![2]),
                                    _construirMiniSticker(_coloresDetectados![3]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Botón Aceptar
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton.icon(
                      // Se habilita solo cuando YOLO detecta exactamente 4 stickers
                      onPressed: _coloresDetectados == null ? null : _aceptarLectura,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text("ACEPTAR LECTURA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

/// Dibuja el fondo oscuro con un recorte cuadrado transparente en el centro
class _PintorOverlayEscaner extends CustomPainter {
  final double tamanoEncuadre;

  _PintorOverlayEscaner(this.tamanoEncuadre);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.65);
    
    // El rectángulo externo (toda la pantalla)
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // El rectángulo interno (el agujero)
    final innerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: tamanoEncuadre,
      height: tamanoEncuadre,
    );

    // Creamos la forma restando el cuadro interno del externo
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outerRect)
      ..addRRect(RRect.fromRectAndRadius(innerRect, const Radius.circular(16)));

    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
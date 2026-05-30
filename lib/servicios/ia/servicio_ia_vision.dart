import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:get/get.dart';

/// Servicio de Visión Local (YOLOv8 + CNN) para detectar y clasificar colores.
class ServicioIAVision extends GetxService {
  Interpreter? _yoloInterpreter;
  Interpreter? _cnnInterpreter;

  // --- CONFIGURACIÓN DE MODELOS ---
  // 🔥 CORRECCIÓN: Cambiado de 416 a 640 para coincidir con la arquitectura de tu YOLOv8 exportado
  static const int _yoloSize = 640; 
  static const int _cnnSize = 64;   

  // Mapeo de colores ordenado alfabéticamente (estándar de Keras)
  static const List<Color> _etiquetasColores = [
    Colors.yellow,  // 0: amarillo
    Colors.blue,    // 1: azul
    Colors.white,   // 2: blanco
    Colors.orange,  // 3: naranja
    Colors.red,     // 4: rojo
    Colors.green,   // 5: verde
  ];

  @override
  void onInit() {
    super.onInit();
    _inicializarModelos();
  }

  @override
  void onClose() {
    _yoloInterpreter?.close();
    _cnnInterpreter?.close();
    super.onClose();
  }

  Future<void> _inicializarModelos() async {
    try {
      final opciones = InterpreterOptions()..threads = 4;
      _yoloInterpreter = await Interpreter.fromAsset('assets/models/yolo_cubos.tflite', options: opciones);
      _cnnInterpreter = await Interpreter.fromAsset('assets/models/clasificador_colores.tflite', options: opciones);
      debugPrint("✅ Modelos TFLite locales cargados correctamente a resolución $_yoloSize.");
    } catch (e) {
      debugPrint("❌ Error al cargar los modelos TFLite: $e");
    }
  }

  /// PROCESO ESTÁTICO: Recibe la foto ya recortada en bytes, devuelve los 4 colores
  Future<List<Color>?> procesarImagenEstatica(Uint8List bytesRecortados) async {
    try {
      if (_yoloInterpreter == null || _cnnInterpreter == null) {
        await _inicializarModelos();
        if (_yoloInterpreter == null || _cnnInterpreter == null) return null;
      }

      // Convertir la imagen que ya viene recortada a objeto Image
      img.Image? imagenCuadrada = img.decodeImage(bytesRecortados);
      if (imagenCuadrada == null) return null;

      // 1. Ejecutar YOLO para encontrar las 4 piezas
      List<Rect> boxes = _ejecutarYOLO(imagenCuadrada);
      if (boxes.length != 4) return null;

      // 2. Ordenar las cajas espacialmente [SupIzq, SupDer, InfIzq, InfDer]
      boxes = _ordenarCajas2x2(boxes);

      // 3. Ejecutar CNN para extraer el color de cada caja
      List<Color> coloresDetectados = [];
      for (Rect box in boxes) {
        Color color = _recortarYClasificarCNN(imagenCuadrada, box);
        coloresDetectados.add(color);
      }

      return coloresDetectados;

    } catch (e, stacktrace) {
      debugPrint("🚨 Error interno IA Local: $e\n$stacktrace");
      return null;
    }
  }

  /// FASE 1: Detección con YOLOv8
  List<Rect> _ejecutarYOLO(img.Image imagenCentro) {
    // Redimensionamos a 640x640 para que coincida con el tensor esperado
    img.Image imagenRedimensionada = img.copyResize(imagenCentro, width: _yoloSize, height: _yoloSize);

    var tensorEntrada = List.generate(1, (i) => List.generate(_yoloSize, (y) => List.generate(_yoloSize, (x) {
      final pixel = imagenRedimensionada.getPixel(x, y);
      return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
    })));

    final outputShape = _yoloInterpreter!.getOutputTensor(0).shape; 
    final int numCoordenadasYClases = outputShape[1]; 
    final int numAnclas = outputShape[2]; 

    var tensorSalida = List.generate(1, (i) => List.generate(numCoordenadasYClases, (j) => List.filled(numAnclas, 0.0)));

    _yoloInterpreter!.run(tensorEntrada, tensorSalida);

    List<_YoloBox> detecciones = [];
    
    for (int i = 0; i < numAnclas; i++) {
      double maximaConfianza = 0.0;
      for (int c = 4; c < numCoordenadasYClases; c++) {
        if (tensorSalida[0][c][i] > maximaConfianza) {
          maximaConfianza = tensorSalida[0][c][i];
        }
      }

      if (maximaConfianza > 0.40) { 
        double cx = tensorSalida[0][0][i];
        double cy = tensorSalida[0][1][i];
        double w = tensorSalida[0][2][i];
        double h = tensorSalida[0][3][i];

        detecciones.add(_YoloBox(
          rect: Rect.fromLTWH((cx - w/2) / _yoloSize, (cy - h/2) / _yoloSize, w / _yoloSize, h / _yoloSize),
          score: maximaConfianza,
        ));
      }
    }

    detecciones = _aplicarNMS(detecciones, 0.4);

    detecciones.sort((a, b) => b.score.compareTo(a.score));
    if (detecciones.length > 4) detecciones = detecciones.sublist(0, 4);

    return detecciones.map((e) => e.rect).toList();
  }

  /// FASE 2: Extracción de Color utilizando la CNN (clasificador_colores.tflite)
  Color _recortarYClasificarCNN(img.Image imagenOriginal, Rect boxNormalizado) {
    if (_cnnInterpreter == null) {
      debugPrint("⚠️ CNN no inicializada. Devolviendo blanco por defecto.");
      return Colors.white;
    }

    // 1. Calcular coordenadas absolutas de la caja detectada por YOLO
    int px = (boxNormalizado.left * imagenOriginal.width).round();
    int py = (boxNormalizado.top * imagenOriginal.height).round();
    int pw = (boxNormalizado.width * imagenOriginal.width).round();
    int ph = (boxNormalizado.height * imagenOriginal.height).round();

    px = px.clamp(0, imagenOriginal.width - 1);
    py = py.clamp(0, imagenOriginal.height - 1);
    pw = pw.clamp(1, imagenOriginal.width - px);
    ph = ph.clamp(1, imagenOriginal.height - py);

    // 2. Extraer exactamente el área del sticker
    img.Image pegatinaCruda = img.copyCrop(
      imagenOriginal, 
      x: px, 
      y: py, 
      width: pw, 
      height: ph
    );

    // 3. Redimensionar al tamaño esperado por tu modelo CNN (64x64)
    img.Image pegatinaResized = img.copyResize(pegatinaCruda, width: _cnnSize, height: _cnnSize);

    // 4. Preparar el Tensor de Entrada [1, 64, 64, 3] (Normalizado de 0.0 a 1.0)
    var tensorEntrada = List.generate(1, (i) => List.generate(_cnnSize, (y) => List.generate(_cnnSize, (x) {
      final pixel = pegatinaResized.getPixel(x, y);
      return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
    })));

    // 5. Preparar el Tensor de Salida [1, 6] (Probabilidades para las 6 clases)
    var tensorSalida = List.generate(1, (i) => List.filled(6, 0.0));

    // 6. Ejecutar Inferencia de la CNN
    _cnnInterpreter!.run(tensorEntrada, tensorSalida);

    // 7. Encontrar la clase con la probabilidad más alta (ArgMax)
    List<double> probabilidades = tensorSalida[0];
    int indiceMejorClase = 0;
    double maximaProbabilidad = probabilidades[0];
    
    for (int i = 1; i < probabilidades.length; i++) {
      if (probabilidades[i] > maximaProbabilidad) {
        maximaProbabilidad = probabilidades[i];
        indiceMejorClase = i;
      }
    }

    debugPrint("🎨 Color CNN: ${_etiquetasColores[indiceMejorClase]} (Confianza: ${(maximaProbabilidad * 100).toStringAsFixed(1)}%)");

    // 8. Retornar el color mapeado
    return _etiquetasColores[indiceMejorClase];
  }

  List<Rect> _ordenarCajas2x2(List<Rect> boxes) {
    if (boxes.length != 4) return boxes;

    boxes.sort((a, b) => a.center.dy.compareTo(b.center.dy));

    List<Rect> filaSuperior = [boxes[0], boxes[1]];
    List<Rect> filaInferior = [boxes[2], boxes[3]];

    filaSuperior.sort((a, b) => a.center.dx.compareTo(b.center.dx));
    filaInferior.sort((a, b) => a.center.dx.compareTo(b.center.dx));

    return [filaSuperior[0], filaSuperior[1], filaInferior[0], filaInferior[1]];
  }

  List<_YoloBox> _aplicarNMS(List<_YoloBox> cajas, double umbralIoU) {
    cajas.sort((a, b) => b.score.compareTo(a.score));
    List<_YoloBox> seleccionadas = [];

    for (var cajaActual in cajas) {
      bool superpuesta = false;
      for (var seleccionada in seleccionadas) {
        if (_calcularIoU(cajaActual.rect, seleccionada.rect) > umbralIoU) {
          superpuesta = true;
          break;
        }
      }
      if (!superpuesta) seleccionadas.add(cajaActual);
    }
    return seleccionadas;
  }

  double _calcularIoU(Rect a, Rect b) {
    Rect interseccion = a.intersect(b);
    if (interseccion.width < 0 || interseccion.height < 0) return 0.0;
    double areaInterseccion = interseccion.width * interseccion.height;
    double areaA = a.width * a.height;
    double areaB = b.width * b.height;
    return areaInterseccion / (areaA + areaB - areaInterseccion);
  }
}

class _YoloBox {
  final Rect rect;
  final double score;
  _YoloBox({required this.rect, required this.score});
}
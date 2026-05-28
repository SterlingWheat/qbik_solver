import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:get/get.dart';
import 'dart:math';

/// Servicio de Visión por Computadora (IA) para detectar y clasificar los colores del cubo.
/// Convertido a GetxService para manejar eficientemente la memoria de los modelos TFLite.
class ServicioIAVision extends GetxService {
  Interpreter? _yoloInterpreter;
  Interpreter? _cnnInterpreter;

  // --- CONFIGURACIÓN DE MODELOS ---
  static const int _yoloSize = 416; // Tamaño ajustado al modelo exportado
  static const int _cnnSize = 64;   // Tamaño de entrada de la CNN (64x64)

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
    // Inicializamos los modelos en segundo plano apenas se inyecta el servicio
    _inicializarModelos();
  }

  @override
  void onClose() {
    // Liberamos la RAM cerrando los intérpretes cuando el servicio se destruye
    _yoloInterpreter?.close();
    _cnnInterpreter?.close();
    super.onClose();
  }

  /// Carga ambos modelos en memoria
  Future<void> _inicializarModelos() async {
    try {
      final opciones = InterpreterOptions()..threads = 4;
      
      _yoloInterpreter = await Interpreter.fromAsset('assets/models/yolo_cubos.tflite', options: opciones);
      _cnnInterpreter = await Interpreter.fromAsset('assets/models/clasificador_colores.tflite', options: opciones);
      
      var tensorEntrada = _cnnInterpreter!.getInputTensor(0);
      var tensorSalida = _cnnInterpreter!.getOutputTensor(0);
      debugPrint("🧠 [INFO CNN] Entrada: Tipo ${tensorEntrada.type}, Forma ${tensorEntrada.shape}");
      debugPrint("🧠 [INFO CNN] Salida: Tipo ${tensorSalida.type}, Forma ${tensorSalida.shape}");
      
      debugPrint("✅ Modelos TFLite cargados correctamente en GetxService.");
    } catch (e) {
      debugPrint("❌ Error al cargar los modelos TFLite: $e");
    }
  }

  /// PROCESO PRINCIPAL: Recibe el fotograma de la cámara y devuelve los 4 colores del cubo 2x2.
  Future<List<Color>?> procesarFrame2x2(CameraImage imagenCamara) async {
    try {
      // Si por alguna razón los modelos aún no cargan, esperamos
      if (_yoloInterpreter == null || _cnnInterpreter == null) {
        await _inicializarModelos();
        if (_yoloInterpreter == null || _cnnInterpreter == null) return null;
      }

      // 1. Damos un respiro al procesador para evitar el ANR (Application Not Responding)
      await Future.delayed(Duration.zero); 
      
      img.Image? imagenOriginal = _convertirYUV420aRGB(imagenCamara);
      if (imagenOriginal == null) return null;

      // 2. Recortamos la imagen al cuadrado central
      int tamanoRecorte = min(imagenOriginal.width, imagenOriginal.height);
      int offsetX = (imagenOriginal.width - tamanoRecorte) ~/ 2;
      int offsetY = (imagenOriginal.height - tamanoRecorte) ~/ 2;
      
      img.Image imagenCuadrada = img.copyCrop(
        imagenOriginal, 
        x: offsetX, y: offsetY, width: tamanoRecorte, height: tamanoRecorte
      );

      // 3. Respiro antes de la matemática pesada de YOLO
      await Future.delayed(Duration.zero); 
      
      List<Rect> boxes = _ejecutarYOLO(imagenCuadrada);
      
      if (boxes.length != 4) return null;

      // 4. Ordenar espacialmente [SupIzq, SupDer, InfIzq, InfDer]
      boxes = _ordenarCajas2x2(boxes);

      // 5. Respiro antes de la clasificación de colores
      await Future.delayed(Duration.zero); 
      
      List<Color> coloresDetectados = [];
      for (Rect box in boxes) {
        Color color = _recortarYClasificarCNN(imagenCuadrada, box);
        coloresDetectados.add(color);
      }

      return coloresDetectados;

    } catch (e, stacktrace) {
      debugPrint("🚨 Error interno IA: $e\n$stacktrace");
      return null;
    }
  }

  /// FASE 1: Detección con YOLOv8 (Lectura Dinámica)
  List<Rect> _ejecutarYOLO(img.Image imagenCentro) {
    img.Image imagenRedimensionada = img.copyResize(imagenCentro, width: _yoloSize, height: _yoloSize);

    var tensorEntrada = List.generate(
      1, (i) => List.generate(
        _yoloSize, (y) => List.generate(
          _yoloSize, (x) {
            final pixel = imagenRedimensionada.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }
        )
      )
    );

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

  /// FASE 2: Clasificación de Colores con la CNN (Conversión BGR)
  Color _recortarYClasificarCNN(img.Image imagenOriginal, Rect boxNormalizado) {
    int px = (boxNormalizado.left * imagenOriginal.width).round();
    int py = (boxNormalizado.top * imagenOriginal.height).round();
    int pw = (boxNormalizado.width * imagenOriginal.width).round();
    int ph = (boxNormalizado.height * imagenOriginal.height).round();

    int offsetRecorteX = (pw * 0.20).round();
    int offsetRecorteY = (ph * 0.20).round();
    int anchoPuro = (pw * 0.60).round();
    int altoPuro = (ph * 0.60).round();

    img.Image pegatinaCruda = img.copyCrop(
      imagenOriginal, 
      x: px + offsetRecorteX, 
      y: py + offsetRecorteY, 
      width: anchoPuro, 
      height: altoPuro
    );

    img.Image pegatina64 = img.copyResize(pegatinaCruda, width: _cnnSize, height: _cnnSize);

    var tensorEntrada = List.generate(
      1, (i) => List.generate(
        _cnnSize, (y) => List.generate(
          _cnnSize, (x) {
            final pixel = pegatina64.getPixel(x, y);
            
            // Normalización de Transfer Learning (-1.0 a 1.0)
            return [
              (pixel.r - 127.5) / 127.5, 
              (pixel.g - 127.5) / 127.5, 
              (pixel.b - 127.5) / 127.5
            ];
          }
        )
      )
    );

    var tensorSalida = List.generate(1, (_) => List.filled(6, 0.0));

    _cnnInterpreter!.run(tensorEntrada, tensorSalida);

    int indiceGanador = 0;
    double confianzaMaxima = tensorSalida[0][0];
    for (int i = 1; i < 6; i++) {
      if (tensorSalida[0][i] > confianzaMaxima) {
        confianzaMaxima = tensorSalida[0][i];
        indiceGanador = i;
      }
    }

    return _etiquetasColores[indiceGanador];
  }

  // --- MÉTODOS AUXILIARES ---

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

  img.Image? _convertirYUV420aRGB(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _procesarYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return img.Image.fromBytes(
          width: image.width, height: image.height,
          bytes: image.planes[0].bytes.buffer,
          order: img.ChannelOrder.bgra,
        );
      }
    } catch (e) {
      debugPrint("Error formato cámara: $e");
    }
    return null;
  }

  img.Image _procesarYUV420(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    
    final img.Image rgbImage = img.Image(width: height, height: width);

    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;

    final int yRowStride = image.planes[0].bytesPerRow;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      int uvRow = y >> 1;
      int yPos = y * yRowStride;
      int uvPosBase = uvRow * uvRowStride;

      for (int x = 0; x < width; x++) {
        int indexY = yPos + x;
        int uvPos = uvPosBase + (x >> 1) * uvPixelStride;

        if (indexY >= yPlane.length) indexY = yPlane.length - 1;
        if (uvPos >= uPlane.length) uvPos = uPlane.length - 1;
        if (uvPos >= vPlane.length) uvPos = vPlane.length - 1;

        int yp = yPlane[indexY];
        int up = uPlane[uvPos];
        int vp = vPlane[uvPos];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        rgbImage.setPixelRgb(y, width - x - 1, r, g, b);
      }
    }
    
    return rgbImage;
  }
}

class _YoloBox {
  final Rect rect;
  final double score;
  _YoloBox({required this.rect, required this.score});
}
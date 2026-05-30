import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';


class GestorVoz extends GetxService {
  late FlutterTts _tts;

  @override
  void onInit() {
    super.onInit();
    _inicializarTTS();
  }

  void _inicializarTTS() async {
    _tts = FlutterTts();
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.5); // Velocidad moderada para seguir el cubo
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> narrarMovimiento(String movimiento) async {
    String textoDescriptivo = _traducirMovimiento(movimiento);
    if (textoDescriptivo.isNotEmpty) {
      await detener(); // Detiene cualquier voz previa antes de hablar
      await _tts.speak(textoDescriptivo);
    }
  }

  Future<void> detener() async {
    await _tts.stop();
  }

  String _traducirMovimiento(String movimiento) {
    switch (movimiento) {
      // Movimientos de la capa U (Arriba)
      case "U":  return "Gira la capa superior hacia la izquierda";
      case "U'": return "Gira la capa superior hacia la derecha";
      case "U2": return "Gira la capa superior media vuelta";
      
      // Movimientos de la capa R (Derecha)
      case "R":  return "Gira la capa derecha hacia arriba";
      case "R'": return "Gira la capa derecha hacia abajo";
      case "R2": return "Gira la capa derecha media vuelta";
      
      // Movimientos de la capa F (Frente)
      case "F":  return "Gira la capa frontal hacia la derecha";
      case "F'": return "Gira la capa frontal hacia la izquierda";
      case "F2": return "Gira la capa frontal media vuelta";
      
      // Expansión futura para el 3x3
      case "D":  return "Gira la capa inferior hacia la derecha";
      case "D'": return "Gira la capa inferior hacia la izquierda";
      case "D2": return "Gira la capa inferior media vuelta";
      case "L":  return "Gira la capa izquierda hacia abajo";
      case "L'": return "Gira la capa izquierda hacia arriba";
      case "L2": return "Gira la capa izquierda media vuelta";
      case "B":  return "Gira la capa trasera hacia la izquierda";
      case "B'": return "Gira la capa trasera hacia la derecha";
      case "B2": return "Gira la capa trasera media vuelta";
      
      default: return "";
    }
  }
}
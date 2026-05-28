import 'package:get/get.dart';
import 'dart:math';

class GestorEstadisticas extends GetxController {
  
  // Estructura de datos reactiva (.obs) para almacenar los tiempos
  var tiemposPorDisciplina = <String, List<int>>{
    'Cubo 3x3': [],
    'Cubo 2x2': [],
    'Pyraminx': [],
  }.obs;

  /// Guarda un nuevo tiempo y actualiza la UI automáticamente
  void guardarTiempo(String disciplina, int milisegundos) {
    if (tiemposPorDisciplina.containsKey(disciplina)) {
      tiemposPorDisciplina[disciplina]!.add(milisegundos);
      // refresh() le avisa a GetX que el contenido interno de la lista cambió
      tiemposPorDisciplina.refresh(); 
    }
  }

  List<int> obtenerTiempos(String disciplina) {
    return tiemposPorDisciplina[disciplina] ?? [];
  }

  // === CÁLCULOS DE KPIs ===

  String obtenerUltimoTiempo(String disciplina) {
    final tiempos = obtenerTiempos(disciplina);
    if (tiempos.isEmpty) return "--";
    return formatearMilisegundos(tiempos.last);
  }

  String obtenerMejorTiempo(String disciplina) {
    final tiempos = obtenerTiempos(disciplina);
    if (tiempos.isEmpty) return "--";
    return formatearMilisegundos(tiempos.reduce(min));
  }

  String obtenerPeorTiempo(String disciplina) {
    final tiempos = obtenerTiempos(disciplina);
    if (tiempos.isEmpty) return "--";
    return formatearMilisegundos(tiempos.reduce(max));
  }

  String obtenerMedia(String disciplina) {
    final tiempos = obtenerTiempos(disciplina);
    if (tiempos.isEmpty) return "--";
    final suma = tiempos.reduce((a, b) => a + b);
    final media = suma / tiempos.length;
    return formatearMilisegundos(media.round());
  }

  /// Convierte milisegundos al formato de speedcubing (m:ss.mmm)
  static String formatearMilisegundos(int totalMs) {
    final minutos = (totalMs / 60000).floor();
    final segundos = ((totalMs % 60000) / 1000).floor();
    final ms = totalMs % 1000;

    String formateado = "";
    if (minutos > 0) formateado += "$minutos:";
    formateado += "${minutos > 0 ? segundos.toString().padLeft(2, '0') : segundos}.";
    formateado += ms.toString().padLeft(3, '0');
    return formateado;
  }
}
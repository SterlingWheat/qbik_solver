import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio de Visión por Computadora en la nube utilizando la API de Gemini.
class ServicioGeminiVision extends GetxService {
  GenerativeModel? _model;
  bool _inicializado = false;

  @override
  void onInit() {
    super.onInit();
    _inicializarModelo();
  }

  void _inicializarModelo() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint("❌ [GEMINI IA] Error: No se encontró la clave 'GEMINI_API_KEY' en el archivo .env");
        return;
      }

      // 🔥 CORRECCIÓN DEFINITIVA: Actualizado a la generación actual de modelos (2026).
      // Si por alguna razón de región sigue fallando, puedes intentar con 'gemini-2.0-flash'
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );
      _inicializado = true;
      debugPrint("✅ [GEMINI IA] Servicio inicializado correctamente con gemini-2.5-flash.");
    } catch (e) {
      debugPrint("❌ [GEMINI IA] Error crítico al inicializar el cliente: $e");
    }
  }

  Future<List<Color>?> procesarFoto2x2(Uint8List bytesImagen) async {
    if (!_inicializado) {
      _inicializarModelo();
      if (!_inicializado) return null;
    }

    try {
      debugPrint("🚀 [GEMINI IA] Preparando imagen para enviar...");
      final imagenPart = DataPart('image/jpeg', bytesImagen);
      
      // Prompt estricto para forzar solo el arreglo de colores y sin Markdown
      final promptTexto = """
      Analiza esta imagen recortada de una cara de un cubo Rubik 2x2.
      Identifica el color de las 4 pegatinas visibles.
      
      Reglas estrictas de salida:
      1. Devuelve ÚNICAMENTE un arreglo JSON.
      2. No uses etiquetas Markdown como ```json o ```.
      3. Solo texto plano con el formato: ["color1", "color2", "color3", "color4"]
      4. El orden es: [Superior-Izquierda, Superior-Derecha, Inferior-Izquierda, Inferior-Derecha].
      5. Valores permitidos exactos: "white", "red", "green", "yellow", "orange", "blue".
      
      Ejemplo de salida:
      ["white", "red", "green", "blue"]
      """;

      final contenido = [
        Content.multi([imagenPart, TextPart(promptTexto)])
      ];

      debugPrint("⏳ [GEMINI IA] Enviando petición a Google Servers...");
      
      final respuesta = await _model!.generateContent(contenido);
      final textoSalida = respuesta.text;

      if (textoSalida == null || textoSalida.isEmpty) {
        debugPrint("⚠️ [GEMINI IA] El servidor retornó un texto vacío.");
        return null;
      }

      debugPrint("🧠 [GEMINI IA] Respuesta cruda recibida: ${textoSalida.trim()}");

      // Limpieza robusta de Markdown por si la IA decide ignorar las instrucciones
      String textoLimpio = textoSalida.trim();
      textoLimpio = textoLimpio.replaceAll('```json', '').replaceAll('```', '').trim();

      // Decodificamos el JSON
      final List<dynamic> coloresStr = jsonDecode(textoLimpio);
      if (coloresStr.length != 4) {
        debugPrint("❌ [GEMINI IA] Error: Se esperaban 4 colores, llegaron ${coloresStr.length}");
        return null;
      }

      List<Color> coloresMapeados = [];
      for (var item in coloresStr) {
        coloresMapeados.add(_mapearStringAColor(item.toString().toLowerCase().trim()));
      }

      debugPrint("✅ [GEMINI IA] Colores procesados con éxito: $coloresStr");
      return coloresMapeados;

    } catch (e, stacktrace) {
      debugPrint("🚨 [GEMINI IA] Falla interna: $e");
      return null;
    }
  }

  Color _mapearStringAColor(String colorStr) {
    switch (colorStr) {
      case 'white':  return Colors.white;
      case 'red':    return Colors.red;
      case 'green':  return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'orange': return Colors.orange;
      case 'blue':   return Colors.blue;
      default:
        debugPrint("⚠️ [GEMINI IA] Color no reconocido: '$colorStr'. Usando blanco.");
        return Colors.white; 
    }
  }
}
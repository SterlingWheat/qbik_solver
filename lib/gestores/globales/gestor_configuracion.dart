import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // 🔥 Importación necesaria
import 'dart:async';

class GestorConfiguracion extends GetxController {
  var esTemaOscuro = true.obs;
  var vibracionActiva = true.obs;
  var usarGeminiAPI = false.obs;

  // Suscripción para escuchar cambios de red en tiempo real
  late StreamSubscription<List<ConnectivityResult>> _suscripcionConectividad;

  @override
  void onInit() {
    super.onInit();
    
    // 🔥 ESCUCHADOR EN TIEMPO REAL
    // Si la app detecta que se fue el internet de repente...
    _suscripcionConectividad = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> resultados) {
      // Si el resultado es 'none' (sin conexión) y Gemini estaba activado:
      if (resultados.contains(ConnectivityResult.none) && usarGeminiAPI.value) {
        usarGeminiAPI.value = false; // Lo apaga automáticamente
        
        Get.snackbar(
          'Conexión perdida',
          'El escáner en la nube se ha desactivado automáticamente para usar el modelo local.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    });
  }

  @override
  void onClose() {
    // Es buena práctica cancelar la suscripción si el gestor se destruye
    _suscripcionConectividad.cancel();
    super.onClose();
  }

  void establecerTemaOscuro(bool valor) {
    esTemaOscuro.value = valor;
    Get.changeThemeMode(valor ? ThemeMode.dark : ThemeMode.light);
    ejecutarVibracion();
  }

  void establecerVibracionActiva(bool valor) {
    vibracionActiva.value = valor;
    if (vibracionActiva.value) {
      HapticFeedback.vibrate();
    }
  }

  // 🔥 VALIDACIÓN AL INTENTAR ACTIVAR
  Future<void> establecerUsarGeminiAPI(bool valor) async {
    ejecutarVibracion();

    // Si el usuario intenta ENCENDER el interruptor, validamos el internet primero
    if (valor == true) {
      final resultados = await Connectivity().checkConnectivity();
      
      if (resultados.contains(ConnectivityResult.none)) {
        Get.snackbar(
          'Sin conexión a Internet',
          'Necesitas internet para habilitar la IA de Gemini. Conéctate a una red e inténtalo de nuevo.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return; // Salimos de la función sin cambiar la variable a true
      }
    }
    
    // Si hay internet (o si el usuario lo está APAGANDO manualmente), cambiamos el valor
    usarGeminiAPI.value = valor;
  }

  void ejecutarVibracion() {
    if (vibracionActiva.value) {
      HapticFeedback.vibrate();
    }
  }
}
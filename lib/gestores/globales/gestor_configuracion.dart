import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class GestorConfiguracion extends GetxController {
  var esTemaOscuro = true.obs;
  var vibracionActiva = true.obs;

  void establecerTemaOscuro(bool valor) {
    esTemaOscuro.value = valor;
    
    // 🔥 ESTO ES LA MAGIA: Le dice a GetX que cambie el tema en toda la app de inmediato
    Get.changeThemeMode(valor ? ThemeMode.dark : ThemeMode.light);
    
    ejecutarVibracion();
  }

  void establecerVibracionActiva(bool valor) {
    vibracionActiva.value = valor;
    if (vibracionActiva.value) {
      // Usamos vibrate() que nunca falla en Android/iOS
      HapticFeedback.vibrate();
    }
  }

  void ejecutarVibracion() {
    if (vibracionActiva.value) {
      // Cambiamos lightImpact por vibrate
      HapticFeedback.vibrate();
    }
  }
}
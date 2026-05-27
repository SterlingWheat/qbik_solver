import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GestorConfiguracion extends ChangeNotifier {
  // Patrón Singleton para acceso global unificado
  static final GestorConfiguracion _instancia = GestorConfiguracion._interno();
  factory GestorConfiguracion() => _instancia;
  GestorConfiguracion._interno();

  // Valores por defecto (Iniciamos en Oscuro y con Vibración activada)
  bool _esTemaOscuro = true;
  bool _vibracionActiva = true;

  bool get esTemaOscuro => _esTemaOscuro;
  bool get vibracionActiva => _vibracionActiva;

  /// Cambia el modo de tema entre Claro y Oscuro
  void establecerTemaOscuro(bool valor) {
    _esTemaOscuro = valor;
    ejecutarVibracion(); // Feedback al cambiar
    notifyListeners();   // Re-renderiza la aplicación completa
  }

  /// Activa o desactiva el feedback háptico global
  void establecerVibracionActiva(bool valor) {
    _vibracionActiva = valor;
    if (_vibracionActiva) {
      HapticFeedback.mediumImpact(); // Confirmación física de activación
    }
    notifyListeners();
  }

  /// Método modular reutilizable para cualquier botón de la aplicación
  void ejecutarVibracion() {
    if (_vibracionActiva) {
      HapticFeedback.lightImpact(); // Vibración sutil estilo speedcubing
    }
  }
}
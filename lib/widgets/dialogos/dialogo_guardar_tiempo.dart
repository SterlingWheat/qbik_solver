import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../gestores/globales/gestor_configuracion.dart';

class DialogoGuardarTiempo extends StatelessWidget {
  final String tiempo;
  final String disciplina;

  const DialogoGuardarTiempo({
    super.key,
    required this.tiempo,
    required this.disciplina,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('¡Tiempo detenido!', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            disciplina,
            style: TextStyle(
              fontSize: 16,
              color: Get.theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tiempo,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace', // Fuente monoespaciada para números
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Deseas guardar este tiempo en estadísticas?',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () {
            Get.find<GestorConfiguracion>().ejecutarVibracion();
            // Retorna false para indicar que NO se guarda
            Get.back(result: false); 
          },
          child: const Text('Descartar', style: TextStyle(color: Colors.redAccent)),
        ),
        FilledButton(
          onPressed: () {
            Get.find<GestorConfiguracion>().ejecutarVibracion();
            // Retorna true para indicar que SÍ se guarda
            Get.back(result: true); 
          },
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
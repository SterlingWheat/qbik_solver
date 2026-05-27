import 'package:flutter/material.dart';
import '../gestores/gestor_configuracion.dart';

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
              color: Theme.of(context).colorScheme.primary,
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
            GestorConfiguracion().ejecutarVibracion();
            Navigator.of(context).pop(false); // No guardar
          },
          child: const Text('Descartar', style: TextStyle(color: Colors.redAccent)),
        ),
        FilledButton(
          onPressed: () {
            GestorConfiguracion().ejecutarVibracion();
            Navigator.of(context).pop(true); // Sí guardar
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
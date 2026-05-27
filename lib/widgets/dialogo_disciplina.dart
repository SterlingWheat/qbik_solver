import 'package:flutter/material.dart';
import '../gestores/gestor_configuracion.dart';

class DialogoDisciplina extends StatelessWidget {
  const DialogoDisciplina({super.key});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = esOscuro ? Colors.white : Colors.black87;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Elige la disciplina',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: colorTexto),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirOpcion(context, 'Cubo 3x3', Icons.grid_on_rounded),
          const SizedBox(height: 12),
          _construirOpcion(context, 'Cubo 2x2', Icons.grid_view_rounded),
          const SizedBox(height: 12),
          _construirOpcion(context, 'Pyraminx', Icons.change_history_rounded),
        ],
      ),
    );
  }

  Widget _construirOpcion(BuildContext context, String titulo, IconData icono) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        GestorConfiguracion().ejecutarVibracion();
        Navigator.of(context).pop(titulo); // Retorna la disciplina seleccionada
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icono, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
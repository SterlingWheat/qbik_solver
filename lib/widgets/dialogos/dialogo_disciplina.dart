import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../gestores/globales/gestor_configuracion.dart';

class DialogoDisciplina extends StatelessWidget {
  const DialogoDisciplina({super.key});

  @override
  Widget build(BuildContext context) {
    final esOscuro = Get.isDarkMode;
    final colorTexto = esOscuro ? Colors.white : Colors.black87;

    return AlertDialog(
      backgroundColor: Get.theme.colorScheme.surface,
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
    final esOscuro = Get.isDarkMode;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Ejecutamos la vibración llamando a nuestro gestor global
        Get.find<GestorConfiguracion>().ejecutarVibracion();
        
        // Cerramos el diálogo retornando el título seleccionado
        Get.back(result: titulo); 
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Get.theme.colorScheme.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icono, color: Get.theme.colorScheme.primary),
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
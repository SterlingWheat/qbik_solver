import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TarjetaKPI extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color colorIcono;

  const TarjetaKPI({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos GetX para conocer el tema sin usar el context
    final esOscuro = Get.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esOscuro ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: colorIcono),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: esOscuro ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: esOscuro ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../gestores/globales/gestor_configuracion.dart';
import '../../widgets/comunes/fondo_decorativo.dart';

class PantallaConfiguracion extends StatelessWidget {
  const PantallaConfiguracion({super.key});

  @override
  Widget build(BuildContext context) {
    final gestorConfig = Get.find<GestorConfiguracion>();
    
    // 🔥 EL ARREGLO ESTÁ AQUÍ:
    // Al usar Theme.of(context), vinculamos TODA esta pantalla al cambio de tema.
    // Cuando el switch activa Get.changeThemeMode(), esto recalcula todo al instante.
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = esOscuro ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoDecorativo(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto),
                    onPressed: () {
                      gestorConfig.ejecutarVibracion();
                      Get.back(); 
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Configuración',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorTexto),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  _construirSeccion(
                    esOscuro: esOscuro,
                    titulo: 'Apariencia',
                    hijos: [
                      Obx(() => ListTile(
                        onTap: () => gestorConfig.establecerTemaOscuro(!gestorConfig.esTemaOscuro.value),
                        leading: Icon(Icons.dark_mode_rounded, color: Theme.of(context).colorScheme.primary),
                        title: Text('Tema Oscuro', style: TextStyle(color: colorTexto, fontWeight: FontWeight.w500)),
                        subtitle: Text('Reduce la fatiga visual', style: TextStyle(color: colorTexto.withOpacity(0.6))),
                        trailing: Switch(
                          value: gestorConfig.esTemaOscuro.value,
                          onChanged: (valor) => gestorConfig.establecerTemaOscuro(valor),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _construirSeccion(
                    esOscuro: esOscuro,
                    titulo: 'Accesibilidad y Sistema',
                    hijos: [
                      Obx(() => ListTile(
                        onTap: () => gestorConfig.establecerVibracionActiva(!gestorConfig.vibracionActiva.value),
                        leading: Icon(Icons.vibration_rounded, color: Theme.of(context).colorScheme.primary),
                        title: Text('Vibración Háptica', style: TextStyle(color: colorTexto, fontWeight: FontWeight.w500)),
                        subtitle: Text('Respuesta física al pulsar botones', style: TextStyle(color: colorTexto.withOpacity(0.6))),
                        trailing: Switch(
                          value: gestorConfig.vibracionActiva.value,
                          onChanged: (valor) => gestorConfig.establecerVibracionActiva(valor),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Las variables esOscuro y colorTexto se pasan actualizadas a este método
  Widget _construirSeccion({required String titulo, required bool esOscuro, required List<Widget> hijos}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            titulo.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: esOscuro ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: esOscuro ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: esOscuro ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(children: hijos),
        ),
      ],
    );
  }
}
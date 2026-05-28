import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../gestores/globales/gestor_estadisticas.dart';
import '../../gestores/globales/gestor_configuracion.dart';
import '../../widgets/comunes/fondo_decorativo.dart';
import '../../widgets/dialogos/dialogo_disciplina.dart';
import '../../widgets/estadisticas/tarjeta_kpi.dart';
import '../../widgets/estadisticas/grafico_tiempos.dart';

/// Controlador local para la selección del filtro de disciplina
class EstadisticasUIController extends GetxController {
  var disciplinaActual = "Cubo 3x3".obs;

  @override
  void onReady() {
    super.onReady();
    _preguntarDisciplina();
  }

  Future<void> _preguntarDisciplina() async {
    final resultado = await Get.dialog<String>(
      const DialogoDisciplina(),
      barrierDismissible: false,
    );

    if (resultado != null) {
      disciplinaActual.value = resultado;
    } else if (Get.previousRoute.isNotEmpty) {
      Get.back();
    }
  }

  void abrirSelectorManual() async {
    final resultado = await Get.dialog<String>(const DialogoDisciplina());
    if (resultado != null) {
      disciplinaActual.value = resultado;
    }
  }
}

class PantallaEstadisticas extends StatelessWidget {
  const PantallaEstadisticas({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializamos el UI local y buscamos el Gestor Global
    final uiCtrl = Get.put(EstadisticasUIController());
    final gestorEstadisticas = Get.find<GestorEstadisticas>();
    final colorTexto = Get.isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoDecorativo(
        child: Column(
          children: [
            // --- CABECERA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto),
                    onPressed: () {
                      Get.find<GestorConfiguracion>().ejecutarVibracion();
                      Get.back();
                    },
                  ),
                  GestureDetector(
                    onTap: uiCtrl.abrirSelectorManual,
                    child: Row(
                      children: [
                        Obx(() => Text(
                          uiCtrl.disciplinaActual.value,
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: Get.theme.colorScheme.primary
                          ),
                        )),
                        Icon(Icons.arrow_drop_down, color: Get.theme.colorScheme.primary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), 
                ],
              ),
            ),

            // --- CONTENIDO DINÁMICO ---
            Expanded(
              // Obx reaccionará automáticamente a cambios de disciplina O a nuevos tiempos
              child: Obx(() {
                final disciplina = uiCtrl.disciplinaActual.value;
                final tiempos = gestorEstadisticas.obtenerTiempos(disciplina);
                
                // ESTADO VACÍO (Si no hay tiempos)
                if (tiempos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_off_outlined, size: 80, color: Get.theme.colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 24),
                          Text(
                            "Aún no hay registros",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorTexto),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Ve al cronómetro y resuelve tu primer $disciplina para ver tus estadísticas.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: colorTexto.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ESTADO CON DATOS
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Grid de KPIs
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        TarjetaKPI(
                          titulo: 'MEJOR',
                          valor: gestorEstadisticas.obtenerMejorTiempo(disciplina),
                          icono: Icons.emoji_events_rounded,
                          colorIcono: Colors.amber,
                        ),
                        TarjetaKPI(
                          titulo: 'MEDIA',
                          valor: gestorEstadisticas.obtenerMedia(disciplina),
                          icono: Icons.functions_rounded,
                          colorIcono: Colors.blueAccent,
                        ),
                        TarjetaKPI(
                          titulo: 'ÚLTIMO',
                          valor: gestorEstadisticas.obtenerUltimoTiempo(disciplina),
                          icono: Icons.history_rounded,
                          colorIcono: Colors.greenAccent,
                        ),
                        TarjetaKPI(
                          titulo: 'PEOR',
                          valor: gestorEstadisticas.obtenerPeorTiempo(disciplina),
                          icono: Icons.trending_down_rounded,
                          colorIcono: Colors.redAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Sección del Gráfico
                    Text(
                      'Evolución de Tiempos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorTexto),
                    ),
                    const SizedBox(height: 16),
                    GraficoTiempos(tiempos: tiempos),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
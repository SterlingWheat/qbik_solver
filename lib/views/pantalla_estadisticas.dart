import 'package:flutter/material.dart';
import '../gestores/gestor_estadisticas.dart';
import '../gestores/gestor_configuracion.dart';
import '../widgets/fondo_decorativo.dart';
import '../widgets/dialogo_disciplina.dart';
import '../widgets/tarjeta_kpi.dart';
import '../widgets/grafico_tiempos.dart';

class PantallaEstadisticas extends StatefulWidget {
  const PantallaEstadisticas({super.key});

  @override
  State<PantallaEstadisticas> createState() => _EstadoPantallaEstadisticas();
}

class _EstadoPantallaEstadisticas extends State<PantallaEstadisticas> {
  String _disciplinaActual = "Cubo 3x3";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preguntarDisciplina();
    });
  }

  Future<void> _preguntarDisciplina() async {
    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DialogoDisciplina(),
    );

    if (resultado != null) {
      setState(() => _disciplinaActual = resultado);
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoDecorativo(
        child: Column(
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorTexto),
                    onPressed: () {
                      GestorConfiguracion().ejecutarVibracion();
                      Navigator.pop(context);
                    },
                  ),
                  GestureDetector(
                    onTap: _preguntarDisciplina,
                    child: Row(
                      children: [
                        Text(
                          _disciplinaActual,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                        Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance visual
                ],
              ),
            ),

            // Contenido dinámico observando el GestorEstadisticas
            Expanded(
              child: ListenableBuilder(
                listenable: GestorEstadisticas(),
                builder: (context, _) {
                  final tiempos = GestorEstadisticas().obtenerTiempos(_disciplinaActual);
                  
                  // ESTADO VACÍO (Si no hay tiempos)
                  if (tiempos.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_off_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                            const SizedBox(height: 24),
                            Text(
                              "Aún no hay registros",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorTexto),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Ve al cronómetro y resuelve tu primer $_disciplinaActual para ver tus estadísticas.",
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
                            valor: GestorEstadisticas().obtenerMejorTiempo(_disciplinaActual),
                            icono: Icons.emoji_events_rounded,
                            colorIcono: Colors.amber,
                          ),
                          TarjetaKPI(
                            titulo: 'MEDIA',
                            valor: GestorEstadisticas().obtenerMedia(_disciplinaActual),
                            icono: Icons.functions_rounded,
                            colorIcono: Colors.blueAccent,
                          ),
                          TarjetaKPI(
                            titulo: 'ÚLTIMO',
                            valor: GestorEstadisticas().obtenerUltimoTiempo(_disciplinaActual),
                            icono: Icons.history_rounded,
                            colorIcono: Colors.greenAccent,
                          ),
                          TarjetaKPI(
                            titulo: 'PEOR',
                            valor: GestorEstadisticas().obtenerPeorTiempo(_disciplinaActual),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
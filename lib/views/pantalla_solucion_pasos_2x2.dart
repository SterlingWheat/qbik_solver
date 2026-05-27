import 'package:flutter/material.dart';
import '../gestores/gestor_reproduccion_2x2.dart';
import '../widgets/fondo_decorativo.dart';

class PantallaSolucionPasos2x2 extends StatefulWidget {
  // El gestor es una variable final obligatoria del Widget padre
  final GestorReproduccion2x2 gestor;

  const PantallaSolucionPasos2x2({super.key, required this.gestor});

  @override
  State<PantallaSolucionPasos2x2> createState() => _EstadoPantallaSolucionPasos2x2();
}

class _EstadoPantallaSolucionPasos2x2 extends State<PantallaSolucionPasos2x2> {
  
  @override
  void dispose() {
    // ¡CORREGIDO! Se accede a través de 'widget.' para respetar el entorno inmutable
    widget.gestor.dispose();
    super.dispose();
  }

  Color _enteroAColor(int valor) {
    switch (valor) {
      case 0: return Colors.white;
      case 1: return Colors.red;
      case 2: return Colors.green;
      case 3: return Colors.yellow;
      case 4: return Colors.orange;
      case 5: return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solución Paso a Paso'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: FondoDecorativo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.gestor, // Escucha los cambios del reproductor de forma reactiva
            builder: (context, _) {
              final estadoActual = widget.gestor.estadoActual;
              final anchoPantalla = MediaQuery.of(context).size.width;
              final tamanoCara = (anchoPantalla * 0.7) / 4;

              return Column(
                children: [
                  // Panel superior de información de movimientos
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Theme.of(context).cardColor.withOpacity(0.85),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text("Giro Actual", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  widget.gestor.movimientoActualStr,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text("Progreso", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  "${widget.gestor.pasoActual} / ${widget.gestor.totalPasos}",
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Visualizador dinámico del cubo en Cruz 2D
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Fila 1: Arriba (U)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: tamanoCara),
                                _construirCaraEstatica(estadoActual.pegatinas, 0, "U", tamanoCara),
                                SizedBox(width: tamanoCara),
                                SizedBox(width: tamanoCara),
                              ],
                            ),
                            // Fila 2: L, F, R, B
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _construirCaraEstatica(estadoActual.pegatinas, 16, "L", tamanoCara),
                                _construirCaraEstatica(estadoActual.pegatinas, 8, "F", tamanoCara),
                                _construirCaraEstatica(estadoActual.pegatinas, 4, "R", tamanoCara),
                                _construirCaraEstatica(estadoActual.pegatinas, 20, "B", tamanoCara),
                              ],
                            ),
                            // Fila 3: Abajo (D)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: tamanoCara),
                                _construirCaraEstatica(estadoActual.pegatinas, 12, "D", tamanoCara),
                                SizedBox(width: tamanoCara),
                                SizedBox(width: tamanoCara),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Control Remoto / Consola de reproducción inferior
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Control de barra de reproducción slider
                        if (widget.gestor.totalPasos > 0)
                          Slider(
                            value: widget.gestor.pasoActual.toDouble(),
                            min: 0,
                            max: widget.gestor.totalPasos.toDouble(),
                            divisions: widget.gestor.totalPasos,
                            onChanged: (val) {
                              // Se conecta el Slider con el método saltarA del gestor
                              widget.gestor.saltarA(val.toInt());
                            },
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              iconSize: 32,
                              icon: const Icon(Icons.replay_10),
                              onPressed: widget.gestor.pasoActual > 0 
                                  ? () => widget.gestor.retroceder() // CORREGIDO
                                  : null,
                            ),
                            const SizedBox(width: 24),
                            // BOTÓN CENTRAL DE PLAY / PAUSE
                            FloatingActionButton.large(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              onPressed: () => widget.gestor.alternarReproduccion(),
                              child: Icon(
                                widget.gestor.estaReproduciendo ? Icons.pause : Icons.play_arrow,
                                size: 42,
                              ),
                            ),
                            const SizedBox(width: 24),
                            IconButton.filledTonal(
                              iconSize: 32,
                              icon: const Icon(Icons.forward_10),
                              onPressed: widget.gestor.pasoActual < widget.gestor.totalPasos
                                  ? () => widget.gestor.avanzar() // CORREGIDO
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _construirCaraEstatica(List<int> pegatinas, int indiceBase, String etiqueta, double tamano) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black26,
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _construirStickerEstatico(pegatinas[indiceBase + 0]),
                    _construirStickerEstatico(pegatinas[indiceBase + 1]),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    _construirStickerEstatico(pegatinas[indiceBase + 2]),
                    _construirStickerEstatico(pegatinas[indiceBase + 3]),
                  ],
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              etiqueta,
              style: TextStyle(
                color: Colors.black.withOpacity(0.15),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirStickerEstatico(int idColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(1.0),
        decoration: BoxDecoration(
          color: _enteroAColor(idColor),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
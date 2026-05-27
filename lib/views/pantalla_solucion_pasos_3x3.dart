import 'package:flutter/material.dart';
import '../gestores/gestor_reproduccion_3x3.dart';
import '../widgets/fondo_decorativo.dart';

class PantallaSolucionPasos3x3 extends StatefulWidget {
  final GestorReproduccion3x3 gestor;

  const PantallaSolucionPasos3x3({super.key, required this.gestor});

  @override
  State<PantallaSolucionPasos3x3> createState() => _EstadoPantallaSolucionPasos3x3();
}

class _EstadoPantallaSolucionPasos3x3 extends State<PantallaSolucionPasos3x3> {
  
  @override
  void dispose() {
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
        title: const Text('Solución 3x3'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: FondoDecorativo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.gestor,
            builder: (context, _) {
              final estadoActual = widget.gestor.estadoActual;
              final anchoPantalla = MediaQuery.of(context).size.width;
              // Calculamos el tamaño exacto para que quepan 4 caras de 3x3 a lo ancho
              final tamanoCara = (anchoPantalla * 0.9) / 4; 

              return Column(
                children: [
                  // 1. AVISO CRÍTICO DE ORIENTACIÓN FÍSICA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade600, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.amber.shade800, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "PUNTO DE PARTIDA OBLIGATORIO",
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.amber.shade900
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Sostén el cubo con la cara BLANCA arriba y la VERDE mirándote de frente.",
                                  style: TextStyle(
                                    fontSize: 14, 
                                    color: Colors.amber.shade900,
                                    height: 1.2
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. PANEL DEL ALGORITMO Y PROGRESO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: Theme.of(context).cardColor.withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  "MOVIMIENTO", 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.gestor.movimientoActualStr,
                                  style: const TextStyle(
                                    fontSize: 48, 
                                    fontWeight: FontWeight.w900, 
                                    color: Colors.blueAccent,
                                    fontFamily: 'monospace' // Letra monoespaciada para notaciones matemáticas
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 2, height: 60, color: Colors.grey.withOpacity(0.3)),
                            Column(
                              children: [
                                const Text(
                                  "PASO", 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${widget.gestor.pasoActual} / ${widget.gestor.totalPasos}",
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. VISUALIZADOR DINÁMICO DEL CUBO 3x3 EN CRUZ
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Fila 1: Arriba (U - Índices 0 al 8)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: tamanoCara),
                                _construirCaraEstatica3x3(estadoActual.pegatinas, 0, "U", tamanoCara),
                                SizedBox(width: tamanoCara),
                                SizedBox(width: tamanoCara),
                              ],
                            ),
                            // Fila 2: L (36), F (18), R (9), B (45)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _construirCaraEstatica3x3(estadoActual.pegatinas, 36, "L", tamanoCara),
                                _construirCaraEstatica3x3(estadoActual.pegatinas, 18, "F", tamanoCara),
                                _construirCaraEstatica3x3(estadoActual.pegatinas, 9, "R", tamanoCara),
                                _construirCaraEstatica3x3(estadoActual.pegatinas, 45, "B", tamanoCara),
                              ],
                            ),
                            // Fila 3: Abajo (D - Índices 27 al 35)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: tamanoCara),
                                _construirCaraEstatica3x3(estadoActual.pegatinas, 27, "D", tamanoCara),
                                SizedBox(width: tamanoCara),
                                SizedBox(width: tamanoCara),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. CONTROL REMOTO / CONSOLA DE REPRODUCCIÓN
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.gestor.totalPasos > 0)
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.blueAccent,
                              thumbColor: Colors.blueAccent,
                              overlayColor: Colors.blueAccent.withOpacity(0.2),
                              trackHeight: 6.0,
                            ),
                            child: Slider(
                              value: widget.gestor.pasoActual.toDouble(),
                              min: 0,
                              max: widget.gestor.totalPasos.toDouble(),
                              divisions: widget.gestor.totalPasos,
                              onChanged: (val) => widget.gestor.saltarA(val.toInt()),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              iconSize: 32,
                              icon: const Icon(Icons.skip_previous_rounded),
                              onPressed: widget.gestor.pasoActual > 0 
                                  ? () => widget.gestor.retroceder() 
                                  : null,
                            ),
                            const SizedBox(width: 24),
                            FloatingActionButton.large(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              onPressed: () => widget.gestor.alternarReproduccion(),
                              child: Icon(
                                widget.gestor.estaReproduciendo ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 48,
                              ),
                            ),
                            const SizedBox(width: 24),
                            IconButton.filledTonal(
                              iconSize: 32,
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: widget.gestor.pasoActual < widget.gestor.totalPasos
                                  ? () => widget.gestor.avanzar() 
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

  /// Construye una cara de 3x3 piezas (9 stickers)
  Widget _construirCaraEstatica3x3(List<int> pegatinas, int indiceBase, String etiqueta, double tamano) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38, width: 0.8),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _construirFila3(pegatinas, indiceBase + 0, indiceBase + 1, indiceBase + 2)),
              Expanded(child: _construirFila3(pegatinas, indiceBase + 3, indiceBase + 4, indiceBase + 5)),
              Expanded(child: _construirFila3(pegatinas, indiceBase + 6, indiceBase + 7, indiceBase + 8)),
            ],
          ),
          // Marca de agua central semitransparente (U, D, R, L, F, B)
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Text(
                etiqueta,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFila3(List<int> pegatinas, int i1, int i2, int i3) {
    return Row(
      children: [
        _construirStickerEstatico(pegatinas[i1]),
        _construirStickerEstatico(pegatinas[i2]),
        _construirStickerEstatico(pegatinas[i3]),
      ],
    );
  }

  Widget _construirStickerEstatico(int idColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: _enteroAColor(idColor),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
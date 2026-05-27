import 'package:flutter/material.dart';
import '../gestores/gestor_ingreso_2x2.dart';
import '../servicios/validador_2x2.dart';
import '../servicios/solver_bfs_2x2.dart';
import '../gestores/gestor_reproduccion_2x2.dart';
import '../widgets/despliegue_cruz_2x2.dart';
import '../widgets/fondo_decorativo.dart';
import 'pantalla_solucion_pasos_2x2.dart';

class PantallaIngresoManual2x2 extends StatefulWidget {
  const PantallaIngresoManual2x2({super.key});

  @override
  State<PantallaIngresoManual2x2> createState() => _EstadoPantallaIngresoManual2x2();
}

class _EstadoPantallaIngresoManual2x2 extends State<PantallaIngresoManual2x2> {
  // El gestor del estado local de ingreso se declara como final aquí correctamente
  final GestorIngreso2x2 _gestor = GestorIngreso2x2();
  bool _estaCalculando = false;

  @override
  void dispose() {
    _gestor.dispose();
    super.dispose();
  }

  Future<void> _ejecutarResolucion() async {
    // 1. Validar la integridad del mapeo plano
    ResultadoValidacion2x2 resultado = Validador2x2.validarArregloPlano(_gestor.pegatinas);
    
    if (!resultado.esValido) {
      _mostrarSnackBar(resultado.mensajeError ?? "Error de validación", esError: true);
      return;
    }

    final estadoActual = resultado.estadoCubo!;

    // 2. Cortocircuito: Si el cubo ya está resuelto, evitamos cálculos inútiles
    if (estadoActual.estaResuelto) {
      _mostrarSnackBar("✅ El cubo ya está resuelto. ¡No hay nada que calcular!", esError: false);
      return;
    }

    setState(() => _estaCalculando = true);

    try {
      // 3. Llamada al Solver asíncrono (BFS)
      List<String> solucion = await SolverBFS2x2.resolver(estadoActual);

      if (!mounted) return;

      // Se instancia de forma segura el gestor de reproducción inmutable para la siguiente vista
      final gestorReproduccion = GestorReproduccion2x2(
        estadoInicial: estadoActual,
        algoritmoSolucion: solucion,
      );

      // 4. Navegación pasándole el objeto final
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaSolucionPasos2x2(gestor: gestorReproduccion),
        ),
      );
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar(e.toString().replaceAll('Exception: ', ''), esError: true);
      }
    } finally {
      if (mounted) setState(() => _estaCalculando = false);
    }
  }

  void _mostrarSnackBar(String texto, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? Colors.red.shade800 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso Manual 2x2'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: FondoDecorativo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _gestor,
            builder: (context, _) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Sostén tu cubo con la cara Blanca hacia Arriba (U) y la Verde al Frente (F). Copia los colores aquí:",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _gestor.limpiarTodo,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Limpiar"),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: _gestor.llenarResuelto,
                        icon: const Icon(Icons.playlist_add_check),
                        label: const Text("Llenar Armado"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: DespliegueCruz2x2(
                          pegatinas: _gestor.pegatinas,
                          alTocarPegatina: _gestor.pintarPegatina,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Colors.white, Colors.red, Colors.green,
                            Colors.yellow, Colors.orange, Colors.blue
                          ].map((color) => _construirBotonColor(color)).toList(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _estaCalculando ? null : _ejecutarResolucion,
                            icon: _estaCalculando 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_awesome),
                            label: Text(_estaCalculando ? 'CALCULANDO...' : 'RESOLVER'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
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

  Widget _construirBotonColor(Color color) {
    bool seleccionado = _gestor.colorSeleccionado == color;
    return GestureDetector(
      onTap: () => _gestor.seleccionarColor(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: seleccionado ? Theme.of(context).colorScheme.primary : Colors.black26,
            width: seleccionado ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
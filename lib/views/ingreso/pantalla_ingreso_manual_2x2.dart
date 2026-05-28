import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../gestores/cubo_2x2/gestor_ingreso_2x2.dart';
import '../../gestores/cubo_2x2/gestor_reproduccion_2x2.dart';
import '../../servicios/validadores/validador_2x2.dart';
import '../../servicios/solvers/solver_bfs_2x2.dart';
import '../../widgets/cubo_2x2/despliegue_cruz_2x2.dart';
import '../../widgets/comunes/fondo_decorativo.dart';

/// Controlador local para manejar la UI de la pantalla de ingreso 2x2
class IngresoManual2x2UIController extends GetxController {
  // Inyectamos el gestor lógico de ingreso de datos
  final gestorIngreso = Get.put(GestorIngreso2x2());
  
  // Variable reactiva para bloquear el botón mientras el Solver trabaja
  var estaCalculando = false.obs;

  Future<void> ejecutarResolucion() async {
    // 1. Validar la integridad del mapeo plano
    ResultadoValidacion2x2 resultado = Validador2x2.validarArregloPlano(gestorIngreso.pegatinas);
    
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

    estaCalculando.value = true;

    try {
      // 3. Llamada al Solver asíncrono (BFS)
      List<String> solucion = await SolverBFS2x2.resolver(estadoActual);

      // Se instancia de forma segura el gestor de reproducción inmutable para la siguiente vista
      final gestorReproduccion = GestorReproduccion2x2(
        estadoInicial: estadoActual,
        algoritmoSolucion: solucion,
      );

      // 4. Navegación usando GetX, pasando el gestor al reproductor
      Get.toNamed('/solucion-pasos-2x2', arguments: gestorReproduccion);
    } catch (e) {
      _mostrarSnackBar(e.toString().replaceAll('Exception: ', ''), esError: true);
    } finally {
      estaCalculando.value = false;
    }
  }

  void _mostrarSnackBar(String texto, {required bool esError}) {
    Get.snackbar(
      esError ? 'Error' : 'Aviso',
      texto,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: esError ? Colors.red.shade800 : Colors.green.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }
}

class PantallaIngresoManual2x2 extends StatelessWidget {
  const PantallaIngresoManual2x2({super.key});

  @override
  Widget build(BuildContext context) {
    // Instanciamos nuestro controlador local
    final uiCtrl = Get.put(IngresoManual2x2UIController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso Manual 2x2'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Liberamos la memoria al volver atrás
            Get.delete<IngresoManual2x2UIController>();
            Get.delete<GestorIngreso2x2>();
            Get.back();
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: FondoDecorativo(
        child: SafeArea(
          // GetBuilder reacciona solo cuando el usuario pinta o borra una pegatina
          child: GetBuilder<GestorIngreso2x2>(
            builder: (gestor) {
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
                  
                  // Botones de acción rápida
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: gestor.limpiarTodo,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Limpiar"),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: gestor.llenarResuelto,
                        icon: const Icon(Icons.playlist_add_check),
                        label: const Text("Llenar Armado"),
                      ),
                    ],
                  ),
                  
                  // Componente del Cubo Desplegado (Reutilizado)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: DespliegueCruz2x2(
                          pegatinas: gestor.pegatinas,
                          alTocarPegatina: gestor.pintarPegatina,
                        ),
                      ),
                    ),
                  ),
                  
                  // Panel Inferior (Paleta de Colores y Botón Resolver)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Get.theme.cardColor.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Fila con los 6 colores estándar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Colors.white, Colors.red, Colors.green,
                            Colors.yellow, Colors.orange, Colors.blue
                          ].map((color) => _construirBotonColor(color, gestor)).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Botón Resolver (Enlazado con Obx para la animación de carga)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Obx(() {
                            final calculando = uiCtrl.estaCalculando.value;
                            return FilledButton.icon(
                              // Si está calculando o faltan piezas, se deshabilita el botón
                              onPressed: (calculando || !gestor.estaCompleto()) ? null : uiCtrl.ejecutarResolucion,
                              icon: calculando 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.auto_awesome),
                              label: Text(calculando ? 'CALCULANDO...' : 'RESOLVER'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            );
                          }),
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

  Widget _construirBotonColor(Color color, GestorIngreso2x2 gestor) {
    bool seleccionado = gestor.colorSeleccionado == color;
    
    return GestureDetector(
      onTap: () => gestor.seleccionarColor(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: seleccionado ? Get.theme.colorScheme.primary : Colors.black26,
            width: seleccionado ? 3 : 1,
          ),
          boxShadow: seleccionado ? [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)
          ] : [],
        ),
      ),
    );
  }
}
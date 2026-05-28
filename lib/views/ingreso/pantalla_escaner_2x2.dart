import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../gestores/globales/gestor_configuracion.dart';
import '../../gestores/cubo_2x2/gestor_escaner_2x2.dart';
import '../../gestores/cubo_2x2/gestor_reproduccion_2x2.dart';
import '../../servicios/validadores/validador_2x2.dart';
import '../../servicios/solvers/solver_bfs_2x2.dart';
import '../../widgets/comunes/fondo_decorativo.dart';

/// Controlador local para la interfaz gráfica del Escáner
class EscanerUIController extends GetxController {
  // Inyectamos el gestor lógico del escáner
  final gestorEscaner = Get.put(GestorEscaner2x2());
  
  // Variable reactiva para el estado del botón
  var estaCalculando = false.obs;

  Future<void> abrirCamaraParaCara(int indiceCara, String nombreCara) async {
    Get.find<GestorConfiguracion>().ejecutarVibracion();
    
    // Navegamos usando GetX y esperamos el resultado (los colores detectados)
    // Pasamos nombreCara como parámetro dinámico
    final coloresDetectados = await Get.toNamed('/camara-2x2', arguments: nombreCara);

    if (coloresDetectados != null && coloresDetectados is List<Color> && coloresDetectados.length == 4) {
      gestorEscaner.guardarCaraEscaneada(indiceCara, coloresDetectados);
    }
  }

  Future<void> ejecutarResolucion() async {
    ResultadoValidacion2x2 resultado = Validador2x2.validarArregloPlano(gestorEscaner.obtenerPegatinasPlanas());
    
    if (!resultado.esValido) {
      _mostrarSnackBar(resultado.mensajeError ?? "Error de lectura en cámara", esError: true);
      return;
    }

    final estadoActual = resultado.estadoCubo!;

    if (estadoActual.estaResuelto) {
      _mostrarSnackBar("✅ El cubo ya está resuelto.", esError: false);
      return;
    }

    estaCalculando.value = true;

    try {
      List<String> solucion = await SolverBFS2x2.resolver(estadoActual);

      // Instanciamos el reproductor y lo pasamos por argumentos a la siguiente ruta
      final gestorReproduccion = GestorReproduccion2x2(
        estadoInicial: estadoActual,
        algoritmoSolucion: solucion,
      );

      // offNamed reemplaza la vista actual (Navigator.pushReplacement)
      Get.offNamed('/solucion-pasos-2x2', arguments: gestorReproduccion);
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

class PantallaEscaner2x2 extends StatelessWidget {
  const PantallaEscaner2x2({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializamos el controlador local de UI
    final uiCtrl = Get.put(EscanerUIController());
    final esOscuro = Get.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner IA 2x2'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Al retroceder, borramos los gestores locales para liberar memoria
            Get.delete<EscanerUIController>();
            Get.delete<GestorEscaner2x2>();
            Get.back();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              Get.find<GestorConfiguracion>().ejecutarVibracion();
              uiCtrl.gestorEscaner.reiniciarEscaner();
            },
            tooltip: 'Reiniciar Escaneo',
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: FondoDecorativo(
        child: SafeArea(
          // GetBuilder reacciona a los cambios en el Gestor lógico (cuando se escanea una cara)
          child: GetBuilder<GestorEscaner2x2>(
            builder: (gestor) {
              final anchoPantalla = Get.width;
              final tamanoCara = (anchoPantalla * 0.85) / 4;

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Toca cada cara para abrir la cámara inteligente.\nAsegúrate de tener la cara Blanca arriba (U) y la Verde al frente (F).",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  
                  // Despliegue en Cruz Interactivo
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: tamanoCara),
                                _construirBotonCara(0, "U", tamanoCara, uiCtrl, esOscuro),
                                SizedBox(width: tamanoCara),
                                SizedBox(width: tamanoCara),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _construirBotonCara(4, "L", tamanoCara, uiCtrl, esOscuro),
                                _construirBotonCara(2, "F", tamanoCara, uiCtrl, esOscuro),
                                _construirBotonCara(1, "R", tamanoCara, uiCtrl, esOscuro),
                                _construirBotonCara(5, "B", tamanoCara, uiCtrl, esOscuro),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: tamanoCara),
                                _construirBotonCara(3, "D", tamanoCara, uiCtrl, esOscuro),
                                SizedBox(width: tamanoCara),
                                SizedBox(width: tamanoCara),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Botón de resolución inferior
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Get.theme.cardColor.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      // Obx para reaccionar al estado de "_estaCalculando"
                      child: Obx(() {
                        final calculando = uiCtrl.estaCalculando.value;
                        final completo = gestor.estaCompleto();

                        return FilledButton.icon(
                          onPressed: (calculando || !completo) ? null : uiCtrl.ejecutarResolucion,
                          icon: calculando 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.document_scanner_rounded),
                          label: Text(calculando ? 'CALCULANDO...' : 'RESOLVER CUBO'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }),
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

  Widget _construirBotonCara(int indiceCara, String etiqueta, double tamano, EscanerUIController uiCtrl, bool esOscuro) {
    final bool estaEscaneada = uiCtrl.gestorEscaner.caraEstaEscaneada(indiceCara);

    return GestureDetector(
      onTap: () => uiCtrl.abrirCamaraParaCara(indiceCara, etiqueta),
      child: Container(
        width: tamano,
        height: tamano,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: estaEscaneada 
              ? Colors.transparent 
              : (esOscuro ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: estaEscaneada ? Colors.transparent : Colors.blueAccent.withOpacity(0.5),
            width: estaEscaneada ? 0 : 2,
          ),
        ),
        child: estaEscaneada
            ? _construirCuadriculaColores(uiCtrl.gestorEscaner.obtenerColoresCara(indiceCara))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.blueAccent.withOpacity(0.8), size: tamano * 0.35),
                  const SizedBox(height: 4),
                  Text(
                    etiqueta,
                    style: TextStyle(fontWeight: FontWeight.bold, color: esOscuro ? Colors.white70 : Colors.black87),
                  )
                ],
              ),
      ),
    );
  }

  Widget _construirCuadriculaColores(List<Color> colores) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _construirStickerDetectado(colores[0]),
              _construirStickerDetectado(colores[1]),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _construirStickerDetectado(colores[2]),
              _construirStickerDetectado(colores[3]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirStickerDetectado(Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black26, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2, offset: const Offset(1, 1))
          ]
        ),
      ),
    );
  }
}
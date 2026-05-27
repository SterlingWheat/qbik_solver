import 'package:flutter/material.dart';
import '../gestores/gestor_configuracion.dart';
import '../gestores/gestor_escaner_2x2.dart';
import '../servicios/validador_2x2.dart';
import '../servicios/solver_bfs_2x2.dart';
import '../gestores/gestor_reproduccion_2x2.dart';
import '../widgets/fondo_decorativo.dart';
import 'pantalla_solucion_pasos_2x2.dart';
import 'pantalla_camara_2x2.dart';

class PantallaEscaner2x2 extends StatefulWidget {
  const PantallaEscaner2x2({super.key});

  @override
  State<PantallaEscaner2x2> createState() => _EstadoPantallaEscaner2x2();
}

class _EstadoPantallaEscaner2x2 extends State<PantallaEscaner2x2> {
  // Inicializamos el gestor que crearemos en el siguiente paso
  final GestorEscaner2x2 _gestor = GestorEscaner2x2();
  bool _estaCalculando = false;

  @override
  void dispose() {
    _gestor.dispose();
    super.dispose();
  }

  Future<void> _abrirCamaraParaCara(int indiceCara, String nombreCara) async {
    GestorConfiguracion().ejecutarVibracion();
    
    // Navegamos a la cámara y esperamos el resultado (List<Color> de 4 elementos)
    final coloresDetectados = await Navigator.push<List<Color>>(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaCamara2x2(nombreCara: nombreCara),
      ),
    );

    if (coloresDetectados != null && coloresDetectados.length == 4) {
      _gestor.guardarCaraEscaneada(indiceCara, coloresDetectados);
    }
  }

  Future<void> _ejecutarResolucion() async {
    // Reusamos tu excelente Validador2x2
    ResultadoValidacion2x2 resultado = Validador2x2.validarArregloPlano(_gestor.obtenerPegatinasPlanas());
    
    if (!resultado.esValido) {
      _mostrarSnackBar(resultado.mensajeError ?? "Error de lectura en cámara", esError: true);
      return;
    }

    final estadoActual = resultado.estadoCubo!;

    if (estadoActual.estaResuelto) {
      _mostrarSnackBar("✅ El cubo ya está resuelto.", esError: false);
      return;
    }

    setState(() => _estaCalculando = true);

    try {
      List<String> solucion = await SolverBFS2x2.resolver(estadoActual);

      if (!mounted) return;

      final gestorReproduccion = GestorReproduccion2x2(
        estadoInicial: estadoActual,
        algoritmoSolucion: solucion,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaSolucionPasos2x2(gestor: gestorReproduccion),
        ),
      );
    } catch (e) {
      if (mounted) _mostrarSnackBar(e.toString().replaceAll('Exception: ', ''), esError: true);
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
        title: const Text('Escáner IA 2x2'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              GestorConfiguracion().ejecutarVibracion();
              _gestor.reiniciarEscaner();
            },
            tooltip: 'Reiniciar Escaneo',
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: FondoDecorativo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _gestor,
            builder: (context, _) {
              final anchoPantalla = MediaQuery.of(context).size.width;
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
                            // Fila 1: U
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: tamanoCara),
                                _construirBotonCara(0, "U", tamanoCara),
                                SizedBox(width: tamanoCara),
                                SizedBox(width: tamanoCara),
                              ],
                            ),
                            // Fila 2: L, F, R, B
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _construirBotonCara(4, "L", tamanoCara),
                                _construirBotonCara(2, "F", tamanoCara),
                                _construirBotonCara(1, "R", tamanoCara),
                                _construirBotonCara(5, "B", tamanoCara),
                              ],
                            ),
                            // Fila 3: D
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: tamanoCara),
                                _construirBotonCara(3, "D", tamanoCara),
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
                      color: Theme.of(context).cardColor.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton.icon(
                        // Solo se habilita si las 6 caras fueron escaneadas
                        onPressed: (_estaCalculando || !_gestor.estaCompleto()) ? null : _ejecutarResolucion,
                        icon: _estaCalculando 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.document_scanner_rounded),
                        label: Text(_estaCalculando ? 'CALCULANDO...' : 'RESOLVER CUBO'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
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

  /// Construye el botón interactivo para una cara.
  /// Mapeo de índices para el gestor: 0=U, 1=R, 2=F, 3=D, 4=L, 5=B
  Widget _construirBotonCara(int indiceCara, String etiqueta, double tamano) {
    final bool estaEscaneada = _gestor.caraEstaEscaneada(indiceCara);
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _abrirCamaraParaCara(indiceCara, etiqueta),
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
            ? _construirCuadriculaColores(_gestor.obtenerColoresCara(indiceCara))
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

  /// Pinta la cuadrícula 2x2 si la cara ya fue detectada por la IA
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
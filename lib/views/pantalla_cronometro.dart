import 'package:flutter/material.dart';
import 'dart:async';
import '../gestores/gestor_configuracion.dart';
import '../widgets/fondo_decorativo.dart';
import '../widgets/dialogo_disciplina.dart';
import '../widgets/dialogo_guardar_tiempo.dart';
import '../gestores/gestor_estadisticas.dart';
import 'pantalla_estadisticas.dart';

class PantallaCronometro extends StatefulWidget {
  const PantallaCronometro({super.key});

  @override
  State<PantallaCronometro> createState() => _EstadoPantallaCronometro();
}

class _EstadoPantallaCronometro extends State<PantallaCronometro> {
  String _disciplinaActual = "Cubo 3x3"; // Valor por defecto
  
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timerRenderizado;
  
  // Para la UI
  String _tiempoMostrado = "00.000";
  bool _estaCorriendo = false;

  @override
  void initState() {
    super.initState();
    // Mostramos el modal de disciplina justo después de construir la pantalla por primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preguntarDisciplina();
    });
  }

  @override
  void dispose() {
    _timerRenderizado?.cancel();
    super.dispose();
  }

  Future<void> _preguntarDisciplina() async {
    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Obliga al usuario a elegir
      builder: (context) => const DialogoDisciplina(),
    );

    if (resultado != null) {
      setState(() {
        _disciplinaActual = resultado;
      });
    } else {
      // Si por alguna razón cierra el diálogo sin elegir, volvemos atrás
      if (mounted) Navigator.pop(context);
    }
  }

  void _manejarToquePantalla() {
    GestorConfiguracion().ejecutarVibracion();

    if (_estaCorriendo) {
      // DETENER
      _detenerCronometro();
    } else {
      // INICIAR
      _iniciarCronometro();
    }
  }

  void _iniciarCronometro() {
    _stopwatch.reset();
    _stopwatch.start();
    _estaCorriendo = true;
    
    // Timer para actualizar la pantalla a 60 FPS aprox (cada 16ms)
    _timerRenderizado = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _actualizarTiempoMostrado();
    });
    
    setState(() {});
  }

  void _detenerCronometro() async {
    _stopwatch.stop();
    _timerRenderizado?.cancel();
    _estaCorriendo = false;
    _actualizarTiempoMostrado(); // Última actualización precisa
    setState(() {});

    // Mostrar modal para guardar el tiempo
    final guardar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogoGuardarTiempo(
        tiempo: _tiempoMostrado,
        disciplina: _disciplinaActual,
      ),
    );

    // Regla de oro en Flutter: verificar si el widget sigue vivo después de un await
    if (!mounted) return;

    if (guardar == true) {
      // 1. Guardamos el tiempo usando los milisegundos reales
      final milisegundos = _stopwatch.elapsedMilliseconds;
      GestorEstadisticas().guardarTiempo(_disciplinaActual, milisegundos);
      
      // 2. Navegamos automáticamente a estadísticas
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaEstadisticas()),
      );
    } else {
      // 3. SOLO reiniciamos visualmente el cronómetro si NO navegamos
      // (Es decir, si el usuario presionó "Descartar")
      setState(() {
        _stopwatch.reset();
        _tiempoMostrado = "00.000";
      });
    }
  }

  void _actualizarTiempoMostrado() {
    final milisegundosTotales = _stopwatch.elapsedMilliseconds;
    
    final minutos = (milisegundosTotales / 60000).floor();
    final segundos = ((milisegundosTotales % 60000) / 1000).floor();
    final milisegundos = milisegundosTotales % 1000;

    // Formatear al estilo speedcubing: (m):ss.mmm
    String tiempoFormateado = "";
    if (minutos > 0) {
      tiempoFormateado += "$minutos:";
      tiempoFormateado += "${segundos.toString().padLeft(2, '0')}.";
    } else {
      tiempoFormateado += "${segundos.toString().padLeft(2, '0')}.";
    }
    tiempoFormateado += milisegundos.toString().padLeft(3, '0');

    if (mounted) {
      setState(() {
        _tiempoMostrado = tiempoFormateado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTexto = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoDecorativo(
        // GestureDetector ocupa toda la pantalla
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // Detecta toques en espacios vacíos
          onTap: _manejarToquePantalla,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior
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
                    Text(
                      _disciplinaActual,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 48), // Espacio para centrar el título
                  ],
                ),
              ),

              // Área central del Cronómetro Gigante
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Instrucción visual (Se oculta al correr)
                      AnimatedOpacity(
                        opacity: _estaCorriendo ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          'Toca en cualquier lugar para iniciar',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorTexto.withOpacity(0.5),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Cronómetro Gigante
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            _tiempoMostrado,
                            style: TextStyle(
                              fontSize: 120, // Tamaño gigante
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: -2.0,
                              color: colorTexto,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
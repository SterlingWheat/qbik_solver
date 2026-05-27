import 'package:flutter/material.dart';
import 'dart:ui';
import '../gestores/gestor_configuracion.dart';

class TarjetaMetodoIngreso extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final VoidCallback alPresionar;
  final int indice; // Para animar la entrada en cascada

  const TarjetaMetodoIngreso({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.alPresionar,
    required this.indice,
  });

  @override
  State<TarjetaMetodoIngreso> createState() => _EstadoTarjetaMetodoIngreso();
}

class _EstadoTarjetaMetodoIngreso extends State<TarjetaMetodoIngreso> with TickerProviderStateMixin {
  late AnimationController _controladorEntrada;
  late Animation<double> _animacionOpacidad;
  late Animation<Offset> _animacionDeslizamiento;

  late AnimationController _controladorToque;
  late Animation<double> _animacionEscala;

  @override
  void initState() {
    super.initState();

    _controladorEntrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animacionOpacidad = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controladorEntrada, curve: Curves.easeOut),
    );
    _animacionDeslizamiento = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controladorEntrada, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: 150 * widget.indice), () {
      if (mounted) _controladorEntrada.forward();
    });

    _controladorToque = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _animacionEscala = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controladorToque, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controladorEntrada.dispose();
    _controladorToque.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return FadeTransition(
      opacity: _animacionOpacidad,
      child: SlideTransition(
        position: _animacionDeslizamiento,
        child: GestureDetector(
          onTapDown: (_) => _controladorToque.forward(),
          onTapUp: (_) {
            _controladorToque.reverse();
            GestorConfiguracion().ejecutarVibracion();
            widget.alPresionar();
          },
          onTapCancel: () => _controladorToque.reverse(),
          child: ScaleTransition(
            scale: _animacionEscala,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: esOscuro ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: esOscuro ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Contenedor del ícono con brillo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorPrimario.withOpacity(0.15),
                        ),
                        child: Icon(
                          widget.icono,
                          size: 40,
                          color: esOscuro ? Colors.white : colorPrimario,
                          shadows: [
                            Shadow(color: colorPrimario.withOpacity(0.5), blurRadius: 10)
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Textos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.titulo,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: esOscuro ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.subtitulo,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                color: esOscuro ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Flecha indicadora
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: (esOscuro ? Colors.white : Colors.black).withOpacity(0.3),
                        size: 20,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
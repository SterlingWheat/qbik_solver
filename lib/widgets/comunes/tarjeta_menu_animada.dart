import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import '../../gestores/globales/gestor_configuracion.dart';

class TarjetaMenuAnimada extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final VoidCallback alPresionar;
  final int indice;

  const TarjetaMenuAnimada({
    super.key,
    required this.titulo,
    required this.icono,
    required this.alPresionar,
    required this.indice,
  });

  @override
  State<TarjetaMenuAnimada> createState() => _EstadoTarjetaMenuAnimada();
}

class _EstadoTarjetaMenuAnimada extends State<TarjetaMenuAnimada> with TickerProviderStateMixin {
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
    _animacionDeslizamiento = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controladorEntrada, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: 100 * widget.indice), () {
      if (mounted) _controladorEntrada.forward();
    });

    _controladorToque = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _animacionEscala = Tween<double>(begin: 1.0, end: 0.92).animate(
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
    final colorTextoIcono = esOscuro ? Colors.white : const Color(0xFF1E293B);
    final colorFondoCristal = esOscuro ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03);
    final colorBorde = esOscuro ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.08);
    final colorSombra = esOscuro ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.05);

    return FadeTransition(
      opacity: _animacionOpacidad,
      child: SlideTransition(
        position: _animacionDeslizamiento,
        child: GestureDetector(
          onTapDown: (_) => _controladorToque.forward(),
          onTapUp: (_) {
            _controladorToque.reverse();
            // Ejecutamos la vibración localizando nuestro gestor global de GetX
            Get.find<GestorConfiguracion>().ejecutarVibracion();
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
                  decoration: BoxDecoration(
                    color: colorFondoCristal,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colorBorde, width: 1.5),
                    boxShadow: [BoxShadow(color: colorSombra, blurRadius: 20, spreadRadius: 1)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          widget.icono,
                          size: 64,
                          color: colorTextoIcono,
                          shadows: [
                            Shadow(
                              color: Get.theme.colorScheme.primary.withOpacity(esOscuro ? 1.0 : 0.4),
                              blurRadius: 15,
                            )
                          ],
                        ),
                        Text(
                          widget.titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: colorTextoIcono,
                          ),
                        ),
                      ],
                    ),
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
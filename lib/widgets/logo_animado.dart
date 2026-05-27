import 'package:flutter/material.dart';

class LogoAnimado extends StatefulWidget {
  const LogoAnimado({super.key});

  @override
  State<LogoAnimado> createState() => _EstadoLogoAnimado();
}

class _EstadoLogoAnimado extends State<LogoAnimado> with SingleTickerProviderStateMixin {
  late AnimationController _controlador;
  late Animation<double> _animacionEscala;
  late Animation<double> _animacionOpacidad;

  @override
  void initState() {
    super.initState();
    
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Efecto de rebote al escalar
    _animacionEscala = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.easeOutBack),
    );

    // Desvanecimiento de entrada
    _animacionOpacidad = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.easeIn),
    );

    _controlador.forward();
  }

  @override
  void dispose() {
    _controlador.dispose(); // Vital para evitar fugas de memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animacionOpacidad,
      child: ScaleTransition(
        scale: _animacionEscala,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.view_in_ar_rounded, // Ícono temporal estilo 3D/Cubo
            size: 80,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
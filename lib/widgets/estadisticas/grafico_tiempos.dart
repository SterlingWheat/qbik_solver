import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';

class GraficoTiempos extends StatelessWidget {
  final List<int> tiempos;

  const GraficoTiempos({super.key, required this.tiempos});

  @override
  Widget build(BuildContext context) {
    if (tiempos.isEmpty) return const SizedBox.shrink();

    // Usamos GetX para detectar el tema actual
    final esOscuro = Get.isDarkMode;
    final colorTexto = esOscuro ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      height: 220, // Altura optimizada para dar espacio al eje X
      decoration: BoxDecoration(
        color: esOscuro ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: esOscuro ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 10, right: 16, left: 10),
      child: CustomPaint(
        painter: _PintorGraficoConEjes(
          tiempos: tiempos,
          colorLinea: Get.theme.colorScheme.primary, // Usamos Get.theme
          colorTexto: colorTexto,
          esOscuro: esOscuro, 
        ),
      ),
    );
  }
}

class _PintorGraficoConEjes extends CustomPainter {
  final List<int> tiempos;
  final Color colorLinea;
  final Color colorTexto;
  final bool esOscuro; 

  _PintorGraficoConEjes({
    required this.tiempos,
    required this.colorLinea,
    required this.colorTexto,
    required this.esOscuro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tiempos.isEmpty) return;

    // --- CONFIGURACIÓN DE MÁRGENES ---
    final double paddingIzquierda = 45.0; 
    final double paddingAbajo = 25.0;     
    final double anchoEfectivo = size.width - paddingIzquierda;
    final double altoEfectivo = size.height - paddingAbajo;

    final int maxTiempo = tiempos.reduce(max);
    final int minTiempo = tiempos.reduce(min);
    
    // Previene divisiones por cero si todos los tiempos del grid son idénticos
    final int rango = (maxTiempo - minTiempo == 0) ? 1000 : maxTiempo - minTiempo; 

    // Pinceles (Paints) y Estilos
    final paintGrid = Paint()
      ..color = colorTexto.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final paintEstiloTexto = TextStyle(
      color: colorTexto.withOpacity(0.6), 
      fontSize: 10, 
      fontWeight: FontWeight.w500,
      fontFamily: 'monospace',
    );

    // --- DIBUJAR EJE Y (Grid horizontal y etiquetas de tiempo) ---
    final int divisionesY = 4;
    for (int i = 0; i <= divisionesY; i++) {
      final double factorY = i / divisionesY;
      final double y = altoEfectivo - (factorY * altoEfectivo);
      final int valorTiempo = minTiempo + (factorY * rango).round();

      canvas.drawLine(
        Offset(paddingIzquierda, y), 
        Offset(size.width, y), 
        paintGrid,
      );

      final String textoY = "${(valorTiempo / 1000).toStringAsFixed(1)}s";
      final spanY = TextSpan(style: paintEstiloTexto, text: textoY);
      final tpY = TextPainter(text: spanY, textDirection: TextDirection.ltr);
      tpY.layout();
      
      tpY.paint(canvas, Offset(paddingIzquierda - tpY.width - 8, y - (tpY.height / 2)));
    }

    // --- MANEJO ESPECIAL: SI SOLO EXISTE 1 SOLVE ---
    if (tiempos.length == 1) {
      final double x = paddingIzquierda + (anchoEfectivo / 2);
      final double y = altoEfectivo / 2;
      
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = colorLinea);
      
      final spanX = TextSpan(style: paintEstiloTexto, text: '1');
      final tpX = TextPainter(text: spanX, textDirection: TextDirection.ltr);
      tpX.layout();
      tpX.paint(canvas, Offset(x - (tpX.width / 2), size.height - paddingAbajo + 8));
      return;
    }

    // --- CONSTRUCCIÓN DE LA CURVA, DEGRADADO Y EJE X ---
    final path = Path();
    final puntos = <Offset>[];

    final int saltosX = (tiempos.length / 8).ceil(); 

    for (int i = 0; i < tiempos.length; i++) {
      final double factorX = i / (tiempos.length - 1);
      final double factorY = (tiempos[i] - minTiempo) / rango;

      final double x = paddingIzquierda + (factorX * anchoEfectivo);
      final double y = altoEfectivo - (factorY * altoEfectivo); 

      puntos.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // --- DIBUJAR EJE X (Número de Solves) ---
      if (i == 0 || i == tiempos.length - 1 || i % saltosX == 0) {
        final spanX = TextSpan(style: paintEstiloTexto, text: '${i + 1}');
        final tpX = TextPainter(text: spanX, textDirection: TextDirection.ltr);
        tpX.layout();
        
        tpX.paint(canvas, Offset(x - (tpX.width / 2), size.height - paddingAbajo + 8));
        
        canvas.drawLine(
          Offset(x, altoEfectivo), 
          Offset(x, altoEfectivo + 4), 
          paintGrid,
        );
      }
    }

    // --- DIBUJAR DEGRADADO DE RELLENO (Bajo la curva) ---
    final paintFondo = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colorLinea.withOpacity(0.4), colorLinea.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(paddingIzquierda, 0, anchoEfectivo, altoEfectivo))
      ..style = PaintingStyle.fill;

    final pathFondo = Path.from(path)
      ..lineTo(puntos.last.dx, altoEfectivo)
      ..lineTo(puntos.first.dx, altoEfectivo)
      ..close();

    canvas.drawPath(pathFondo, paintFondo);

    // --- DIBUJAR LÍNEA PRINCIPAL DEL GRÁFICO ---
    final paintLinea = Paint()
      ..color = colorLinea
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paintLinea);

    // --- DIBUJAR PUNTOS DE INTERSECCIÓN (Dots) ---
    final paintPuntoInterior = Paint()..color = colorLinea..style = PaintingStyle.fill;
    final paintPuntoBorde = Paint()
      ..color = (esOscuro ? const Color(0xFF1E293B) : Colors.white) 
      ..style = PaintingStyle.fill;

    for (var punto in puntos) {
      canvas.drawCircle(punto, 4.5, paintPuntoBorde);
      canvas.drawCircle(punto, 2.5, paintPuntoInterior);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modelos/estado_cubo_3x3.dart';
import '../../gestores/globales/gestor_configuracion.dart';
import '../../widgets/comunes/fondo_decorativo.dart';
import '../../servicios/solvers/solver_3x3.dart';
import '../../gestores/cubo_3x3/gestor_reproduccion_3x3.dart';

// ═══════════════════════════════════════════════════════════════
// CONTROLADOR LOCAL DE INGRESO 3x3
// Maneja el estado de los 54 stickers y la validación
// ═══════════════════════════════════════════════════════════════
class IngresoManual3x3Controller extends GetxController {
  final List<Color?> pegatinas = List.filled(54, null);
  Color colorSel = Colors.white;
  var calculando = false.obs;

  static const Map<int, Color> centros = {
    4:  Colors.white,
    13: Colors.red,
    22: Colors.green,
    31: Colors.yellow,
    40: Colors.orange,
    49: Colors.blue,
  };

  static const List<Color> paleta = [
    Colors.white, Colors.red, Colors.green,
    Colors.yellow, Colors.orange, Colors.blue,
  ];
  
  static const List<String> etiquetas = [
    'Blanco', 'Rojo', 'Verde', 'Amarillo', 'Naranja', 'Azul',
  ];

  @override
  void onInit() {
    super.onInit();
    centros.forEach((idx, color) => pegatinas[idx] = color);
  }

  int cantidad(Color c) => pegatinas.where((p) => p == c).length;
  bool get completo => pegatinas.every((p) => p != null);

  void seleccionarColor(Color color) {
    colorSel = color;
    update();
  }

  void pintar(int idx) {
    if (centros.containsKey(idx)) return;
    
    if (pegatinas[idx] == colorSel) {
      pegatinas[idx] = null;
    } else if (cantidad(colorSel) < 9) {
      pegatinas[idx] = colorSel;
    }
    update();
  }

  void limpiar() {
    for (int i = 0; i < 54; i++) pegatinas[i] = centros[i];
    update();
  }

  void llenarResuelto() {
    const colores = [
      Colors.white, Colors.red, Colors.green,
      Colors.yellow, Colors.orange, Colors.blue,
    ];
    for (int cara = 0; cara < 6; cara++) {
      for (int j = 0; j < 9; j++) {
        pegatinas[cara * 9 + j] = colores[cara];
      }
    }
    update();
  }

  Future<void> resolver() async {
    List<int> p;
    try {
      p = pegatinas.map((c) => _colorAInt(c)).toList();
    } catch (e) {
      _snack('Faltan colores por pintar o hay colores inválidos.', esError: true);
      return;
    }

    final String? error = _validar(p);
    if (error != null) { 
      _snack(error, esError: true); 
      return; 
    }

    final estadoInicial = EstadoCubo3x3(p);
    if (estadoInicial.estaResuelto) {
      _snack("✅ El cubo ya está resuelto.", esError: false);
      return;
    }

    calculando.value = true;
    try {
      final solucion = await Solver3x3.resolver(estadoInicial);
      
      final gestorReproduccion = GestorReproduccion3x3(
        estadoInicial: estadoInicial,
        algoritmoSolucion: solucion,
      );

      // Navegación limpia de GetX
      Get.toNamed('/solucion-pasos-3x3', arguments: gestorReproduccion);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), esError: true);
    } finally {
      calculando.value = false;
    }
  }

  int _colorAInt(Color? c) {
    if (c == Colors.white)  return 0;
    if (c == Colors.red)    return 1;
    if (c == Colors.green)  return 2;
    if (c == Colors.yellow) return 3;
    if (c == Colors.orange) return 4;
    if (c == Colors.blue)   return 5;
    throw Exception('Color nulo o desconocido');
  }

  String? _validar(List<int> p) {
    final cnt = List.filled(6, 0);
    for (final v in p) { if (v < 0 || v > 5) return 'Color inválido.'; cnt[v]++; }
    for (int i = 0; i < 6; i++) {
      if (cnt[i] != 9) return 'Tienes ${cnt[i]} de ${etiquetas[i]} (necesitas 9).';
    }
    for (int i = 0; i < 6; i++) {
      if (p[i * 9 + 4] != i) return 'Centro incorrecto en cara ${i + 1}.';
    }
    bool op(int a, int b) =>
        (a==0&&b==3)||(a==3&&b==0)||(a==1&&b==4)||(a==4&&b==1)||(a==2&&b==5)||(a==5&&b==2);
    const ar = [
      [1,46],[3,37],[5,10],[7,19],[21,41],[23,12],
      [50,39],[48,14],[28,25],[30,43],[32,16],[34,52],
    ];
    final vaA = <String>{};
    for (final a in ar) {
      final c1 = p[a[0]], c2 = p[a[1]];
      if (c1 == c2) return 'Arista con el mismo color en ambos lados (${etiquetas[c1]}).';
      if (op(c1, c2)) return 'Imposible: arista con colores opuestos (${etiquetas[c1]}-${etiquetas[c2]}).';
      final h = ([c1, c2]..sort()).join('-');
      if (vaA.contains(h)) return 'Pieza duplicada: arista ${etiquetas[c1]}-${etiquetas[c2]}.';
      vaA.add(h);
    }
    const es = [
      [0,47,36],[2,45,11],[6,18,38],[8,20,9],
      [27,24,44],[29,26,15],[33,53,42],[35,51,17],
    ];
    final vaE = <String>{};
    for (final e in es) {
      final c1=p[e[0]], c2=p[e[1]], c3=p[e[2]];
      if (c1==c2||c1==c3||c2==c3) return 'Esquina con colores repetidos.';
      if (op(c1,c2)||op(c1,c3)||op(c2,c3)) return 'Imposible: esquina con colores opuestos.';
      final h = ([c1,c2,c3]..sort()).join('-');
      if (vaE.contains(h)) return 'Pieza duplicada: esquina ${etiquetas[c1]}-${etiquetas[c2]}-${etiquetas[c3]}.';
      vaE.add(h);
    }
    return null;
  }

  void _snack(String msg, {required bool esError}) {
    Get.snackbar(
      esError ? 'Error' : 'Aviso',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: esError ? Colors.red.shade800 : Colors.green.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VISTA: INGRESO MANUAL 3x3 — PORTRAIT
// ═══════════════════════════════════════════════════════════════
class PantallaIngresoManual3x3 extends StatelessWidget {
  const PantallaIngresoManual3x3({super.key});

  @override
  Widget build(BuildContext context) {
    // Instanciamos el controlador local
    final ctrl = Get.put(IngresoManual3x3Controller());
    
    final dark = Get.isDarkMode;
    final txtColor = dark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FondoDecorativo(
        child: SafeArea(
          child: Column(children: [

            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: txtColor),
                  onPressed: () {
                    Get.find<GestorConfiguracion>().ejecutarVibracion();
                    Get.delete<IngresoManual3x3Controller>();
                    Get.back();
                  },
                ),
                Expanded(
                  child: Text('Ingreso Manual 3×3',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: Get.theme.colorScheme.primary)),
                ),
                TextButton.icon(
                  onPressed: ctrl.limpiar,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Limpiar'),
                ),
                TextButton.icon(
                  onPressed: ctrl.llenarResuelto,
                  icon: const Icon(Icons.playlist_add_check, size: 18),
                  label: const Text('Armado'),
                ),
              ]),
            ),

            // Instrucción
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Sostén el cubo con Blanco arriba y Verde al frente.\nToca cada celda y pinta el color que ves.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: txtColor.withOpacity(0.65)),
              ),
            ),

            // ── Cruz rotada 90° a la derecha ─────────────────
            Expanded(
              child: LayoutBuilder(builder: (ctx, box) {
                final double cellPorAncho = box.maxWidth  / 9.6;
                final double cellPorAlto  = box.maxHeight / 13.0;
                final double cell = min(cellPorAncho, cellPorAlto);

                return Center(
                  child: RotatedBox(
                    quarterTurns: 1, // 90° horario
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: GetBuilder<IngresoManual3x3Controller>(
                        builder: (_) => _buildCruz(cell, dark, txtColor, ctrl),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Paleta horizontal
            GetBuilder<IngresoManual3x3Controller>(
              builder: (_) => _buildPaleta(dark, context, ctrl),
            ),

            // Botón Resolver
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: Obx(() {
                  final calculando = ctrl.calculando.value;
                  return FilledButton.icon(
                    onPressed: (calculando || !ctrl.completo) ? null : () {
                      Get.find<GestorConfiguracion>().ejecutarVibracion();
                      ctrl.resolver();
                    },
                    icon: calculando
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: Text(calculando ? 'CALCULANDO...' : 'RESOLVER',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  );
                }),
              ),
            ),

          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Cruz 2D en su orientación natural (se rota externamente)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCruz(double cell, bool dark, Color txtColor, IngresoManual3x3Controller ctrl) {
    final gap = cell * 0.13;
    final bs = cell * 3 + gap * 2;

    Widget bloque(int base, String label, Color labelColor) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
          style: TextStyle(fontSize: cell * 0.48, fontWeight: FontWeight.bold, color: labelColor),
          textAlign: TextAlign.center),
        SizedBox(height: gap * 0.3),
        SizedBox(
          width: bs, height: bs,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
            ),
            itemBuilder: (_, j) => _celda(base + j, cell, dark, ctrl),
          ),
        ),
      ],
    );

    final colGap = SizedBox(width: gap * 1.6);
    final rowGap = SizedBox(height: gap * 1.6);
    final spacer = SizedBox(width: bs);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        spacer, colGap, bloque(0,  'U\nBlanco', Colors.white70), colGap, spacer, colGap, spacer,
      ]),
      rowGap,
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        bloque(36, 'L\nNaranja',  Colors.orange), colGap,
        bloque(18, 'F\nVerde',    Colors.green), colGap,
        bloque(9,  'R\nRojo',     Colors.red), colGap,
        bloque(45, 'B\nAzul',     Colors.blue),
      ]),
      rowGap,
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        spacer, colGap, bloque(27, 'D\nAmarillo', Colors.yellow), colGap, spacer, colGap, spacer,
      ]),
    ]);
  }

  Widget _celda(int idx, double size, bool dark, IngresoManual3x3Controller ctrl) {
    final esCentro = IngresoManual3x3Controller.centros.containsKey(idx);
    final color = ctrl.pegatinas[idx];
    final vacia = color == null;

    return GestureDetector(
      onTap: esCentro ? null : () {
        Get.find<GestorConfiguracion>().ejecutarVibracion();
        ctrl.pintar(idx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        decoration: BoxDecoration(
          color: vacia
              ? (dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07))
              : color,
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(
            color: esCentro
                ? Colors.white.withOpacity(0.7)
                : (vacia ? Colors.grey.withOpacity(0.28) : Colors.black.withOpacity(0.38)),
            width: esCentro ? 2.2 : 1.0,
          ),
          boxShadow: (!vacia && !esCentro)
              ? [BoxShadow(color: color!.withOpacity(0.35), blurRadius: 3)]
              : null,
        ),
        child: Center(
          child: esCentro
              ? Icon(Icons.circle, size: size * 0.32, color: Colors.white.withOpacity(0.65))
              : (vacia
                  ? Text('+', style: TextStyle(color: Colors.grey.withOpacity(0.4), fontSize: size * 0.42, fontWeight: FontWeight.w300))
                  : null),
        ),
      ),
    );
  }

  Widget _buildPaleta(bool dark, BuildContext context, IngresoManual3x3Controller ctrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(IngresoManual3x3Controller.paleta.length, (i) {
          final color = IngresoManual3x3Controller.paleta[i];
          final restante = 9 - ctrl.cantidad(color);
          final sel = ctrl.colorSel == color;
          
          return GestureDetector(
            onTap: (restante == 0 && !sel) ? null : () => ctrl.seleccionarColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel ? Get.theme.colorScheme.primary : Colors.grey.withOpacity(0.4),
                  width: sel ? 3.5 : 1.2,
                ),
                boxShadow: sel ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)] : [],
              ),
              child: Center(
                child: Container(
                  width: 19, height: 19,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$restante',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
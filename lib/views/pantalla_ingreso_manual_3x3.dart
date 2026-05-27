import 'dart:math';
import 'package:flutter/material.dart';
import '../modelos/estado_cubo_3x3.dart';
import '../gestores/gestor_configuracion.dart';
import '../widgets/fondo_decorativo.dart';
import '../servicios/solver_3x3.dart';
import '../gestores/gestor_reproduccion_3x3.dart';
import 'pantalla_solucion_pasos_3x3.dart';

// ═══════════════════════════════════════════════════════════════
// INGRESO MANUAL 3x3 — PORTRAIT con cruz rotada 90° a la derecha
//
// La pantalla permanece en vertical. La cruz 2D se dibuja en su
// orientación natural y luego se aplica Transform.rotate(pi/2)
// para girarla 90° a la derecha, quedando más ancha y con celdas
// más grandes en pantallas portrait.
//
// Layout:
//   AppBar (título + Limpiar + Armado)
//   Instrucción
//   Cruz rotada 90° (Expanded)
//   Paleta de colores (horizontal)
//   Botón RESOLVER
// ═══════════════════════════════════════════════════════════════
class PantallaIngresoManual3x3 extends StatefulWidget {
  const PantallaIngresoManual3x3({super.key});
  @override
  State<PantallaIngresoManual3x3> createState() =>
      _EstadoPantallaIngresoManual3x3();
}

class _EstadoPantallaIngresoManual3x3
    extends State<PantallaIngresoManual3x3> {

  // 54 stickers WCA: [U:0-8][R:9-17][F:18-26][D:27-35][L:36-44][B:45-53]
  final List<Color?> _pegatinas = List.filled(54, null);
  Color _colorSel = Colors.white;
  bool _calculando = false;

  static const Map<int, Color> _centros = {
    4:  Colors.white,
    13: Colors.red,
    22: Colors.green,
    31: Colors.yellow,
    40: Colors.orange,
    49: Colors.blue,
  };

  static const List<Color> _paleta = [
    Colors.white, Colors.red, Colors.green,
    Colors.yellow, Colors.orange, Colors.blue,
  ];
  static const List<String> _etiquetas = [
    'Blanco', 'Rojo', 'Verde', 'Amarillo', 'Naranja', 'Azul',
  ];

  @override
  void initState() {
    super.initState();
    _centros.forEach((idx, color) => _pegatinas[idx] = color);
  }

  int _cantidad(Color c) => _pegatinas.where((p) => p == c).length;
  bool get _completo => _pegatinas.every((p) => p != null);

  void _pintar(int idx) {
    if (_centros.containsKey(idx)) return;
    setState(() {
      if (_pegatinas[idx] == _colorSel) {
        _pegatinas[idx] = null;
      } else if (_cantidad(_colorSel) < 9) {
        _pegatinas[idx] = _colorSel;
      }
    });
  }

  void _limpiar() {
    setState(() {
      for (int i = 0; i < 54; i++) _pegatinas[i] = _centros[i];
    });
  }

  void _llenarResuelto() {
    setState(() {
      const colores = [
        Colors.white, Colors.red, Colors.green,
        Colors.yellow, Colors.orange, Colors.blue,
      ];
      for (int cara = 0; cara < 6; cara++) {
        for (int j = 0; j < 9; j++) {
          _pegatinas[cara * 9 + j] = colores[cara];
        }
      }
    });
  }

  Future<void> _resolver() async {
    final List<int> p = _pegatinas.map(_colorAInt).toList();
    final String? error = _validar(p);
    if (error != null) { _snack(error, esError: true); return; }

    setState(() => _calculando = true);
    try {
      final solucion = await Solver3x3.resolver(EstadoCubo3x3(p));
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PantallaSolucionPasos3x3(
          gestor: GestorReproduccion3x3(
            estadoInicial: EstadoCubo3x3(p),
            algoritmoSolucion: solucion,
          ),
        ),
      ));
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), esError: true);
    } finally {
      if (mounted) setState(() => _calculando = false);
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
      if (cnt[i] != 9) return 'Tienes ${cnt[i]} de ${_etiquetas[i]} (necesitas 9).';
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
      if (c1 == c2) return 'Arista con el mismo color en ambos lados (${_etiquetas[c1]}).';
      if (op(c1, c2)) return 'Imposible: arista con colores opuestos (${_etiquetas[c1]}-${_etiquetas[c2]}).';
      final h = ([c1, c2]..sort()).join('-');
      if (vaA.contains(h)) return 'Pieza duplicada: arista ${_etiquetas[c1]}-${_etiquetas[c2]}.';
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
      if (vaE.contains(h)) return 'Pieza duplicada: esquina ${_etiquetas[c1]}-${_etiquetas[c2]}-${_etiquetas[c3]}.';
      vaE.add(h);
    }
    return null;
  }

  void _snack(String msg, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: esError ? Colors.red.shade800 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
                    GestorConfiguracion().ejecutarVibracion();
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: Text('Ingreso Manual 3×3',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
                ),
                TextButton.icon(
                  onPressed: _limpiar,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Limpiar'),
                ),
                TextButton.icon(
                  onPressed: _llenarResuelto,
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
            // RotatedBox gira en cuartos y ajusta los constraints
            // correctamente (a diferencia de Transform.rotate).
            // FittedBox escala la cruz para que llene el espacio
            // disponible sin desbordar.
            Expanded(
              child: LayoutBuilder(builder: (ctx, box) {
                // Con la cruz girada 90°, el ancho de pantalla corresponde
                // a las 9 filas de la cruz y el alto a las 12 columnas.
                // Calculamos cell a partir de ambas restricciones.
                final double cellPorAncho = box.maxWidth  / 9.6;
                final double cellPorAlto  = box.maxHeight / 13.0;
                final double cell = min(cellPorAncho, cellPorAlto);

                return Center(
                  child: RotatedBox(
                    quarterTurns: 1, // 90° horario
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: _buildCruz(cell, dark, txtColor),
                    ),
                  ),
                );
              }),
            ),

            // Paleta horizontal
            _buildPaleta(dark),

            // Botón Resolver
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: FilledButton.icon(
                  onPressed: (_calculando || !_completo) ? null : () {
                    GestorConfiguracion().ejecutarVibracion();
                    _resolver();
                  },
                  icon: _calculando
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_calculando ? 'CALCULANDO...' : 'RESOLVER',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),

          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Cruz 2D en su orientación natural (se rota externamente)
  //         [ U ]
  //  [L] [F] [R] [B]
  //         [ D ]
  // ─────────────────────────────────────────────────────────────
  Widget _buildCruz(double cell, bool dark, Color txtColor) {
    final gap = cell * 0.13;
    final bs = cell * 3 + gap * 2;

    Widget bloque(int base, String label, Color labelColor) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
          style: TextStyle(fontSize: cell * 0.48, fontWeight: FontWeight.bold,
              color: labelColor),
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
            itemBuilder: (_, j) => _celda(base + j, cell, dark),
          ),
        ),
      ],
    );

    final colGap = SizedBox(width: gap * 1.6);
    final rowGap = SizedBox(height: gap * 1.6);
    final spacer = SizedBox(width: bs);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        spacer, colGap,
        bloque(0,  'U\nBlanco',   Colors.white70),
        colGap, spacer, colGap, spacer,
      ]),
      rowGap,
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        bloque(36, 'L\nNaranja',  Colors.orange),
        colGap,
        bloque(18, 'F\nVerde',    Colors.green),
        colGap,
        bloque(9,  'R\nRojo',     Colors.red),
        colGap,
        bloque(45, 'B\nAzul',     Colors.blue),
      ]),
      rowGap,
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        spacer, colGap,
        bloque(27, 'D\nAmarillo', Colors.yellow),
        colGap, spacer, colGap, spacer,
      ]),
    ]);
  }

  Widget _celda(int idx, double size, bool dark) {
    final esCentro = _centros.containsKey(idx);
    final color = _pegatinas[idx];
    final vacia = color == null;

    return GestureDetector(
      onTap: esCentro ? null : () {
        GestorConfiguracion().ejecutarVibracion();
        _pintar(idx);
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
                : (vacia
                    ? Colors.grey.withOpacity(0.28)
                    : Colors.black.withOpacity(0.38)),
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
                  ? Text('+',
                      style: TextStyle(
                          color: Colors.grey.withOpacity(0.4),
                          fontSize: size * 0.42,
                          fontWeight: FontWeight.w300))
                  : null),
        ),
      ),
    );
  }

  // Paleta horizontal (igual que versión original)
  Widget _buildPaleta(bool dark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_paleta.length, (i) {
          final color = _paleta[i];
          final restante = 9 - _cantidad(color);
          final sel = _colorSel == color;
          return GestureDetector(
            onTap: (restante == 0 && !sel) ? null : () =>
                setState(() => _colorSel = color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.withOpacity(0.4),
                  width: sel ? 3.5 : 1.2,
                ),
                boxShadow: sel
                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
                    : [],
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
                      style: const TextStyle(color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.bold)),
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
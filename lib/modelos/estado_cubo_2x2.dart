/// Clase que representa el estado matemático puro de un Cubo Rubik 2x2.
/// Utiliza un arreglo plano de 24 posiciones para optimizar drásticamente 
/// la velocidad del algoritmo de resolución (BFS).
class EstadoCubo2x2 {
  // Las 24 pegatinas (stickers) del cubo.
  // Mapeo de caras: 0:U (Arriba), 1:R (Derecha), 2:F (Frente), 3:D (Abajo), 4:L (Izquierda), 5:B (Atrás)
  // Cada cara tiene 4 pegatinas ordenadas: 0:Sup-Izq, 1:Sup-Der, 2:Inf-Izq, 3:Inf-Der
  final List<int> pegatinas;

  EstadoCubo2x2(this.pegatinas) {
    if (pegatinas.length != 24) {
      throw Exception('El estado matemático del cubo 2x2 debe tener exactamente 24 pegatinas.');
    }
  }

  /// Crea un cubo en estado completamente resuelto (cada cara con un color uniforme).
  factory EstadoCubo2x2.resuelto() {
    List<int> inicial = [];
    for (int cara = 0; cara < 6; cara++) {
      inicial.addAll([cara, cara, cara, cara]);
    }
    return EstadoCubo2x2(inicial);
  }

  /// Clona el estado actual para evitar mutaciones indeseadas (Inmutabilidad).
  EstadoCubo2x2 clonar() {
    return EstadoCubo2x2(List<int>.from(pegatinas));
  }

  /// Comprueba si el estado actual es un cubo resuelto.
  /// No asume una orientación específica (ej. blanco arriba), solo verifica
  /// que las 4 pegatinas de cada cara sean del mismo color.
  bool get estaResuelto {
    for (int cara = 0; cara < 6; cara++) {
      int idxBase = cara * 4;
      int colorCara = pegatinas[idxBase];
      if (pegatinas[idxBase + 1] != colorCara ||
          pegatinas[idxBase + 2] != colorCara ||
          pegatinas[idxBase + 3] != colorCara) {
        return false;
      }
    }
    return true;
  }

  /// Genera un identificador único rápido para usar en estructuras HashSet durante el BFS.
  String get hashEstado => String.fromCharCodes(pegatinas.map((c) => c + 65));

  /// Aplica un movimiento algorítmico estándar (ej. "U", "R'", "F2") y retorna el nuevo estado.
  EstadoCubo2x2 aplicarMovimiento(String movimiento) {
    EstadoCubo2x2 nuevoEstado = clonar();
    
    // Parseo de movimientos (Base + Modificador)
    String base = movimiento[0];
    bool inverso = movimiento.contains("'");
    bool doble = movimiento.contains("2");

    int repeticiones = doble ? 2 : (inverso ? 3 : 1);

    for (int i = 0; i < repeticiones; i++) {
      nuevoEstado = nuevoEstado._aplicarGiroHorario(base);
    }

    return nuevoEstado;
  }

  /// Aplica un giro de 90 grados en sentido horario a la cara especificada.
  /// Utiliza tablas de permutación matemáticas precisas.
  EstadoCubo2x2 _aplicarGiroHorario(String cara) {
    List<int> p = List.from(pegatinas);
    List<int> n = List.from(pegatinas);

    switch (cara) {
      case 'U': // Up (Arriba)
        // Gira la cara U
        n[0] = p[2]; n[1] = p[0]; n[2] = p[3]; n[3] = p[1];
        // Permuta los bordes adyacentes (R, F, L, B)
        n[4] = p[20]; n[5] = p[21]; // R recibe B
        n[8] = p[4];  n[9] = p[5];  // F recibe R
        n[16] = p[8]; n[17] = p[9]; // L recibe F
        n[20] = p[16]; n[21] = p[17]; // B recibe L
        break;

      case 'R': // Right (Derecha)
        n[4] = p[6]; n[5] = p[4]; n[6] = p[7]; n[7] = p[5];
        n[1] = p[9]; n[3] = p[11]; // U recibe F
        n[20] = p[3]; n[22] = p[1]; // B recibe U (Invertido)
        n[13] = p[22]; n[15] = p[20]; // D recibe B (Invertido)
        n[9] = p[13]; n[11] = p[15]; // F recibe D
        break;

      case 'F': // Front (Frente)
        n[8] = p[10]; n[9] = p[8]; n[10] = p[11]; n[11] = p[9];
        n[2] = p[19]; n[3] = p[17]; // U recibe L
        n[4] = p[2]; n[6] = p[3]; // R recibe U
        n[12] = p[6]; n[13] = p[4]; // D recibe R
        n[17] = p[12]; n[19] = p[13]; // L recibe D
        break;

      case 'D': // Down (Abajo)
        n[12] = p[14]; n[13] = p[12]; n[14] = p[15]; n[15] = p[13];
        n[10] = p[6]; n[11] = p[7]; // F recibe R
        n[6] = p[22]; n[7] = p[23]; // R recibe B
        n[22] = p[18]; n[23] = p[19]; // B recibe L
        n[18] = p[10]; n[19] = p[11]; // L recibe F
        break;

      case 'L': // Left (Izquierda)
        n[16] = p[18]; n[17] = p[16]; n[18] = p[19]; n[19] = p[17];
        n[0] = p[21]; n[2] = p[23]; // U recibe B
        n[8] = p[0]; n[10] = p[2]; // F recibe U
        n[12] = p[8]; n[14] = p[10]; // D recibe F
        n[21] = p[14]; n[23] = p[12]; // B recibe D
        break;

      case 'B': // Back (Atrás)
        n[20] = p[22]; n[21] = p[20]; n[22] = p[23]; n[23] = p[21];
        n[0] = p[5]; n[1] = p[7]; // U recibe R
        n[16] = p[1]; n[18] = p[0]; // L recibe U
        n[14] = p[16]; n[15] = p[18]; // D recibe L
        n[5] = p[15]; n[7] = p[14]; // R recibe D
        break;

      default:
        throw Exception("Movimiento no reconocido: $cara");
    }

    return EstadoCubo2x2(n);
  }

  // Compara dos estados para determinar si son exactamente iguales
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadoCubo2x2 && hashEstado == other.hashEstado;

  @override
  int get hashCode => hashEstado.hashCode;
}
/// Clase que representa el estado matemático puro de un Cubo Rubik 3x3.
/// Utiliza un arreglo plano de 54 posiciones para una ejecución ultra rápida
/// requerida por los algoritmos de resolución.
class EstadoCubo3x3 {
  // Las 54 pegatinas (stickers) del cubo.
  // Mapeo oficial de caras (WCA estándar: Blanco Arriba, Verde Frente):
  // 0: U (Arriba), 1: R (Derecha), 2: F (Frente), 
  // 3: D (Abajo), 4: L (Izquierda), 5: B (Atrás)
  //
  // Cada cara tiene 9 pegatinas indexadas de 0 a 8 en orden de lectura:
  // [0, 1, 2]
  // [3, 4, 5]
  // [6, 7, 8]
  final List<int> pegatinas;

  EstadoCubo3x3(this.pegatinas) {
    if (pegatinas.length != 54) {
      throw Exception('El estado matemático del cubo 3x3 debe tener exactamente 54 pegatinas.');
    }
  }

  /// Crea un cubo en estado completamente resuelto.
  factory EstadoCubo3x3.resuelto() {
    List<int> inicial = [];
    for (int cara = 0; cara < 6; cara++) {
      inicial.addAll(List.filled(9, cara));
    }
    return EstadoCubo3x3(inicial);
  }

  /// Clona el estado actual garantizando la inmutabilidad
  EstadoCubo3x3 clonar() {
    return EstadoCubo3x3(List<int>.from(pegatinas));
  }

  /// Comprueba si el estado actual está resuelto.
  /// Verifica que las 9 pegatinas de cada cara sean del mismo color que su centro (índice 4).
  bool get estaResuelto {
    for (int cara = 0; cara < 6; cara++) {
      int idxBase = cara * 9;
      int colorCentro = pegatinas[idxBase + 4];
      for (int i = 0; i < 9; i++) {
        if (pegatinas[idxBase + i] != colorCentro) return false;
      }
    }
    return true;
  }

  /// Genera un identificador único para usar en Set/Map (Hashing veloz).
  String get hashEstado => String.fromCharCodes(pegatinas.map((c) => c + 65));

  /// Aplica un movimiento algorítmico estándar (ej. "U", "R'", "F2") y retorna el nuevo estado.
  EstadoCubo3x3 aplicarMovimiento(String movimiento) {
    if (movimiento.isEmpty) return this;
    
    EstadoCubo3x3 nuevoEstado = clonar();
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
  /// Mapeo matemático indexado absoluto para máxima eficiencia de CPU (O(1)).
  EstadoCubo3x3 _aplicarGiroHorario(String cara) {
    List<int> p = List.from(pegatinas);
    List<int> n = List.from(pegatinas);

    // Helper interno para rotar los 8 bordes de una cara (el centro no se mueve)
    void rotarCara(int base) {
      n[base + 0] = p[base + 6];
      n[base + 1] = p[base + 3];
      n[base + 2] = p[base + 0];
      n[base + 3] = p[base + 7];
      n[base + 5] = p[base + 1];
      n[base + 6] = p[base + 8];
      n[base + 7] = p[base + 5];
      n[base + 8] = p[base + 2];
    }

    switch (cara) {
      case 'U': // Up (Arriba)
        rotarCara(0);
        // Permuta los anillos adyacentes: B(45) -> R(9) -> F(18) -> L(36)
        for (int i = 0; i < 3; i++) {
          n[9 + i] = p[45 + i];
          n[18 + i] = p[9 + i];
          n[36 + i] = p[18 + i];
          n[45 + i] = p[36 + i];
        }
        break;

      case 'R': // Right (Derecha)
        rotarCara(9);
        // Anillos: U(0) -> B(45) invertido -> D(27) -> F(18)
        n[2] = p[20]; n[5] = p[23]; n[8] = p[26];
        n[20] = p[29]; n[23] = p[32]; n[26] = p[35];
        n[29] = p[51]; n[32] = p[48]; n[35] = p[45];
        n[51] = p[2]; n[48] = p[5]; n[45] = p[8];
        break;

      case 'F': // Front (Frente)
        rotarCara(18);
        // Anillos: U(0) -> R(9) -> D(27) -> L(36)
        n[6] = p[44]; n[7] = p[41]; n[8] = p[38];
        n[9] = p[6]; n[12] = p[7]; n[15] = p[8];
        n[27] = p[15]; n[28] = p[12]; n[29] = p[9];
        n[38] = p[27]; n[41] = p[28]; n[44] = p[29];
        break;

      case 'D': // Down (Abajo)
        rotarCara(27);
        // Anillos: F(18) -> R(9) -> B(45) -> L(36)
        for (int i = 6; i <= 8; i++) {
          n[9 + i] = p[18 + i];
          n[45 + i] = p[9 + i];
          n[36 + i] = p[45 + i];
          n[18 + i] = p[36 + i];
        }
        break;

      case 'L': // Left (Izquierda)
        rotarCara(36);
        // Anillos: U(0) -> F(18) -> D(27) -> B(45) invertido
        n[0] = p[53]; n[3] = p[50]; n[6] = p[47];
        n[18] = p[0]; n[21] = p[3]; n[24] = p[6];
        n[27] = p[18]; n[30] = p[21]; n[33] = p[24];
        n[53] = p[27]; n[50] = p[30]; n[47] = p[33];
        break;

      case 'B': // Back (Atrás)
        rotarCara(45);
        // Anillos: U(0) -> L(36) -> D(27) -> R(9)
        n[0] = p[11]; n[1] = p[14]; n[2] = p[17];
        n[36] = p[2]; n[39] = p[1]; n[42] = p[0];
        n[33] = p[36]; n[34] = p[39]; n[35] = p[42];
        n[11] = p[35]; n[14] = p[34]; n[17] = p[33];
        break;

      default:
        throw Exception("Movimiento inválido: $cara");
    }

    return EstadoCubo3x3(n);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadoCubo3x3 && hashEstado == other.hashEstado;

  @override
  int get hashCode => hashEstado.hashCode;
}
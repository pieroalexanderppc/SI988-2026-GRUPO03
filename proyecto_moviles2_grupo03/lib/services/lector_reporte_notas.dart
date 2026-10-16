/// H19 - Lectura del reporte de notas del portal a partir del texto reconocido
/// por la camara (OCR).
///
/// Es logica pura (sin ML Kit ni Firebase) para poder probarla con tests:
/// recibe las palabras detectadas con su posicion en la imagen y reconstruye
/// la tabla Unidad / Criterio / Peso C. / Peso U. / Nota / Fecha / Descripcion.
library;

/// Una palabra reconocida con su caja en la imagen (en pixeles).
class PalabraOcr {
  final String texto;
  final double izquierda;
  final double arriba;
  final double derecha;
  final double abajo;

  const PalabraOcr(this.texto, this.izquierda, this.arriba, this.derecha, this.abajo);

  double get centroY => (arriba + abajo) / 2;
  double get alto => abajo - arriba;
}

/// Un criterio de evaluacion leido (una fila "Evaluacion 01 ...").
class CriterioDetectado {
  /// Nombre del criterio en el portal (ej. "Evaluacion 01").
  String nombre;

  /// Descripcion (ej. "Examen de unidad"); se usa como nombre del tipo.
  String descripcion;
  double? peso;

  /// `null` si el criterio aun no tiene nota (pendiente).
  double? nota;

  CriterioDetectado({required this.nombre, this.descripcion = '', this.peso, this.nota});
}

/// Una unidad leida con sus criterios.
class UnidadDetectada {
  String nombre;
  double? peso;
  final List<CriterioDetectado> criterios;

  UnidadDetectada({required this.nombre, this.peso, List<CriterioDetectado>? criterios})
      : criterios = criterios ?? [];
}

/// Resultado de leer un reporte completo.
class ReporteDetectado {
  final String? curso;
  final List<UnidadDetectada> unidades;

  const ReporteDetectado({this.curso, required this.unidades});

  bool get vacio => unidades.isEmpty || unidades.every((u) => u.criterios.isEmpty);
  int get cantidadNotas => unidades.fold(0, (a, u) => a + u.criterios.where((c) => c.nota != null).length);
}

enum _Columna { unidad, criterio, pesoC, pesoU, nota, fecha, descripcion }

class LectorReporteNotas {
  static final _reUnidad = RegExp(r'^unidad\s*([ivxl]+|\d+)\b', caseSensitive: false);
  static final _reCriterio = RegExp(r'^evaluaci\S*\s*(\d+)', caseSensitive: false);
  static final _reCriterioFila = RegExp(
    r'^(evaluaci\S*\s*\d+)\s+(\S+)\s*%?\s*(?:(\d{1,2}(?:[.,]\d+)?)\s+)?(?:[a-z]{3}\s+\d{1,2}\s+\d{4}\s+)?(.*)$',
    caseSensitive: false,
  );
  static final _reNotaCelda = RegExp(r'^\d{1,2}(?:[.,]\d{1,2})?$');

  /// Lee el reporte. Devuelve un reporte vacio si no reconoce la tabla.
  static ReporteDetectado leer(List<PalabraOcr> palabras) {
    final filas = _agruparEnFilas(palabras);
    final altoTipico = _mediana(palabras.map((p) => p.alto).where((h) => h > 0).toList()) ?? 12;

    String? curso;
    bool vioEncabezado = false;
    List<(_Columna, double)>? columnas;
    final unidades = <UnidadDetectada>[];

    for (final fila in filas) {
      final texto = fila.map((p) => p.texto).join(' ').trim();
      if (texto.isEmpty) continue;

      final encabezado = _leerEncabezado(fila);
      if (encabezado != null) {
        columnas = encabezado;
        vioEncabezado = true;
        continue;
      }

      final celdas = columnas == null ? null : _asignarColumnas(fila, columnas, altoTipico);
      final etiqueta = celdas == null
          ? texto
          : '${celdas[_Columna.unidad] ?? ''} ${celdas[_Columna.criterio] ?? ''}'.trim();

      // Fila de unidad: "Unidad I ... 30 %"
      final mUnidad = _reUnidad.firstMatch(etiqueta.isEmpty ? texto : etiqueta);
      if (mUnidad != null) {
        final peso = _numero(celdas?[_Columna.pesoU]) ?? _primerPorcentaje(texto);
        unidades.add(UnidadDetectada(nombre: 'Unidad ${_aArabigo(mUnidad.group(1)!)}', peso: peso));
        continue;
      }

      // Fila de criterio: "Evaluacion 01  10 %  13  Oct 09 2026  Actitudinal"
      final criterio = _leerCriterio(texto, etiqueta, celdas);
      if (criterio != null) {
        if (unidades.isEmpty) unidades.add(UnidadDetectada(nombre: 'Unidad 1'));
        unidades.last.criterios.add(criterio);
        continue;
      }

      // Titulo del curso: primera fila en mayusculas antes de la tabla.
      if (!vioEncabezado && curso == null && _esTitulo(texto)) {
        curso = texto;
      }
    }

    unidades.removeWhere((u) => u.criterios.isEmpty && u.peso == null);
    return ReporteDetectado(curso: curso, unidades: unidades);
  }

  // --- Filas y columnas ---

  /// Agrupa las palabras en filas segun la altura de su centro.
  static List<List<PalabraOcr>> _agruparEnFilas(List<PalabraOcr> palabras) {
    final ordenadas = [...palabras]..sort((a, b) => a.centroY.compareTo(b.centroY));
    final altoTipico = _mediana(ordenadas.map((p) => p.alto).where((h) => h > 0).toList()) ?? 12;
    final tolerancia = altoTipico * 0.55;

    final filas = <List<PalabraOcr>>[];
    final centros = <double>[];
    for (final p in ordenadas) {
      if (filas.isNotEmpty && (p.centroY - centros.last).abs() <= tolerancia) {
        filas.last.add(p);
        final f = filas.last;
        centros[centros.length - 1] = f.map((e) => e.centroY).reduce((a, b) => a + b) / f.length;
      } else {
        filas.add([p]);
        centros.add(p.centroY);
      }
    }
    for (final f in filas) {
      f.sort((a, b) => a.izquierda.compareTo(b.izquierda));
    }
    return filas;
  }

  /// Si la fila es el encabezado de la tabla, devuelve donde empieza cada columna.
  static List<(_Columna, double)>? _leerEncabezado(List<PalabraOcr> fila) {
    final textos = fila.map((p) => _normalizar(p.texto)).toList();
    if (!textos.any((t) => t.startsWith('criterio')) || !textos.any((t) => t == 'nota')) return null;

    final columnas = <(_Columna, double)>[];
    var pesos = 0;
    for (var i = 0; i < fila.length; i++) {
      final t = textos[i];
      final x = fila[i].izquierda;
      if (t == 'unidad') {
        columnas.add((_Columna.unidad, x));
      } else if (t.startsWith('criterio')) {
        columnas.add((_Columna.criterio, x));
      } else if (t == 'peso' || t.startsWith('peso')) {
        // "Peso C." y "Peso U."; si el OCR lee la letra, se usa; si no, por orden.
        final siguiente = i + 1 < fila.length ? textos[i + 1] : '';
        final esU = t.endsWith('u') || t.endsWith('u.') || siguiente.startsWith('u');
        final esC = t.endsWith('c') || t.endsWith('c.') || siguiente.startsWith('c');
        columnas.add((esU || (!esC && pesos > 0) ? _Columna.pesoU : _Columna.pesoC, x));
        pesos++;
      } else if (t == 'nota') {
        columnas.add((_Columna.nota, x));
      } else if (t == 'fecha') {
        columnas.add((_Columna.fecha, x));
      } else if (t.startsWith('descrip')) {
        columnas.add((_Columna.descripcion, x));
      }
    }
    columnas.sort((a, b) => a.$2.compareTo(b.$2));
    return columnas.length >= 4 ? columnas : null;
  }

  /// Une las palabras de una fila por columna, segun donde empieza cada una.
  static Map<_Columna, String> _asignarColumnas(
    List<PalabraOcr> fila,
    List<(_Columna, double)> columnas,
    double altoTipico,
  ) {
    final celdas = <_Columna, List<String>>{};
    final tolerancia = altoTipico * 0.8;
    for (final p in fila) {
      var columna = columnas.first.$1;
      for (final (c, inicio) in columnas) {
        if (inicio <= p.izquierda + tolerancia) columna = c;
      }
      celdas.putIfAbsent(columna, () => []).add(p.texto);
    }
    return celdas.map((c, textos) => MapEntry(c, textos.join(' ').trim()));
  }

  // --- Interpretacion ---

  static CriterioDetectado? _leerCriterio(String texto, String etiqueta, Map<_Columna, String>? celdas) {
    final mEtiqueta = _reCriterio.firstMatch(etiqueta);
    if (celdas != null && mEtiqueta != null) {
      final notaTexto = celdas[_Columna.nota]?.trim() ?? '';
      return CriterioDetectado(
        nombre: 'Evaluacion ${mEtiqueta.group(1)!.padLeft(2, '0')}',
        descripcion: (celdas[_Columna.descripcion] ?? '').trim(),
        peso: _numero(celdas[_Columna.pesoC]),
        nota: _reNotaCelda.hasMatch(_limpiarNumero(notaTexto)) ? _numero(notaTexto) : null,
      );
    }

    // Sin encabezado: se interpreta la fila completa.
    final m = _reCriterioFila.firstMatch(texto);
    if (m == null) return null;
    final numeroCriterio = _reCriterio.firstMatch(m.group(1)!)!.group(1)!;
    return CriterioDetectado(
      nombre: 'Evaluacion ${numeroCriterio.padLeft(2, '0')}',
      descripcion: (m.group(4) ?? '').trim(),
      peso: _numero(m.group(2)),
      nota: m.group(3) == null ? null : _numero(m.group(3)),
    );
  }

  static bool _esTitulo(String texto) {
    final letras = texto.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÑáéíóúñ]'), '');
    if (letras.length < 4) return false;
    final mayusculas = letras.replaceAll(RegExp(r'[^A-ZÁÉÍÓÚÑ]'), '').length;
    return mayusculas / letras.length >= 0.7;
  }

  // --- Utilidades ---

  static String _normalizar(String t) => t
      .toLowerCase()
      .replaceAll('ó', 'o')
      .replaceAll('í', 'i')
      .replaceAll('é', 'e')
      .replaceAll('á', 'a')
      .replaceAll('ú', 'u')
      .trim();

  /// Corrige confusiones tipicas del OCR en celdas numericas (O->0, l->1).
  static String _limpiarNumero(String t) => t
      .replaceAll('%', '')
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll(',', '.')
      .replaceAll(RegExp('[Oo]'), '0')
      .replaceAll(RegExp('[lI|]'), '1');

  static double? _numero(String? t) {
    if (t == null) return null;
    final limpio = _limpiarNumero(t);
    final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(limpio);
    return m == null ? null : double.tryParse(m.group(0)!);
  }

  static double? _primerPorcentaje(String texto) {
    final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*%').firstMatch(texto);
    return m == null ? null : _numero(m.group(1));
  }

  /// "I" -> 1, "II" -> 2, "IV" -> 4; si ya es numero lo deja igual.
  static int _aArabigo(String valor) {
    final n = int.tryParse(valor);
    if (n != null) return n;
    const valores = {'i': 1, 'v': 5, 'x': 10, 'l': 50};
    final s = valor.toLowerCase();
    var total = 0;
    for (var i = 0; i < s.length; i++) {
      final actual = valores[s[i]] ?? 0;
      final siguiente = i + 1 < s.length ? (valores[s[i + 1]] ?? 0) : 0;
      total += actual < siguiente ? -actual : actual;
    }
    return total;
  }

  static double? _mediana(List<double> valores) {
    if (valores.isEmpty) return null;
    final v = [...valores]..sort();
    return v[v.length ~/ 2];
  }
}

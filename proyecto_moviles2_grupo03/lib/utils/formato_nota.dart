/// Formatos de presentacion de notas y porcentajes (DESIGN.md seccion 3).
class FormatoNota {
  /// Nota siempre con 1 decimal. Sin nota se muestra una raya.
  static String nota(double? valor) => valor == null ? '—' : valor.toStringAsFixed(1);

  /// Porcentaje sin decimales si es entero (30), con 1 decimal si no (12.5).
  static String porcentaje(double valor) {
    final redondeado = double.parse(valor.toStringAsFixed(1));
    return redondeado == redondeado.roundToDouble()
        ? redondeado.toStringAsFixed(0)
        : redondeado.toStringAsFixed(1);
  }
}

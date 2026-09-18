class EntradaCleaner {
  static String limpiar(String entrada) {
    return entrada
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
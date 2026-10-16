import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'lector_reporte_notas.dart';

/// Origen de la imagen del reporte.
enum OrigenImagen { camara, galeria }

/// H19 - Toma o elige la foto del reporte y la lee con ML Kit en el dispositivo.
///
/// La imagen no sale del telefono ni se guarda: el archivo temporal se borra
/// apenas termina el reconocimiento.
class EscanerNotas {
  final ImagePicker _picker = ImagePicker();

  /// ML Kit solo funciona en Android e iOS.
  static bool get disponible =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Devuelve `null` si el usuario cancelo la camara o la galeria.
  Future<ReporteDetectado?> escanear(OrigenImagen origen) async {
    final foto = await _picker.pickImage(
      source: origen == OrigenImagen.camara ? ImageSource.camera : ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (foto == null) return null;

    final reconocedor = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final texto = await reconocedor.processImage(InputImage.fromFilePath(foto.path));
      final palabras = <PalabraOcr>[
        for (final bloque in texto.blocks)
          for (final linea in bloque.lines)
            for (final e in linea.elements)
              PalabraOcr(e.text, e.boundingBox.left, e.boundingBox.top, e.boundingBox.right, e.boundingBox.bottom),
      ];
      return LectorReporteNotas.leer(palabras);
    } finally {
      await reconocedor.close();
      // Criterio 9: la imagen no se almacena.
      try {
        await File(foto.path).delete();
      } catch (_) {}
    }
  }
}

import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';

import '../models/curso.dart';
import '../services/calculos_multinivel.dart';

/// Servicio para exportar el avance académico a Excel (.xlsx) y CSV con soporte nativo para compartir (H35).
class ExportadorExcelService {
  /// Genera los bytes de un libro de Excel (.xlsx) válido conforme al estándar Office Open XML.
  static Uint8List generarExcel({
    required String cicloNombre,
    required List<Curso> cursos,
    required Map<String, ResultadoCalculoCurso> resultados,
    required double? promedioCiclo,
    required int totalCreditos,
    String? nombreEstudiante,
    String? correoEstudiante,
    DateTime? fechaEmision,
  }) {
    final fecha = fechaEmision ?? DateTime.now();
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');

    // Configuración de anchos de columnas
    buffer.writeln('  <cols>');
    buffer.writeln('    <col min="1" max="1" width="6" customWidth="1"/>'); // N°
    buffer.writeln('    <col min="2" max="2" width="34" customWidth="1"/>'); // Asignatura
    buffer.writeln('    <col min="3" max="3" width="12" customWidth="1"/>'); // Créditos
    buffer.writeln('    <col min="4" max="4" width="16" customWidth="1"/>'); // % Evaluado
    buffer.writeln('    <col min="5" max="5" width="16" customWidth="1"/>'); // Nota Actual
    buffer.writeln('    <col min="6" max="6" width="18" customWidth="1"/>'); // Estado
    buffer.writeln('  </cols>');

    buffer.writeln('  <sheetData>');

    int row = 1;

    // Fila 1: Título Institucional
    buffer.writeln('    <row r="$row">');
    buffer.writeln(
        '      <c r="A$row" t="inlineStr" s="1"><is><t>PONDERA - REPORTE DE AVANCE ACADÉMICO</t></is></c>');
    buffer.writeln('    </row>');
    row++;

    // Fila 2: Ciclo
    buffer.writeln('    <row r="$row">');
    buffer.writeln(
        '      <c r="A$row" t="inlineStr" s="2"><is><t>Ciclo Académico:</t></is></c>');
    buffer.writeln(
        '      <c r="B$row" t="inlineStr" s="3"><is><t>$cicloNombre</t></is></c>');
    buffer.writeln('    </row>');
    row++;

    // Fila 3: Estudiante
    if (nombreEstudiante != null && nombreEstudiante.isNotEmpty) {
      buffer.writeln('    <row r="$row">');
      buffer.writeln(
          '      <c r="A$row" t="inlineStr" s="2"><is><t>Estudiante:</t></is></c>');
      buffer.writeln(
          '      <c r="B$row" t="inlineStr" s="3"><is><t>$nombreEstudiante ${correoEstudiante != null ? "($correoEstudiante)" : ""}</t></is></c>');
      buffer.writeln('    </row>');
      row++;
    }

    // Fila 4: Fecha
    buffer.writeln('    <row r="$row">');
    buffer.writeln(
        '      <c r="A$row" t="inlineStr" s="2"><is><t>Fecha de Emisión:</t></is></c>');
    buffer.writeln(
        '      <c r="B$row" t="inlineStr" s="3"><is><t>$fechaStr</t></is></c>');
    buffer.writeln('    </row>');
    row++;

    // Fila vacía de separación
    row++;

    // Fila de encabezados de la tabla (Índigo institucional #3B36C4)
    buffer.writeln('    <row r="$row">');
    buffer.writeln(
        '      <c r="A$row" t="inlineStr" s="4"><is><t>N°</t></is></c>');
    buffer.writeln(
        '      <c r="B$row" t="inlineStr" s="4"><is><t>Asignatura</t></is></c>');
    buffer.writeln(
        '      <c r="C$row" t="inlineStr" s="4"><is><t>Créditos</t></is></c>');
    buffer.writeln(
        '      <c r="D$row" t="inlineStr" s="4"><is><t>% Evaluado</t></is></c>');
    buffer.writeln(
        '      <c r="E$row" t="inlineStr" s="4"><is><t>Nota Actual</t></is></c>');
    buffer.writeln(
        '      <c r="F$row" t="inlineStr" s="4"><is><t>Estado</t></is></c>');
    buffer.writeln('    </row>');
    row++;

    final primerFilaCursos = row;

    for (int i = 0; i < cursos.length; i++) {
      final curso = cursos[i];
      final res = resultados[curso.id];
      final creds = curso.creditosEfectivos;
      final nota = res?.notaActual;
      final pctEvaluado = res?.porcentajeEvaluado ?? 0.0;

      String estadoStr = 'Sin notas';
      int estiloNota = 5; // Normal

      if (nota != null) {
        if (nota >= 10.5) {
          estadoStr = (res?.estado == EstadoCalculoCurso.completo)
              ? 'Aprobado'
              : 'En curso (Aprobado)';
          estiloNota = 6; // Verde Aprobado
        } else {
          estadoStr = (res?.estado == EstadoCalculoCurso.completo)
              ? 'Desaprobado'
              : 'En riesgo';
          estiloNota = 7; // Rojo Desaprobado
        }
      }

      final zebra = (i % 2 == 0) ? '' : ' s="8"';

      buffer.writeln('    <row r="$row">');
      buffer.writeln(
          '      <c r="A$row"$zebra><v>${i + 1}</v></c>');
      buffer.writeln(
          '      <c r="B$row" t="inlineStr"$zebra><is><t>${_xmlEscape(curso.nombre)}</t></is></c>');
      buffer.writeln(
          '      <c r="C$row"$zebra><v>$creds</v></c>');
      buffer.writeln(
          '      <c r="D$row"$zebra><v>${pctEvaluado.toStringAsFixed(1)}%</v></c>');

      if (nota != null) {
        buffer.writeln(
            '      <c r="E$row" s="$estiloNota"><v>${nota.toStringAsFixed(1)}</v></c>');
      } else {
        buffer.writeln(
            '      <c r="E$row" t="inlineStr"$zebra><is><t>--</t></is></c>');
      }

      buffer.writeln(
          '      <c r="F$row" t="inlineStr"$zebra><is><t>$estadoStr</t></is></c>');
      buffer.writeln('    </row>');
      row++;
    }

    final ultimaFilaCursos = row - 1;

    // Fila de Totales y Fórmulas de Excel
    if (cursos.isNotEmpty) {
      buffer.writeln('    <row r="$row">');
      buffer.writeln(
          '      <c r="A$row" s="9"><is><t></t></is></c>');
      buffer.writeln(
          '      <c r="B$row" t="inlineStr" s="9"><is><t>TOTAL CRÉDITOS / PROMEDIO PONDERADO</t></is></c>');
      // Fórmula nativa Excel para suma de créditos
      buffer.writeln(
          '      <c r="C$row" s="9"><f>SUM(C$primerFilaCursos:C$ultimaFilaCursos)</f><v>$totalCreditos</v></c>');
      buffer.writeln(
          '      <c r="D$row" s="9"><is><t></t></is></c>');

      // Fórmula nativa Excel recalculable para Promedio Ponderado o Promedio
      if (promedioCiclo != null) {
        buffer.writeln(
            '      <c r="E$row" s="10"><f>SUMPRODUCT(C$primerFilaCursos:C$ultimaFilaCursos,E$primerFilaCursos:E$ultimaFilaCursos)/SUM(C$primerFilaCursos:C$ultimaFilaCursos)</f><v>${promedioCiclo.toStringAsFixed(2)}</v></c>');
      } else {
        buffer.writeln(
            '      <c r="E$row" s="10"><f>AVERAGE(E$primerFilaCursos:E$ultimaFilaCursos)</f><v>0</v></c>');
      }

      final condicionCiclo = (promedioCiclo != null && promedioCiclo >= 10.5)
          ? 'PROMEDIO APROBATORIO'
          : (promedioCiclo != null ? 'EN RIESGO ACADÉMICO' : 'SIN EVALUAR');
      buffer.writeln(
          '      <c r="F$row" t="inlineStr" s="9"><is><t>$condicionCiclo</t></is></c>');
      buffer.writeln('    </row>');
    }

    buffer.writeln('  </sheetData>');
    buffer.writeln('</worksheet>');

    final sheetXml = buffer.toString();

    // Empaquetado en ZIP como .xlsx OpenXML
    final archive = Archive();

    // 1. [Content_Types].xml
    archive.addFile(ArchiveFile.string(
      '[Content_Types].xml',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''',
    ));

    // 2. _rels/.rels
    archive.addFile(ArchiveFile.string(
      '_rels/.rels',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''',
    ));

    // 3. xl/_rels/workbook.xml.rels
    archive.addFile(ArchiveFile.string(
      'xl/_rels/workbook.xml.rels',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''',
    ));

    // 4. xl/workbook.xml
    archive.addFile(ArchiveFile.string(
      'xl/workbook.xml',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Avance Académico" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''',
    ));

    // 5. xl/styles.xml (Paleta azul índigo institucional #3B36C4, verde #157A45 y rojo #C0352B)
    archive.addFile(ArchiveFile.string(
      'xl/styles.xml',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="5">
    <font><name val="Calibri"/><sz val="11"/></font>
    <font><b/><name val="Calibri"/><sz val="14"/><color rgb="FF3B36C4"/></font>
    <font><b/><name val="Calibri"/><sz val="11"/><color rgb="FF1A1A24"/></font>
    <font><b/><name val="Calibri"/><sz val="11"/><color rgb="FFFFFFFF"/></font>
    <font><b/><name val="Calibri"/><sz val="11"/></font>
  </fonts>
  <fills count="6">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF3B36C4"/></patternFill></fill> <!-- Header Indigo -->
    <fill><patternFill patternType="solid"><fgColor rgb="FFE8F5E9"/></patternFill></fill> <!-- Verde Aprobado -->
    <fill><patternFill patternType="solid"><fgColor rgb="FFFFEBEE"/></patternFill></fill> <!-- Rojo Desaprobado -->
    <fill><patternFill patternType="solid"><fgColor rgb="FFF8F9FA"/></patternFill></fill> <!-- Zebra -->
  </fills>
  <borders count="2">
    <border><left/><right/><top/><bottom/><diagonal/></border>
    <border>
      <left style="thin"><color rgb="FFDCDCE8"/></left>
      <right style="thin"><color rgb="FFDCDCE8"/></right>
      <top style="thin"><color rgb="FFDCDCE8"/></top>
      <bottom style="thin"><color rgb="FFDCDCE8"/></bottom>
    </border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="11">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/> <!-- 0: default -->
    <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/> <!-- 1: titulo -->
    <xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0"/> <!-- 2: label negrita -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/> <!-- 3: texto info -->
    <xf numFmtId="0" fontId="3" fillId="2" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="center"/></xf> <!-- 4: Header Indigo -->
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0"/> <!-- 5: Normal tabla -->
    <xf numFmtId="0" fontId="4" fillId="3" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="center"/></xf> <!-- 6: Aprobado verde -->
    <xf numFmtId="0" fontId="4" fillId="4" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="center"/></xf> <!-- 7: Desaprobado rojo -->
    <xf numFmtId="0" fontId="0" fillId="5" borderId="1" xfId="0"/> <!-- 8: Zebra tabla -->
    <xf numFmtId="0" fontId="2" fillId="5" borderId="1" xfId="0"/> <!-- 9: Totales negrita -->
    <xf numFmtId="0" fontId="1" fillId="5" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="center"/></xf> <!-- 10: Promedio ponderado -->
  </cellXfs>
</styleSheet>''',
    ));

    // 6. xl/worksheets/sheet1.xml
    archive.addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', sheetXml));

    final zipEncoder = ZipEncoder();
    final encoded = zipEncoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Genera una cadena CSV con codificación UTF-8 y BOM (\uFEFF) para compatibilidad total con Excel en español.
  static String generarCsv({
    required String cicloNombre,
    required List<Curso> cursos,
    required Map<String, ResultadoCalculoCurso> resultados,
    required double? promedioCiclo,
    required int totalCreditos,
    String? nombreEstudiante,
    String? correoEstudiante,
    DateTime? fechaEmision,
  }) {
    final fecha = fechaEmision ?? DateTime.now();
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    // BOM UTF-8 (\uFEFF) para que Excel detecte automáticamente la codificación de tildes
    buffer.write('\uFEFF');

    buffer.writeln('PONDERA - REPORTE DE AVANCE ACADÉMICO;');
    buffer.writeln('Ciclo Académico:;$cicloNombre;');
    if (nombreEstudiante != null && nombreEstudiante.isNotEmpty) {
      buffer.writeln(
          'Estudiante:;"$nombreEstudiante${correoEstudiante != null ? " ($correoEstudiante)" : ""}";');
    }
    buffer.writeln('Fecha de Emisión:;$fechaStr;');
    buffer.writeln();

    // Encabezados
    buffer.writeln('N°;Asignatura;Créditos;% Evaluado;Nota Actual;Estado');

    for (int i = 0; i < cursos.length; i++) {
      final curso = cursos[i];
      final res = resultados[curso.id];
      final creds = curso.creditosEfectivos;
      final nota = res?.notaActual;
      final pctEvaluado = (res?.porcentajeEvaluado ?? 0.0).toStringAsFixed(1);

      String estadoStr = 'Sin notas';
      if (nota != null) {
        if (nota >= 10.5) {
          estadoStr = (res?.estado == EstadoCalculoCurso.completo)
              ? 'Aprobado'
              : 'En curso (Aprobado)';
        } else {
          estadoStr = (res?.estado == EstadoCalculoCurso.completo)
              ? 'Desaprobado'
              : 'En riesgo';
        }
      }

      final notaStr = nota != null ? nota.toStringAsFixed(1) : '--';
      final nombreLimpio = curso.nombre.replaceAll('"', '""');

      buffer.writeln(
          '${i + 1};"$nombreLimpio";$creds;$pctEvaluado%;$notaStr;$estadoStr');
    }

    buffer.writeln();
    final promedioStr =
        promedioCiclo != null ? promedioCiclo.toStringAsFixed(2) : '--';
    buffer.writeln('TOTAL CRÉDITOS:;$totalCreditos;;;');
    buffer.writeln('PROMEDIO PONDERADO:;$promedioStr;;;');

    return buffer.toString();
  }

  /// Comparte un archivo binario mediante la hoja nativa del sistema operativo (WhatsApp, Drive, Gmail, etc.) (H35).
  static Future<void> compartirArchivo({
    required Uint8List bytes,
    required String nombreArchivo,
    required String mimeType,
    String? subject,
    String? texto,
  }) async {
    final xFile = XFile.fromData(
      bytes,
      name: nombreArchivo,
      mimeType: mimeType,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: subject ?? 'Reporte Pondera - $nombreArchivo',
        text: texto,
      ),
    );
  }

  static String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

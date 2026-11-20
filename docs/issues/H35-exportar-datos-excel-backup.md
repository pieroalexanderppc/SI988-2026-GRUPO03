# Issue H35: Exportación de Reporte Académico a Excel (.xlsx / CSV) y Compartir Vía Nativa

- **Título en GitHub:** `feat(h35): Exportación de reporte académico a Excel (.xlsx / CSV) con fórmulas dinámicas y compartir vía nativa`
- **Labels:** `enhancement`, `interoperability`, `reporting`, `H35`, `sprint-3`
- **Responsable:** Nicolás Alonso Telleria Espinoza (`@NicolasT1`) / Elvis Mamani Valdivia (`@elvisMamaniValdivia`)
- **Rama:** `feat/h35-exportar-excel-backup`

---

## 📖 Descripción / User Story
> **Como** estudiante universitario de la UPT que gestiona su progreso académico en Pondera,  
> **quiero** exportar el detalle completo de mis asignaturas, créditos, notas y estados a una hoja de cálculo estructurada en formato Excel (`.xlsx`) y alternativamente a `.csv`, con fórmulas nativas recalculables,  
> **para** tener una copia de respaldo descargable, analizar mis calificaciones en herramientas de escritorio o en la nube (Excel / Google Sheets), y compartir mi reporte académico de forma inmediata a través de WhatsApp, Google Drive o correo institucional.

---

## 🎯 Criterios de Aceptación (Gherkin)

### CA1: Generación binaria estándar de Microsoft Excel (.xlsx) con estilos
- **Dado** un ciclo académico con cursos registrados y notas calculadas en Pondera,
- **Cuando** el usuario solicita "Exportar a Excel (.xlsx)",
- **Entonces** el sistema genera un archivo binario conforme al estándar Office Open XML (SpreadsheetML) con compresión ZIP válida, encabezados en azul índigo institucional (`#3B36C4`), formatos de celda para números decimales y coloreado condicional (verde para notas $\ge 10.5$ y rojo para notas $< 10.5$).

### CA2: Inclusión de fórmulas dinámicas nativas recalculables
- **Dado** el libro de Excel generado para el ciclo,
- **Cuando** el archivo se abre en Microsoft Excel, LibreOffice Calc o Google Sheets,
- **Entonces** la fila de totales contiene fórmulas dinámicas activas (`=SUM(...)`, `=SUMPRODUCT(...)` y `=AVERAGE(...)`) que se recalculan automáticamente si el usuario altera cualquier calificación en su software de hoja de cálculo.

### CA3: Exportación alternativa en formato plano CSV con codificación UTF-8 con BOM
- **Dado** que el usuario prefiere una exportación en formato tabular plano o ligero,
- **Cuando** selecciona "Exportar a CSV (.csv UTF-8)",
- **Entonces** el sistema genera el archivo delimitado por punto y coma con el Byte Order Mark (`\uFEFF`) al inicio, garantizando que tildes, la letra "ñ" y caracteres en español se visualicen sin corrupción tipográfica.

### CA4: Integración con la Share API nativa del sistema operativo
- **Dado** que se ha generado el archivo binario (`.xlsx` o `.csv`),
- **Cuando** se completa la exportación,
- **Entonces** se despliega la hoja nativa de compartir del dispositivo móvil (`SharePlus.instance.share`) permitiendo el envío directo por WhatsApp, Gmail, Telegram o guardado en el gestor de archivos local.

---

## 🛠️ Tareas Técnicas Implementadas
1. Creación del servicio `ExportadorExcelService` en `lib/services/exportador_excel_service.dart`.
2. Modelado de las estructuras XML OpenXML (`[Content_Types].xml`, `workbook.xml`, `styles.xml`, `sheet1.xml`).
3. Formulación de fórmulas de hoja de cálculo `SUMPRODUCT` y `SUM` ponderadas por créditos.
4. Exportación en `.csv` con `\uFEFF` UTF-8 BOM.
5. Adición de la dependencia `archive` y `share_plus` en `pubspec.yaml`.
6. Pruebas unitarias de integridad binaria en `test/exportador_excel_test.dart` pasando al 100%.

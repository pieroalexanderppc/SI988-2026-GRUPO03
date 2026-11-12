# [H26] Recordatorios de Evaluaciones y Fechas de Exámenes

## Descripción
**Como** estudiante universitario usuario de Pondera,  
**Quiero** registrar y gestionar recordatorios para mis próximas evaluaciones de cursos,  
**Para** no olvidar las fechas importantes de exámenes, entregas y prácticas, y saber cuántos días me quedan para prepararme.

---

## Contexto y Justificación
Los estudiantes suelen llevar múltiples cursos simultáneos con fechas de evaluación dispersas. La aplicación permite calcular notas pero requería una funcionalidad activa de agenda y recordatorios vinculada a los cursos y unidades registradas.

---

## Criterios de Aceptación (Gherkin)

### Escenario 1: Creación de recordatorio
- **Dado** que el estudiante está autenticado con correo verificado,
- **Cuando** presiona el botón de agregar recordatorio desde RecordatoriosScreen o desde la pantalla de cursos,
- **Entonces** puede seleccionar el curso, ingresar el título de la evaluación, fecha y hora del examen y una descripción opcional.

### Escenario 2: Listado y filtros de recordatorios
- **Dado** que existen recordatorios registrados,
- **Cuando** el usuario entra a RecordatoriosScreen,
- **Entonces** puede filtrar por estado (Todos, Pendientes, Vencidos, Completados) y ver el tiempo restante formateado (ej. "Hoy", "Mañana", "En 3 días", "Vencido").

### Escenario 3: Marcar como completado y eliminación
- **Dado** que una evaluación ya se rindió,
- **Cuando** el estudiante presiona el checkbox de completado,
- **Entonces** el estado se actualiza en Firestore inmediatamente y se tacha visualmente.

---

## Tareas Técnicas
- [x] Crear modelo RecordatorioEvaluacion con serialización a Firestore (	oMap y romMap).
- [x] Implementar servicio RecordatoriosService con operaciones CRUD y Streams en tiempo real.
- [x] Desarrollar la pantalla RecordatoriosScreen con selector de filtros, tarjetas de estado y diálogo de creación/edición.
- [x] Integrar accesos directos desde HomeScreen, CiclosScreen y CursosScreen.
- [x] Añadir suite de pruebas unitarias y de widgets en 	est/recordatorios_test.dart.

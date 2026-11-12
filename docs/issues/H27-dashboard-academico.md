# [H27] Dashboard Académico en Pantalla de Inicio con Semáforo de Riesgo y Próximas Evaluaciones

## Descripción
**Como** estudiante universitario autenticado con mi cuenta en Pondera,  
**Quiero** ver un panel de resumen académico (Dashboard) en la pantalla principal al iniciar sesión,  
**Para** conocer de un vistazo el promedio acumulado del ciclo activo, identificar rápidamente los cursos que están en riesgo mediante un semáforo visual y revisar las evaluaciones próximas a rendir.

---

## Contexto y Justificación
Actualmente, la pantalla principal (`HomeScreen`) muestra exclusivamente la calculadora rápida de promedio ponderado aislada. Aunque existe la gestión de ciclos (`CiclosScreen`) y recordatorios (`RecordatoriosScreen`), el usuario tiene que navegar por múltiples pantallas para saber su estado general.
Esta historia implementa la vista de Dashboard recomendada en la Hoja de Ruta del proyecto (*"Pantalla de inicio para usuarios con cuenta"*), unificando el estado del ciclo activo, cursos matriculados con semáforo de alerta, y un carrusel de recordatorios urgentes.

---

## Criterios de Aceptación (Gherkin)

### Escenario 1: Visualización del Dashboard para usuario autenticado
- **Dado** que el estudiante ha iniciado sesión con su correo verificado,
- **Cuando** ingresa a la aplicación (`HomeScreen`),
- **Entonces** visualiza un selector de vista superior con dos opciones: **"Mi Dashboard"** y **"Calculadora Rápida"**, situándose por defecto en **"Mi Dashboard"**.

### Escenario 2: Tarjeta de métricas del ciclo activo
- **Dado** que el estudiante tiene al menos un ciclo registrado con cursos,
- **Cuando** visualiza el Dashboard,
- **Entonces** se muestra una tarjeta destacada con:
  - Nombre del ciclo activo (ej. *"2026-I"*).
  - Promedio ponderado acumulado del ciclo.
  - Total de créditos matriculados.
  - Indicador de estado general (Aprobando / En Riesgo).

### Escenario 3: Semáforo de riesgo por curso
- **Dado** que se listan los cursos del ciclo activo,
- **Cuando** se calcula el promedio parcial/proyectado de cada curso,
- **Entonces** cada tarjeta de curso muestra una etiqueta de semáforo:
  - 🟢 **Aprobado** (Nota $\ge 14.0$).
  - 🟡 **En Riesgo** (Nota entre $10.5$ y $13.9$).
  - 🔴 **Crítico / Desaprobado** (Nota $< 10.5$).
- **Y** al tocar cualquier curso, navega directamente a la pantalla de unidades/evaluaciones de dicho curso.

### Escenario 4: Próximas evaluaciones pendientes
- **Dado** que el estudiante tiene recordatorios activos registrados (H26),
- **Cuando** observa la sección de alertas del Dashboard,
- **Entonces** se muestran las 2 evaluaciones más próximas ordenadas cronológicamente con la cantidad de días restantes y un botón de acceso directo a `RecordatoriosScreen`.

---

## Tareas Técnicas
- [x] Crear el widget `DashboardAcademicoWidget` que consulta en tiempo real los ciclos y cursos del usuario en Firestore.
- [x] Implementar el cálculo de estado de semáforo por curso utilizando la paleta oficial (`EstadoNotaColors`).
- [x] Conectar el Stream de `RecordatoriosService` para extraer los recordatorios próximos más urgentes.
- [x] Adaptar `HomeScreen` con navegación segmentada (`SegmentedButton` de Material 3) para alternar entre el Dashboard y la Calculadora rápida.
- [x] Mantener intacta la calculadora rápida y el modo sin cuenta para usuarios invitados.

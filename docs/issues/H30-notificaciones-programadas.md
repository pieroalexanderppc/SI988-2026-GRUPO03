# [H30] Notificaciones Locales y Alarmas Programadas en Segundo Plano para Evaluaciones

## Descripción
**Como** estudiante universitario con evaluaciones y exámenes registrados en Pondera,  
**Quiero** recibir notificaciones y alarmas locales automáticas en mi teléfono antes de cada examen o entrega,  
**Para** organizar mis repasos con anticipación y evitar olvidar fechas críticas de evaluación, incluso sin conexión a internet ni tener la aplicación abierta.

---

## Contexto y Justificación
En el issue H26 se completó el CRUD y listado cronológico de recordatorios de evaluaciones. No obstante, para que un recordatorio sea verdaderamente efectivo en un entorno móvil, la aplicación debe aprovechar los servicios nativos de alarmas del sistema operativo Android/iOS para alertar al estudiante de forma proactiva con una antelación configurable (24 horas antes y 1 hora antes de la prueba).

Esta funcionalidad cumple con el estándar de notificaciones locales (`flutter_local_notifications`), zonificación horaria (`timezone`) y compatibilidad con Android 13/14+ (`POST_NOTIFICATIONS` y `SCHEDULE_EXACT_ALARM`).

---

## Criterios de Aceptación (Gherkin)

### Escenario 1: Gestión de permisos nativos en Android
- **Dado** que el usuario abre la pantalla de recordatorios o registra una evaluación,
- **Cuando** se inicializa el servicio de notificaciones,
- **Entonces** se solicita de forma amigable el permiso `POST_NOTIFICATIONS` para Android 13 o superior (API 33+).

### Escenario 2: Programación con antelación configurable
- **Dado** que se registra o edita un recordatorio de evaluación con fecha y hora futura,
- **Cuando** el usuario activa la opción de alarma y define la antelación (ej. 24 horas),
- **Entonces** el sistema agenda la alarma exacta en la zona horaria local (`America/Lima` / UTC) tanto para la antelación principal como para una alerta inminente 1 hora antes de la prueba.

### Escenario 3: Cancelación al rendir o eliminar evaluación
- **Dado** un recordatorio con notificaciones pendientes programadas,
- **Cuando** el usuario lo marca como "rendida/completada" o lo elimina,
- **Entonces** las alarmas asociadas en el sistema operativo se cancelan inmediatamente para evitar alertas innecesarias.

### Escenario 4: Interacción y visualización en interfaz
- **Dado** el listado de recordatorios en `RecordatoriosScreen`,
- **Cuando** una tarjeta tiene la notificación activa,
- **Entonces** muestra un badge visual con ícono de campana y texto informativo (ej. *"24h antes"*), y en el diálogo de edición permite alternar la alarma y ajustar la antelación deseada.

---

## Tareas Técnicas
- [x] Configurar `flutter_local_notifications` y `timezone` en `pubspec.yaml`.
- [x] Declarar permisos en `AndroidManifest.xml` (`RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`).
- [x] Extender modelo `RecordatorioEvaluacion` con atributos `notificar`, `antelacionHoras`, `notificacionId` y `notificacionIdCorta`.
- [x] Crear el servicio singleton `NotificacionesService` en `lib/services/notificaciones_service.dart`.
- [x] Integrar `NotificacionesService` en `RecordatoriosService` (programación y cancelación en el ciclo de vida CRUD).
- [x] Agregar controles de configuración en el diálogo y tarjetas de `RecordatoriosScreen`.
- [x] Inicializar el servicio en `main.dart`.
- [x] Desarrollar suite de pruebas unitarias y de integración en `test/notificaciones_service_test.dart`.

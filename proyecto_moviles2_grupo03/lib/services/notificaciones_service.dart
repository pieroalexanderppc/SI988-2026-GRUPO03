import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/recordatorio_evaluacion.dart';

/// Servicio singleton para la gestión de notificaciones locales y alarmas
/// programadas en segundo plano para evaluaciones de Pondera (H30).
class NotificacionesService {
  static final NotificacionesService _instance =
      NotificacionesService._internal();

  factory NotificacionesService() => _instance;

  NotificacionesService._internal();

  FlutterLocalNotificationsPlugin? _plugin;
  bool _inicializado = false;
  bool _timezoneInicializado = false;

  /// Registro en memoria para verificar programaciones en pruebas unitarias y de widgets.
  @visibleForTesting
  final List<Map<String, dynamic>> registrosPruebas = [];

  bool get estaInicializado => _inicializado;

  static const String canalId = 'pondera_evaluaciones';
  static const String canalNombre = 'Recordatorios de Evaluaciones';
  static const String canalDescripcion =
      'Alertas y recordatorios programados de exámenes, prácticas y entregas de Pondera.';

  /// Inicializa el plugin de notificaciones locales y la base de datos de zonas horarias.
  Future<void> inicializar({
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    if (_inicializado && plugin == null) return;

    _plugin = plugin ?? FlutterLocalNotificationsPlugin();

    // Inicialización segura de TimeZones (con fallback)
    if (!_timezoneInicializado) {
      try {
        tz.initializeTimeZones();
        // Fallback para Perú / UTC-5 si no se puede inferir automáticamente
        try {
          tz.setLocalLocation(tz.getLocation('America/Lima'));
        } catch (_) {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
        _timezoneInicializado = true;
      } catch (e) {
        debugPrint('[NotificacionesService] Error inicializando timezones: $e');
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // En entorno de pruebas (flutter test), evitamos invocar canales nativos no registrados
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _inicializado = true;
      return;
    }

    try {
      await _plugin?.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint(
              '[NotificacionesService] Notificación pulsada con payload: ${response.payload}');
        },
      );
      _inicializado = true;
    } catch (e) {
      debugPrint('[NotificacionesService] Inicialización en entorno no-nativo: $e');
      _inicializado = true;
    }
  }

  /// Solicita permisos de notificación en Android 13+ (POST_NOTIFICATIONS) e iOS.
  Future<bool> solicitarPermisos() async {
    if (!_inicializado) await inicializar();

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _plugin
            ?.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final concedido =
              await androidImpl.requestNotificationsPermission();
          return concedido ?? false;
        }
      } else if (!kIsWeb && Platform.isIOS) {
        final iosImpl = _plugin
            ?.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosImpl != null) {
          final concedido = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return concedido ?? false;
        }
      }
    } catch (e) {
      debugPrint('[NotificacionesService] Error solicitando permisos: $e');
    }
    return true;
  }

  /// Configuración de canal y prioridad para Android.
  NotificationDetails _detallesNotificacion({String? subtitulo}) {
    final androidDetails = AndroidNotificationDetails(
      canalId,
      canalNombre,
      channelDescription: canalDescripcion,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Recordatorio de examen',
      icon: '@mipmap/ic_launcher',
      subText: subtitulo,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Programa las notificaciones para un recordatorio de evaluación.
  ///
  /// Agenda:
  /// 1. Alerta anticipada principal (por defecto 24 horas antes o según `antelacionHoras`).
  /// 2. Alerta urgente corta (1 hora antes de la evaluación si la fecha aún no llega).
  Future<void> programarNotificacion(RecordatorioEvaluacion rec) async {
    if (!_inicializado) await inicializar();

    // Si está completado o no se desea notificar, cancelamos alertas existentes
    if (rec.completado || !rec.notificar) {
      await cancelarNotificacion(rec.id);
      return;
    }

    final now = DateTime.now();
    if (rec.fecha.isBefore(now)) {
      // La evaluación ya pasó, no se programa
      return;
    }

    // 1. Alerta principal con la antelación configurada (ej. 24h)
    final fechaAnticipada =
        rec.fecha.subtract(Duration(hours: rec.antelacionHoras));

    if (fechaAnticipada.isAfter(now)) {
      await _agendarAlarma(
        id: rec.notificacionId,
        fecha: fechaAnticipada,
        titulo: '📅 Próxima evaluación: ${rec.titulo}',
        cuerpo: 'En ${rec.antelacionHoras}h rendirás la evaluación de ${rec.cursoNombre}. ¡Buen momento para repasar!',
        payload: rec.id,
        subtitulo: rec.cursoNombre,
      );
    }

    // 2. Alerta urgente corta (1 hora antes de la evaluación)
    final fechaCorta = rec.fecha.subtract(const Duration(hours: 1));
    if (rec.antelacionHoras > 1 &&
        fechaCorta.isAfter(now) &&
        fechaCorta != fechaAnticipada) {
      await _agendarAlarma(
        id: rec.notificacionIdCorta,
        fecha: fechaCorta,
        titulo: '⏰ ¡En 1 hora! Evaluación: ${rec.titulo}',
        cuerpo: 'Todo listo para ${rec.cursoNombre}. Revisa tus materiales y ten a mano tu fórmula de cálculo.',
        payload: rec.id,
        subtitulo: '¡Evaluación inminente!',
      );
    }
  }

  /// Agenda internamente en el plugin de notificaciones o en memoria para tests.
  Future<void> _agendarAlarma({
    required int id,
    required DateTime fecha,
    required String titulo,
    required String cuerpo,
    required String payload,
    String? subtitulo,
  }) async {
    registrosPruebas.add({
      'id': id,
      'fecha': fecha,
      'titulo': titulo,
      'cuerpo': cuerpo,
      'payload': payload,
    });

    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      final tzFecha = tz.TZDateTime.from(fecha, tz.local);
      await _plugin?.zonedSchedule(
        id: id,
        scheduledDate: tzFecha,
        notificationDetails: _detallesNotificacion(subtitulo: subtitulo),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: titulo,
        body: cuerpo,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificacionesService] zonedSchedule fallback/mock: $e');
    }
  }

  /// Cancela las notificaciones programadas asociadas a un recordatorio.
  Future<void> cancelarNotificacion(String recordatorioId) async {
    if (!_inicializado) await inicializar();

    final idPrincipal = (recordatorioId.hashCode & 0x7FFFFFFF);
    final idCorta = ('${recordatorioId}_1h'.hashCode & 0x7FFFFFFF);

    registrosPruebas.removeWhere((r) => r['payload'] == recordatorioId);

    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      await _plugin?.cancel(id: idPrincipal);
      await _plugin?.cancel(id: idCorta);
    } catch (e) {
      debugPrint('[NotificacionesService] Error al cancelar notificación: $e');
    }
  }

  /// Muestra una notificación inmediata (útil para pruebas o confirmación de guardado).
  Future<void> mostrarNotificacionInmediata({
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {
    if (!_inicializado) await inicializar();

    const id = 999999;
    registrosPruebas.add({
      'id': id,
      'fecha': DateTime.now(),
      'titulo': titulo,
      'cuerpo': cuerpo,
      'payload': payload ?? '',
    });

    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      await _plugin?.show(
        id: id,
        title: titulo,
        body: cuerpo,
        notificationDetails: _detallesNotificacion(),
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificacionesService] Fallback mostrar inmediata: $e');
    }
  }

  /// Cancela todas las notificaciones pendientes de la aplicación.
  Future<void> cancelarTodas() async {
    if (!_inicializado) await inicializar();

    registrosPruebas.clear();
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      await _plugin?.cancelAll();
    } catch (e) {
      debugPrint('[NotificacionesService] Error al cancelar todas: $e');
    }
  }

  /// Limpia los registros acumulados durante pruebas unitarias.
  @visibleForTesting
  void limpiarRegistrosParaPruebas() {
    registrosPruebas.clear();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database_helper.dart';

class NotificacionesService {
  NotificacionesService._();

  static final NotificacionesService instance =
      NotificacionesService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  bool _inicializado = false;

  static const Set<String> _titulosAlertasInventario = {
    'Producto próximo a caducar',
    'Caducidad mañana',
    'Stock bajo',
    'Producto agotado',
  };

  Future<void> inicializar() async {
    if (_inicializado) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const configuracion = InitializationSettings(android: android);

    await _plugin.initialize(settings: configuracion);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'alertas_inventario',
        'Alertas de inventario',
        description: 'Avisos de caducidad y niveles de existencias',
        importance: Importance.high,
      ),
    );

    _inicializado = true;
  }

  NotificationDetails get _detalles => const NotificationDetails(
        android: AndroidNotificationDetails(
          'alertas_inventario',
          'Alertas de inventario',
          channelDescription:
              'Avisos de caducidad y niveles de existencias',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );

  tz.TZDateTime _aHoraLocal(DateTime fecha) {
    return tz.TZDateTime(
      tz.local,
      fecha.year,
      fecha.month,
      fecha.day,
      9,
    );
  }

  /// Actualiza las alertas sin interrumpir la operación que la invocó.
  ///
  /// Devuelve true si se pudieron actualizar y false si ocurrió un error.
  Future<bool> actualizarAlertasSeguro() async {
    try {
      await programarAlertasInventario();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error al actualizar las alertas: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Cancela únicamente notificaciones que pertenecen al inventario.
  ///
  /// No cancela la notificación de prueba ni las de otras funciones que
  /// utilicen títulos diferentes.
  Future<void> _cancelarAlertasAnteriores() async {
    final pendientes = await _plugin.pendingNotificationRequests();

    for (final notificacion in pendientes) {
      if (_titulosAlertasInventario.contains(notificacion.title)) {
        await _plugin.cancel(id: notificacion.id);
      }
    }
  }

  Future<void> programarAlertasInventario() async {
    await inicializar();

    final db = await _databaseHelper.database;
    final ahora = DateTime.now();

    // Recalcular las alertas sin cancelar las notificaciones ajenas
    // al inventario.
    await _cancelarAlertasAnteriores();

    final fechaHoy = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    // ------------------------------------------------------------
    // 1. ALERTAS DE CADUCIDAD
    // ------------------------------------------------------------

    final lotes = await db.rawQuery('''
      SELECT
        l.id AS lote_id,
        l.cantidad,
        l.fecha_caducidad,
        p.nombre AS producto_nombre
      FROM lotes l
      INNER JOIN productos p ON p.id = l.producto_id
      WHERE l.cantidad > 0
        AND p.notificaciones_habilitadas = 1
    ''');

    for (final lote in lotes) {
      final idLote = (lote['lote_id'] as num).toInt();
      final fechaTexto = lote['fecha_caducidad']?.toString();

      if (fechaTexto == null) continue;

      final fecha = DateTime.tryParse(fechaTexto);

      if (fecha == null) continue;

      final caducidad = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
      );

      final diasRestantes = caducidad.difference(fechaHoy).inDays;

      // No programar avisos de caducidades que ya pasaron o que son hoy.
      if (diasRestantes <= 0) continue;

      final nombre = lote['producto_nombre']?.toString() ?? 'Producto';
      final cantidad = (lote['cantidad'] as num).toInt();

      // Aviso una semana antes de la caducidad.
      if (diasRestantes >= 7) {
        final fechaRecordatorioSemana = _aHoraLocal(
          caducidad.subtract(const Duration(days: 7)),
        );

        if (fechaRecordatorioSemana.isAfter(
          tz.TZDateTime.now(tz.local),
        )) {
          await _plugin.zonedSchedule(
            id: idLote * 10 + 1,
            title: 'Producto próximo a caducar',
            body: '$nombre tiene $cantidad unidad(es) y caduca en 7 días.',
            scheduledDate: fechaRecordatorioSemana,
            notificationDetails: _detalles,
            androidScheduleMode:
                AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }

      // Aviso un día antes de la caducidad.
      final fechaRecordatorioDiaAnterior = _aHoraLocal(
        caducidad.subtract(const Duration(days: 1)),
      );

      if (fechaRecordatorioDiaAnterior.isAfter(
        tz.TZDateTime.now(tz.local),
      )) {
        await _plugin.zonedSchedule(
          id: idLote * 10 + 2,
          title: 'Caducidad mañana',
          body: '$nombre tiene $cantidad unidad(es). Revisa este lote.',
          scheduledDate: fechaRecordatorioDiaAnterior,
          notificationDetails: _detalles,
          androidScheduleMode:
              AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }

    // ------------------------------------------------------------
    // 2. ALERTAS DE STOCK BAJO Y PRODUCTOS AGOTADOS
    // ------------------------------------------------------------

    final hoy =
        '${ahora.year.toString().padLeft(4, '0')}-'
        '${ahora.month.toString().padLeft(2, '0')}-'
        '${ahora.day.toString().padLeft(2, '0')}';

    final productos = await db.rawQuery('''
      SELECT
        p.id,
        p.nombre,
        p.stock_minimo,
        COUNT(l.id) AS lotes_registrados,
        COALESCE(
          SUM(
            CASE
              WHEN l.fecha_caducidad >= ? THEN l.cantidad
              ELSE 0
            END
          ),
          0
        ) AS stock
      FROM productos p
      LEFT JOIN lotes l ON l.producto_id = p.id
      WHERE p.notificaciones_habilitadas = 1
      GROUP BY p.id, p.nombre, p.stock_minimo
    ''', [hoy]);

    final manana = DateTime(
      ahora.year,
      ahora.month,
      ahora.day + 1,
    );

    final horaRecordatorio = _aHoraLocal(manana);

    for (final producto in productos) {
      final idProducto = (producto['id'] as num).toInt();
      final nombre = producto['nombre']?.toString() ?? 'Producto';
      final stock = (producto['stock'] as num).toInt();
      final minimo = (producto['stock_minimo'] as num).toInt();
      final lotesRegistrados =
          (producto['lotes_registrados'] as num).toInt();

      // Producto que ya tiene lotes registrados, pero no existencias
      // vigentes disponibles.
      if (stock == 0 && lotesRegistrados > 0) {
        await _plugin.zonedSchedule(
          id: 2000000 + idProducto,
          title: 'Producto agotado',
          body: '$nombre no tiene existencias disponibles.',
          scheduledDate: horaRecordatorio,
          notificationDetails: _detalles,
          androidScheduleMode:
              AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else if (stock > 0 && stock <= minimo) {
        // Producto con existencias iguales o inferiores al mínimo.
        await _plugin.zonedSchedule(
          id: 1000000 + idProducto,
          title: 'Stock bajo',
          body: '$nombre: quedan $stock unidad(es). '
              'El mínimo configurado es $minimo.',
          scheduledDate: horaRecordatorio,
          notificationDetails: _detalles,
          androidScheduleMode:
              AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  Future<void> mostrarNotificacionPrueba() async {
    await inicializar();

    await _plugin.show(
      id: 999999,
      title: 'Notificaciones activadas',
      body: 'Las alertas de tu inventario están configuradas.',
      notificationDetails: _detalles,
    );
  }
}
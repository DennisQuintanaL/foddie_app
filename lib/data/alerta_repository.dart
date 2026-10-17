import 'database_helper.dart';

class AlertaRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Obtiene los lotes que todavía tienen existencias.
  /// Incluye los vencidos para identificarlos en el calendario.
  Future<List<Map<String, Object?>>> obtenerLotesConCaducidad() async {
    final db = await _databaseHelper.database;

    return db.rawQuery('''
      SELECT
        l.id AS lote_id,
        l.producto_id,
        l.tienda_id,
        l.cantidad,
        l.fecha_caducidad,
        l.fecha_registro,
        p.nombre AS producto_nombre,
        p.unidad AS unidad,
        p.imagen_path AS imagen_path,
        t.nombre AS tienda_nombre
      FROM lotes l
      INNER JOIN productos p ON p.id = l.producto_id
      LEFT JOIN tiendas t ON t.id = l.tienda_id
      WHERE l.cantidad > 0
      ORDER BY l.fecha_caducidad ASC
    ''');
  }

  /// Calcula el stock disponible por producto.
  /// Los lotes vencidos no cuentan como existencias disponibles.
  Future<List<Map<String, Object?>>> obtenerResumenStock() async {
    final db = await _databaseHelper.database;
    final hoy = _fecha(DateTime.now());

    return db.rawQuery('''
      SELECT
        p.id AS producto_id,
        p.nombre AS producto_nombre,
        p.unidad AS unidad,
        p.imagen_path AS imagen_path,
        p.stock_minimo AS stock_minimo,
        COALESCE(SUM(
          CASE
            WHEN l.fecha_caducidad >= ? THEN l.cantidad
            ELSE 0
          END
        ), 0) AS stock_disponible
      FROM productos p
      LEFT JOIN lotes l ON l.producto_id = p.id
      GROUP BY
        p.id,
        p.nombre,
        p.unidad,
        p.imagen_path,
        p.stock_minimo
      ORDER BY p.nombre ASC
    ''', [hoy]);
  }

  /// Obtiene los productos que necesitan atención.
  ///
  /// Estado:
  /// - agotado: no tiene stock disponible.
  /// - caducado: tiene lotes vencidos con existencias.
  /// - por_caducar: tiene lotes que vencen en los próximos 7 días.
  /// - stock_bajo: tiene existencias iguales o inferiores al mínimo.
  ///
  /// Un producto puede tener más de una condición.
  Future<List<Map<String, Object?>>> obtenerProductosConAlertas() async {
    final db = await _databaseHelper.database;
    final hoy = DateTime.now();
    final fechaHoy = _fecha(hoy);
    final fechaLimite = _fecha(hoy.add(const Duration(days: 7)));

    return db.rawQuery('''
      SELECT
        p.id AS producto_id,
        p.nombre AS producto_nombre,
        p.descripcion AS descripcion,
        p.unidad AS unidad,
        p.imagen_path AS imagen_path,
        p.stock_minimo AS stock_minimo,

        COALESCE(SUM(
          CASE
            WHEN l.fecha_caducidad >= ? THEN l.cantidad
            ELSE 0
          END
        ), 0) AS stock_disponible,

        COALESCE(SUM(
          CASE
            WHEN l.fecha_caducidad < ? THEN l.cantidad
            ELSE 0
          END
        ), 0) AS stock_caducado,

        MIN(
          CASE
            WHEN l.cantidad > 0
              AND l.fecha_caducidad >= ?
              AND l.fecha_caducidad <= ?
            THEN l.fecha_caducidad
            ELSE NULL
          END
        ) AS proxima_caducidad

      FROM productos p
      LEFT JOIN lotes l ON l.producto_id = p.id
      GROUP BY
        p.id,
        p.nombre,
        p.descripcion,
        p.unidad,
        p.imagen_path,
        p.stock_minimo
      HAVING
        stock_disponible = 0
        OR stock_caducado > 0
        OR proxima_caducidad IS NOT NULL
        OR stock_disponible <= p.stock_minimo
      ORDER BY
        CASE WHEN stock_caducado > 0 THEN 0 ELSE 1 END,
        proxima_caducidad ASC,
        p.nombre ASC
    ''', [
      fechaHoy,
      fechaHoy,
      fechaHoy,
      fechaLimite,
    ]);
  }

  String _fecha(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }
}

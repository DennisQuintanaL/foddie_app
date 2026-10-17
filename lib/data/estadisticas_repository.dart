import '../data/database_helper.dart';

class EstadisticasRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  String _fecha(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '$anio-$mes-$dia';
  }

  Future<Map<String, Object?>> obtenerResumen() async {
    final db = await _databaseHelper.database;
    final hoy = _fecha(DateTime.now());

    final productos = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM productos
    ''');

    final unidades = await db.rawQuery('''
      SELECT COALESCE(SUM(cantidad), 0) AS total
      FROM lotes
      WHERE cantidad > 0 AND fecha_caducidad >= ?
    ''', [hoy]);

    final gastos = await db.rawQuery('''
      SELECT COALESCE(SUM(cantidad * precio_unitario), 0) AS total
      FROM historial_compras
    ''');

    final stockBajo = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM (
        SELECT
          p.id,
          p.stock_minimo,
          COALESCE(SUM(
            CASE
              WHEN l.fecha_caducidad >= ? THEN l.cantidad
              ELSE 0
            END
          ), 0) AS stock
        FROM productos p
        LEFT JOIN lotes l ON l.producto_id = p.id
        GROUP BY p.id, p.stock_minimo
      )
      WHERE stock > 0 AND stock <= stock_minimo
    ''', [hoy]);

    return {
      'productos': (productos.first['total'] as num).toInt(),
      'unidades': (unidades.first['total'] as num).toInt(),
      'gastos': (gastos.first['total'] as num).toDouble(),
      'stock_bajo': (stockBajo.first['total'] as num).toInt(),
    };
  }

  Future<List<Map<String, Object?>>> obtenerGastosPorTienda() async {
    final db = await _databaseHelper.database;

    return db.rawQuery('''
      SELECT
        t.id AS tienda_id,
        t.nombre AS tienda_nombre,
        COALESCE(SUM(h.cantidad * h.precio_unitario), 0) AS total_gastado
      FROM tiendas t
      LEFT JOIN historial_compras h ON h.tienda_id = t.id
      GROUP BY t.id, t.nombre
      ORDER BY total_gastado DESC, t.nombre ASC
    ''');
  }

  Future<List<Map<String, Object?>>> obtenerProximasCaducidades({
    int dias = 30,
  }) async {
    final db = await _databaseHelper.database;
    final hoy = _fecha(DateTime.now());
    final limite = _fecha(DateTime.now().add(Duration(days: dias)));

    return db.rawQuery('''
      SELECT
        l.id AS lote_id,
        l.cantidad,
        l.fecha_caducidad,
        p.nombre AS producto_nombre,
        p.unidad AS unidad,
        t.nombre AS tienda_nombre
      FROM lotes l
      INNER JOIN productos p ON p.id = l.producto_id
      LEFT JOIN tiendas t ON t.id = l.tienda_id
      WHERE l.cantidad > 0
        AND l.fecha_caducidad >= ?
        AND l.fecha_caducidad <= ?
      ORDER BY l.fecha_caducidad ASC
    ''', [hoy, limite]);
  }
}

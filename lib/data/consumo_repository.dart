import '../data/database_helper.dart';

class ConsumoRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Map<String, Object?>>> consumirProducto({
    required int productoId,
    required int cantidad,
  }) async {
    if (cantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que cero.');
    }

    final db = await _databaseHelper.database;

    return db.transaction((txn) async {
      final hoy = DateTime.now().toIso8601String().split('T').first;

      // Solo se consideran lotes con existencias y no vencidos.
      final lotes = await txn.query(
        'lotes',
        where: 'producto_id = ? AND cantidad > 0 AND fecha_caducidad >= ?',
        whereArgs: [productoId, hoy],
        orderBy: 'fecha_caducidad ASC, id ASC',
      );

      final stockDisponible = lotes.fold<int>(
        0,
        (total, lote) => total + (lote['cantidad'] as int),
      );

      if (stockDisponible < cantidad) {
        throw StateError(
          'Stock insuficiente. Disponible: $stockDisponible unidades.',
        );
      }

      var pendiente = cantidad;
      final detalle = <Map<String, Object?>>[];

      for (final lote in lotes) {
        if (pendiente == 0) break;

        final cantidadLote = lote['cantidad'] as int;
        final descontar =
            cantidadLote < pendiente ? cantidadLote : pendiente;
        final nuevaCantidad = cantidadLote - descontar;

        await txn.update(
          'lotes',
          {'cantidad': nuevaCantidad},
          where: 'id = ?',
          whereArgs: [lote['id']],
        );

        detalle.add({
          'lote_id': lote['id'],
          'fecha_caducidad': lote['fecha_caducidad'],
          'cantidad_consumida': descontar,
          'cantidad_restante': nuevaCantidad,
        });

        pendiente -= descontar;
      }

      return detalle;
    });
  }

  Future<int> obtenerStockDisponible(int productoId) async {
    final db = await _databaseHelper.database;
    final hoy = DateTime.now().toIso8601String().split('T').first;

    final resultado = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(cantidad), 0) AS total
      FROM lotes
      WHERE producto_id = ?
        AND cantidad > 0
        AND fecha_caducidad >= ?
      ''',
      [productoId, hoy],
    );

    return (resultado.first['total'] as num).toInt();
  }
}

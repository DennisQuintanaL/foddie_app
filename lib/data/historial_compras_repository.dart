import '../data/database_helper.dart';

class HistorialComprasRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> registrarCompra({
    required int productoId,
    required int tiendaId,
    required int cantidad,
    required double precioUnitario,
    required DateTime fechaCaducidad,
  }) async {
    if (cantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que cero.');
    }

    if (precioUnitario < 0) {
      throw ArgumentError('El precio no puede ser negativo.');
    }

    final db = await _databaseHelper.database;
    final ahora = DateTime.now().toIso8601String();
    final caducidad =
        '${fechaCaducidad.year.toString().padLeft(4, '0')}-'
        '${fechaCaducidad.month.toString().padLeft(2, '0')}-'
        '${fechaCaducidad.day.toString().padLeft(2, '0')}';

    await db.transaction((txn) async {
      // Crear el lote con las unidades compradas.
      final loteId = await txn.insert('lotes', {
        'producto_id': productoId,
        'tienda_id': tiendaId,
        'cantidad': cantidad,
        'fecha_caducidad': caducidad,
        'fecha_registro': ahora,
      });

      // Registrar la compra relacionada con el lote.
      await txn.insert('historial_compras', {
        'producto_id': productoId,
        'tienda_id': tiendaId,
        'lote_id': loteId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'fecha_compra': ahora,
      });

      // Guardar la última tienda en la que se compró el producto.
      await txn.update(
        'productos',
        {'ultima_tienda_id': tiendaId},
        where: 'id = ?',
        whereArgs: [productoId],
      );
    });
  }

  Future<List<Map<String, Object?>>> obtenerHistorial() async {
    final db = await _databaseHelper.database;

    return db.rawQuery('''
      SELECT
        h.id,
        h.producto_id,
        h.tienda_id,
        h.lote_id,
        h.cantidad,
        h.precio_unitario,
        h.fecha_compra,
        p.nombre AS producto_nombre,
        p.unidad AS unidad,
        t.nombre AS tienda_nombre
      FROM historial_compras h
      INNER JOIN productos p ON p.id = h.producto_id
      INNER JOIN tiendas t ON t.id = h.tienda_id
      ORDER BY h.fecha_compra DESC, h.id DESC
    ''');
  }
}

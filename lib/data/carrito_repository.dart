import 'database_helper.dart';

class CarritoRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Obtiene los productos del carrito junto con sus imágenes.
  Future<List<Map<String, Object?>>> obtenerItems() async {
    final db = await _db.database;

    return db.rawQuery('''
      SELECT
        lc.id AS carrito_id,
        lc.producto_id,
        lc.cantidad AS cantidad_carrito,
        lc.agregado_en,
        p.nombre AS producto_nombre,
        p.imagen_path,
        p.unidad
      FROM lista_compras lc
      INNER JOIN productos p ON p.id = lc.producto_id
      ORDER BY p.nombre COLLATE NOCASE ASC
    ''');
  }

  /// Agrega un producto o incrementa su cantidad si ya existe.
  Future<void> agregarProducto(int productoId, {int cantidad = 1}) async {
    if (cantidad < 1) {
      throw ArgumentError('La cantidad debe ser mayor que cero.');
    }

    final db = await _db.database;

    await db.transaction((txn) async {
      final existentes = await txn.query(
        'lista_compras',
        columns: ['id', 'cantidad'],
        where: 'producto_id = ?',
        whereArgs: [productoId],
        limit: 1,
      );

      if (existentes.isNotEmpty) {
        final registro = existentes.first;
        final cantidadActual = registro['cantidad'] as int;

        await txn.update(
          'lista_compras',
          {'cantidad': cantidadActual + cantidad},
          where: 'id = ?',
          whereArgs: [registro['id']],
        );
      } else {
        final ahora = DateTime.now();
        final fecha =
            '${ahora.year.toString().padLeft(4, '0')}-'
            '${ahora.month.toString().padLeft(2, '0')}-'
            '${ahora.day.toString().padLeft(2, '0')} '
            '${ahora.hour.toString().padLeft(2, '0')}:'
            '${ahora.minute.toString().padLeft(2, '0')}:'
            '${ahora.second.toString().padLeft(2, '0')}';

        await txn.insert('lista_compras', {
          'producto_id': productoId,
          'cantidad': cantidad,
          'agregado_en': fecha,
        });
      }
    });
  }

  /// Establece una nueva cantidad para un producto del carrito.
  Future<void> actualizarCantidad(int productoId, int cantidad) async {
    final db = await _db.database;

    if (cantidad <= 0) {
      await eliminarProducto(productoId);
      return;
    }

    await db.update(
      'lista_compras',
      {'cantidad': cantidad},
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
  }

  /// Elimina un producto del carrito.
  Future<void> eliminarProducto(int productoId) async {
    final db = await _db.database;

    await db.delete(
      'lista_compras',
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
  }

  /// Vacía completamente el carrito.
  Future<void> vaciar() async {
    final db = await _db.database;
    await db.delete('lista_compras');
  }

  /// Devuelve el total de unidades que hay en el carrito.
  Future<int> obtenerCantidadTotal() async {
    final db = await _db.database;

    final resultado = await db.rawQuery('''
      SELECT COALESCE(SUM(cantidad), 0) AS total
      FROM lista_compras
    ''');

    return (resultado.first['total'] as num).toInt();
  }
}

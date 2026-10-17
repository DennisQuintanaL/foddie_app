import 'database_helper.dart';
import '../models/lote.dart';

class LoteRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // CREATE
  Future<int> crear(Lote lote) async {
    if (lote.cantidad < 0) {
      throw ArgumentError('La cantidad no puede ser negativa');
    }

    return _db.insertar(
      'lotes',
      lote.toMap(),
    );
  }

  // READ: obtener todos los lotes
  Future<List<Lote>> obtenerTodos() async {
    final registros = await _db.consultar('lotes');

    return registros
        .map((registro) => Lote.fromMap(registro))
        .toList();
  }

  // READ: obtener un lote por ID
  Future<Lote?> obtenerPorId(int id) async {
    final registro = await _db.consultarPorId('lotes', id);

    if (registro == null) return null;

    return Lote.fromMap(registro);
  }

  // READ: obtener los lotes de un producto, primero el que caduca antes
  Future<List<Lote>> obtenerPorProducto(int productoId) async {
    final db = await _db.database;

    final registros = await db.query(
      'lotes',
      where: 'producto_id = ? AND cantidad > 0',
      whereArgs: [productoId],
      orderBy: 'fecha_caducidad ASC, id ASC',
    );

    return registros
        .map((registro) => Lote.fromMap(registro))
        .toList();
  }

  // UPDATE
  Future<int> editar(Lote lote) async {
    if (lote.id == null) {
      throw ArgumentError('El lote debe tener un ID');
    }

    if (lote.cantidad < 0) {
      throw ArgumentError('La cantidad no puede ser negativa');
    }

    return _db.actualizar(
      'lotes',
      lote.id!,
      lote.toMap(),
    );
  }

  // DELETE
  Future<int> eliminar(int id) {
    return _db.eliminar('lotes', id);
  }

  // READ: calcular el stock total de un producto
  Future<int> obtenerStockTotal(int productoId) async {
    final db = await _db.database;

    final resultado = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(cantidad), 0) AS stock
      FROM lotes
      WHERE producto_id = ? AND cantidad > 0
      ''',
      [productoId],
    );

    return resultado.first['stock'] as int;
  }
}
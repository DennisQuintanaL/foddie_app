import 'database_helper.dart';
import '../models/producto.dart';

class ProductoRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // CREATE
  Future<int> crear(Producto producto) {
    return _db.insertar(
      'productos',
      producto.toMap(),
    );
  }

  // READ: obtener todos los productos
  Future<List<Producto>> obtenerTodos() async {
    final registros = await _db.consultar('productos');

    return registros
        .map((registro) => Producto.fromMap(registro))
        .toList();
  }

  // READ: obtener un producto por ID
  Future<Producto?> obtenerPorId(int id) async {
    final registro = await _db.consultarPorId('productos', id);

    if (registro == null) return null;

    return Producto.fromMap(registro);
  }

  // READ: obtener productos de una categoría
  Future<List<Producto>> obtenerPorCategoria(
    int categoriaId,
  ) async {
    final db = await _db.database;

    final registros = await db.query(
      'productos',
      where: 'categoria_id = ?',
      whereArgs: [categoriaId],
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    return registros
        .map((registro) => Producto.fromMap(registro))
        .toList();
  }

  // UPDATE
  Future<int> editar(Producto producto) {
    if (producto.id == null) {
      throw ArgumentError('El producto debe tener un ID');
    }

    return _db.actualizar(
      'productos',
      producto.id!,
      producto.toMap(),
    );
  }

  // DELETE
  Future<int> eliminar(int id) {
    return _db.eliminar('productos', id);
  }
}
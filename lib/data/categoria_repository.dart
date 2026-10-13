import 'database_helper.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> crear(Categoria categoria) {
    return _db.insertar(
      'categorias',
      categoria.toMap(),
    );
  }

  Future<List<Categoria>> obtenerTodas() async {
    final registros = await _db.consultar('categorias');

    return registros
        .map((registro) => Categoria.fromMap(registro))
        .toList();
  }

  Future<Categoria?> obtenerPorId(int id) async {
    final registro = await _db.consultarPorId('categorias', id);

    if (registro == null) return null;

    return Categoria.fromMap(registro);
  }

  Future<int> editar(Categoria categoria) {
    if (categoria.id == null) {
      throw ArgumentError('La categoría debe tener un ID');
    }

    return _db.actualizar(
      'categorias',
      categoria.id!,
      categoria.toMap(),
    );
  }

  Future<int> eliminar(int id) {
    return _db.eliminar('categorias', id);
  }
}
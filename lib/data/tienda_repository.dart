import 'database_helper.dart';
import '../models/tienda.dart';

class TiendaRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<int> crear(Tienda tienda) {
    return _db.insertar(
      'tiendas',
      tienda.toMap(),
    );
  }

  Future<List<Tienda>> obtenerTodas() async {
    final registros = await _db.consultar('tiendas');

    return registros
        .map((registro) => Tienda.fromMap(registro))
        .toList();
  }

  Future<Tienda?> obtenerPorId(int id) async {
    final registro = await _db.consultarPorId('tiendas', id);

    if (registro == null) return null;

    return Tienda.fromMap(registro);
  }

  Future<int> editar(Tienda tienda) {
    if (tienda.id == null) {
      throw ArgumentError('La tienda debe tener un ID');
    }

    return _db.actualizar(
      'tiendas',
      tienda.id!,
      tienda.toMap(),
    );
  }

  Future<int> eliminar(int id) {
    return _db.eliminar('tiendas', id);
  }
}
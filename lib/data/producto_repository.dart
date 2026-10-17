import '../data/database_helper.dart';
import '../models/status_articulo.dart';

class ProductoRepository {
  final _dbHelper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> obtenerAlertasYEstado() async {
    final db = await _dbHelper.database;

    // Consulta que consolida el stock total de lotes y el lote con la caducidad más próxima (FEFO)
    final List<Map<String, dynamic>> resultado = await db.rawQuery('''
      SELECT 
        p.id,
        p.nombre,
        p.imagen_path,
        p.unidad,
        p.stock_minimo,
        COALESCE(SUM(l.cantidad), 0) AS stock_total,
        MIN(l.fecha_caducidad) AS proxima_caducidad
      FROM productos p
      LEFT JOIN lotes l ON p.id = l.producto_id AND l.cantidad > 0
      GROUP BY p.id
    ''');

    final DateTime hoy = DateTime.now();
    final DateTime hoyLimpio = DateTime(hoy.year, hoy.month, hoy.day);

    return resultado.map((item) {
      final int stockTotal = item['stock_total'] as int;
      final int stockMinimo = item['stock_minimo'] as int;
      final String? fechaCadStr = item['proxima_caducidad'] as String?;

      EstatusArticulo estatus = EstatusArticulo.normal;
      DateTime? fechaCad;

      if (fechaCadStr != null) {
        fechaCad = DateTime.parse(fechaCadStr);
        final diferenciaDias = fechaCad.difference(hoyLimpio).inDays;

        if (diferenciaDias < 0) {
          estatus = EstatusArticulo.caducado;
        } else if (diferenciaDias <= 3) {
          estatus = EstatusArticulo.porCaducar;
        }
      }

      if (stockTotal == 0) {
        estatus = EstatusArticulo.sinExistencia;
      } else if (stockTotal <= stockMinimo && estatus == EstatusArticulo.normal) {
        estatus = EstatusArticulo.porAgotarse;
      }

      return {
        'id': item['id'],
        'nombre': item['nombre'],
        'imagen': item['imagen_path'],
        'cantidad': stockTotal,
        'unidad': item['unidad'],
        'fecha': fechaCad,
        'estatus': estatus,
      };
    }).toList();
  }
}
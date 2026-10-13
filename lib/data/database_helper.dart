import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventario_domestico.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categorias (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL UNIQUE,
            descripcion TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE tiendas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            direccion TEXT,
            telefono TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            descripcion TEXT,
            categoria_id INTEGER NOT NULL,
            imagen_path TEXT,
            unidad TEXT NOT NULL DEFAULT 'pieza',
            stock_minimo INTEGER NOT NULL DEFAULT 1
              CHECK (stock_minimo >= 0),
            ultima_tienda_id INTEGER,
            notificaciones_habilitadas INTEGER NOT NULL DEFAULT 1
              CHECK (notificaciones_habilitadas IN (0, 1)),
            FOREIGN KEY (categoria_id)
              REFERENCES categorias(id) ON DELETE RESTRICT,
            FOREIGN KEY (ultima_tienda_id)
              REFERENCES tiendas(id) ON DELETE SET NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE lotes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            producto_id INTEGER NOT NULL,
            tienda_id INTEGER,
            cantidad INTEGER NOT NULL DEFAULT 0
              CHECK (cantidad >= 0),
            fecha_caducidad TEXT NOT NULL,
            fecha_registro TEXT NOT NULL,
            FOREIGN KEY (producto_id)
              REFERENCES productos(id) ON DELETE RESTRICT,
            FOREIGN KEY (tienda_id)
              REFERENCES tiendas(id) ON DELETE SET NULL
        )
        ''');

        await db.execute('''
          CREATE TABLE historial_compras (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            producto_id INTEGER NOT NULL,
            tienda_id INTEGER NOT NULL,
            lote_id INTEGER,
            cantidad INTEGER NOT NULL CHECK (cantidad > 0),
            precio_unitario REAL NOT NULL DEFAULT 0
              CHECK (precio_unitario >= 0),
            fecha_compra TEXT NOT NULL,
            FOREIGN KEY (producto_id)
              REFERENCES productos(id) ON DELETE RESTRICT,
            FOREIGN KEY (tienda_id)
              REFERENCES tiendas(id) ON DELETE RESTRICT,
            FOREIGN KEY (lote_id)
              REFERENCES lotes(id) ON DELETE SET NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE lista_compras (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            producto_id INTEGER NOT NULL UNIQUE,
            cantidad INTEGER NOT NULL DEFAULT 1
              CHECK (cantidad > 0),
            agregado_en TEXT NOT NULL,
            FOREIGN KEY (producto_id)
              REFERENCES productos(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_lotes_producto_caducidad
          ON lotes(producto_id, fecha_caducidad)
        ''');

        await db.execute('''
          CREATE INDEX idx_historial_producto
          ON historial_compras(producto_id, fecha_compra)
        ''');
      },
    );
  }

  // CREATE
  Future<int> insertar(String tabla, Map<String, Object?> datos) async {
    final db = await database;
    return db.insert(tabla, datos);
  }

  // READ de todos los registros
  Future<List<Map<String, Object?>>> consultar(String tabla) async {
    final db = await database;
    return db.query(tabla);
  }

  // READ de un registro por ID
  Future<Map<String, Object?>?> consultarPorId(String tabla, int id) async {
    final db = await database;
    final resultado = await db.query(
      tabla,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return resultado.isEmpty ? null : resultado.first;
  }

  // UPDATE
  Future<int> actualizar(String tabla, int id, Map<String, Object?> datos) async {
    final db = await database;
    return db.update(
      tabla,
      datos,
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // DELETE
  Future<int> eliminar(String tabla, int id) async {
    final db = await database;
    return db.delete(
      tabla,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
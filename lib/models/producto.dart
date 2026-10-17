class Producto {
  final int? id;
  final String nombre;
  final String? descripcion;
  final int categoriaId;
  final String? imagenPath;
  final String unidad;
  final int stockMinimo;
  final int? ultimaTiendaId;
  final bool notificacionesHabilitadas;

  Producto({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.categoriaId,
    this.imagenPath,
    this.unidad = 'pieza',
    this.stockMinimo = 1,
    this.ultimaTiendaId,
    this.notificacionesHabilitadas = true,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
      'imagen_path': imagenPath,
      'unidad': unidad,
      'stock_minimo': stockMinimo,
      'ultima_tienda_id': ultimaTiendaId,
      'notificaciones_habilitadas':
          notificacionesHabilitadas ? 1 : 0,
    }..removeWhere((key, value) => value == null);
  }

  factory Producto.fromMap(Map<String, Object?> map) {
    return Producto(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      categoriaId: map['categoria_id'] as int,
      imagenPath: map['imagen_path'] as String?,
      unidad: map['unidad'] as String,
      stockMinimo: map['stock_minimo'] as int,
      ultimaTiendaId: map['ultima_tienda_id'] as int?,
      notificacionesHabilitadas:
          (map['notificaciones_habilitadas'] as int) == 1,
    );
  }
}
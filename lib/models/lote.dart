class Lote {
  final int? id;
  final int productoId;
  final int? tiendaId;
  final int cantidad;
  final String fechaCaducidad;
  final String fechaRegistro;

  Lote({
    this.id,
    required this.productoId,
    this.tiendaId,
    required this.cantidad,
    required this.fechaCaducidad,
    required this.fechaRegistro,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'tienda_id': tiendaId,
      'cantidad': cantidad,
      'fecha_caducidad': fechaCaducidad,
      'fecha_registro': fechaRegistro,
    }..removeWhere((key, value) => value == null);
  }

  factory Lote.fromMap(Map<String, Object?> map) {
    return Lote(
      id: map['id'] as int,
      productoId: map['producto_id'] as int,
      tiendaId: map['tienda_id'] as int?,
      cantidad: map['cantidad'] as int,
      fechaCaducidad: map['fecha_caducidad'] as String,
      fechaRegistro: map['fecha_registro'] as String,
    );
  }
}
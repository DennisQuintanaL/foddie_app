class Categoria {
  final int? id;
  final String nombre;
  final String? descripcion;

  Categoria({
    this.id,
    required this.nombre,
    this.descripcion,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    }..removeWhere((key, value) => value == null);
  }

  factory Categoria.fromMap(Map<String, Object?> map) {
    return Categoria(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
    );
  }
}
class Tienda {
  final int? id;
  final String nombre;
  final String? direccion;
  final String? telefono;

  Tienda({
    this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
    }..removeWhere((key, value) => value == null);
  }

  factory Tienda.fromMap(Map<String, Object?> map) {
    return Tienda(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] as String?,
    );
  }
}
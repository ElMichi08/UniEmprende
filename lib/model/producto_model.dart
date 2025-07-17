class ProductoModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;
  final String emprendimientoId;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
    required this.emprendimientoId,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'imagen_url': imagenUrl,
    'emprendimiento_id': emprendimientoId,
  };

  factory ProductoModel.fromJson(Map<String, dynamic> json, String id) {
    return ProductoModel(
      id: id,
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagen_url'],
      emprendimientoId: json['emprendimiento_id'],
    );
  }
}

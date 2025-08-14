class ProductoModel {
  final String idProducto;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenBase64;
  final String idEmprendimiento;

  ProductoModel({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenBase64,
    required this.idEmprendimiento,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json, String id) {
    return ProductoModel(
      idProducto: id,
      nombre: (json['nombre'] ?? '') as String,
      descripcion: (json['descripcion'] ?? '') as String,
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      // ⬇️ fallback a 'imagen' y default '' para no romper
      imagenBase64: (json['imagenBase64'] ?? json['imagen'] ?? '') as String,
      idEmprendimiento: (json['id_emprendimiento'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'imagenBase64': imagenBase64,
    'id_emprendimiento': idEmprendimiento,
  };
}

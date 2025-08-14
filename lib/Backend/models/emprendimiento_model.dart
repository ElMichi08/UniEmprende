class EmprendimientoModel {
  final String idEmprendimiento;
  final String nombre;
  final String descripcion;
  final String ubicacion;
  final String logo;
  final String categoria;
  final String idUsuario;

  EmprendimientoModel({
    required this.idEmprendimiento,
    required this.nombre,
    required this.descripcion,
    required this.ubicacion,
    required this.logo,
    required this.categoria,
    required this.idUsuario,
  });

  factory EmprendimientoModel.fromJson(Map<String, dynamic> json, String id) {
    return EmprendimientoModel(
      idEmprendimiento: id,
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      ubicacion: json['ubicacion'],
      logo: json['logo'],
      categoria: json['categoria'],
      idUsuario: json['id_usuario'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'ubicacion': ubicacion,
    'logo': logo,
    'categoria': categoria,
    'id_usuario': idUsuario,
  };
}

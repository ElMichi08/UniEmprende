class EmprendimientoModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String sector;
  final String logoUrl;
  final String correoContacto;
  final String whatsapp;
  final String creadoPor;
  final DateTime fechaRegistro;

  EmprendimientoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.sector,
    required this.logoUrl,
    required this.correoContacto,
    required this.whatsapp,
    required this.creadoPor,
    required this.fechaRegistro,
  });

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'sector': sector,
    'logo_url': logoUrl,
    'correo_contacto': correoContacto,
    'whatsapp': whatsapp,
    'creado_por': creadoPor,
    'fecha_registro': fechaRegistro.toIso8601String(),
  };

  // Construir desde JSON de Firestore
  factory EmprendimientoModel.fromJson(Map<String, dynamic> json, String id) {
    return EmprendimientoModel(
      id: id,
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      sector: json['sector'],
      logoUrl: json['logo_url'],
      correoContacto: json['correo_contacto'],
      whatsapp: json['whatsapp'],
      creadoPor: json['creado_por'],
      fechaRegistro: DateTime.parse(json['fecha_registro']),
    );
  }
}

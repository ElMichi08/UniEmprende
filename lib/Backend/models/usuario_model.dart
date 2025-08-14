class UsuarioModel {
  final String idUsuario;
  final String nombre;
  final String apellido;
  final String correo;
  final String contrasena;
  final String tipoUsuario; // 'emprendedor' o 'consumidor'
  final String telefono;

  UsuarioModel({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.contrasena,
    required this.tipoUsuario,
    required this.telefono,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json, String id) {
    return UsuarioModel(
      idUsuario: id,
      nombre: json['nombre'],
      apellido: json['apellido'] ?? '',
      correo: json['correo'],
      contrasena: json['contrasena'],
      tipoUsuario: json['tipo_usuario'],
      telefono: json['telefono'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'apellido': apellido,
    'correo': correo,
    'contrasena': contrasena,
    'tipo_usuario': tipoUsuario,
    'telefono': telefono,
  };
}

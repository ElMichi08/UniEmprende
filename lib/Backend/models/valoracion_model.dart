class ValoracionModel {
  final String idValoracion;
  final String comentario;
  final int puntaje;
  final DateTime fecha;
  final String idEmprendimiento;
  final String autorCorreo;

  ValoracionModel({
    required this.idValoracion,
    required this.comentario,
    required this.puntaje,
    required this.fecha,
    required this.idEmprendimiento,
    required this.autorCorreo,
  });

  factory ValoracionModel.fromJson(Map<String, dynamic> json, String id) {
    return ValoracionModel(
      idValoracion: id,
      comentario: json['comentario'],
      puntaje: json['puntaje'],
      fecha: DateTime.parse(json['fecha']),
      idEmprendimiento: json['id_emprendimiento'],
      autorCorreo: json['autor_correo'],
    );
  }

  Map<String, dynamic> toJson() => {
    'comentario': comentario,
    'puntaje': puntaje,
    'fecha': fecha.toIso8601String(),
    'id_emprendimiento': idEmprendimiento,
    'autor_correo': autorCorreo,
  };
}

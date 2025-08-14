import 'package:flutter/material.dart';
import 'package:lata_emprende/Backend/controller/auth_controller.dart';
import 'package:lata_emprende/Backend/models/valoracion_model.dart';
import 'package:lata_emprende/Backend/services/firebase_auth_service.dart';

class ValoracionController {
  final FirestoreService _firestoreService = FirestoreService();

  /// Crear nueva valoración
  Future<void> crearValoracion({
    required BuildContext context,
    required String comentario,
    required int puntaje,
    required String idEmprendimiento,
  }) async {
    try {
      final usuario = AuthController.usuarioActual;
      if (usuario == null) {
        throw Exception('Debes iniciar sesión para valorar');
      }

      // Mostrar loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await _firestoreService.crearValoracion(
        comentario: comentario,
        puntaje: puntaje,
        idEmprendimiento: idEmprendimiento,
        autorCorreo: usuario.correo,
      );

      // Cerrar loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Valoración enviada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Cerrar formulario
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Obtener valoraciones de un emprendimiento
  Future<List<ValoracionModel>> obtenerValoraciones(
    String idEmprendimiento,
  ) async {
    try {
      return await _firestoreService.obtenerValoracionesPorEmprendimiento(
        idEmprendimiento,
      );
    } catch (e) {
      print('Error al obtener valoraciones: $e');
      return [];
    }
  }

  /// Obtener promedio de valoraciones
  Future<double> obtenerPromedio(String idEmprendimiento) async {
    try {
      return await _firestoreService.obtenerPromedioValoraciones(
        idEmprendimiento,
      );
    } catch (e) {
      return 0.0;
    }
  }
}

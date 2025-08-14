import 'package:flutter/material.dart';
import 'package:lata_emprende/Backend/models/usuario_model.dart';
import 'package:lata_emprende/Backend/services/firebase_auth_service.dart';

class AuthController {
  final FirestoreService _firestoreService = FirestoreService();

  // Variable estática para mantener el usuario actual
  static UsuarioModel? _usuarioActual;

  // Getter para obtener el usuario actual
  static UsuarioModel? get usuarioActual => _usuarioActual;

  Future<void> registrarUsuario({
    required BuildContext context,
    required String nombres,
    required String apellidos,
    required String correo,
    required String telefono,
    required String contrasena,
    required String tipoUsuario,
  }) async {
    try {
      print('AuthController: Iniciando registro...');

      // Validaciones básicas
      if (nombres.trim().isEmpty) {
        throw Exception('El nombre es obligatorio');
      }
      if (apellidos.trim().isEmpty) {
        throw Exception('Los apellidos son obligatorios');
      }
      if (correo.trim().isEmpty || !correo.contains('@')) {
        throw Exception('Ingrese un correo válido');
      }
      if (contrasena.length < 6) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      }

      // Mostrar indicador de carga
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Registrar SOLO en Firestore (sin Firebase Auth)
      final userId = await _firestoreService.registrarUsuario(
        nombre: nombres.trim(),
        apellido: apellidos.trim(),
        correo: correo.trim(),
        telefono: telefono.trim(),
        contrasena: contrasena,
        tipoUsuario: tipoUsuario,
      );

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (userId.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/');
      } else {
        throw Exception('No se pudo completar el registro');
      }
    } catch (e) {
      print('Error en AuthController.registrarUsuario: $e');

      // Cerrar indicador de carga si está abierto
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Iniciar sesión validando correo y contraseña
  Future<void> iniciarSesion({
    required BuildContext context,
    required String correo,
    required String contrasena,
  }) async {
    try {
      print('AuthController: Iniciando sesión...');

      if (correo.trim().isEmpty || !correo.contains('@')) {
        throw Exception('Ingrese un correo válido');
      }
      if (contrasena.isEmpty) {
        throw Exception('Ingrese su contraseña');
      }

      // Mostrar indicador de carga
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final usuario = await _firestoreService.validarLogin(
        correo.trim(),
        contrasena,
      );

      // Cerrar indicador de carga
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (usuario != null && context.mounted) {
        // Guardar el usuario actual
        _usuarioActual = usuario;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      print('Error en AuthController.iniciarSesion: $e');

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Obtener datos del usuario por ID
  Future<UsuarioModel?> obtenerUsuario(String id) async {
    try {
      return await _firestoreService.obtenerUsuarioPorId(id);
    } catch (e) {
      print('Error en AuthController.obtenerUsuario: $e');
      rethrow;
    }
  }

  /// Actualizar perfil de usuario
  Future<void> actualizarPerfilUsuario({
    required String id,
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    try {
      await _firestoreService.actualizarUsuario(
        id: id,
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
      );

      // Actualizar el usuario actual si es el mismo
      if (_usuarioActual != null && _usuarioActual!.idUsuario == id) {
        _usuarioActual = UsuarioModel(
          idUsuario: _usuarioActual!.idUsuario,
          nombre: nombre,
          apellido: apellido,
          correo: _usuarioActual!.correo,
          contrasena: _usuarioActual!.contrasena,
          tipoUsuario: _usuarioActual!.tipoUsuario,
          telefono: telefono,
        );
      }
    } catch (e) {
      print('Error en AuthController.actualizarPerfilUsuario: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  void cerrarSesion() {
    _usuarioActual = null;
  }
}

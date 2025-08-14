import 'package:flutter/material.dart';
import 'package:lata_emprende/Backend/models/emprendimiento_model.dart';
import 'package:lata_emprende/Backend/models/producto_model.dart';
import 'package:lata_emprende/Backend/services/firebase_auth_service.dart';
import 'package:lata_emprende/Backend/controller/auth_controller.dart';

class EmprendimientoController {
  final FirestoreService _firestoreService = FirestoreService();

  /// Crear emprendimiento
  Future<void> crearEmprendimiento({
    required BuildContext context,
    required String nombre,
    required String descripcion,
    required String ubicacion,
    required String categoria,
  }) async {
    try {
      final usuario = AuthController.usuarioActual;
      if (usuario == null) {
        throw Exception('No hay usuario logueado');
      }

      if (usuario.tipoUsuario != 'emprendedor') {
        throw Exception('Solo los emprendedores pueden crear emprendimientos');
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

      await _firestoreService.crearEmprendimiento(
        nombre: nombre,
        descripcion: descripcion,
        ubicacion: ubicacion,
        categoria: categoria,
        idUsuario: usuario.idUsuario,
      );

      // Cerrar loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Emprendimiento creado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Volver a la pantalla anterior
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

  /// Obtener emprendimiento del usuario actual
  Future<EmprendimientoModel?> obtenerMiEmprendimiento() async {
    try {
      final usuario = AuthController.usuarioActual;
      if (usuario == null) return null;

      return await _firestoreService.obtenerEmprendimientoPorUsuario(
        usuario.idUsuario,
      );
    } catch (e) {
      print('Error al obtener emprendimiento: $e');
      return null;
    }
  }

  /// Crear producto
  Future<void> crearProducto({
    required BuildContext context,
    required String nombre,
    required String descripcion,
    required double precio,
    required String idEmprendimiento,
    required String imagenBase64, // aquí recibes la imagen en base64
  }) async {
    try {
      // Mostrar loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await _firestoreService.crearProducto(
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        idEmprendimiento: idEmprendimiento,
        imagenBase64: imagenBase64, // ✅ lo envías al servicio
      );

      // Cerrar loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Producto agregado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Volver a la pantalla anterior
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

  /// Obtener productos del emprendimiento
  Future<List<ProductoModel>> obtenerMisProductos(
    String idEmprendimiento,
  ) async {
    try {
      return await _firestoreService.obtenerProductosPorEmprendimiento(
        idEmprendimiento,
      );
    } catch (e) {
      print('Error al obtener productos: $e');
      return [];
    }
  }

  /// Eliminar producto
  Future<void> eliminarProducto({
    required BuildContext context,
    required String idProducto,
  }) async {
    try {
      await _firestoreService.eliminarProducto(idProducto);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lata_emprende/Backend/models/emprendimiento_model.dart';
import 'package:lata_emprende/Backend/models/producto_model.dart';
import 'package:lata_emprende/Backend/models/usuario_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:lata_emprende/Backend/models/valoracion_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Encriptar contraseña usando SHA-256
  String _encryptPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Registrar usuario SOLO en Firestore (sin Firebase Auth)
  Future<String> registrarUsuario({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String contrasena,
    required String tipoUsuario,
  }) async {
    try {
      print('Iniciando registro de usuario en Firestore...');
      print('Correo: $correo');
      print('Teléfono: $telefono');
      print('Tipo de usuario: $tipoUsuario');

      // Verificar si el correo ya existe
      final existeUsuario = await _db
          .collection('usuarios')
          .where('correo', isEqualTo: correo)
          .get();

      if (existeUsuario.docs.isNotEmpty) {
        throw Exception('Este correo ya está registrado');
      }

      // Verificar si el teléfono ya existe
      if (telefono.isNotEmpty) {
        final existeTelefono = await _db
            .collection('usuarios')
            .where('telefono', isEqualTo: telefono)
            .get();

        if (existeTelefono.docs.isNotEmpty) {
          throw Exception('Este número de teléfono ya está registrado');
        }
      }

      // Encriptar la contraseña
      String contrasenaEncriptada = _encryptPassword(contrasena);

      // Crear datos del usuario
      final userData = {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono,
        'contrasena': contrasenaEncriptada,
        'tipo_usuario': tipoUsuario,
        'fecha_registro': DateTime.now().toIso8601String(),
      };

      print('Guardando datos en Firestore...');
      print('Datos: $userData');

      // Guardar en Firestore con ID automático
      final docRef = await _db.collection('usuarios').add(userData);

      print('Usuario registrado exitosamente con ID: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      print('FirebaseException: ${e.code} - ${e.message}');
      throw Exception('Error en Firebase: ${e.message}');
    } catch (e) {
      print('Error general al registrar usuario: $e');
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// Obtener usuario por ID
  Future<UsuarioModel?> obtenerUsuarioPorId(String id) async {
    try {
      final doc = await _db.collection('usuarios').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return UsuarioModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario: $e');
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  /// Obtener usuario por correo
  Future<UsuarioModel?> obtenerUsuarioPorCorreo(String correo) async {
    try {
      final query = await _db
          .collection('usuarios')
          .where('correo', isEqualTo: correo)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return UsuarioModel.fromJson(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario por correo: $e');
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Validar login (correo y contraseña)
  Future<UsuarioModel?> validarLogin(String correo, String contrasena) async {
    try {
      final usuario = await obtenerUsuarioPorCorreo(correo);

      if (usuario == null) {
        throw Exception('Usuario no encontrado');
      }

      // Verificar contraseña
      String contrasenaEncriptada = _encryptPassword(contrasena);
      if (usuario.contrasena != contrasenaEncriptada) {
        throw Exception('Contraseña incorrecta');
      }

      return usuario;
    } catch (e) {
      print('Error en validación de login: $e');
      rethrow;
    }
  }

  /// Actualizar usuario
  Future<void> actualizarUsuario({
    required String id,
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    try {
      await _db.collection('usuarios').doc(id).update({
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
      });
    } catch (e) {
      print('Error al actualizar usuario: $e');
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  // ====== MÉTODOS PARA EMPRENDIMIENTOS ======

  /// Crear emprendimiento
  Future<String> crearEmprendimiento({
    required String nombre,
    required String descripcion,
    required String ubicacion,
    required String categoria,
    required String idUsuario,
    String logo = '',
  }) async {
    try {
      final emprendimientoData = {
        'nombre': nombre,
        'descripcion': descripcion,
        'ubicacion': ubicacion,
        'logo': logo,
        'categoria': categoria,
        'id_usuario': idUsuario,
        'fecha_creacion': DateTime.now().toIso8601String(),
      };

      final docRef = await _db
          .collection('emprendimientos')
          .add(emprendimientoData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear emprendimiento: $e');
    }
  }

  /// Obtener emprendimiento por ID de usuario
  Future<EmprendimientoModel?> obtenerEmprendimientoPorUsuario(
    String idUsuario,
  ) async {
    try {
      final query = await _db
          .collection('emprendimientos')
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return EmprendimientoModel.fromJson(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener emprendimiento: $e');
    }
  }

  // ====== MÉTODOS PARA PRODUCTOS ======

  /// Crear producto
  Future<String> crearProducto({
    required String nombre,
    required String descripcion,
    required double precio,
    required String idEmprendimiento,
    required String imagenBase64, // ✅ obligatorio
  }) async {
    try {
      final productoData = {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'imagenBase64': imagenBase64, // ✅ guardas el Base64
        'id_emprendimiento': idEmprendimiento,
        'fecha_creacion': DateTime.now().toIso8601String(),
      };

      final docRef = await _db.collection('productos').add(productoData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  /// Obtener productos por emprendimiento
  Future<List<ProductoModel>> obtenerProductosPorEmprendimiento(
    String idEmprendimiento,
  ) async {
    try {
      final query = await _db
          .collection('productos')
          .where('id_emprendimiento', isEqualTo: idEmprendimiento)
          .get();

      return query.docs
          .map((doc) => ProductoModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  /// Eliminar producto
  Future<void> eliminarProducto(String idProducto) async {
    try {
      await _db.collection('productos').doc(idProducto).delete();
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  /// Obtener todos los productos (para vista home)
  Future<List<Map<String, dynamic>>> obtenerTodosLosProductos() async {
    try {
      // Obtener todos los productos
      final productosQuery = await _db.collection('productos').get();

      List<Map<String, dynamic>> productosConEmprendimiento = [];

      for (var productoDoc in productosQuery.docs) {
        final productoData = productoDoc.data();
        final producto = ProductoModel.fromJson(productoData, productoDoc.id);

        // Obtener datos del emprendimiento
        final emprendimientoDoc = await _db
            .collection('emprendimientos')
            .doc(producto.idEmprendimiento)
            .get();

        if (emprendimientoDoc.exists) {
          final emprendimiento = EmprendimientoModel.fromJson(
            emprendimientoDoc.data()!,
            emprendimientoDoc.id,
          );

          productosConEmprendimiento.add({
            'producto': producto,
            'emprendimiento': emprendimiento,
          });
        }
      }

      return productosConEmprendimiento;
    } catch (e) {
      print('Error al obtener todos los productos: $e');
      return [];
    }
  }

  /// Obtener teléfono del usuario emprendedor por ID de emprendimiento
  Future<String?> obtenerTelefonoEmprendedor(String idEmprendimiento) async {
    try {
      // Obtener el emprendimiento
      final emprendimientoDoc = await _db
          .collection('emprendimientos')
          .doc(idEmprendimiento)
          .get();

      if (emprendimientoDoc.exists) {
        final idUsuario = emprendimientoDoc.data()!['id_usuario'];

        // Obtener el usuario propietario
        final usuarioDoc = await _db
            .collection('usuarios')
            .doc(idUsuario)
            .get();

        if (usuarioDoc.exists) {
          return usuarioDoc.data()!['telefono'];
        }
      }
      return null;
    } catch (e) {
      print('Error al obtener teléfono del emprendedor: $e');
      return null;
    }
  }
  // ====== MÉTODOS PARA VALORACIONES ======

  /// Crear valoración
  Future<String> crearValoracion({
    required String comentario,
    required int puntaje,
    required String idEmprendimiento,
    required String autorCorreo,
  }) async {
    try {
      final valoracionData = {
        'comentario': comentario,
        'puntaje': puntaje,
        'fecha': DateTime.now().toIso8601String(),
        'id_emprendimiento': idEmprendimiento,
        'autor_correo': autorCorreo,
      };

      final docRef = await _db.collection('valoraciones').add(valoracionData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear valoración: $e');
    }
  }

  /// Obtener valoraciones por emprendimiento (SIN orderBy para evitar índices)
  Future<List<ValoracionModel>> obtenerValoracionesPorEmprendimiento(
    String idEmprendimiento,
  ) async {
    try {
      final query = await _db
          .collection('valoraciones')
          .where('id_emprendimiento', isEqualTo: idEmprendimiento)
          .get(); // Removemos el orderBy

      // Ordenamos en el cliente en lugar de en Firestore
      final valoraciones = query.docs
          .map((doc) => ValoracionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Ordenar por fecha (más recientes primero)
      valoraciones.sort((a, b) => b.fecha.compareTo(a.fecha));

      return valoraciones;
    } catch (e) {
      throw Exception('Error al obtener valoraciones: $e');
    }
  }

  /// Calcular promedio de valoraciones
  Future<double> obtenerPromedioValoraciones(String idEmprendimiento) async {
    try {
      final valoraciones = await obtenerValoracionesPorEmprendimiento(
        idEmprendimiento,
      );

      if (valoraciones.isEmpty) return 0.0;

      final suma = valoraciones.fold<int>(0, (sum, val) => sum + val.puntaje);
      return suma / valoraciones.length;
    } catch (e) {
      return 0.0;
    }
  }
}

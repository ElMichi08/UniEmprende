import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uni_emprende/backend/model/emprendimiento_model.dart';
import 'package:uni_emprende/backend/model/producto_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Servicios para Emprendimientos
  Future<String> crearEmprendimiento(EmprendimientoModel emprendimiento) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('emprendimientos')
          .add(emprendimiento.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear emprendimiento: $e');
    }
  }

  Future<EmprendimientoModel?> obtenerEmprendimientoPorUsuario(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('emprendimientos')
          .where('creado_por', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        return EmprendimientoModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener emprendimiento: $e');
    }
  }

  Future<List<EmprendimientoModel>> obtenerTodosLosEmprendimientos() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('emprendimientos')
          .orderBy('fecha_registro', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EmprendimientoModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener emprendimientos: $e');
    }
  }

  Future<void> actualizarEmprendimiento(String id, EmprendimientoModel emprendimiento) async {
    try {
      await _firestore
          .collection('emprendimientos')
          .doc(id)
          .update(emprendimiento.toJson());
    } catch (e) {
      throw Exception('Error al actualizar emprendimiento: $e');
    }
  }

  // Servicios para Productos
  Future<String> crearProducto(ProductoModel producto) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('productos')
          .add(producto.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  Future<List<ProductoModel>> obtenerProductos() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('productos')
          .orderBy('nombre')
          .get();

      return querySnapshot.docs
          .map((doc) => ProductoModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  Future<List<ProductoModel>> obtenerProductosPorEmprendimiento(String emprendimientoId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('productos')
          .where('emprendimiento_id', isEqualTo: emprendimientoId)
          .orderBy('nombre')
          .get();

      return querySnapshot.docs
          .map((doc) => ProductoModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos del emprendimiento: $e');
    }
  }

  Future<List<ProductoModel>> buscarProductos(String query) async {
    try {
      // Búsqueda por nombre (case insensitive)
      QuerySnapshot querySnapshot = await _firestore
          .collection('productos')
          .where('nombre', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('nombre', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => ProductoModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar productos: $e');
    }
  }

  Future<void> actualizarProducto(String id, ProductoModel producto) async {
    try {
      await _firestore
          .collection('productos')
          .doc(id)
          .update(producto.toJson());
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  Future<void> eliminarProducto(String id) async {
    try {
      await _firestore.collection('productos').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // Obtener usuario actual
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
}

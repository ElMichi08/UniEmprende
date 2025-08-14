import 'package:lata_emprende/Backend/models/emprendimiento_model.dart';
import 'package:lata_emprende/Backend/models/producto_model.dart';
import 'package:lata_emprende/Backend/services/firebase_auth_service.dart';
import 'package:lata_emprende/Backend/models/valoracion_model.dart';

class HomeController {
  final FirestoreService _firestoreService = FirestoreService();

  /// Obtener todos los productos con sus emprendimientos
  Future<List<Map<String, dynamic>>> obtenerTodosLosProductos() async {
    try {
      final productos = await _firestoreService.obtenerTodosLosProductos();

      // Filtrar productos válidos
      final productosValidos = productos.where((item) {
        final producto = item['producto'] as ProductoModel?;
        final emprendimiento = item['emprendimiento'] as EmprendimientoModel?;

        return producto != null &&
            emprendimiento != null &&
            producto.nombre.isNotEmpty &&
            emprendimiento.nombre.isNotEmpty;
      }).toList();

      return productosValidos;
    } catch (e) {
      print('Error en HomeController.obtenerTodosLosProductos: $e');
      rethrow; // Re-lanza el error para que HomeView lo maneje
    }
  }

  /// Buscar productos por nombre o descripción
  List<Map<String, dynamic>> buscarProductos(
    List<Map<String, dynamic>> productos,
    String busqueda,
  ) {
    if (busqueda.isEmpty) return productos;

    final busquedaLower = busqueda.toLowerCase();

    return productos.where((item) {
      final producto = item['producto'] as ProductoModel;
      final emprendimiento = item['emprendimiento'] as EmprendimientoModel;

      return producto.nombre.toLowerCase().contains(busquedaLower) ||
          producto.descripcion.toLowerCase().contains(busquedaLower) ||
          emprendimiento.nombre.toLowerCase().contains(busquedaLower);
    }).toList();
  }

  /// Filtrar productos por categoría
  List<Map<String, dynamic>> filtrarPorCategoria(
    List<Map<String, dynamic>> productos,
    String categoria,
  ) {
    if (categoria.isEmpty || categoria == 'todas') return productos;

    return productos.where((item) {
      final emprendimiento = item['emprendimiento'] as EmprendimientoModel;
      return emprendimiento.categoria.toLowerCase() == categoria.toLowerCase();
    }).toList();
  }

  /// Aplicar búsqueda y filtros combinados
  List<Map<String, dynamic>> aplicarFiltros(
    List<Map<String, dynamic>> productos,
    String busqueda,
    String categoria,
  ) {
    List<Map<String, dynamic>> resultado = productos;

    // Aplicar filtro de categoría primero
    resultado = filtrarPorCategoria(resultado, categoria);

    // Luego aplicar búsqueda
    resultado = buscarProductos(resultado, busqueda);

    return resultado;
  }

  /// Obtener teléfono del emprendedor
  Future<String?> obtenerTelefonoEmprendedor(String idEmprendimiento) async {
    try {
      return await _firestoreService.obtenerTelefonoEmprendedor(
        idEmprendimiento,
      );
    } catch (e) {
      print('Error en HomeController.obtenerTelefonoEmprendedor: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>>
  obtenerTodosLosProductosConValoraciones() async {
    try {
      final productos = await _firestoreService.obtenerTodosLosProductos();

      // Para cada producto, agregar información de valoraciones
      for (var item in productos) {
        final emprendimiento = item['emprendimiento'] as EmprendimientoModel;

        try {
          // Obtener valoraciones del emprendimiento
          final valoraciones = await _firestoreService
              .obtenerValoracionesPorEmprendimiento(
                emprendimiento.idEmprendimiento,
              );

          // Calcular promedio
          double promedio = 0.0;
          if (valoraciones.isNotEmpty) {
            final suma = valoraciones.fold<int>(
              0,
              (sum, val) => sum + val.puntaje,
            );
            promedio = suma / valoraciones.length;
          }

          // Agregar datos de valoración al item
          item['valoraciones'] = valoraciones;
          item['promedio_valoracion'] = promedio;
          item['total_valoraciones'] = valoraciones.length;
        } catch (e) {
          print(
            'Error al obtener valoraciones para ${emprendimiento.nombre}: $e',
          );
          // En caso de error, poner valores por defecto
          item['valoraciones'] = <ValoracionModel>[];
          item['promedio_valoracion'] = 0.0;
          item['total_valoraciones'] = 0;
        }
      }

      return productos;
    } catch (e) {
      print(
        'Error en HomeController.obtenerTodosLosProductosConValoraciones: $e',
      );
      rethrow;
    }
  }
}

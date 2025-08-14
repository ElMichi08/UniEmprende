import 'package:flutter/material.dart';
import 'package:lata_emprende/Backend/controller/auth_controller.dart';
import 'package:lata_emprende/Backend/controller/emprendimiento_controller.dart';
import 'package:lata_emprende/Backend/models/emprendimiento_model.dart';
import 'package:lata_emprende/Backend/models/producto_model.dart';
import 'package:lata_emprende/Frontend/view/crear_emprendimiento_view.dart';
import 'package:lata_emprende/Frontend/view/agregar_producto_view.dart';
import 'dart:convert';

class ProductosView extends StatefulWidget {
  const ProductosView({super.key});

  @override
  State<ProductosView> createState() => _ProductosViewState();
}

class _ProductosViewState extends State<ProductosView> {
  final EmprendimientoController _controller = EmprendimientoController();
  EmprendimientoModel? _emprendimiento;
  List<ProductoModel> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    try {
      // Verificar si es emprendedor
      final usuario = AuthController.usuarioActual;
      if (usuario?.tipoUsuario != 'emprendedor') {
        setState(() => _cargando = false);
        return;
      }

      // Obtener emprendimiento
      _emprendimiento = await _controller.obtenerMiEmprendimiento();

      // Si tiene emprendimiento, obtener productos
      if (_emprendimiento != null) {
        _productos = await _controller.obtenerMisProductos(
          _emprendimiento!.idEmprendimiento,
        );
      }
    } catch (e) {
      print('Error al cargar datos: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _confirmarEliminar(ProductoModel producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.eliminarProducto(
                context: context,
                idProducto: producto.idProducto,
              );
              _cargarDatos(); // Recargar lista
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthController.usuarioActual;

    if (usuario?.tipoUsuario != 'emprendedor') {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Solo los emprendedores pueden gestionar productos',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    // Si no tiene emprendimiento
    if (_emprendimiento == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'Aún no tienes un emprendimiento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Crea tu perfil de emprendimiento para comenzar a agregar productos',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrearEmprendimientoView(),
                    ),
                  );
                  _cargarDatos(); // Recargar después de crear
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Crear Emprendimiento',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si tiene emprendimiento
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del emprendimiento
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  const Icon(Icons.business, size: 40, color: Colors.redAccent),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _emprendimiento!.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _emprendimiento!.categoria.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Título y botón agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Productos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgregarProductoView(
                        idEmprendimiento: _emprendimiento!.idEmprendimiento,
                      ),
                    ),
                  );
                  _cargarDatos(); // Recargar después de agregar
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Agregar',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Lista de productos
          Expanded(
            child: _productos.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 60, color: Colors.grey),
                        SizedBox(height: 15),
                        Text(
                          'No tienes productos',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              0.81, // relación equilibrada imagen+texto
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final producto = _productos[index];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen con altura fija (no deformada)
                                SizedBox(
                                  height: 120,
                                  width: double.infinity,
                                  child: producto.imagenBase64.isNotEmpty
                                      ? Image.memory(
                                          base64Decode(producto.imagenBase64),
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),

                                // Contenido textual
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        producto.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${producto.precio.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Botón eliminar flotante
                            Positioned(
                              top: 5,
                              right: 5,
                              child: InkWell(
                                onTap: () => _confirmarEliminar(producto),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

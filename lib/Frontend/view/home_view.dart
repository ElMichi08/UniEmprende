import 'package:flutter/material.dart';
import 'package:lata_emprende/Backend/controller/home_controller.dart';
import 'package:lata_emprende/Backend/models/emprendimiento_model.dart';
import 'package:lata_emprende/Backend/models/producto_model.dart';
import 'package:lata_emprende/Backend/services/whatsapp_service.dart';
import 'package:lata_emprende/Backend/controller/valoracion_controller.dart';
import 'package:lata_emprende/Backend/models/valoracion_model.dart';
import 'package:lata_emprende/Frontend/view/agregar_valoracion_view.dart';
import 'dart:convert';
import 'dart:typed_data';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with AutomaticKeepAliveClientMixin {
  final HomeController _homeController = HomeController();
  final TextEditingController _busquedaController = TextEditingController();

  List<Map<String, dynamic>> _todosLosProductos = [];
  List<Map<String, dynamic>> _productosFiltrados = [];
  bool _cargando = true;
  String? _errorMessage;
  String _categoriaSeleccionada = 'todas';

  // Categorías disponibles
  final List<String> _categorias = [
    'todas',
    'comida',
    'ropa',
    'artesania',
    'tecnologia',
    'servicios',
    'otros',
  ];

  // Mantener el estado cuando cambia de pestañas
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargarProductosSafely();
    _busquedaController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductosSafely() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _errorMessage = null;
    });

    try {
      // Usar el nuevo método que incluye valoraciones
      final productos = await _homeController
          .obtenerTodosLosProductosConValoraciones();

      if (mounted) {
        setState(() {
          _todosLosProductos = productos;
          _productosFiltrados = productos;
          _cargando = false;
        });
      }
    } catch (e) {
      print('Error al cargar productos en HomeView: $e');

      if (mounted) {
        setState(() {
          _todosLosProductos = [];
          _productosFiltrados = [];
          _cargando = false;
          _errorMessage = 'Error al cargar productos. Toca para reintentar.';
        });
      }
    }
  }

  void _aplicarFiltros() {
    if (!mounted) return;

    setState(() {
      _productosFiltrados = _homeController.aplicarFiltros(
        _todosLosProductos,
        _busquedaController.text,
        _categoriaSeleccionada,
      );
    });
  }

  void _cambiarCategoria(String categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
    });
    _aplicarFiltros();
  }

  void _limpiarBusqueda() {
    _busquedaController.clear();
    setState(() {
      _categoriaSeleccionada = 'todas';
    });
    _aplicarFiltros();
  }

  void _mostrarDetalleProducto(
    ProductoModel producto,
    EmprendimientoModel emprendimiento,
  ) {
    if (!mounted) return;

    // Buscar las valoraciones precargadas
    final item = _productosFiltrados.firstWhere(
      (item) =>
          (item['producto'] as ProductoModel).idProducto == producto.idProducto,
      orElse: () => {},
    );

    final valoraciones = item['valoraciones'] as List<ValoracionModel>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del dialog
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        producto.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenido expandible
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen del producto
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: producto.imagenBase64.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(producto.imagenBase64),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : const Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Precio destacado
                      Center(
                        child: Text(
                          '\$${producto.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Descripción del producto
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        producto.descripcion.isNotEmpty
                            ? producto.descripcion
                            : 'Sin descripción disponible',
                        style: const TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 16),

                      // Info del emprendimiento
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Emprendimiento:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              emprendimiento.nombre,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Categoría: ${emprendimiento.categoria.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Ubicación: ${emprendimiento.ubicacion}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sección de valoraciones (usando valoraciones precargadas)
                      _buildSeccionValoracionesPrecargadas(valoraciones),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _contactarPorWhatsApp(
                            emprendimiento.idEmprendimiento,
                            emprendimiento.nombre,
                            producto.nombre,
                          );
                        },
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text(
                          'Contactar por WhatsApp',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarAgregarValoracion(emprendimiento);
                        },
                        icon: const Icon(
                          Icons.star_border,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Valorar Emprendimiento',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagenProducto(String base64String) {
    try {
      if (base64String.isEmpty) {
        return const Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        );
      }
      Uint8List bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 120, // fijo para que no se deforme
        ),
      );
    } catch (e) {
      print("Error al decodificar imagen: $e");
      return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _cargarProductosSafely,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Reintentar',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    final bool hayBusqueda =
        _busquedaController.text.isNotEmpty ||
        _categoriaSeleccionada != 'todas';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hayBusqueda ? Icons.search_off : Icons.inventory,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            hayBusqueda
                ? 'No se encontraron productos'
                : 'No hay productos disponibles',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            hayBusqueda
                ? 'Intenta con otros términos de búsqueda'
                : 'Los emprendedores pueden agregar productos desde la pestaña "Productos"',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (hayBusqueda)
            ElevatedButton.icon(
              onPressed: _limpiarBusqueda,
              icon: const Icon(Icons.clear, color: Colors.white),
              label: const Text(
                'Limpiar filtros',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _cargarProductosSafely,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Actualizar',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Column(
      children: [
        // Barra de búsqueda
        TextField(
          controller: _busquedaController,
          decoration: InputDecoration(
            hintText: 'Buscar productos o emprendimientos...',
            prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
            suffixIcon: _busquedaController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _busquedaController.clear(),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Filtros de categoría
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categorias.length,
            itemBuilder: (context, index) {
              final categoria = _categorias[index];
              final isSelected = categoria == _categoriaSeleccionada;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    categoria == 'todas' ? 'Todas' : categoria.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) => _cambiarCategoria(categoria),
                  selectedColor: Colors.redAccent,
                  checkmarkColor: Colors.white,
                  side: const BorderSide(color: Colors.redAccent),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin

    return RefreshIndicator(
      onRefresh: _cargarProductosSafely,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.storefront, size: 28, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  'Productos Disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Filtros de búsqueda
            _buildFiltros(),

            const SizedBox(height: 20),

            // Contador de resultados
            if (!_cargando && _errorMessage == null)
              Text(
                '${_productosFiltrados.length} producto(s) encontrado(s)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 10),

            // Contenido principal
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorWidget()
                  : _productosFiltrados.isEmpty
                  ? _buildEmptyWidget()
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio:
                                0.85, // Ajustar para dar más espacio
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _productosFiltrados.length,
                      itemBuilder: (context, index) {
                        try {
                          final item = _productosFiltrados[index];
                          final producto = item['producto'] as ProductoModel;
                          final emprendimiento =
                              item['emprendimiento'] as EmprendimientoModel;

                          // Obtener datos de valoración
                          final promedioValoracion =
                              item['promedio_valoracion'] as double? ?? 0.0;
                          final totalValoraciones =
                              item['total_valoraciones'] as int? ?? 0;

                          return GestureDetector(
                            onTap: () => _mostrarDetalleProducto(
                              producto,
                              emprendimiento,
                            ),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Imagen del producto
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                      ),
                                      child: _buildImagenProducto(
                                        producto.imagenBase64,
                                      ),
                                    ),
                                  ),

                                  // Info del producto
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Nombre del producto
                                          Text(
                                            producto.nombre.isNotEmpty
                                                ? producto.nombre
                                                : 'Sin nombre',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          const SizedBox(height: 2),

                                          // Precio
                                          Text(
                                            '\$${producto.precio.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // ⭐ NUEVO: Estrellas de valoración
                                          if (totalValoraciones > 0)
                                            Row(
                                              children: [
                                                ...List.generate(5, (
                                                  starIndex,
                                                ) {
                                                  return Icon(
                                                    Icons.star,
                                                    size: 12,
                                                    color:
                                                        starIndex <
                                                            promedioValoracion
                                                                .round()
                                                        ? Colors.amber
                                                        : Colors.grey.shade300,
                                                  );
                                                }),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '(${totalValoraciones})',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              'Sin valoraciones',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),

                                          const Spacer(),

                                          // Nombre del emprendimiento
                                          Text(
                                            emprendimiento.nombre.isNotEmpty
                                                ? emprendimiento.nombre
                                                : 'Sin nombre',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          // Categoría
                                          Text(
                                            emprendimiento.categoria
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          print(
                            'Error al renderizar producto en índice $index: $e',
                          );
                          return const Card(
                            child: Center(
                              child: Text(
                                'Error al cargar producto',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactarPorWhatsApp(
    String idEmprendimiento,
    String nombreEmprendimiento,
    String nombreProducto,
  ) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Obtener teléfono del emprendedor
      final telefono = await _homeController.obtenerTelefonoEmprendedor(
        idEmprendimiento,
      );

      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      if (telefono == null || telefono.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Este emprendimiento no tiene número de WhatsApp registrado.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // Contactar por WhatsApp
      await WhatsAppService.contactarEmprendedor(
        numeroTelefono: telefono,
        nombreEmprendimiento: nombreEmprendimiento,
        nombreProducto: nombreProducto,
        context: context,
      );
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al contactar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSeccionValoraciones(String idEmprendimiento) {
    return FutureBuilder<List<ValoracionModel>>(
      future: ValoracionController().obtenerValoraciones(idEmprendimiento),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final valoraciones = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Valoraciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (valoraciones.isNotEmpty)
                  _buildPromedioEstrellas(valoraciones),
              ],
            ),
            const SizedBox(height: 8),

            if (valoraciones.isEmpty)
              const Text(
                'Sin valoraciones aún',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              )
            else
              ...valoraciones
                  .take(3)
                  .map((valoracion) => _buildValoracionCard(valoracion)),

            if (valoraciones.length > 3)
              TextButton(
                onPressed: () => _mostrarTodasLasValoraciones(
                  idEmprendimiento,
                  valoraciones,
                ),
                child: Text('Ver todas (${valoraciones.length})'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPromedioEstrellas(List<ValoracionModel> valoraciones) {
    final promedio =
        valoraciones.fold<double>(0, (sum, val) => sum + val.puntaje) /
        valoraciones.length;

    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            Icons.star,
            size: 16,
            color: index < promedio.round()
                ? Colors.amber
                : Colors.grey.shade300,
          );
        }),
        const SizedBox(width: 4),
        Text(
          '${promedio.toStringAsFixed(1)} (${valoraciones.length})',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildValoracionCard(ValoracionModel valoracion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 14,
                    color: index < valoracion.puntaje
                        ? Colors.amber
                        : Colors.grey.shade300,
                  );
                }),
                const Spacer(),
                Text(
                  valoracion.autorCorreo,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              valoracion.comentario,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAgregarValoracion(EmprendimientoModel emprendimiento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarValoracionView(
          idEmprendimiento: emprendimiento.idEmprendimiento,
          nombreEmprendimiento: emprendimiento.nombre,
        ),
      ),
    );
  }

  void _mostrarTodasLasValoraciones(
    String idEmprendimiento,
    List<ValoracionModel> valoraciones,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Todas las Valoraciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: valoraciones.length,
                  itemBuilder: (context, index) {
                    return _buildValoracionCard(valoraciones[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Nuevo método para valoraciones precargadas
  Widget _buildSeccionValoracionesPrecargadas(
    List<ValoracionModel> valoraciones,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Valoraciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (valoraciones.isNotEmpty) _buildPromedioEstrellas(valoraciones),
          ],
        ),
        const SizedBox(height: 8),

        if (valoraciones.isEmpty)
          const Text(
            'Sin valoraciones aún',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          )
        else
          ...valoraciones
              .take(3)
              .map((valoracion) => _buildValoracionCard(valoracion)),

        if (valoraciones.length > 3)
          TextButton(
            onPressed: () =>
                _mostrarTodasLasValoracionesPrecargadas(valoraciones),
            child: Text('Ver todas (${valoraciones.length})'),
          ),
      ],
    );
  }

  // Actualizar el método de mostrar todas las valoraciones
  void _mostrarTodasLasValoracionesPrecargadas(
    List<ValoracionModel> valoraciones,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Todas las Valoraciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: valoraciones.length,
                  itemBuilder: (context, index) {
                    return _buildValoracionCard(valoraciones[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

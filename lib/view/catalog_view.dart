import 'package:flutter/material.dart';
import 'package:uni_emprende/view/add_product_view.dart';
import 'package:uni_emprende/view/create_business_profile_view.dart';
import 'package:uni_emprende/view/product_detail_view.dart';
import 'package:uni_emprende/view/admin_dashboard_view.dart';
import 'package:uni_emprende/backend/services/auth_service.dart';
import 'package:uni_emprende/backend/services/firestore_service.dart';
import 'package:uni_emprende/backend/services/admin_service.dart';
import 'package:uni_emprende/backend/model/producto_model.dart';
import 'package:uni_emprende/view/login_view.dart';
import 'package:uni_emprende/widgets/advanced_filters_widget.dart';
import 'package:uni_emprende/widgets/admin_guard.dart';
import 'package:uni_emprende/main.dart';

class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AdminService _adminService = AdminService();
  
  int _selectedIndex = 0;
  List<ProductoModel> _productos = [];
  List<ProductoModel> _productosFiltrados = [];
  List<String> _sectoresDisponibles = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  // Filtros
  String? _sectorSeleccionado;
  double? _precioMinimo;
  double? _precioMaximo;
  String? _ordenarPor;
  bool _descendente = false;
  bool _filtrosActivos = false;

  @override
  void initState() {
    super.initState();
    _verificarAdmin();
    _cargarDatos();
    _searchController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _verificarAdmin() async {
    try {
      final esAdmin = await _adminService.esAdministrador();
      setState(() {
        _isAdmin = esAdmin;
      });
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final productos = await _firestoreService.obtenerProductos();
      final sectores = await _firestoreService.obtenerSectoresUnicos();
      
      setState(() {
        _productos = productos;
        _productosFiltrados = productos;
        _sectoresDisponibles = sectores;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al cargar productos: $e', isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _aplicarFiltros() async {
    try {
      final nombreQuery = _searchController.text.trim();
      
      final productosFiltrados = await _firestoreService.filtrarProductos(
        nombreQuery: nombreQuery.isNotEmpty ? nombreQuery : null,
        sector: _sectorSeleccionado,
        precioMinimo: _precioMinimo,
        precioMaximo: _precioMaximo,
        ordenarPor: _ordenarPor,
        descendente: _descendente,
      );

      setState(() {
        _productosFiltrados = productosFiltrados;
        _filtrosActivos = _sectorSeleccionado != null ||
                         _precioMinimo != null ||
                         _precioMaximo != null ||
                         _ordenarPor != null ||
                         nombreQuery.isNotEmpty;
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al aplicar filtros: $e', isError: true);
      }
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _sectorSeleccionado = null;
      _precioMinimo = null;
      _precioMaximo = null;
      _ordenarPor = null;
      _descendente = false;
      _filtrosActivos = false;
    });
    _searchController.clear();
    _aplicarFiltros();
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al cerrar sesión: $e', isError: true);
      }
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Inicio
        // Ya estamos en el catálogo
        break;
      case 1: // Filtro
        _mostrarFiltrosAvanzados();
        break;
      case 2: // Agregar
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductView()),
        ).then((_) => _cargarDatos());
        break;
      case 3: // Perfil
        if (_isAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminGuard(
                child: const AdminDashboardView(),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateBusinessProfileView()),
          );
        }
        break;
    }
  }

  void _mostrarFiltrosAvanzados() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return AdvancedFiltersWidget(
              sectorSeleccionado: _sectorSeleccionado,
              precioMinimo: _precioMinimo,
              precioMaximo: _precioMaximo,
              ordenarPor: _ordenarPor,
              descendente: _descendente,
              sectoresDisponibles: _sectoresDisponibles,
              onSectorChanged: (sector) {
                setState(() {
                  _sectorSeleccionado = sector;
                });
              },
              onPrecioMinimoChanged: (precio) {
                setState(() {
                  _precioMinimo = precio;
                });
              },
              onPrecioMaximoChanged: (precio) {
                setState(() {
                  _precioMaximo = precio;
                });
              },
              onOrdenamientoChanged: (campo, desc) {
                setState(() {
                  _ordenarPor = campo;
                  _descendente = desc;
                });
              },
              onLimpiarFiltros: _limpiarFiltros,
              onAplicarFiltros: _aplicarFiltros,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/UniEmprendeLogo.jpg',
          height: 40,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar producto',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _mostrarFiltrosAvanzados,
                  icon: Icon(
                    Icons.tune,
                    color: _filtrosActivos ? const Color(0xFFE53935) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Indicador de filtros activos
          if (_filtrosActivos)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtros aplicados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _limpiarFiltros,
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),

          // Lista de productos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _productosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filtrosActivos
                                  ? 'No se encontraron productos con los filtros aplicados'
                                  : 'No hay productos disponibles',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_filtrosActivos) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _limpiarFiltros,
                                child: const Text('Limpiar filtros'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarDatos,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _productosFiltrados.length,
                          itemBuilder: (context, index) {
                            final producto = _productosFiltrados[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailView(
                                      producto: producto,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12.0),
                                          ),
                                        ),
                                        child: producto.imagenUrl.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(12.0),
                                                ),
                                                child: Image.network(
                                                  producto.imagenUrl,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Center(
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 60,
                                                        color: Colors.grey[400],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 60,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        producto.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      child: Text(
                                        '\$${producto.precio.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE53935),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.filter_list,
              color: _filtrosActivos ? const Color(0xFFE53935) : null,
            ),
            label: 'Filtro',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(_isAdmin ? Icons.admin_panel_settings : Icons.person),
            label: _isAdmin ? 'Admin' : 'Perfil',
          ),
        ],
      ),
    );
  }
}

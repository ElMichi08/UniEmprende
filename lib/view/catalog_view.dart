import 'package:flutter/material.dart';
import 'package:uni_emprende/view/add_product_view.dart';
import 'package:uni_emprende/view/create_business_profile_view.dart';
import 'package:uni_emprende/view/product_detail_view.dart';
import 'package:uni_emprende/backend/services/auth_service.dart';
import 'package:uni_emprende/backend/services/firestore_service.dart';
import 'package:uni_emprende/backend/model/producto_model.dart';
import 'package:uni_emprende/view/login_view.dart';
import 'package:uni_emprende/main.dart';

class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  int _selectedIndex = 0;
  List<ProductoModel> _productos = [];
  List<ProductoModel> _productosFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _searchController.addListener(_filtrarProductos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final productos = await _firestoreService.obtenerProductos();
      setState(() {
        _productos = productos;
        _productosFiltrados = productos;
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

  void _filtrarProductos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos.where((producto) {
          return producto.nombre.toLowerCase().contains(query) ||
                 producto.descripcion.toLowerCase().contains(query);
        }).toList();
      }
    });
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
        // Implementar lógica de filtro avanzado
        _mostrarFiltros();
        break;
      case 2: // Agregar
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductView()),
        ).then((_) => _cargarProductos()); // Recargar productos al volver
        break;
      case 3: // Perfil
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateBusinessProfileView()),
        );
        break;
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Ordenar por nombre'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _productosFiltrados.sort((a, b) => a.nombre.compareTo(b.nombre));
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Ordenar por precio (menor a mayor)'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _productosFiltrados.sort((a, b) => a.precio.compareTo(b.precio));
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.money_off),
                title: const Text('Ordenar por precio (mayor a menor)'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _productosFiltrados.sort((a, b) => b.precio.compareTo(a.precio));
                  });
                },
              ),
            ],
          ),
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
            onPressed: _cargarProductos,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                              _searchController.text.isNotEmpty
                                  ? 'No se encontraron productos'
                                  : 'No hay productos disponibles',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarProductos,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_list),
            label: 'Filtro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

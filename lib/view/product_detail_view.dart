import 'package:flutter/material.dart';
import 'package:uni_emprende/backend/model/producto_model.dart';
import 'package:uni_emprende/backend/services/firestore_service.dart';
import 'package:uni_emprende/backend/model/emprendimiento_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailView extends StatefulWidget {
  final ProductoModel producto;

  const ProductDetailView({
    super.key,
    required this.producto,
  });

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final FirestoreService _firestoreService = FirestoreService();
  EmprendimientoModel? _emprendimiento;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmprendimiento();
  }

  Future<void> _cargarEmprendimiento() async {
    try {
      // Buscar el emprendimiento por ID
      final emprendimientos = await _firestoreService.obtenerTodosLosEmprendimientos();
      final emprendimiento = emprendimientos.firstWhere(
        (e) => e.id == widget.producto.emprendimientoId,
        orElse: () => throw Exception('Emprendimiento no encontrado'),
      );
      
      setState(() {
        _emprendimiento = emprendimiento;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar información del emprendimiento: $e')),
        );
      }
    }
  }

  Future<void> _contactarVendedor() async {
    if (_emprendimiento == null) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contactar a ${_emprendimiento!.nombre}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_emprendimiento!.whatsapp.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('WhatsApp'),
                  subtitle: Text(_emprendimiento!.whatsapp),
                  onTap: () async {
                    final url = 'https://wa.me/${_emprendimiento!.whatsapp.replaceAll('+', '')}?text=Hola, estoy interesado en ${widget.producto.nombre}';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Correo electrónico'),
                subtitle: Text(_emprendimiento!.correoContacto),
                onTap: () async {
                  final url = 'mailto:${_emprendimiento!.correoContacto}?subject=Consulta sobre ${widget.producto.nombre}';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                  if (mounted) Navigator.pop(context);
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: widget.producto.imagenUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.network(
                                widget.producto.imagenUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 100,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.image,
                                size: 100,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.producto.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Precio \$${widget.producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  if (_emprendimiento != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Por: ${_emprendimiento!.nombre}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.producto.descripcion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _contactarVendedor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Contactar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE53935),
        unselectedItemColor: Colors.grey[600],
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
        onTap: (index) {
          Navigator.pop(context);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uni_emprende/backend/model/producto_model.dart';
import 'package:uni_emprende/backend/model/resena_model.dart';
import 'package:uni_emprende/backend/services/firestore_service.dart';
import 'package:uni_emprende/backend/model/emprendimiento_model.dart';
import 'package:uni_emprende/widgets/custom_bottom_navigation.dart';
import 'package:uni_emprende/view/rate_product_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_emprende/main.dart';

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
  List<ResenaModel> _resenas = [];
  double _calificacionPromedio = 0.0;
  bool _isLoading = true;
  bool _usuarioYaCalifico = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarEmprendimiento(),
      _cargarResenas(),
      _verificarSiUsuarioCalifico(),
    ]);
  }

  Future<void> _cargarEmprendimiento() async {
    try {
      final emprendimientos = await _firestoreService.obtenerTodosLosEmprendimientos();
      final emprendimiento = emprendimientos.firstWhere(
        (e) => e.id == widget.producto.emprendimientoId,
        orElse: () => throw Exception('Emprendimiento no encontrado'),
      );
      
      setState(() {
        _emprendimiento = emprendimiento;
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al cargar información del emprendimiento: $e', isError: true);
      }
    }
  }

  Future<void> _cargarResenas() async {
    try {
      final resenas = await _firestoreService.obtenerResenasPorProducto(widget.producto.id);
      final promedio = await _firestoreService.obtenerCalificacionPromedio(widget.producto.id);
      
      setState(() {
        _resenas = resenas;
        _calificacionPromedio = promedio;
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al cargar reseñas: $e', isError: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verificarSiUsuarioCalifico() async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId != null) {
        final yaCalifico = await _firestoreService.usuarioYaCalificoProducto(
          widget.producto.id,
          userId,
        );
        setState(() {
          _usuarioYaCalifico = yaCalifico;
        });
      }
    } catch (e) {
      // Error silencioso, no es crítico
    }
  }

  Future<void> _contactarVendedor() async {
    if (_emprendimiento == null) {
      context.showSnackBar('No se pudo obtener la información del vendedor.', isError: true);
      return;
    }

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
                    } else {
                      if (mounted) context.showSnackBar('No se pudo abrir WhatsApp.', isError: true);
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
                  } else {
                    if (mounted) context.showSnackBar('No se pudo abrir el cliente de correo.', isError: true);
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

  Future<void> _irACalificar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateProductView(producto: widget.producto),
      ),
    );

    if (result == true) {
      // Se agregó una nueva reseña, recargar datos
      _cargarResenas();
      _verificarSiUsuarioCalifico();
    }
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : 
          (index < rating ? Icons.star_half : Icons.star_border),
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildResenaItem(ResenaModel resena) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    resena.usuarioEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildStarRating(resena.calificacion.toDouble()),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              resena.comentario,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${resena.fechaCreacion.day}/${resena.fechaCreacion.month}/${resena.fechaCreacion.year}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del producto
                  Container(
                    width: double.infinity,
                    height: 250,
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
                  const SizedBox(height: 20),
                  
                  // Nombre del producto
                  Text(
                    widget.producto.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Precio
                  Text(
                    'Precio \$${widget.producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  
                  // Información del emprendimiento
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
                  
                  // Calificación promedio
                  if (_resenas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStarRating(_calificacionPromedio),
                        const SizedBox(width: 8),
                        Text(
                          '${_calificacionPromedio.toStringAsFixed(1)} (${_resenas.length} reseñas)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.producto.descripcion,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Botón Contactar
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
                  
                  const SizedBox(height: 16),
                  
                  // Botón Calificar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _usuarioYaCalifico ? null : _irACalificar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _usuarioYaCalifico ? Colors.grey : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        _usuarioYaCalifico ? 'Ya calificaste este producto' : 'Calificar',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  
                  // Reseñas
                  if (_resenas.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      'Reseñas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_resenas.map((resena) => _buildResenaItem(resena)).toList()),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uni_emprende/backend/services/firestore_service.dart';
import 'package:uni_emprende/backend/services/storage_service.dart';
import 'package:uni_emprende/backend/model/emprendimiento_model.dart';
import 'package:uni_emprende/backend/model/producto_model.dart';
import 'package:uni_emprende/main.dart';

class AddProductView extends StatefulWidget {
  const AddProductView({super.key});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  
  XFile? _selectedImage;
  bool _isLoading = false;
  EmprendimientoModel? _emprendimiento;

  @override
  void initState() {
    super.initState();
    _cargarEmprendimiento();
  }

  Future<void> _cargarEmprendimiento() async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId != null) {
        final emprendimiento = await _firestoreService.obtenerEmprendimientoPorUsuario(userId);
        setState(() {
          _emprendimiento = emprendimiento;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al cargar emprendimiento: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _storageService.seleccionarImagen(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        _selectedImage = image;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Cámara'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _storageService.seleccionarImagen(source: ImageSource.camera);
                    if (image != null) {
                      setState(() {
                        _selectedImage = image;
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al seleccionar imagen: $e', isError: true);
      }
    }
  }

  Future<void> _handleSaveProduct() async {
    if (_emprendimiento == null) {
      context.showSnackBar('Primero debes crear un perfil de emprendimiento', isError: true);
      return;
    }

    if (_productNameController.text.trim().isEmpty ||
        _productDescriptionController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      context.showSnackBar('Por favor, completa todos los campos', isError: true);
      return;
    }

    final precio = double.tryParse(_priceController.text.trim());
    if (precio == null || precio <= 0) {
      context.showSnackBar('Por favor, ingresa un precio válido', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imagenUrl = '';
      
      // Si hay una imagen seleccionada, subirla
      if (_selectedImage != null) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        imagenUrl = await _storageService.subirImagenProducto(_selectedImage!, tempId);
      }

      final producto = ProductoModel(
        id: '',
        nombre: _productNameController.text.trim(),
        descripcion: _productDescriptionController.text.trim(),
        precio: precio,
        imagenUrl: imagenUrl,
        emprendimientoId: _emprendimiento!.id,
      );

      await _firestoreService.crearProducto(producto);
      
      if (mounted) {
        context.showSnackBar('Producto guardado exitosamente');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al guardar producto: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar Producto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Subir Imagen del Producto',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Nombre del Producto *',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Descripción del Producto *',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Precio *',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixText: '\$ ',
              ),
            ),
            if (_emprendimiento != null) ...[
              const SizedBox(height: 20),
              Text(
                'Emprendimiento: ${_emprendimiento!.nombre}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSaveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar Producto',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uni_emprende/backend/services/auth_service.dart';
import 'package:uni_emprende/backend/services/firestore_service.dart';
import 'package:uni_emprende/backend/services/storage_service.dart';
import 'package:uni_emprende/backend/model/emprendimiento_model.dart';
import 'package:uni_emprende/view/login_view.dart';
import 'package:uni_emprende/main.dart';
import 'package:uni_emprende/widgets/image_upload_widget.dart';

class CreateBusinessProfileView extends StatefulWidget {
  const CreateBusinessProfileView({super.key});

  @override
  State<CreateBusinessProfileView> createState() => _CreateBusinessProfileViewState();
}

class _CreateBusinessProfileViewState extends State<CreateBusinessProfileView> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController = TextEditingController();
  final TextEditingController _sectorController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  
  String _logoUrl = '';
  bool _isLoading = false;
  EmprendimientoModel? _existingEmprendimiento;

  @override
  void initState() {
    super.initState();
    _cargarEmprendimientoExistente();
  }

  Future<void> _cargarEmprendimientoExistente() async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId != null) {
        final emprendimiento = await _firestoreService.obtenerEmprendimientoPorUsuario(userId);
        if (emprendimiento != null) {
          setState(() {
            _existingEmprendimiento = emprendimiento;
            _businessNameController.text = emprendimiento.nombre;
            _businessDescriptionController.text = emprendimiento.descripcion;
            _sectorController.text = emprendimiento.sector;
            _whatsappController.text = emprendimiento.whatsapp;
            _logoUrl = emprendimiento.logoUrl;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al cargar datos: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _sectorController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_businessNameController.text.trim().isEmpty ||
        _businessDescriptionController.text.trim().isEmpty ||
        _sectorController.text.trim().isEmpty) {
      context.showSnackBar('Por favor, completa todos los campos obligatorios', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _firestoreService.currentUserId;
      final userEmail = _firestoreService.currentUserEmail;
      
      if (userId == null || userEmail == null) {
        throw Exception('Usuario no autenticado');
      }

      String logoUrl = _logoUrl.isNotEmpty ? _logoUrl : (_existingEmprendimiento?.logoUrl ?? '');
      
      final emprendimiento = EmprendimientoModel(
        id: _existingEmprendimiento?.id ?? '',
        nombre: _businessNameController.text.trim(),
        descripcion: _businessDescriptionController.text.trim(),
        sector: _sectorController.text.trim(),
        logoUrl: logoUrl,
        correoContacto: userEmail,
        whatsapp: _whatsappController.text.trim(),
        creadoPor: userId,
        fechaRegistro: _existingEmprendimiento?.fechaRegistro ?? DateTime.now(),
      );

      if (_existingEmprendimiento != null) {
        // Actualizar emprendimiento existente
        await _firestoreService.actualizarEmprendimiento(_existingEmprendimiento!.id, emprendimiento);
        if (mounted) {
          context.showSnackBar('Perfil actualizado exitosamente');
        }
      } else {
        // Crear nuevo emprendimiento
        await _firestoreService.crearEmprendimiento(emprendimiento);
        if (mounted) {
          context.showSnackBar('Perfil creado exitosamente');
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al guardar perfil: $e', isError: true);
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
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _existingEmprendimiento != null 
                  ? 'Editar perfil de emprendimiento'
                  : 'Crear perfil de emprendimiento',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ImageUploadWidget(
                initialImageUrl: _existingEmprendimiento?.logoUrl,
                onImageUploaded: (url) {
                  _logoUrl = url;
                },
                uploadPath: 'emprendimientos',
                buttonText: 'Agregar Logo del Emprendimiento',
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Nombre del Negocio *',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _businessNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Descripción del Negocio *',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _businessDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sector *',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sectorController,
              decoration: InputDecoration(
                hintText: 'Ej: Tecnología, Alimentación, Textil, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'WhatsApp',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Ej: +593987654321',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSaveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _existingEmprendimiento != null ? 'Actualizar Perfil' : 'Guardar Perfil',
                        style: const TextStyle(fontSize: 18),
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

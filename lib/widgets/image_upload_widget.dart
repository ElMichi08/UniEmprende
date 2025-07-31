import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uni_emprende/backend/services/storage_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String) onImageUploaded;
  final String uploadPath;
  final String buttonText;

  const ImageUploadWidget({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
    required this.uploadPath,
    this.buttonText = 'Seleccionar Imagen',
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final StorageService _storageService = StorageService();
  XFile? _selectedImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _uploadedImageUrl = widget.initialImageUrl;
  }

  Future<void> _seleccionarYSubirImagen() async {
    try {
      // Primero verificar la configuración
      final isConfigured = await _storageService.verificarConfiguracion();
      if (!isConfigured) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firebase Storage no está configurado correctamente. Verifica las reglas de seguridad.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Seleccionar imagen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _procesarSeleccionImagen(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Cámara'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _procesarSeleccionImagen(ImageSource.camera);
                  },
                ),
                if (_uploadedImageUrl != null || _selectedImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Eliminar imagen'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _uploadedImageUrl = null;
                      });
                      widget.onImageUploaded('');
                    },
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _procesarSeleccionImagen(ImageSource source) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final image = await _storageService.seleccionarImagen(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        // Subir imagen inmediatamente
        final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
        final imageUrl = await _storageService.subirImagen(
          image,
          widget.uploadPath,
          uniqueId,
        );

        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploading = false;
        });

        widget.onImageUploaded(imageUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen subida exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _seleccionarYSubirImagen,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _isUploading ? Colors.grey[300] : const Color(0xFF00BCD4),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _isUploading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Subiendo...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : _uploadedImageUrl?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          _uploadedImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                widget.buttonText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.buttonText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
      ),
    );
  }
}

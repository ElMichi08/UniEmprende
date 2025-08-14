import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lata_emprende/Backend/controller/emprendimiento_controller.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class AgregarProductoView extends StatefulWidget {
  final String idEmprendimiento;

  const AgregarProductoView({super.key, required this.idEmprendimiento});

  @override
  State<AgregarProductoView> createState() => _AgregarProductoViewState();
}

class _AgregarProductoViewState extends State<AgregarProductoView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  File? _imagenProducto;
  String? _imagenBase64;
  bool _procesandoImagen = false;

  /// Método principal de compresión - CORREGIDO
  Future<String> comprimirImagen(File archivo) async {
    setState(() => _procesandoImagen = true);

    try {
      // ✅ CAMBIO: Usar XFile para leer bytes
      XFile xFile = XFile(archivo.path);
      Uint8List bytes = await xFile.readAsBytes();
      int tamanoOriginal = bytes.length;

      print('Tamaño original: ${(tamanoOriginal / 1024).toStringAsFixed(2)}KB');

      // Si la imagen ya es pequeña, convertir directamente
      if (tamanoOriginal <= 500 * 1024) {
        String base64String = base64Encode(bytes);
        print('Imagen ya es pequeña, usando original');
        return base64String;
      }

      // Intentar compresión con flutter_image_compress
      try {
        String? comprimidaConPlugin = await _comprimirConPlugin(archivo);
        if (comprimidaConPlugin != null) {
          return comprimidaConPlugin;
        }
      } catch (e) {
        print('Plugin falló: $e');
      }

      // Fallback: compresión manual con bytes ya leídos
      return await _comprimirManualConBytes(bytes);
    } catch (e) {
      print('Error general en compresión: $e');
      // Último fallback: usar bytes directamente
      return await _fallbackBasicoConBytes(archivo);
    }
  }

  /// Intenta compresión con flutter_image_compress
  Future<String?> _comprimirConPlugin(File archivo) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        archivo.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (result != null && result.length <= 700 * 1024) {
        String base64String = base64Encode(result);
        print(
          'Compresión exitosa con plugin: ${(result.length / 1024).toStringAsFixed(2)}KB',
        );
        return base64String;
      }
      return null;
    } catch (e) {
      print('Error con flutter_image_compress: $e');
      return null;
    }
  }

  /// Nueva función que trabaja directamente con bytes - CORREGIDO
  Future<String> _comprimirManualConBytes(Uint8List bytes) async {
    try {
      // Decodificar la imagen
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Redimensionar progresivamente
      img.Image imagenRedimensionada = image;

      // Primera pasada: redimensionar si es muy grande
      if (image.width > 1024 || image.height > 1024) {
        int newWidth = image.width > image.height
            ? 1024
            : (1024 * image.width / image.height).round();
        int newHeight = image.height > image.width
            ? 1024
            : (1024 * image.height / image.width).round();

        imagenRedimensionada = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Comprimir con diferentes calidades hasta conseguir tamaño objetivo
      List<int> calidades = [85, 75, 65, 55, 45, 35, 25];
      int maxSizeInBytes = 600 * 1024; // 600KB objetivo

      for (int calidad in calidades) {
        Uint8List imagenComprimida = Uint8List.fromList(
          img.encodeJpg(imagenRedimensionada, quality: calidad),
        );

        print(
          'Probando calidad $calidad: ${(imagenComprimida.length / 1024).toStringAsFixed(2)}KB',
        );

        if (imagenComprimida.length <= maxSizeInBytes) {
          String base64String = base64Encode(imagenComprimida);
          int tamanoOriginal = bytes.length;
          double reduccion =
              ((1 - imagenComprimida.length / tamanoOriginal) * 100);

          print('Compresión manual exitosa:');
          print(
            '- Tamaño final: ${(imagenComprimida.length / 1024).toStringAsFixed(2)}KB',
          );
          print('- Reducción: ${reduccion.toStringAsFixed(1)}%');
          print('- Calidad usada: $calidad');

          return base64String;
        }
      }

      // Si aún es muy grande, redimensionar más agresivamente
      imagenRedimensionada = img.copyResize(
        imagenRedimensionada,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.linear,
      );

      Uint8List imagenFinal = Uint8List.fromList(
        img.encodeJpg(imagenRedimensionada, quality: 60),
      );

      String base64String = base64Encode(imagenFinal);
      print(
        'Compresión agresiva: ${(imagenFinal.length / 1024).toStringAsFixed(2)}KB',
      );

      return base64String;
    } catch (e) {
      print('Error en compresión manual con bytes: $e');
      rethrow;
    }
  }

  /// Fallback mejorado que usa XFile - CORREGIDO
  Future<String> _fallbackBasicoConBytes(File archivo) async {
    try {
      // ✅ CAMBIO: Usar XFile en lugar de File.readAsBytes()
      XFile xFile = XFile(archivo.path);
      Uint8List bytes = await xFile.readAsBytes();

      // Si es muy grande, reducir tomando una muestra
      if (bytes.length > 1024 * 1024) {
        // Intentar decodificar y redimensionar básicamente
        try {
          img.Image? image = img.decodeImage(bytes);
          if (image != null) {
            // Redimensionar a 512x512 máximo
            img.Image resized = img.copyResize(
              image,
              width: 512,
              height: 512,
              interpolation: img.Interpolation.linear,
            );

            Uint8List comprimida = Uint8List.fromList(
              img.encodeJpg(resized, quality: 50),
            );

            String base64String = base64Encode(comprimida);
            print(
              'Fallback con redimensionado: ${(comprimida.length / 1024).toStringAsFixed(2)}KB',
            );
            return base64String;
          }
        } catch (e) {
          print('Error en redimensionado de fallback: $e');
        }

        // Si el redimensionado falla, tomar muestra de bytes
        int step = (bytes.length / (800 * 1024)).ceil();
        List<int> reducidos = [];
        for (int i = 0; i < bytes.length; i += step) {
          reducidos.add(bytes[i]);
          if (reducidos.length >= 800 * 1024) break; // Límite de seguridad
        }
        bytes = Uint8List.fromList(reducidos);
      }

      String base64String = base64Encode(bytes);
      print(
        'Fallback básico con XFile: ${(bytes.length / 1024).toStringAsFixed(2)}KB',
      );

      return base64String;
    } catch (e) {
      print('Error en fallback básico con XFile: $e');

      // Último recurso: crear una imagen placeholder pequeña
      try {
        // Crear una imagen sólida pequeña de 100x100
        img.Image placeholder = img.Image(width: 100, height: 100);
        img.fill(
          placeholder,
          color: img.ColorRgb8(200, 200, 200),
        ); // Gris claro

        Uint8List placeholderBytes = Uint8List.fromList(
          img.encodeJpg(placeholder, quality: 80),
        );

        String base64String = base64Encode(placeholderBytes);
        print(
          'Usando imagen placeholder: ${(placeholderBytes.length / 1024).toStringAsFixed(2)}KB',
        );

        // Mostrar advertencia al usuario
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Se usó imagen por defecto debido a problemas técnicos',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        return base64String;
      } catch (e2) {
        print('Error crítico en fallback: $e2');
        throw Exception('No se pudo procesar la imagen: $e2');
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();

    // Mostrar opciones
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Mostrar indicador de carga
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Procesando imagen...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }

        // Comprimir imagen
        final imagenComprimida = await comprimirImagen(file);

        setState(() {
          _imagenProducto = file;
          _imagenBase64 = imagenComprimida;
          _procesandoImagen = false;
        });

        // Mostrar resultado
        final sizeInKB = (_imagenBase64!.length * 3 / 4 / 1024).toStringAsFixed(
          2,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Imagen procesada: ${sizeInKB}KB'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _procesandoImagen = false);

      print('Error completo al procesar imagen: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al procesar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _seleccionarImagen,
            ),
          ),
        );
      }
    }
  }

  void _eliminarImagen() {
    setState(() {
      _imagenProducto = null;
      _imagenBase64 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Contenedor de imagen mejorado
              Stack(
                children: [
                  GestureDetector(
                    onTap: _procesandoImagen ? null : _seleccionarImagen,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _imagenBase64 != null
                              ? Colors.green.withOpacity(0.5)
                              : Colors.redAccent.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _procesandoImagen
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Procesando imagen...',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : _imagenBase64 != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(
                                    base64Decode(_imagenBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                            Text('Error al cargar imagen'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Toca para agregar imagen',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'JPG, PNG • Máx. 1MB',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Botón eliminar
                  if (_imagenBase64 != null && !_procesandoImagen)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _eliminarImagen,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                  // Badge de estado
                  if (_imagenBase64 != null && !_procesandoImagen)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Imagen lista',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del producto';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el precio';
                  }
                  final precio = double.tryParse(value);
                  if (precio == null || precio <= 0) {
                    return 'Ingresa un precio válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _procesandoImagen
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            if (_imagenBase64 == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor, agrega una imagen del producto',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final precio = double.parse(_precioController.text);
                            final controller = EmprendimientoController();
                            controller.crearProducto(
                              context: context,
                              nombre: _nombreController.text.trim(),
                              descripcion: _descripcionController.text.trim(),
                              precio: precio,
                              idEmprendimiento: widget.idEmprendimiento,
                              imagenBase64: _imagenBase64!,
                            );
                          }
                        },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Guardar Producto',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }
}

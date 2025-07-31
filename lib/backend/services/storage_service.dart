import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<XFile?> seleccionarImagen({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      throw Exception('Error al seleccionar imagen: $e');
    }
  }

  Future<String> subirImagen(XFile imageFile, String carpeta, String nombreArchivo) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      File file = File(imageFile.path);
      
      // Verificar que el archivo existe
      if (!await file.exists()) {
        throw Exception('El archivo de imagen no existe');
      }

      // Crear un nombre único para evitar conflictos
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final uniqueFileName = '${user.uid}_${timestamp}_$nombreArchivo.$extension';
      
      // Crear referencia al archivo en Firebase Storage
      Reference ref = _storage.ref().child('$carpeta/$uniqueFileName');
      
      // Configurar metadata
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/$extension',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Subir archivo con metadata
      UploadTask uploadTask = ref.putFile(file, metadata);
      
      // Monitorear el progreso (opcional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Progreso: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });
      
      // Esperar a que termine la subida
      TaskSnapshot snapshot = await uploadTask;
      
      // Obtener URL de descarga
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Imagen subida exitosamente: $downloadUrl');
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      print('Firebase Error: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'storage/unauthorized':
          throw Exception('No tienes permisos para subir imágenes. Verifica las reglas de Firebase Storage.');
        case 'storage/canceled':
          throw Exception('La subida fue cancelada.');
        case 'storage/unknown':
          throw Exception('Error desconocido al subir la imagen.');
        case 'storage/object-not-found':
          throw Exception('No se pudo encontrar el objeto en el almacenamiento.');
        case 'storage/bucket-not-found':
          throw Exception('El bucket de almacenamiento no existe.');
        case 'storage/project-not-found':
          throw Exception('El proyecto de Firebase no existe.');
        case 'storage/quota-exceeded':
          throw Exception('Se ha excedido la cuota de almacenamiento.');
        case 'storage/unauthenticated':
          throw Exception('Usuario no autenticado para esta operación.');
        case 'storage/retry-limit-exceeded':
          throw Exception('Se ha excedido el límite de reintentos.');
        default:
          throw Exception('Error de Firebase Storage: ${e.message}');
      }
    } catch (e) {
      print('Error general: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  Future<String> subirImagenEmprendimiento(XFile imageFile, String emprendimientoId) async {
    return await subirImagen(imageFile, 'emprendimientos', 'logo_$emprendimientoId');
  }

  Future<String> subirImagenProducto(XFile imageFile, String productoId) async {
    return await subirImagen(imageFile, 'productos', 'producto_$productoId');
  }

  Future<void> eliminarImagen(String url) async {
    try {
      if (url.isEmpty) return;
      
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
      print('Imagen eliminada exitosamente: $url');
    } on FirebaseException catch (e) {
      print('Error al eliminar imagen: ${e.code} - ${e.message}');
      // No lanzamos excepción aquí porque la eliminación de imagen no es crítica
    } catch (e) {
      print('Error general al eliminar imagen: $e');
    }
  }

  // Método para verificar si Firebase Storage está configurado correctamente
  Future<bool> verificarConfiguracion() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Intentar crear una referencia de prueba
      Reference testRef = _storage.ref().child('test/configuracion.txt');
      
      // Intentar subir un archivo de prueba pequeño
      final testData = 'test configuration';
      await testRef.putString(testData);
      
      // Intentar obtener la URL
      await testRef.getDownloadURL();
      
      // Limpiar el archivo de prueba
      await testRef.delete();
      
      return true;
    } catch (e) {
      print('Error en verificación de configuración: $e');
      return false;
    }
  }
}

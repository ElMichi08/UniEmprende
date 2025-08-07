import 'package:flutter/material.dart';
import 'package:uni_emprende/backend/model/producto_model.dart';
import 'package:uni_emprende/backend/model/resena_model.dart';
import 'package:uni_emprende/backend/services/firestore_service.dart';
import 'package:uni_emprende/main.dart';

class RateProductView extends StatefulWidget {
  final ProductoModel producto;

  const RateProductView({
    super.key,
    required this.producto,
  });

  @override
  State<RateProductView> createState() => _RateProductViewState();
}

class _RateProductViewState extends State<RateProductView> {
  final TextEditingController _comentarioController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  int _calificacion = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarResena() async {
    if (_calificacion == 0) {
      context.showSnackBar('Por favor, selecciona una calificación', isError: true);
      return;
    }

    if (_comentarioController.text.trim().isEmpty) {
      context.showSnackBar('Por favor, escribe un comentario', isError: true);
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

      // Verificar si el usuario ya calificó este producto
      final yaCalifico = await _firestoreService.usuarioYaCalificoProducto(
        widget.producto.id,
        userId,
      );

      if (yaCalifico) {
        if (mounted) {
          context.showSnackBar('Ya has calificado este producto', isError: true);
        }
        return;
      }

      final resena = ResenaModel(
        id: '',
        productoId: widget.producto.id,
        usuarioId: userId,
        usuarioEmail: userEmail,
        comentario: _comentarioController.text.trim(),
        calificacion: _calificacion,
        fechaCreacion: DateTime.now(),
      );

      await _firestoreService.crearResena(resena);

      if (mounted) {
        context.showSnackBar('Reseña enviada exitosamente');
        Navigator.pop(context, true); // Retornar true para indicar que se agregó una reseña
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al enviar reseña: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _calificacion = index + 1;
            });
          },
          child: Icon(
            index < _calificacion ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 40,
          ),
        );
      }),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calificar Producto',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.producto.nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Tu calificación:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            _buildStarRating(),
            const SizedBox(height: 30),
            const Text(
              'Comentarios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _comentarioController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Escribe aquí tu mensaje',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFFE53935)),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.all(16.0),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enviarResena,
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
                        'Publicar',
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

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lata_emprende/Backend/controller/emprendimiento_controller.dart';

class CrearEmprendimientoView extends StatefulWidget {
  const CrearEmprendimientoView({super.key});

  @override
  State<CrearEmprendimientoView> createState() =>
      _CrearEmprendimientoViewState();
}

class _CrearEmprendimientoViewState extends State<CrearEmprendimientoView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  String _categoriaSeleccionada = 'comida';

  final List<String> _categorias = [
    'comida',
    'ropa',
    'artesania',
    'tecnologia',
    'servicios',
    'otros',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Emprendimiento'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ✅ Logo estático de la app
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.3),
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
                  borderRadius: BorderRadius.circular(13),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback si no encuentra el logo
                      return const Icon(
                        Icons.business,
                        size: 60,
                        color: Colors.redAccent,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Negocio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingresa el nombre del negocio'
                    : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Negocio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingresa una descripción'
                    : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _ubicacionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingresa la dirección'
                    : null,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Row(
                      children: [
                        _getCategoriaIcon(categoria),
                        const SizedBox(width: 10),
                        Text(
                          _getCategoriaLabel(categoria),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _categoriaSeleccionada = value!),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final controller = EmprendimientoController();
                      controller.crearEmprendimiento(
                        context: context,
                        nombre: _nombreController.text.trim(),
                        descripcion: _descripcionController.text.trim(),
                        ubicacion: _ubicacionController.text.trim(),
                        categoria: _categoriaSeleccionada,
                      );
                    }
                  },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Crear Emprendimiento',
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

  // Helper para obtener iconos de categorías
  Icon _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'comida':
        return const Icon(Icons.restaurant, color: Colors.orange);
      case 'ropa':
        return const Icon(Icons.checkroom, color: Colors.purple);
      case 'artesania':
        return const Icon(Icons.palette, color: Colors.brown);
      case 'tecnologia':
        return const Icon(Icons.computer, color: Colors.blue);
      case 'servicios':
        return const Icon(Icons.build, color: Colors.green);
      case 'otros':
        return const Icon(Icons.more_horiz, color: Colors.grey);
      default:
        return const Icon(Icons.category, color: Colors.grey);
    }
  }

  // Helper para obtener labels formateados de categorías
  String _getCategoriaLabel(String categoria) {
    switch (categoria) {
      case 'comida':
        return 'Comida';
      case 'ropa':
        return 'Ropa';
      case 'artesania':
        return 'Artesanía';
      case 'tecnologia':
        return 'Tecnología';
      case 'servicios':
        return 'Servicios';
      case 'otros':
        return 'Otros';
      default:
        return categoria.toUpperCase();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }
}

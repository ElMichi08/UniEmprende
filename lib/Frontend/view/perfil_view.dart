import 'package:flutter/material.dart';
import 'package:lata_emprende/Backend/controller/auth_controller.dart';

import '../../Backend/models/usuario_model.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  UsuarioModel? _usuario;
  bool _editando = false;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    // Obtener el usuario actual del AuthController
    final usuario = AuthController.usuarioActual;

    if (usuario != null) {
      setState(() {
        _usuario = usuario;
        _nombreController.text = usuario.nombre;
        _apellidoController.text = usuario.apellido;
        _telefonoController.text = usuario.telefono;
      });
    } else {
      // Si no hay usuario logueado, redirigir al login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Future<void> guardarCambios() async {
    if (_formKey.currentState!.validate() && _usuario != null) {
      try {
        await AuthController().actualizarPerfilUsuario(
          id: _usuario!.idUsuario,
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(),
          telefono: _telefonoController.text.trim(),
        );

        setState(() {
          _editando = false;
        });

        await cargarPerfil();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void cerrarSesion() {
    AuthController().cerrarSesion();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Botones de acción en la parte superior
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mi Perfil',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_editando ? Icons.close : Icons.edit),
                        onPressed: () {
                          setState(() => _editando = !_editando);
                        },
                        color: Colors.redAccent,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: cerrarSesion,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Mostrar información del tipo de usuario
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _usuario!.tipoUsuario == 'emprendedor'
                          ? Icons.business
                          : Icons.person,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tipo: ${_usuario!.tipoUsuario.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombres'),
                enabled: _editando,
                validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
              ),

              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                enabled: _editando,
                validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
              ),

              TextFormField(
                initialValue: _usuario!.correo,
                decoration: const InputDecoration(labelText: 'Correo'),
                enabled: false,
              ),

              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                enabled: _editando,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              if (_editando)
                ElevatedButton(
                  onPressed: guardarCambios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Guardar Cambios'),
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
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
}

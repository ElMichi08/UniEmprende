import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lata_emprende/Backend/controller/auth_controller.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();
  String _tipoUsuario = 'consumidor'; // Valor por defecto

  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 100),
              const SizedBox(height: 20),
              const Text('Registrarse', style: TextStyle(fontSize: 24)),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nombresController,
                decoration: const InputDecoration(labelText: 'Nombres'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingresa tus nombres'
                    : null,
              ),

              TextFormField(
                controller: _apellidosController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingresa tus apellidos'
                    : null,
              ),

              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un correo válido';
                  }
                  if (!value.contains('@')) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ej: 987654321',
                  prefixText: '+593 ',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
              ),

              TextFormField(
                controller: _contrasenaController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una contraseña';
                  }
                  if (value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _confirmarContrasenaController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _contrasenaController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              // ✅ NUEVO: Título para el tipo de perfil
              const Text(
                'Tipo de perfil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'consumidor',
                    label: Text('Consumidor'),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment<String>(
                    value: 'emprendedor',
                    label: Text('Emprendedor'),
                    icon: Icon(Icons.store),
                  ),
                ],
                selected: {_tipoUsuario},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _tipoUsuario = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.redAccent.withOpacity(0.2);
                    }
                    return null;
                  }),
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final authController = AuthController();
                    authController.registrarUsuario(
                      context: context,
                      nombres: _nombresController.text.trim(),
                      apellidos: _apellidosController.text.trim(),
                      correo: _correoController.text.trim(),
                      telefono: _telefonoController.text.trim(),
                      contrasena: _contrasenaController.text.trim(),
                      tipoUsuario: _tipoUsuario,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Registrar Cuenta',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text('¿Ya tienes una cuenta? Inicia Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }
}

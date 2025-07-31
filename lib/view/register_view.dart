import 'package:flutter/material.dart';
import 'package:uni_emprende/view/login_view.dart'; // Asegúrate de que la ruta sea correcta
import 'package:uni_emprende/view/catalog_view.dart'; // Asegúrate de que la ruta sea correcta
import 'package:uni_emprende/backend/services/auth_service.dart'; // Importa tu servicio de autenticación
import 'package:uni_emprende/main.dart'; // Para usar la extensión showSnackBar
import 'package:firebase_auth/firebase_auth.dart'; // Para manejar FirebaseAuthException

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  // final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        context.showSnackBar('Las contraseñas no coinciden.', isError: true);
      }
      return;
    }

    try {
      await AuthService().registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        context.showSnackBar('Registro exitoso. ¡Bienvenido!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CatalogView()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        if (e.code == 'weak-password') {
          message = 'La contraseña es demasiado débil.';
        } else if (e.code == 'email-already-in-use') {
          message = 'El correo electrónico ya está en uso.';
        } else if (e.code == 'invalid-domain') {
          message = e.message ?? 'Solo se permiten correos @espe.edu.ec';
        } else if (e.code == 'invalid-email') {
          message = 'El formato del correo electrónico es inválido.';
        } else {
          message = 'Error de registro: ${e.message}';
        }
        context.showSnackBar(message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Ocurrió un error inesperado: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/UniEmprendeLogo.jpg', 
                height: 120,
              ),
              const SizedBox(height: 40),
              const Text(
                'Registrarse',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333), 
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombres',
                  hintText: 'Ingresa tus nombres completos',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Apellidos',
                  hintText: 'Ingresa tus apellidos completos',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  hintText: 'Ingresa tu correo electrónico',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Escribe una contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  hintText: 'Confirma tu contraseña',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.lock_reset),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935), // Color rojo del botón
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Registrar Cuenta',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                },
                child: const Text(
                  '¿Ya tienes una cuenta? Inicia Sesión',
                  style: TextStyle(
                    color: Color(0xFFE53935), // Color rojo para el texto
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

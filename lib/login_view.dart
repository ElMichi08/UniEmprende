import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:uni_emprende/view/register_view.dart'; // Asegúrate de que la ruta sea correcta
import 'package:uni_emprende/view/catalog_view.dart'; // Asegúrate de que la ruta sea correcta
import 'package:uni_emprende/backend/services/auth_service.dart'; // Asegúrate de que la ruta sea correcta
import 'package:uni_emprende/main.dart'; // Para usar la extensión showSnackBar
import 'package:firebase_auth/firebase_auth.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    try {
      await AuthService().signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        context.showSnackBar('Inicio de sesión exitoso');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CatalogView()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No se encontró un usuario con ese correo.';
        } else if (e.code == 'wrong-password') {
          message = 'Contraseña incorrecta.';
        } else if (e.code == 'invalid-domain') {
          message = e.message ?? 'Solo se permiten correos @espe.edu.ec';
        } else if (e.code == 'invalid-email') {
          message = 'El formato del correo electrónico es inválido.';
        } else {
          message = 'Error de autenticación: ${e.message}';
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
                'uni_emprende', // Ruta del logo
                height: 120,
              ),
              const SizedBox(height: 40),
              const Text(
                'Inicio de Sesión',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333), // Color de texto oscuro
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  hintText: 'example@espe.edu.ec',
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935), // Color rojo del botón
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterView()),
                  );
                },
                child: const Text(
                  'Registrarse',
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

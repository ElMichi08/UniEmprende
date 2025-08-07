import 'package:flutter/material.dart';
import 'package:uni_emprende/backend/services/admin_service.dart';
import 'package:uni_emprende/view/catalog_view.dart';
import 'package:uni_emprende/main.dart';

class AdminGuard extends StatefulWidget {
  final Widget child;

  const AdminGuard({
    super.key,
    required this.child,
  });

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
  }

  Future<void> _verificarPermisos() async {
    try {
      final esAdmin = await _adminService.esAdministrador();
      setState(() {
        _isAdmin = esAdmin;
        _isLoading = false;
      });

      if (!esAdmin && mounted) {
        context.showSnackBar('No tienes permisos de administrador', isError: true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CatalogView()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        context.showSnackBar('Error al verificar permisos: $e', isError: true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CatalogView()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Acceso denegado'),
        ),
      );
    }

    return widget.child;
  }
}

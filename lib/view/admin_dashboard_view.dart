import 'package:flutter/material.dart';
import 'package:uni_emprende/backend/services/admin_service.dart';
import 'package:uni_emprende/backend/model/emprendimiento_model.dart';
import 'package:uni_emprende/view/admin_edit_business_view.dart';
import 'package:uni_emprende/widgets/custom_bottom_navigation.dart';
import 'package:uni_emprende/main.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final AdminService _adminService = AdminService();
  List<EmprendimientoModel> _emprendimientos = [];
  Map<String, int> _estadisticas = {};
  bool _isLoading = true;
  int _selectedIndex = 3; // Perfil está seleccionado

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final emprendimientos = await _adminService.obtenerTodosLosEmprendimientosAdmin();
      final estadisticas = await _adminService.obtenerEstadisticas();

      setState(() {
        _emprendimientos = emprendimientos;
        _estadisticas = estadisticas;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al cargar datos: $e', isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editarEmprendimiento(EmprendimientoModel emprendimiento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditBusinessView(emprendimiento: emprendimiento),
      ),
    );

    if (result == true) {
      _cargarDatos(); // Recargar datos si hubo cambios
    }
  }

  Future<void> _eliminarEmprendimiento(EmprendimientoModel emprendimiento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar "${emprendimiento.nombre}"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _adminService.eliminarEmprendimientoAdmin(emprendimiento.id);
        if (mounted) {
          context.showSnackBar('Emprendimiento eliminado exitosamente');
          _cargarDatos();
        }
      } catch (e) {
        if (mounted) {
          context.showSnackBar('Error al eliminar emprendimiento: $e', isError: true);
        }
      }
    }
  }

  Widget _buildEstadisticaCard(String titulo, int valor, IconData icono, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icono, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              valor.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmprendimientoCard(EmprendimientoModel emprendimiento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE53935),
          child: Text(
            emprendimiento.nombre.isNotEmpty ? emprendimiento.nombre[0].toUpperCase() : 'E',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          emprendimiento.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emprendimiento.sector),
            Text(
              emprendimiento.correoContacto,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'editar') {
              _editarEmprendimiento(emprendimiento);
            } else if (value == 'eliminar') {
              _eliminarEmprendimiento(emprendimiento);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panel de Administración',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Estadísticas
                  Row(
                    children: [
                      Expanded(
                        child: _buildEstadisticaCard(
                          'Emprendimientos',
                          _estadisticas['emprendimientos'] ?? 0,
                          Icons.business,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEstadisticaCard(
                          'Productos',
                          _estadisticas['productos'] ?? 0,
                          Icons.inventory,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEstadisticaCard(
                          'Reseñas',
                          _estadisticas['resenas'] ?? 0,
                          Icons.star,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Lista de emprendimientos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Emprendimientos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        '${_emprendimientos.length} total',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_emprendimientos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No hay emprendimientos registrados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...(_emprendimientos.map((emprendimiento) => 
                        _buildEmprendimientoCard(emprendimiento)).toList()),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _selectedIndex,
      ),
    );
  }
}

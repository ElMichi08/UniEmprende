import 'package:flutter/material.dart';
import 'package:uni_emprende/view/catalog_view.dart';
import 'package:uni_emprende/view/add_product_view.dart';
import 'package:uni_emprende/view/create_business_profile_view.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleNavigation(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Navegación por defecto
    switch (index) {
      case 0: // Inicio
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CatalogView()),
          (route) => false,
        );
        break;
      case 1: // Filtro
        // Mantener en la pantalla actual, solo cambiar índice
        break;
      case 2: // Agregar
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductView()),
        );
        break;
      case 3: // Perfil
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateBusinessProfileView()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFE53935),
      unselectedItemColor: Colors.grey[600],
      currentIndex: currentIndex,
      onTap: (index) => _handleNavigation(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.filter_list),
          label: 'Filtro',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Agregar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}

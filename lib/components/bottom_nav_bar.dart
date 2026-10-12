import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import '../components/theme_provider.dart';

class MyBottomNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;

  const MyBottomNavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GNav(
        color: isDarkMode ? Colors.grey[500] : Colors.grey[600], // Iconos inactivos en gris
        activeColor: Colors.redAccent, // Color de selección
        tabBackgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.red.shade50, // Fondo del tab activo
        mainAxisAlignment: MainAxisAlignment.center,
        tabBorderRadius: 16,
        gap: 8,
        onTabChange: (value) => onTabChange!(value),
        tabs: const [
          GButton(
            icon: Icons.restaurant_menu,
            text: 'Menú',
          ),
          GButton(
            icon: Icons.shopping_bag_rounded,
            text: 'Carrito',
          ),
        ],
      ),
    );
  }
}
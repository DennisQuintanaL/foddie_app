import 'dart:io';
import 'package:flutter/material.dart';
import '../models/status_articulo.dart';

class FoodTile extends StatelessWidget {
  final String nombre;
  final String? imagenPath;
  final int cantidad;
  final String unidad;
  final DateTime? fechaCaducidad;
  final EstatusArticulo estatus;
  final VoidCallback onAgregarCarrito;

  const FoodTile({
    super.key,
    required this.nombre,
    this.imagenPath,
    required this.cantidad,
    required this.unidad,
    this.fechaCaducidad,
    required this.estatus,
    required this.onAgregarCarrito,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            color: Colors.grey.shade200,
            child: imagenPath != null && imagenPath!.isNotEmpty
                ? Image.file(File(imagenPath!), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 30))
                : const Icon(Icons.fastfood, size: 30, color: Colors.grey),
          ),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: estatus.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estatus.color, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estatus.icono, size: 14, color: estatus.color),
                      const SizedBox(width: 4),
                      Text(
                        estatus.etiqueta,
                        style: TextStyle(
                            color: estatus.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Stock: $cantidad $unidad'),
            if (fechaCaducidad != null)
              Text(
                'Caduca: ${fechaCaducidad!.day}/${fechaCaducidad!.month}/${fechaCaducidad!.year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.teal),
          onPressed: onAgregarCarrito,
          tooltip: 'Agregar al carrito',
        ),
      ),
    );
  }
}
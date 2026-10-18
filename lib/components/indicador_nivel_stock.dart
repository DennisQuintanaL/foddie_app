// ignore: duplicate_ignore
// ignore: file_names
// ignore: file_names
// ignore: file_names
// ignore_for_file: duplicate_ignore, file_names

import 'package:flutter/material.dart';

class StockStatusProgress extends StatelessWidget {
  final int stockDisponible;
  final int stockMinimo;
  final String unidad;

  const StockStatusProgress({
    super.key,
    required this.stockDisponible,
    required this.stockMinimo,
    this.unidad = 'piezas',
  });

  @override
  Widget build(BuildContext context) {
    // Cálculo del porcentaje basado en un objetivo óptimo del doble del stock mínimo
    final int objetivoOptimo = stockMinimo > 0 ? stockMinimo * 2 : 10;
    final double porcentaje = (stockDisponible / objetivoOptimo).clamp(0.0, 1.0);

    Color colorBarra;
    String estadoTexto;

    if (stockDisponible == 0) {
      colorBarra = Colors.red;
      estadoTexto = 'Agotado';
    } else if (stockDisponible <= stockMinimo) {
      colorBarra = Colors.orange.shade800;
      estadoTexto = 'Stock Bajo';
    } else {
      colorBarra = Colors.green.shade600;
      estadoTexto = 'Suficiente';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$stockDisponible / $objetivoOptimo $unidad',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorBarra.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorBarra, width: 1),
              ),
              child: Text(
                estadoTexto,
                style: TextStyle(
                  color: colorBarra,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: porcentaje,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(colorBarra),
          ),
        ),
      ],
    );
  }
}

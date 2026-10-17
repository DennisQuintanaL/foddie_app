import 'package:flutter/material.dart';

enum EstatusArticulo {
  caducado,
  porCaducar,
  sinExistencia,
  porAgotarse,
  normal
}

extension EstatusArticuloExtension on EstatusArticulo {
  String get etiqueta {
    switch (this) {
      case EstatusArticulo.caducado: return 'Caducado';
      case EstatusArticulo.porCaducar: return 'Por caducar';
      case EstatusArticulo.sinExistencia: return 'Sin existencia';
      case EstatusArticulo.porAgotarse: return 'Por agotarse';
      case EstatusArticulo.normal: return 'En orden';
    }
  }

  Color get color {
    switch (this) {
      case EstatusArticulo.caducado: return Colors.red.shade700;
      case EstatusArticulo.porCaducar: return Colors.orange.shade800;
      case EstatusArticulo.sinExistencia: return Colors.purple.shade700;
      case EstatusArticulo.porAgotarse: return Colors.amber.shade900;
      case EstatusArticulo.normal: return Colors.green.shade700;
    }
  }

  IconData get icono {
    switch (this) {
      case EstatusArticulo.caducado: return Icons.dangerous;
      case EstatusArticulo.porCaducar: return Icons.warning_amber_rounded;
      case EstatusArticulo.sinExistencia: return Icons.remove_shopping_cart;
      case EstatusArticulo.porAgotarse: return Icons.inventory_2_outlined;
      case EstatusArticulo.normal: return Icons.check_circle_outline;
    }
  }
}
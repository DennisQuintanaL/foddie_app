import 'package:flutter/material.dart';
import '../data/consumo_repository.dart';
import '../data/notificaciones_service.dart';

class QuickConsumeSheet extends StatefulWidget {
  final int productoId;
  final String nombreProducto;
  final int stockDisponible;
  final String unidad;
  final VoidCallback onConsumido;

  const QuickConsumeSheet({
    super.key,
    required this.productoId,
    required this.nombreProducto,
    required this.stockDisponible,
    required this.unidad,
    required this.onConsumido,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required int productoId,
    required String nombreProducto,
    required int stockDisponible,
    required String unidad,
    required VoidCallback onConsumido,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickConsumeSheet(
        productoId: productoId,
        nombreProducto: nombreProducto,
        stockDisponible: stockDisponible,
        unidad: unidad,
        onConsumido: onConsumido,
      ),
    );
  }

  @override
  State<QuickConsumeSheet> createState() => _QuickConsumeSheetState();
}

class _QuickConsumeSheetState extends State<QuickConsumeSheet> {
  int _cantidad = 1;
  bool _procesando = false;
  final ConsumoRepository _consumoRepo = ConsumoRepository();

  Future<void> _ejecutarConsumo() async {
    setState(() => _procesando = true);

    try {
      await _consumoRepo.consumirProducto(
        productoId: widget.productoId,
        cantidad: _cantidad,
      );

      await NotificacionesService.instance.actualizarAlertasSeguro();

      if (!mounted) return;

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se consumieron $_cantidad ${widget.unidad} de ${widget.nombreProducto}',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      widget.onConsumido();
    } catch (e) {
      if (!mounted) return;

      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError ? e.message : 'Error al consumir: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.restaurant, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consumir ${widget.nombreProducto}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stock disponible (vigente): ${widget.stockDisponible} ${widget.unidad}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                onPressed: _cantidad > 1 && !_procesando
                    ? () => setState(() => _cantidad--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  '$_cantidad',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: _cantidad < widget.stockDisponible && !_procesando
                    ? () => setState(() => _cantidad++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _procesando || widget.stockDisponible <= 0
                  ? null
                  : _ejecutarConsumo,
              icon: _procesando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _procesando ? 'Procesando...' : 'Confirmar consumo FEFO',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

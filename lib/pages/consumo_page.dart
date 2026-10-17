
import 'package:flutter/material.dart';

import '../data/consumo_repository.dart';
import '../data/producto_repository.dart';
import '../data/notificaciones_service.dart';
import '../models/producto.dart';

class ConsumoPage extends StatefulWidget {
  const ConsumoPage({super.key});

  @override
  State<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends State<ConsumoPage> {
  final ConsumoRepository _consumoRepository = ConsumoRepository();
  final ProductoRepository _productoRepository = ProductoRepository();
  final TextEditingController _cantidadController =
      TextEditingController();

  List<Producto> _productos = [];
  int? _productoId;
  int _stockDisponible = 0;
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await _productoRepository.obtenerTodos();

      if (!mounted) return;

      setState(() {
        _productos = productos;
        _productoId =
            productos.isEmpty ? null : productos.first.id;
        _cargando = false;
      });

      if (_productoId != null) {
        await _actualizarStock(_productoId!);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);
      _mensaje('No se pudieron cargar los productos: $e');
    }
  }

  Future<void> _actualizarStock(int productoId) async {
    try {
      final stock = await _consumoRepository
          .obtenerStockDisponible(productoId);

      if (!mounted) return;

      setState(() => _stockDisponible = stock);
    } catch (e) {
      _mensaje('No se pudo consultar el inventario: $e');
    }
  }

  Future<void> _consumir() async {
    if (_productoId == null) {
      _mensaje('Selecciona un producto.');
      return;
    }

    final cantidad =
        int.tryParse(_cantidadController.text.trim());

    if (cantidad == null || cantidad <= 0) {
      _mensaje('Ingresa una cantidad mayor que cero.');
      return;
    }

    setState(() => _procesando = true);

    try {
      final productoConsumidoId = _productoId!;

      final detalle = await _consumoRepository.consumirProducto(
        productoId: productoConsumidoId,
        cantidad: cantidad,
      );

      // El consumo ya se registró correctamente.
      // Actualizar las alertas no debe invalidar el consumo.
      final alertasActualizadas =
          await NotificacionesService.instance
              .actualizarAlertasSeguro();

      if (!mounted) return;

      await _actualizarStock(productoConsumidoId);
      _cantidadController.clear();

      final resumen = detalle.map((lote) {
        return '${lote['cantidad_consumida']} unidad(es), '
            'caducidad ${lote['fecha_caducidad']}';
      }).join('\n');

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Consumo registrado'),
          content: Text(
            'Se consumieron $cantidad unidad(es) siguiendo FEFO.\n\n'
            '$resumen'
            '${alertasActualizadas ? '' : '\n\n'
                'El consumo se guardó, pero no se pudieron actualizar '
                'las alertas.'}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _mensaje(
          e is StateError
              ? e.message
              : 'No se pudo registrar el consumo: $e',
        );

        await _actualizarStock(_productoId!);
      }
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  void _mensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumo de inventario'),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _productos.isEmpty
              ? const Center(
                  child: Text(
                    'Primero registra al menos un producto.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Registrar consumo',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      initialValue: _productoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                      ),
                      items: _productos
                          .where((p) => p.id != null)
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p.id,
                              child: Text(p.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: _procesando
                          ? null
                          : (id) async {
                              if (id == null) return;

                              setState(() => _productoId = id);
                              await _actualizarStock(id);
                            },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory),
                        title: const Text('Stock disponible'),
                        subtitle: const Text(
                          'No incluye lotes vencidos',
                        ),
                        trailing: Text(
                          '$_stockDisponible',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cantidadController,
                      enabled: !_procesando,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad a consumir',
                        hintText: 'Ej. 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _procesando ? null : _consumir,
                      icon: _procesando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _procesando
                            ? 'Procesando...'
                            : 'Registrar consumo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'El sistema descontará primero las existencias '
                      'que caduquen antes. Si el stock no alcanza, '
                      'no realizará ningún descuento.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
    );
  }
}

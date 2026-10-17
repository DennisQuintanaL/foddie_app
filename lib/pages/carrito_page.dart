import 'dart:io';

import 'package:flutter/material.dart';

import '../data/carrito_repository.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final CarritoRepository _carrito = CarritoRepository();

  List<Map<String, Object?>> _items = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarItems();
  }

  Future<void> _cargarItems() async {
    try {
      final items = await _carrito.obtenerItems();

      if (!mounted) return;

      setState(() {
        _items = items;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el carrito.';
      });
    }
  }

  Future<void> _cambiarCantidad(int productoId, int cantidad) async {
    try {
      await _carrito.actualizarCantidad(productoId, cantidad);
      await _cargarItems();
    } catch (e) {
      _mostrarMensaje('No se pudo actualizar la cantidad.');
    }
  }

  Future<void> _eliminar(int productoId) async {
    try {
      await _carrito.eliminarProducto(productoId);
      await _cargarItems();
      _mostrarMensaje('Producto eliminado del carrito.');
    } catch (e) {
      _mostrarMensaje('No se pudo eliminar el producto.');
    }
  }

  Future<void> _vaciarCarrito() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text(
          '¿Deseas eliminar todos los productos de la lista de compras?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _carrito.vaciar();
      await _cargarItems();
      _mostrarMensaje('El carrito está vacío.');
    } catch (e) {
      _mostrarMensaje('No se pudo vaciar el carrito.');
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Widget _imagenProducto(String? ruta) {
    if (ruta != null && ruta.isNotEmpty && File(ruta).existsSync()) {
      return Image.file(
        File(ruta),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imagenPredeterminada();
        },
      );
    }

    return _imagenPredeterminada();
  }

  Widget _imagenPredeterminada() {
    return Container(
      width: 64,
      height: 64,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.inventory_2_outlined, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUnidades = _items.fold<int>(
      0,
      (total, item) => total + (item['cantidad_carrito'] as int),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Vaciar carrito',
              onPressed: _vaciarCarrito,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _cargarItems,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 76,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tu lista está vacía',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Agrega productos desde la pantalla principal.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_items.length} productos diferentes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '$totalUnidades unidades',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final productoId = item['producto_id'] as int;
                      final cantidad = item['cantidad_carrito'] as int;
                      final nombre = item['producto_nombre'] as String;
                      final unidad = item['unidad'] as String;
                      final imagen = item['imagen_path'] as String?;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _imagenProducto(imagen),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('$cantidad $unidad'),
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Disminuir',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _cambiarCantidad(
                                            productoId,
                                            cantidad - 1,
                                          ),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                        ),
                                        Text('$cantidad'),
                                        IconButton(
                                          tooltip: 'Aumentar',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _cambiarCantidad(
                                            productoId,
                                            cantidad + 1,
                                          ),
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar producto',
                                onPressed: () => _eliminar(productoId),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

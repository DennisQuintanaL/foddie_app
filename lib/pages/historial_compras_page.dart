import 'package:flutter/material.dart';

import '../data/historial_compras_repository.dart';
import '../data/notificaciones_service.dart';
import '../data/producto_repository.dart';
import '../data/tienda_repository.dart';
import '../models/producto.dart';
import '../models/tienda.dart';

class HistorialComprasPage extends StatefulWidget {
  const HistorialComprasPage({super.key});

  @override
  State<HistorialComprasPage> createState() =>
      _HistorialComprasPageState();
}

class _HistorialComprasPageState extends State<HistorialComprasPage> {
  final _historialRepository = HistorialComprasRepository();
  final _productoRepository = ProductoRepository();
  final _tiendaRepository = TiendaRepository();

  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();

  List<Producto> _productos = [];
  List<Tienda> _tiendas = [];
  List<Map<String, Object?>> _historial = [];

  int? _productoId;
  int? _tiendaId;

  DateTime _fechaCaducidad =
      DateTime.now().add(const Duration(days: 30));

  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final productos = await _productoRepository.obtenerTodos();
      final tiendas = await _tiendaRepository.obtenerTodas();
      final historial = await _historialRepository.obtenerHistorial();

      if (!mounted) return;

      setState(() {
        _productos = productos;
        _tiendas = tiendas;
        _historial = historial;

        if (!_productos.any((p) => p.id == _productoId)) {
          _productoId = _productos
              .where((p) => p.id != null)
              .map((p) => p.id!)
              .firstOrNull;
        }

        if (!_tiendas.any((t) => t.id == _tiendaId)) {
          _tiendaId = _tiendas
              .where((t) => t.id != null)
              .map((t) => t.id!)
              .firstOrNull;
        }

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mensaje('No se pudieron cargar los datos: $e');
    }
  }

  Future<bool> _actualizarAlertasSeguro() async {
    try {
      await NotificacionesService.instance.programarAlertasInventario();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar las alertas: $e');
      return false;
    }
  }

  Future<void> _seleccionarCaducidad() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _fechaCaducidad.isBefore(hoy) ? hoy : _fechaCaducidad,
      firstDate: hoy,
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de caducidad',
    );

    if (fecha != null && mounted) {
      setState(() => _fechaCaducidad = fecha);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  Future<void> _registrarCompra() async {
    if (_productoId == null) {
      _mensaje('Registra y selecciona un producto primero.');
      return;
    }

    if (_tiendaId == null) {
      _mensaje('Registra y selecciona una tienda primero.');
      return;
    }

    final cantidad = int.tryParse(_cantidadController.text.trim());
    final precio = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );

    if (cantidad == null || cantidad <= 0) {
      _mensaje('La cantidad debe ser un entero mayor que cero.');
      return;
    }

    if (precio == null || !precio.isFinite || precio < 0) {
      _mensaje('Ingresa un precio válido por unidad.');
      return;
    }

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    if (_fechaCaducidad.isBefore(hoy)) {
      _mensaje('La fecha de caducidad no puede estar en el pasado.');
      return;
    }

    setState(() => _guardando = true);

    try {
      await _historialRepository.registrarCompra(
        productoId: _productoId!,
        tiendaId: _tiendaId!,
        cantidad: cantidad,
        precioUnitario: precio,
        fechaCaducidad: _fechaCaducidad,
      );

      // La compra ya está guardada; un error de notificaciones
      // no debe hacer que se reporte como una compra fallida.
      final alertasActualizadas = await _actualizarAlertasSeguro();

      _cantidadController.clear();
      _precioController.clear();

      await _cargarDatos();

      if (!mounted) return;

      _mensaje(
        alertasActualizadas
            ? 'Compra registrada y alertas actualizadas.'
            : 'Compra registrada, pero no se pudieron actualizar las alertas.',
      );
    } catch (e) {
      if (mounted) {
        _mensaje('No se pudo registrar la compra: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de compras'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando
                ? null
                : () async {
                    setState(() => _cargando = true);
                    await _cargarDatos();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Registrar compra',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_productos.isEmpty)
                    const Text(
                      'Primero registra un producto para poder comprarlo.',
                    )
                  else
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
                              child: Text('${p.nombre} (${p.unidad})'),
                            ),
                          )
                          .toList(),
                      onChanged: _guardando
                          ? null
                          : (id) => setState(() => _productoId = id),
                    ),
                  const SizedBox(height: 12),
                  if (_tiendas.isEmpty)
                    const Text(
                      'Primero registra una tienda para asociarla a la compra.',
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _tiendaId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tienda',
                        border: OutlineInputBorder(),
                      ),
                      items: _tiendas
                          .where((t) => t.id != null)
                          .map(
                            (t) => DropdownMenuItem<int>(
                              value: t.id,
                              child: Text(t.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: _guardando
                          ? null
                          : (id) => setState(() => _tiendaId = id),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cantidadController,
                    enabled: !_guardando,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad comprada',
                      hintText: 'Ej. 5',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _precioController,
                    enabled: !_guardando,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio por unidad',
                      prefixText: '\$ ',
                      hintText: 'Ej. 12.50',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Fecha de caducidad'),
                      subtitle: Text(_formatearFecha(_fechaCaducidad)),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: _guardando ? null : _seleccionarCaducidad,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _guardando ||
                            _productos.isEmpty ||
                            _tiendas.isEmpty
                        ? null
                        : _registrarCompra,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Registrar compra',
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Compras registradas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_historial.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Todavía no hay compras registradas.'),
                    )
                  else
                    ..._historial.map((compra) {
                      final cantidad =
                          (compra['cantidad'] as num).toInt();
                      final precio =
                          (compra['precio_unitario'] as num).toDouble();
                      final total = cantidad * precio;
                      final fecha = DateTime.tryParse(
                        compra['fecha_compra']?.toString() ?? '',
                      );

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.receipt_long),
                          ),
                          title: Text(
                            compra['producto_nombre']?.toString() ??
                                'Producto',
                          ),
                          subtitle: Text(
                            'Tienda: ${compra['tienda_nombre'] ?? 'Sin tienda'}'
                            '\nCantidad: $cantidad ${compra['unidad'] ?? 'unidades'}'
                            '\nPrecio unitario: \$${precio.toStringAsFixed(2)}'
                            '\nFecha: ${fecha == null ? 'Desconocida' : _formatearFecha(fecha)}',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total'),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

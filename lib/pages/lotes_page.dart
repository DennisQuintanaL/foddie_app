
import 'package:flutter/material.dart';

import '../data/lote_repository.dart';
import '../data/notificaciones_service.dart';
import '../data/producto_repository.dart';
import '../data/tienda_repository.dart';
import '../models/lote.dart';
import '../models/producto.dart';
import '../models/tienda.dart';

class LotesPage extends StatefulWidget {
  const LotesPage({super.key});

  @override
  State<LotesPage> createState() => _LotesPageState();
}

class _LotesPageState extends State<LotesPage> {
  final LoteRepository _loteRepository = LoteRepository();
  final ProductoRepository _productoRepository = ProductoRepository();
  final TiendaRepository _tiendaRepository = TiendaRepository();

  List<Lote> _lotes = [];
  List<Producto> _productos = [];
  List<Tienda> _tiendas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _loteRepository.obtenerTodos(),
        _productoRepository.obtenerTodos(),
        _tiendaRepository.obtenerTodas(),
      ]);

      if (!mounted) return;

      setState(() {
        _lotes = resultados[0] as List<Lote>;
        _productos = resultados[1] as List<Producto>;
        _tiendas = resultados[2] as List<Tienda>;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);
      _mensaje('No se pudieron cargar los lotes: $e');
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

  String _nombreProducto(int id) {
    return _productos
            .where((producto) => producto.id == id)
            .map((producto) => producto.nombre)
            .firstOrNull ??
        'Producto no encontrado';
  }

  String _nombreTienda(int? id) {
    if (id == null) return 'Sin tienda asignada';

    return _tiendas
            .where((tienda) => tienda.id == id)
            .map((tienda) => tienda.nombre)
            .firstOrNull ??
        'Tienda no encontrada';
  }

  int _stockProducto(int productoId) {
    return _lotes
        .where((lote) => lote.productoId == productoId)
        .fold<int>(0, (total, lote) => total + lote.cantidad);
  }

  Future<void> _mostrarFormulario({Lote? lote}) async {
    if (_productos.isEmpty) {
      _mensaje('Primero registra un producto.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final cantidadController = TextEditingController(
      text: (lote?.cantidad ?? 1).toString(),
    );

    int? productoId = lote?.productoId ?? _productos.first.id;
    int? tiendaId = lote?.tiendaId;

    DateTime fechaCaducidad =
        DateTime.tryParse(lote?.fechaCaducidad ?? '') ??
        DateTime.now().add(const Duration(days: 30));

    try {
      final resultado = await showDialog<Lote>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  lote == null ? 'Registrar lote' : 'Editar lote',
                ),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: productoId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Producto *',
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
                            onChanged: (valor) {
                              setDialogState(() => productoId = valor);
                            },
                            validator: (valor) => valor == null
                                ? 'Selecciona un producto'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int?>(
                            initialValue: tiendaId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tienda de origen',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Sin tienda asignada'),
                              ),
                              ..._tiendas
                                  .where((t) => t.id != null)
                                  .map(
                                    (t) => DropdownMenuItem<int?>(
                                      value: t.id,
                                      child: Text(t.nombre),
                                    ),
                                  ),
                            ],
                            onChanged: (valor) {
                              setDialogState(() => tiendaId = valor);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: cantidadController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (valor) {
                              final cantidad = int.tryParse(valor ?? '');

                              if (cantidad == null || cantidad < 0) {
                                return 'Ingresa una cantidad igual o mayor a 0';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_month),
                            title: const Text('Fecha de caducidad'),
                            subtitle: Text(
                              '${fechaCaducidad.day.toString().padLeft(2, '0')}/'
                              '${fechaCaducidad.month.toString().padLeft(2, '0')}/'
                              '${fechaCaducidad.year}',
                            ),
                            trailing: const Icon(Icons.edit_calendar),
                            onTap: () async {
                              final seleccion = await showDatePicker(
                                context: dialogContext,
                                initialDate: fechaCaducidad,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                helpText: 'Selecciona la caducidad',
                              );

                              if (seleccion != null) {
                                setDialogState(() {
                                  fechaCaducidad = seleccion;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;

                      final cantidad =
                          int.parse(cantidadController.text.trim());

                      Navigator.pop(
                        dialogContext,
                        Lote(
                          id: lote?.id,
                          productoId: productoId!,
                          tiendaId: tiendaId,
                          cantidad: cantidad,
                          fechaCaducidad:
                              fechaCaducidad.toIso8601String().split('T').first,
                          fechaRegistro: lote?.fechaRegistro ??
                              DateTime.now()
                                  .toIso8601String()
                                  .split('T')
                                  .first,
                        ),
                      );
                    },
                    child: Text(lote == null ? 'Guardar' : 'Actualizar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (resultado == null || !mounted) return;

      try {
        if (lote == null) {
          await _loteRepository.crear(resultado);
        } else {
          await _loteRepository.editar(resultado);
        }

        await _cargarDatos();

        final alertasActualizadas = await _actualizarAlertasSeguro();

        if (!mounted) return;

        final mensaje = lote == null
            ? 'Lote registrado correctamente.'
            : 'Lote actualizado correctamente.';

        _mensaje(
          alertasActualizadas
              ? mensaje
              : '$mensaje No se pudieron actualizar las alertas.',
        );
      } catch (e) {
        _mensaje('No se pudo guardar el lote: $e');
      }
    } finally {
      cantidadController.dispose();
    }
  }

  Future<void> _eliminarLote(Lote lote) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar lote'),
        content: Text(
          '¿Eliminar el lote de "${_nombreProducto(lote.productoId)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _loteRepository.eliminar(lote.id!);
      await _cargarDatos();

      final alertasActualizadas = await _actualizarAlertasSeguro();

      if (!mounted) return;

      _mensaje(
        alertasActualizadas
            ? 'Lote eliminado correctamente.'
            : 'Lote eliminado, pero no se pudieron actualizar las alertas.',
      );
    } catch (e) {
      _mensaje('No se pudo eliminar el lote: $e');
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final productosConStock = _productos.where((producto) {
      final id = producto.id;
      return id != null && _stockProducto(id) > 0;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotes e inventario'),
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Icon(Icons.inventory_2_outlined),
                                const SizedBox(height: 6),
                                Text(
                                  '${_lotes.length}',
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const Text('Lotes'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle_outline),
                                const SizedBox(height: 6),
                                Text(
                                  '$productosConStock',
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const Text('Productos con stock'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _lotes.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay lotes registrados.\n'
                              'Pulsa + para agregar existencias.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarDatos,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              0,
                              12,
                              90,
                            ),
                            itemCount: _lotes.length,
                            itemBuilder: (context, index) {
                              final lote = _lotes[index];
                              final caducidad =
                                  DateTime.tryParse(lote.fechaCaducidad);

                              final ahora = DateTime.now();
                              final hoy = DateTime(
                                ahora.year,
                                ahora.month,
                                ahora.day,
                              );

                              final diasRestantes = caducidad == null
                                  ? null
                                  : DateTime(
                                      caducidad.year,
                                      caducidad.month,
                                      caducidad.day,
                                    ).difference(hoy).inDays;

                              final vencido =
                                  diasRestantes != null && diasRestantes < 0;

                              final proximo = diasRestantes != null &&
                                  diasRestantes >= 0 &&
                                  diasRestantes <= 7;

                              final color = vencido
                                  ? Colors.red
                                  : proximo
                                      ? Colors.orange
                                      : null;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        color?.withValues(alpha: 0.15),
                                    child: Icon(
                                      vencido
                                          ? Icons.warning_amber
                                          : Icons.inventory_2_outlined,
                                      color: color,
                                    ),
                                  ),
                                  title: Text(
                                    _nombreProducto(lote.productoId),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Cantidad: ${lote.cantidad}'),
                                      Text(_nombreTienda(lote.tiendaId)),
                                      Text(
                                        'Caducidad: ${lote.fechaCaducidad}',
                                      ),
                                      if (lote.cantidad == 0)
                                        const Text(
                                          'Lote sin existencias',
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      if (vencido)
                                        const Text(
                                          'Producto caducado',
                                          style: TextStyle(color: Colors.red),
                                        )
                                      else if (proximo)
                                        Text(
                                          'Caduca en $diasRestantes días',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (opcion) {
                                      if (opcion == 'editar') {
                                        _mostrarFormulario(lote: lote);
                                      } else if (opcion == 'eliminar') {
                                        _eliminarLote(lote);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'editar',
                                        child: Text('Editar'),
                                      ),
                                      PopupMenuItem(
                                        value: 'eliminar',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        tooltip: 'Agregar lote',
        child: const Icon(Icons.add),
      ),
    );
  }
}

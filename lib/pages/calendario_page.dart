import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/alerta_repository.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  final AlertaRepository _repository = AlertaRepository();

  DateTime _diaEnfocado = DateTime.now();
  DateTime _diaSeleccionado = DateTime.now();

  Map<DateTime, List<Map<String, Object?>>> _eventos = {};
  List<Map<String, Object?>> _lotes = [];
  List<Map<String, Object?>> _resumenStock = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  DateTime _soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  Future<void> _cargarDatos() async {
    try {
      final lotes = await _repository.obtenerLotesConCaducidad();
      final resumen = await _repository.obtenerResumenStock();

      final eventos = <DateTime, List<Map<String, Object?>>>{};

      for (final lote in lotes) {
        final textoFecha = lote['fecha_caducidad']?.toString();
        if (textoFecha == null) continue;

        final fecha = DateTime.tryParse(textoFecha);
        if (fecha == null) continue;

        final dia = _soloFecha(fecha);
        eventos.putIfAbsent(dia, () => []);
        eventos[dia]!.add(lote);
      }

      if (!mounted) return;

      setState(() {
        _lotes = lotes;
        _resumenStock = resumen;
        _eventos = eventos;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar las alertas: $e';
      });
    }
  }

  List<Map<String, Object?>> _eventosDelDia(DateTime dia) {
    return _eventos[_soloFecha(dia)] ?? [];
  }

  int get _cantidadVencidos {
    final hoy = _soloFecha(DateTime.now());

    return _lotes.where((lote) {
      final fecha = DateTime.tryParse(
        lote['fecha_caducidad']?.toString() ?? '',
      );
      return fecha != null &&
          _soloFecha(fecha).isBefore(hoy) &&
          (lote['cantidad'] as num).toInt() > 0;
    }).length;
  }

  int get _cantidadProximosAVencer {
    final hoy = _soloFecha(DateTime.now());
    final limite = hoy.add(const Duration(days: 7));

    return _lotes.where((lote) {
      final fecha = DateTime.tryParse(
        lote['fecha_caducidad']?.toString() ?? '',
      );

      if (fecha == null || (lote['cantidad'] as num).toInt() <= 0) {
        return false;
      }

      final dia = _soloFecha(fecha);
      return !dia.isBefore(hoy) && !dia.isAfter(limite);
    }).length;
  }

  int get _cantidadSinStock {
    return _resumenStock.where((producto) {
      return (producto['stock_disponible'] as num).toInt() == 0;
    }).length;
  }

  int get _cantidadStockBajo {
    return _resumenStock.where((producto) {
      final stock = (producto['stock_disponible'] as num).toInt();
      final minimo = (producto['stock_minimo'] as num).toInt();
      return stock > 0 && stock <= minimo;
    }).length;
  }

  String _estadoLote(Map<String, Object?> lote) {
    final fecha = DateTime.tryParse(
      lote['fecha_caducidad']?.toString() ?? '',
    );

    if (fecha == null) return 'Fecha no válida';

    final hoy = _soloFecha(DateTime.now());
    final caducidad = _soloFecha(fecha);

    if (caducidad.isBefore(hoy)) return 'Vencido';

    if (!caducidad.isAfter(hoy.add(const Duration(days: 7)))) {
      return 'Próximo a caducar';
    }

    return 'Vigente';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Vencido':
        return Colors.red;
      case 'Próximo a caducar':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _mostrarLotesDelDia(DateTime dia) {
    final lotesDelDia = _eventosDelDia(dia);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Caducidades: ${dia.day}/${dia.month}/${dia.year}',
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ),
          body: lotesDelDia.isEmpty
              ? const Center(
                  child: Text('No hay lotes que caduquen este día.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lotesDelDia.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lote = lotesDelDia[index];
                    final estado = _estadoLote(lote);
                    final cantidad = (lote['cantidad'] as num).toInt();

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.inventory_2,
                          color: _colorEstado(estado),
                        ),
                        title: Text(
                          lote['producto_nombre']?.toString() ??
                              'Producto sin nombre',
                        ),
                        subtitle: Text(
                          'Cantidad: $cantidad ${lote['unidad'] ?? 'unidades'}'
                          '\nTienda: ${lote['tienda_nombre'] ?? 'No especificada'}'
                          '\nEstado: $estado',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.event),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _tarjetaAlerta({
    required String titulo,
    required int cantidad,
    required IconData icono,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icono, color: color),
        ),
        title: Text(titulo),
        trailing: Text(
          '$cantidad',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendario y alertas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendario y alertas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() => _cargando = true);
                    _cargarDatos();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario y alertas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() => _cargando = true);
              _cargarDatos();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              'Resumen del inventario',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _tarjetaAlerta(
              titulo: 'Lotes vencidos',
              cantidad: _cantidadVencidos,
              icono: Icons.warning_amber,
              color: Colors.red,
            ),
            _tarjetaAlerta(
              titulo: 'Próximos a caducar (7 días)',
              cantidad: _cantidadProximosAVencer,
              icono: Icons.event_busy,
              color: Colors.orange,
            ),
            _tarjetaAlerta(
              titulo: 'Productos sin stock disponible',
              cantidad: _cantidadSinStock,
              icono: Icons.remove_shopping_cart,
              color: Colors.red,
            ),
            _tarjetaAlerta(
              titulo: 'Productos con stock bajo',
              cantidad: _cantidadStockBajo,
              icono: Icons.inventory,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 16),
            Text(
              'Calendario de caducidades',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TableCalendar<Map<String, Object?>>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _diaEnfocado,
                  selectedDayPredicate: (dia) =>
                      isSameDay(_diaSeleccionado, dia),
                  eventLoader: _eventosDelDia,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  onPageChanged: (dia) {
                    _diaEnfocado = dia;
                  },
                  onDaySelected: (seleccionado, enfocado) {
                    setState(() {
                      _diaSeleccionado = seleccionado;
                      _diaEnfocado = enfocado;
                    });
                    _mostrarLotesDelDia(seleccionado);
                  },
                  calendarStyle: const CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blueGrey,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca un día para consultar los lotes que caducan en esa fecha. '
              'Los puntos naranjas indican que hay lotes registrados.',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

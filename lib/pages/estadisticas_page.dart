import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/estadisticas_repository.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  final EstadisticasRepository _repository = EstadisticasRepository();

  Map<String, Object?> _resumen = {};
  List<Map<String, Object?>> _gastosPorTienda = [];
  List<Map<String, Object?>> _caducidades = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final resumen = await _repository.obtenerResumen();
      final gastos = await _repository.obtenerGastosPorTienda();
      final caducidades =
          await _repository.obtenerProximasCaducidades();

      if (!mounted) return;

      setState(() {
        _resumen = resumen;
        _gastosPorTienda = gastos;
        _caducidades = caducidades;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar las estadísticas: $e';
      });
    }
  }

  int _numero(String clave) {
    return (_resumen[clave] as num?)?.toInt() ?? 0;
  }

  double _decimal(String clave) {
    return (_resumen[clave] as num?)?.toDouble() ?? 0;
  }

  String _formatearFecha(String texto) {
    final fecha = DateTime.tryParse(texto);
    if (fecha == null) return texto;

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  Widget _tarjetaIndicador({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirGrafica() {
    final datos = _gastosPorTienda
        .where((fila) => (fila['total_gastado'] as num).toDouble() > 0)
        .take(8)
        .toList();

    if (datos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'Todavía no hay compras registradas para mostrar.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maximo = datos
        .map((fila) => (fila['total_gastado'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          maxY: maximo == 0 ? 10 : maximo * 1.2,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (grupo, grupoIndex, rod, rodIndex) {
                final nombre =
                    datos[grupo.x]['tienda_nombre']?.toString() ?? 'Tienda';
                return BarTooltipItem(
                  '$nombre\n\$${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (valor, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      valor >= 1000
                          ? '\$${(valor / 1000).toStringAsFixed(1)}k'
                          : '\$${valor.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (valor, meta) {
                  final indice = valor.toInt();

                  if (indice < 0 || indice >= datos.length) {
                    return const SizedBox.shrink();
                  }

                  final nombre =
                      datos[indice]['tienda_nombre']?.toString() ?? 'Tienda';
                  final etiqueta = nombre.length > 9
                      ? '${nombre.substring(0, 8)}…'
                      : nombre;

                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: SizedBox(
                      width: 62,
                      child: Text(
                        etiqueta,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < datos.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (datos[i]['total_gastado'] as num).toDouble(),
                    width: 22,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')),
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
        title: const Text('Estadísticas del inventario'),
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
              'Resumen general',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _tarjetaIndicador(
              titulo: 'Productos registrados',
              valor: '${_numero('productos')}',
              icono: Icons.inventory_2,
              color: Colors.blue,
            ),
            _tarjetaIndicador(
              titulo: 'Unidades disponibles',
              valor: '${_numero('unidades')}',
              icono: Icons.warehouse,
              color: Colors.green,
            ),
            _tarjetaIndicador(
              titulo: 'Gasto acumulado',
              valor: '\$${_decimal('gastos').toStringAsFixed(2)}',
              icono: Icons.payments,
              color: Colors.purple,
            ),
            _tarjetaIndicador(
              titulo: 'Productos con stock bajo',
              valor: '${_numero('stock_bajo')}',
              icono: Icons.warning_amber,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 20),
            Text(
              'Gasto acumulado por tienda',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: _construirGrafica(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Próximas caducidades',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_caducidades.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay lotes por caducar en los próximos 30 días.',
                  ),
                ),
              )
            else
              ..._caducidades.map((lote) {
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.event,
                      color: Colors.orange,
                    ),
                    title: Text(
                      lote['producto_nombre']?.toString() ?? 'Producto',
                    ),
                    subtitle: Text(
                      'Caduca: ${_formatearFecha(lote['fecha_caducidad'].toString())}'
                      '\nTienda: ${lote['tienda_nombre'] ?? 'No especificada'}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      '${(lote['cantidad'] as num).toInt()} '
                      '${lote['unidad'] ?? 'unidades'}',
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

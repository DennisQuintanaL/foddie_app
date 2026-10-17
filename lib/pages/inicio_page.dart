
import 'dart:io';

import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

import '../data/alerta_repository.dart';
import '../data/carrito_repository.dart';
import '../data/notificaciones_service.dart';
import 'calendario_page.dart';
import 'carrito_page.dart';
import 'categorias_page.dart';
import 'consumo_page.dart';
import 'estadisticas_page.dart';
import 'historial_compras_page.dart';
import 'lotes_page.dart';
import 'productos_page.dart';
import 'tiendas_page.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final AlertaRepository _alertasRepository = AlertaRepository();
  final CarritoRepository _carritoRepository = CarritoRepository();

  List<Map<String, Object?>> _productosConAlertas = [];
  int _cantidadCarrito = 0;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _actualizarNotificaciones();
  }

  Future<void> _cargarDatos() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final productos = await _alertasRepository.obtenerProductosConAlertas();
      final cantidad = await _carritoRepository.obtenerCantidadTotal();

      if (!mounted) return;

      setState(() {
        _productosConAlertas = productos;
        _cantidadCarrito = cantidad;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo cargar el inventario.';
        _cargando = false;
      });

      debugPrint('Error al cargar el inicio: $e');
    }
  }

  Future<void> _actualizarNotificaciones() async {
    final resultado =
        await NotificacionesService.instance.actualizarAlertasSeguro();

    if (!resultado) {
      debugPrint('No se pudieron actualizar las notificaciones.');
    }
  }

  Future<void> _probarNotificaciones() async {
    try {
      await NotificacionesService.instance.mostrarNotificacionPrueba();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se solicitó una notificación de prueba.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo mostrar la notificación: $e'),
        ),
      );
    }
  }

  Future<void> _abrirPagina(Widget pagina) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => pagina),
    );

    if (!mounted) return;

    await _cargarDatos();
    await _actualizarNotificaciones();
  }

  int _numero(Map<String, Object?> producto, String campo) {
    return (producto[campo] as num?)?.toInt() ?? 0;
  }

  String _texto(Map<String, Object?> producto, String campo) {
    return producto[campo]?.toString() ?? '';
  }

  int get _caducados {
    return _productosConAlertas.where((p) {
      return _numero(p, 'stock_caducado') > 0;
    }).length;
  }

  int get _sinExistencias {
    return _productosConAlertas.where((p) {
      return _numero(p, 'stock_disponible') == 0;
    }).length;
  }

  int get _proximosACaducar {
    return _productosConAlertas.where((p) {
      final fecha = p['proxima_caducidad'];
      return fecha != null && fecha.toString().isNotEmpty;
    }).length;
  }

  int get _stockBajo {
    return _productosConAlertas.where((p) {
      final stock = _numero(p, 'stock_disponible');
      final minimo = _numero(p, 'stock_minimo');

      return stock > 0 && stock <= minimo;
    }).length;
  }

  String _estadoProducto(Map<String, Object?> producto) {
    final stock = _numero(producto, 'stock_disponible');
    final minimo = _numero(producto, 'stock_minimo');
    final caducado = _numero(producto, 'stock_caducado');
    final proximaCaducidad = producto['proxima_caducidad'];

    if (caducado > 0) {
      return 'Tiene productos caducados';
    }

    if (stock == 0) {
      return 'Sin existencias';
    }

    if (proximaCaducidad != null) {
      return 'Próximo a caducar: ${proximaCaducidad.toString()}';
    }

    if (stock <= minimo) {
      return 'Stock bajo';
    }

    return 'Revisar inventario';
  }

  Color _colorEstado(Map<String, Object?> producto) {
    final stock = _numero(producto, 'stock_disponible');
    final minimo = _numero(producto, 'stock_minimo');
    final caducado = _numero(producto, 'stock_caducado');

    if (caducado > 0 || stock == 0) {
      return Colors.red;
    }

    if (producto['proxima_caducidad'] != null) {
      return Colors.orange;
    }

    if (stock <= minimo) {
      return Colors.amber.shade800;
    }

    return Colors.blueGrey;
  }

  Widget _imagenProducto(Map<String, Object?> producto) {
    final ruta = producto['imagen_path']?.toString();

    if (ruta != null && ruta.isNotEmpty && File(ruta).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(ruta),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _imagenPredeterminada(),
        ),
      );
    }

    return _imagenPredeterminada();
  }

  Widget _imagenPredeterminada() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.inventory_2_outlined, size: 30),
    );
  }

  Widget _tarjetaResumen({
    required String titulo,
    required int cantidad,
    required IconData icono,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              cantidad.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(titulo),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAlerta(Map<String, Object?> producto) {
    final color = _colorEstado(producto);
    final stock = _numero(producto, 'stock_disponible');
    final unidad = _texto(producto, 'unidad');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _imagenProducto(producto),
        title: Text(
          _texto(producto, 'producto_nombre'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Existencias disponibles: $stock $unidad'),
              const SizedBox(height: 5),
              Text(
                _estadoProducto(producto),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Agregar a la lista de compras',
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () async {
            final id = producto['producto_id'];

            if (id is! num) return;

            try {
              await _carritoRepository.agregarProducto(id.toInt());

              if (!mounted) return;

              await _cargarDatos();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto agregado a la lista de compras.'),
                ),
              );
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No se pudo agregar el producto: $e'),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _tarjetaNavegacion({
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Widget pagina,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icono),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _abrirPagina(pagina),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario doméstico'),
        actions: [
          badges.Badge(
            showBadge: _cantidadCarrito > 0,
            badgeContent: Text(
              _cantidadCarrito > 99 ? '99+' : '$_cantidadCarrito',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
            child: IconButton(
              tooltip: 'Lista de compras',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => _abrirPagina(const CarritoPage()),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido!',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consulta tus existencias y mantén tus productos bajo control.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Resumen del inventario',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            if (_cargando)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(_error!),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _cargarDatos,
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.45,
                  ),
                  delegate: SliverChildListDelegate([
                    _tarjetaResumen(
                      titulo: 'Caducados',
                      cantidad: _caducados,
                      icono: Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                    _tarjetaResumen(
                      titulo: 'Sin existencias',
                      cantidad: _sinExistencias,
                      icono: Icons.remove_shopping_cart,
                      color: Colors.deepOrange,
                    ),
                    _tarjetaResumen(
                      titulo: 'Por caducar',
                      cantidad: _proximosACaducar,
                      icono: Icons.event_busy,
                      color: Colors.orange,
                    ),
                    _tarjetaResumen(
                      titulo: 'Stock bajo',
                      cantidad: _stockBajo,
                      icono: Icons.inventory,
                      color: Colors.amber.shade800,
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Productos que requieren atención',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: _cargarDatos,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
              if (_productosConAlertas.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green,
                        ),
                        SizedBox(height: 8),
                        Text('No hay alertas en tu inventario.'),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _tarjetaAlerta(_productosConAlertas[index]),
                      childCount: _productosConAlertas.length,
                    ),
                  ),
                ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Administración',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _tarjetaNavegacion(
                    titulo: 'Productos',
                    descripcion: 'Registrar y editar productos',
                    icono: Icons.inventory_2_outlined,
                    pagina: const ProductosPage(),
                  ),
                  _tarjetaNavegacion(
                    titulo: 'Categorías',
                    descripcion: 'Organizar productos por categoría',
                    icono: Icons.category_outlined,
                    pagina: const CategoriasPage(),
                  ),
                  _tarjetaNavegacion(
                    titulo: 'Tiendas',
                    descripcion: 'Administrar establecimientos',
                    icono: Icons.store_outlined,
                    pagina: const TiendasPage(),
                  ),
                  _tarjetaNavegacion(
                    titulo: 'Lotes y caducidades',
                    descripcion: 'Registrar cantidades y fechas de vencimiento',
                    icono: Icons.calendar_month_outlined,
                    pagina: const LotesPage(),
                  ),
                  _tarjetaNavegacion(
                    titulo: 'Consumo',
                    descripcion: 'Registrar consumo de productos',
                    icono: Icons.restaurant_outlined,
                    pagina: const ConsumoPage(),
                  ),
                  _tarjetaNavegacion(
                    titulo: 'Calendario',
                    descripcion: 'Consultar las fechas de caducidad',
                    icono: Icons.calendar_today_outlined,
                    pagina: const CalendarioPage(),
                  ),
                  _tarjetaNavegacion(
                    titulo: 'Historial de compras',
                    descripcion: 'Consultar compras anteriores',
                    icono: Icons.receipt_long_outlined,
                    pagina: const HistorialComprasPage(),
                  ),
                  _tarjetaNavegacion(
                    titulo: 'Estadísticas',
                    descripcion: 'Visualizar estadísticas del inventario',
                    icono: Icons.bar_chart_outlined,
                    pagina: const EstadisticasPage(),
                  ),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.notifications_active_outlined),
                      ),
                      title: const Text('Probar notificaciones'),
                      subtitle: const Text(
                        'Comprobar las notificaciones del dispositivo',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _probarNotificaciones,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

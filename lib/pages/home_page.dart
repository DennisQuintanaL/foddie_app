import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import '../components/food_tile.dart';
import '../models/status_articulo.dart';
import 'cart_page.dart';
import 'calendario_page.dart';
import 'add_producto_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int cantidadCarrito = 0;
  int _vistaSeleccionada = 0; // 0: Lista, 1: Calendario

  // Datos mock para pruebas visuales en Fase 1
  final List<Map<String, dynamic>> articulosAlertas = [
    {
      'nombre': 'Leche Entera',
      'imagen': null,
      'cantidad': 1,
      'unidad': 'litro',
      'fecha': DateTime.now().add(const Duration(days: 1)),
      'estatus': EstatusArticulo.porCaducar
    },
    {
      'nombre': 'Huevos',
      'imagen': null,
      'cantidad': 0,
      'unidad': 'pieza',
      'fecha': DateTime.now().subtract(const Duration(days: 2)),
      'estatus': EstatusArticulo.sinExistencia
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Alacena'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: badges.Badge(
              badgeContent: Text(
                '$cantidadCarrito',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              showBadge: cantidadCarrito > 0,
              badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  ).then((_) => setState(() {}));
                },
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Selector de Vista
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Alertas'), icon: Icon(Icons.list)),
                ButtonSegment(value: 1, label: Text('Calendario'), icon: Icon(Icons.calendar_month)),
              ],
              selected: {_vistaSeleccionada},
              onSelectionChanged: (set) {
                setState(() => _vistaSeleccionada = set.first);
              },
            ),
          ),
          Expanded(
            child: _vistaSeleccionada == 0
                ? ListView.builder(
                    itemCount: articulosAlertas.length,
                    itemBuilder: (context, index) {
                      final item = articulosAlertas[index];
                      return FoodTile(
                        nombre: item['nombre'],
                        imagenPath: item['imagen'],
                        cantidad: item['cantidad'],
                        unidad: item['unidad'],
                        fechaCaducidad: item['fecha'],
                        estatus: item['estatus'],
                        onAgregarCarrito: () {
                          setState(() => cantidadCarrito++);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item['nombre']} añadido al carrito')),
                          );
                        },
                      );
                    },
                  )
                : const CalendarioPage(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductoPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
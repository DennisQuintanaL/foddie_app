import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/food.dart';
import '../components/food_tile.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  void addFoodToCart(BuildContext context, Food food) {
    Provider.of<Cart>(context, listen: false).addItemToCart(food);

    // Reemplazo moderno de AlertDialog por SnackBar no intrusivo
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡${food.name} agregado al pedido!'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, value, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Buscar platillo o bebida...', style: TextStyle(color: Colors.grey)),
                Icon(Icons.search, color: Colors.grey),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 25.0, top: 20.0, bottom: 10.0),
            child: Text(
              'Platillos Destacados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),

          // Lista horizontal de alimentos
          Expanded(
            child: ListView.builder(
              itemCount: value.foodMenu.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                Food food = value.foodMenu[index];
                return FoodTile(food: food, onTap: () => addFoodToCart(context, food));
              },
            ),
          ),
        ],
      ),
    );
  }
}
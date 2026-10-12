import 'package:flutter/material.dart';
import 'food.dart';

class Cart extends ChangeNotifier {
  // Catálogo de alimentos disponible
  final List<Food> _foodMenu = [
    Food(
      name: 'Guacamole Crunch King',
      price: '139.00',
      imagePath: 'assets/images/burger.png',
      description: 'Guacamole Crunch King , Pidela en Combo con papas y refresco.',
      category: 'Platillo',
    ),
    Food(
      name: 'Pizza de Pepperoni',
      price: '189.00',
      imagePath: 'assets/images/pizza.png',
      description: 'Masa artesanal al horno con queso mozzarella y extra pepperoni, un clásico favorito.',
      category: 'Platillo',
    ),
    Food(
      name: 'Tacos al Pastor (5 pzs)',
      price: '75.00',
      imagePath: 'assets/images/tacos.png',
      description: 'Tacos al Pastor (5 pzs) Servidos con piña, cilantro, cebolla y salsa.',
      category: 'Platillo',
    ),
    Food(
      name: 'Malteada de Chocolate',
      price: '65.00',
      imagePath: 'assets/images/meal.png',
      description: 'Una malteada base de leche con chocolate y un topping de crema batida.',
      category: 'Bebida',
    ),
  ];

  // Carrito del usuario
  final List<Food> _userCart = [];

  List<Food> get foodMenu => _foodMenu;
  List<Food> get userCart => _userCart;

  void addItemToCart(Food food) {
    _userCart.add(food);
    notifyListeners();
  }

  void removeItemFromCart(Food food) {
    _userCart.remove(food);
    notifyListeners();
  }

  // Cálculo dinámico del total
  double calculateTotal() {
    double total = 0.0;
    for (var item in _userCart) {
      total += double.tryParse(item.price) ?? 0.0;
    }
    return total;
  }
}
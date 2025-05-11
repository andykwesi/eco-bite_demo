import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientListItem extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback? onTap;

  const IngredientListItem({super.key, required this.ingredient, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant, color: Colors.brown, size: 20),
      ),
      title: Text(
        ingredient.name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle:
          ingredient.expiryDate != null
              ? Text(
                ingredient.expiryStatus,
                style: TextStyle(
                  color:
                      ingredient.isExpired
                          ? Colors.red
                          : ingredient.isExpiring
                          ? Colors.orange
                          : Colors.grey,
                  fontSize: 12,
                ),
              )
              : ingredient.quantity != null
              ? Text(
                '${ingredient.quantity} ${ingredient.unit ?? ''}',
                style: const TextStyle(fontSize: 12),
              )
              : null,
      trailing:
          ingredient.isExpired || ingredient.isExpiring
              ? Icon(
                Icons.warning,
                color: ingredient.isExpired ? Colors.red : Colors.orange,
                size: 20,
              )
              : null,
      onTap: onTap,
    );
  }
}

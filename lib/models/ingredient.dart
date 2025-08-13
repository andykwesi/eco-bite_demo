class Ingredient {
  final String name;
  final bool isOwned;
  final String? icon;
  final DateTime? expiryDate;
  final double? quantity;
  final String? unit;

  Ingredient({
    required this.name,
    this.isOwned = false,
    this.icon,
    this.expiryDate,
    this.quantity,
    this.unit,
  }) {
    // Debug logging
    print('DEBUG: Creating Ingredient: $name');
    print('DEBUG: - Is owned: $isOwned');
    print('DEBUG: - Quantity: $quantity');
    print('DEBUG: - Unit: $unit');
    print('DEBUG: - Expiry date: $expiryDate');
  }

  bool get isExpiring {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  String get expiryStatus {
    if (expiryDate == null) return "No expiry date";
    if (isExpired) return "Expired";

    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    if (daysUntilExpiry == 0) return "Expires today";
    if (daysUntilExpiry == 1) return "Expires tomorrow";
    if (isExpiring) return "Expires in $daysUntilExpiry days";
    return "Expires in $daysUntilExpiry days";
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    try {
      print('DEBUG: Creating Ingredient from map: ${map['name']}');

      final ingredient = Ingredient(
        name: map['name'] ?? 'Unknown Ingredient',
        isOwned: map['isOwned'] ?? false,
        icon: map['icon'],
        expiryDate:
            map['expiryDate'] != null
                ? DateTime.tryParse(map['expiryDate'])
                : null,
        quantity:
            map['quantity'] != null
                ? (map['quantity'] as num).toDouble()
                : null,
        unit: map['unit'],
      );

      print('DEBUG: Ingredient created successfully: ${ingredient.name}');
      return ingredient;
    } catch (e, stackTrace) {
      print('DEBUG: Error creating Ingredient from map: $e');
      print('DEBUG: Stack trace: $stackTrace');
      print('DEBUG: Map data: $map');

      // Return a default ingredient to prevent crashes
      return Ingredient(
        name: map['name'] ?? 'Error Ingredient',
        isOwned: false,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isOwned': isOwned,
      'icon': icon,
      'expiryDate': expiryDate?.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
    };
  }
}

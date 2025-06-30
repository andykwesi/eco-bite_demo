import 'dart:async';
import 'dart:convert';
import '../models/ingredient.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeService {
  // Singleton pattern
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  // In a real app, this would connect to an API like Open Food Facts
  // Here we're using a mock database
  final Map<String, Map<String, dynamic>> _mockProductDatabase = {
    '123456789012': {
      'name': 'Organic Milk',
      'quantity': 1.0,
      'unit': 'L',
      'category': 'Dairy',
    },
    '987654321098': {
      'name': 'Whole Wheat Bread',
      'quantity': 500.0,
      'unit': 'g',
      'category': 'Bakery',
    },
    '456789123456': {
      'name': 'Free Range Eggs',
      'quantity': 12.0,
      'unit': 'pcs',
      'category': 'Dairy',
    },
  };

  // Mock scan function - in a real app, this would use the device camera
  Future<String?> scanBarcode() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      // Optionally show a dialog or message to the user
      return null;
    }
    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 1));
    // Return a random barcode from the mock database
    final codes = _mockProductDatabase.keys.toList();
    if (codes.isEmpty) return null;
    return codes[DateTime.now().millisecond % codes.length];
  }

  // Look up product info from barcode
  Future<Ingredient?> getProductFromBarcode(String barcode) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    final productData = _mockProductDatabase[barcode];
    if (productData == null) return null;

    return Ingredient(
      name: productData['name'],
      quantity: productData['quantity'],
      unit: productData['unit'],
      isOwned: true,
      // Default expiry date is 7 days from now, but would be user input in real app
      expiryDate: DateTime.now().add(const Duration(days: 7)),
    );
  }
}

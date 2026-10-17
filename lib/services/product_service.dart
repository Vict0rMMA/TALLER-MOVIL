import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ProductService {
  final String baseUrl;

  ProductService(this.baseUrl);

  Future<List<Product>> getProducts() async {
    final http.Response response;

    try {
      response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder');
    } catch (_) {
      // Sin internet, DNS que no resuelve, conexión rechazada, etc.
      throw const ApiException('No hay conexión. Revisa tu internet');
    }

    if (response.statusCode == 404) {
      throw const ApiException('No se encontró el catálogo de productos');
    }

    if (response.statusCode == 500) {
      throw const ApiException('El servidor no está disponible');
    }

    if (response.statusCode != 200) {
      throw ApiException('Error HTTP ${response.statusCode}');
    }

    try {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } on FormatException {
      throw const ApiException('La respuesta no tiene el formato esperado');
    } on TypeError {
      throw const ApiException('La respuesta no tiene el formato esperado');
    }
  }
}

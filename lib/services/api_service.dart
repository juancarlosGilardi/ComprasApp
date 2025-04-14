import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:compras_app/models/invoice_model.dart';

class ApiService {
  // Configuración de URL base - Ahora con HTTP en lugar de HTTPS
  final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL', 
    defaultValue: 'http://192.64.87.241:8000'  // URL actualizada
  );
  
  final Duration timeout = const Duration(seconds: 30);

  // Método para obtener headers con posible token de autenticación
  Future<Map<String, String>> get _headersWithAuth async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Agregar token de autenticación según el ejemplo de curl
    headers['Authorization'] = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyMTQiLCJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dzLzIwMDgvMDYvaWRlbnRpdHkvY2xhaW1zL3JvbGUiOiJjb25zdWx0b3IifQ.grbpaoN69YUQ-k3zluHeqcUwd0TPVL8Ok5X_VetSD1Y';

    return headers;
  }

  Future<InvoiceData> fetchInvoiceData({
    required String ruc,
    required String tipo,
    required String serie,
    required String numero,
  }) async {
    try {
      // La ruta de la API según el ejemplo de curl
      final url = Uri.parse('$baseUrl/factura');
      
      final body = jsonEncode({
        'ruc': ruc.trim(),
        'tipo': tipo.trim(),        // Cambio de 'tipoDocumento' a 'tipo' según el ejemplo
        'serie': serie.trim(),
        'numero': numero.trim(),
        'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyMTQiLCJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dzLzIwMDgvMDYvaWRlbnRpdHkvY2xhaW1zL3JvbGUiOiJjb25zdWx0b3IifQ.grbpaoN69YUQ-k3zluHeqcUwd0TPVL8Ok5X_VetSD1Y' // Token según el ejemplo
      });
      
      // Usar headers con autenticación
      final headers = await _headersWithAuth;
      
      // Logging para depuración
      if (kDebugMode) {
        debugPrint('Request URL: $url');
        debugPrint('Request Body: $body');
        debugPrint('Request Headers: $headers');
      }
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(timeout);
      
      // Logging para debug
      if (kDebugMode) {
        debugPrint('Response Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Usar compute para parsing en background
        return await compute(invoiceDataFromJson, response.body);
      } else {
        // Intentar parsear mensaje de error del servidor si está disponible
        final errorMessage = _parseErrorResponse(response);
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No se puede establecer conexión con el servidor');
    } on HttpException {
      throw Exception('Error HTTP: Verifique la URL');
    } on TimeoutException {
      throw Exception('La solicitud ha excedido el tiempo de espera');
    } catch (e) {
      // Logging de errores no esperados
      debugPrint('Error inesperado: $e');
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  // Método para parsear mensajes de error del servidor
  String _parseErrorResponse(http.Response response) {
    try {
      final errorBody = json.decode(response.body);
      return errorBody['message'] ?? 
            errorBody['error'] ?? 
            'Error ${response.statusCode}: ${response.reasonPhrase}';
    } catch (_) {
      return 'Error ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}
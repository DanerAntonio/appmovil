import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ventas_informe_model.dart';

class InformeService {
  static Future<List<VentaResumen>> obtenerInformeDiario(String fechaInicio, String fechaFin, String token) async {
    final response = await http.get(
      Uri.parse('\${ApiConstants.baseUrl}/sales/ventas/fecha?fechaInicio=\$fechaInicio&fechaFin=\$fechaFin'),
      headers: {
        'Authorization': 'Bearer \$token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => VentaResumen.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener informe de ventas');
    }
  }
}
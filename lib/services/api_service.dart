import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/venta.dart';
import '../models/cita.dart';

class ApiConfig {
  static const Map<String, String> environments = {
    'colegio': 'http://192.168.56.1:3000/api',
    'casa': 'http://192.168.10.69:3000/api',
    'localhost': 'http://localhost:3000/api',
  };

  static const String activeEnvironment = 'colegio';

  static String get baseUrl => environments[activeEnvironment]!;
}

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const int requestTimeout = 30;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal() {
    print('ApiService inicializado con URL base: $baseUrl');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<dynamic> get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.get(
      Uri.parse(url),
      headers: _buildHeaders(token),
    ).timeout(const Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.post(
      Uri.parse(url),
      headers: _buildHeaders(token),
      body: json.encode(data),
    ).timeout(const Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.put(
      Uri.parse(url),
      headers: _buildHeaders(token),
      body: json.encode(data),
    ).timeout(const Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.delete(
      Uri.parse(url),
      headers: _buildHeaders(token),
    ).timeout(const Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, dynamic data) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.patch(
      Uri.parse(url),
      headers: _buildHeaders(token),
      body: json.encode(data),
    ).timeout(const Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Map<String, String> _buildHeaders(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } else {
      try {
        final errorData = json.decode(response.body);
        throw ApiException(
          statusCode: response.statusCode,
          message: errorData['message'] ?? 'Error en la solicitud',
        );
      } catch (_) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Error en la solicitud: ${response.reasonPhrase}',
        );
      }
    }
  }

  ApiException _convertException(dynamic error) {
    if (error is ApiException) return error;
    if (error is http.ClientException) {
      return ApiException(statusCode: 0, message: 'Error de conexión: ${error.message}');
    } else if (error is FormatException) {
      return ApiException(statusCode: 0, message: 'Error de formato: ${error.message}');
    } else {
      return ApiException(statusCode: 0, message: 'Error desconocido: $error');
    }
  }

  // ---------------------------
  // Autenticación
  // ---------------------------
  Future<Map<String, dynamic>> login(String correo, String password) async {
    final data = await post('/auth/login', {
      'correo': correo,
      'password': password,
    });

    if (data['token'] != null) {
      await saveToken(data['token']);
    }

    return data;
  }

  Future<bool> checkAuth() async {
    final token = await getToken();
    if (token == null) return false;
    try {
      await get('/auth/verify');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await post('/auth/logout', {});
    } catch (e) {
      print('Error al cerrar sesión: $e');
    } finally {
      await removeToken();
    }
  }

  // ---------------------------
  // Ventas CON DETALLES COMPLETOS
  // ---------------------------
  Future<List<Venta>> getVentas() async {
    try {
      print('🐾 Obteniendo ventas desde: $baseUrl/sales/ventas');
      final response = await get('/sales/ventas');
      
      if (response == null) {
        print('❌ La respuesta del servidor es nula');
        return [];
      }

      List<dynamic> ventasData;
      if (response is Map && response.containsKey('data')) {
        ventasData = response['data'] as List;
      } else if (response is List) {
        ventasData = response;
      } else {
        print('❌ Formato de respuesta inesperado: $response');
        throw Exception('Formato de respuesta inválido');
      }

      final ventas = <Venta>[];
      for (var item in ventasData) {
        try {
          // Crear venta base
          final venta = Venta.fromJson(item);
          
          // Obtener detalles de productos y servicios
          try {
            final detallesProductos = await getDetallesVenta(venta.id.toString());
            final detallesServicios = await getDetallesServiciosVenta(venta.id.toString());
            
            // Agregar detalles a la venta
            venta.detalles = detallesProductos;
            venta.servicios = detallesServicios;
          } catch (e) {
            print('⚠️ Error obteniendo detalles para venta ${venta.id}: $e');
          }
          
          ventas.add(venta);
        } catch (e) {
          print('⚠️ Error parseando venta: $e');
          print('📄 Item problemático: $item');
        }
      }

      print('✅ Ventas cargadas exitosamente: ${ventas.length}');
      return ventas;
    } catch (e, stackTrace) {
      print('❌ Error en getVentas: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('No se pudieron cargar las ventas. Verifica tu conexión.');
    }
  }

  Future<Venta> getVentaById(String id) async {
    try {
      final ventaId = int.tryParse(id);
      if (ventaId == null || ventaId <= 0) {
        throw Exception('ID de venta inválido: $id');
      }

      print('🐾 Obteniendo venta ID: $id');
      final response = await get('/sales/ventas/$id');
      final venta = Venta.fromJson(response);
      
      // Obtener detalles completos
      try {
        final detallesProductos = await getDetallesVenta(id);
        final detallesServicios = await getDetallesServiciosVenta(id);
        
        venta.detalles = detallesProductos;
        venta.servicios = detallesServicios;
      } catch (e) {
        print('⚠️ Error obteniendo detalles: $e');
      }
      
      return venta;
    } catch (e) {
      print('❌ Error obteniendo venta $id: $e');
      throw Exception('No se pudo cargar el detalle de la venta');
    }
  }

  // ---------------------------
  // Detalles de Ventas (Productos)
  // ---------------------------
  Future<List<DetalleVenta>> getDetallesVenta(String ventaId) async {
    try {
      print('🐾 Obteniendo detalles de productos para venta: $ventaId');
      final response = await get('/sales/ventas/$ventaId/detalles');
      
      if (response is List) {
        return response.map((item) => DetalleVenta.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo detalles de venta $ventaId: $e');
      return [];
    }
  }

  // ---------------------------
  // Detalles de Servicios en Ventas
  // ---------------------------
  Future<List<DetalleServicio>> getDetallesServiciosVenta(String ventaId) async {
    try {
      print('🐾 Obteniendo detalles de servicios para venta: $ventaId');
      final response = await get('/sales/ventas/$ventaId/detalles-servicios');
      
      if (response is List) {
        return response.map((item) => DetalleServicio.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo detalles de servicios $ventaId: $e');
      return [];
    }
  }

  // ---------------------------
  // Cálculo de Métricas MEJORADO
  // ---------------------------
  Future<Map<String, dynamic>> calcularMetricasCompletas() async {
    try {
      print('🐾 Calculando métricas completas...');
      
      final ventas = await getVentas();
      final citas = await getCitas();
      final hoy = DateTime.now();
      final inicioMes = DateTime(hoy.year, hoy.month, 1);
      
      // Métricas de ventas
      double ingresosTotales = 0;
      double ingresosHoy = 0;
      double ingresosMes = 0;
      int ventasCompletadas = 0;
      int productosVendidos = 0;
      int serviciosVendidos = 0;
      
      for (var venta in ventas) {
        if (venta.estado.toLowerCase() == 'efectiva' || venta.estado.toLowerCase() == 'completado') {
          ingresosTotales += venta.total;
          ventasCompletadas++;
          
          // Contar productos y servicios
          if (venta.detalles != null) {
            productosVendidos += venta.detalles!.fold(0, (sum, detalle) => sum + detalle.cantidad);
          }
          if (venta.servicios != null) {
            serviciosVendidos += venta.servicios!.length;
          }
          
          // Ingresos de hoy
          if (venta.fecha.year == hoy.year && 
              venta.fecha.month == hoy.month && 
              venta.fecha.day == hoy.day) {
            ingresosHoy += venta.total;
          }
          
          // Ingresos del mes
          if (venta.fecha.isAfter(inicioMes) || 
              (venta.fecha.year == hoy.year && venta.fecha.month == hoy.month)) {
            ingresosMes += venta.total;
          }
        }
      }
      
      // Métricas de citas
      final citasHoy = citas.where((c) => 
        c.fecha.year == hoy.year && 
        c.fecha.month == hoy.month && 
        c.fecha.day == hoy.day
      ).length;
      
      final citasPendientes = citas.where((c) => 
        c.estado.toLowerCase() == 'programada' || c.estado.toLowerCase() == 'pendiente'
      ).length;
      
      final citasCompletadas = citas.where((c) => 
        c.estado.toLowerCase() == 'completada'
      ).length;
      
      double ingresosCitas = 0;
      for (var cita in citas.where((c) => c.estado.toLowerCase() == 'completada')) {
        ingresosCitas += cita.getPrecioTotal() ?? 0;
      }
      
      final metricas = {
        // Ventas
        'total_ventas': ventas.length,
        'ventas_completadas': ventasCompletadas,
        'ingresos_totales': ingresosTotales,
        'ingresos_hoy': ingresosHoy,
        'ingresos_mes': ingresosMes,
        'ticket_promedio': ventasCompletadas > 0 ? (ingresosTotales / ventasCompletadas) : 0,
        'productos_vendidos': productosVendidos,
        'servicios_vendidos': serviciosVendidos,
        
        // Citas
        'total_citas': citas.length,
        'citas_hoy': citasHoy,
        'citas_pendientes': citasPendientes,
        'citas_completadas': citasCompletadas,
        'ingresos_citas': ingresosCitas,
        
        // Combinado
        'ingresos_totales_combinados': ingresosTotales + ingresosCitas,
        'clientes_atendidos': ventasCompletadas + citasCompletadas,
      };
      
      print('📊 Métricas calculadas: ${metricas}');
      return metricas;
    } catch (e) {
      print('❌ Error calculando métricas: $e');
      return {
        'total_ventas': 0,
        'ventas_completadas': 0,
        'ingresos_totales': 0.0,
        'ingresos_hoy': 0.0,
        'ingresos_mes': 0.0,
        'ticket_promedio': 0.0,
        'productos_vendidos': 0,
        'servicios_vendidos': 0,
        'total_citas': 0,
        'citas_hoy': 0,
        'citas_pendientes': 0,
        'citas_completadas': 0,
        'ingresos_citas': 0.0,
        'ingresos_totales_combinados': 0.0,
        'clientes_atendidos': 0,
      };
    }
  }

  Future<List<Venta>> getVentasPorEstado(String estado) async {
    try {
      print('🐾 Obteniendo ventas por estado: $estado');
      final response = await get('/sales/ventas/estado/$estado');
      
      if (response is List) {
        return response.map((json) => Venta.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta inesperado para ventas por estado');
    } catch (e) {
      print('❌ Error en getVentasPorEstado: $e');
      throw Exception('No se pudieron cargar las ventas por estado');
    }
  }

  Future<List<Venta>> getVentasPorFecha(DateTime fecha) async {
    try {
      print('🐾 Obteniendo ventas para filtrar por fecha: ${DateFormat('yyyy-MM-dd').format(fecha)}');
      final todasLasVentas = await getVentas();
      
      final ventasFiltradas = todasLasVentas.where((venta) {
        return venta.fecha.year == fecha.year &&
               venta.fecha.month == fecha.month &&
               venta.fecha.day == fecha.day;
      }).toList();
      
      print('✅ Ventas filtradas por fecha: ${ventasFiltradas.length}');
      return ventasFiltradas;
    } catch (e) {
      print('❌ Error en getVentasPorFecha: $e');
      throw Exception('No se pudieron cargar las ventas por fecha');
    }
  }

  Future<void> cambiarEstadoVenta(String id, String nuevoEstado) async {
    try {
      print('🐾 Cambiando estado de venta $id a: $nuevoEstado');
      await patch('/sales/ventas/$id/status', {'estado': nuevoEstado});
      print('✅ Estado cambiado exitosamente');
    } catch (e) {
      print('❌ Error cambiando estado: $e');
      throw Exception('No se pudo cambiar el estado de la venta');
    }
  }

  Future<Venta> createVenta(Map<String, dynamic> ventaData) async {
    try {
      print('🐾 Creando nueva venta');
      final response = await post('/sales/ventas', ventaData);
      print('✅ Venta creada exitosamente');
      return Venta.fromJson(response);
    } catch (e) {
      print('❌ Error creando venta: $e');
      throw Exception('No se pudo crear la venta');
    }
  }

  

  // ---------------------------
  // Productos bajo stock
  // ---------------------------
  Future<List<Map<String, dynamic>>> getProductosBajoStock() async {
    try {
      final response = await get('/inventory/productos/bajo-stock');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo productos bajo stock: $e');
      return [];
    }
  }

  // ---------------------------
  // Productos más vendidos
  // ---------------------------
  Future<List<Map<String, dynamic>>> getProductosMasVendidos() async {
    try {
      final response = await get('/reports/productos/mas-vendidos');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo productos más vendidos: $e');
      return [];
    }
  }

  // ---------------------------
  // Mascotas
  // ---------------------------
  Future<List<dynamic>> getMascotas() async {
    try {
      print('🐾 Obteniendo mascotas desde: $baseUrl/pets/mascotas');
      final response = await get('/pets/mascotas');
      
      if (response == null) {
        print('❌ La respuesta del servidor es nula para mascotas');
        return [];
      }

      // Manejar diferentes formatos de respuesta
      List<dynamic> mascotasData;
      if (response is Map && response.containsKey('data')) {
        mascotasData = response['data'] as List;
      } else if (response is Map && response.containsKey('mascotas')) {
        mascotasData = response['mascotas'] as List;
      } else if (response is List) {
        mascotasData = response;
      } else {
        print('❌ Formato de respuesta inesperado para mascotas: $response');
        return [];
      }

      print('✅ Mascotas cargadas exitosamente: ${mascotasData.length}');
      return mascotasData;
    } catch (e, stackTrace) {
      print('❌ Error en getMascotas: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  Future<dynamic> getMascotaById(int mascotaId) async {
    try {
      print('🐾 Obteniendo mascota ID: $mascotaId');
      final response = await get('/pets/mascotas/$mascotaId');
      return response;
    } catch (e) {
      print('❌ Error obteniendo mascota $mascotaId: $e');
      throw Exception('No se pudo obtener la mascota');
    }
  }

  // ---------------------------
  // Citas
  // ---------------------------
  Future<List<Cita>> getCitas() async {
    try {
      final response = await get('/appointments/citas');
      if (response is List) {
        return response.map((c) => Cita.fromJson(c)).toList();
      }
      throw ApiException(
        statusCode: 500,
        message: 'Formato de respuesta inesperado para citas'
      );
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<List<Cita>> getCitasPorFecha(String fecha) async {
    try {
      final response = await get('/appointments/citas/fecha/$fecha');
      
      if (response is List) {
        return response.map((c) => Cita.fromJson(c)).toList();
      }
      throw ApiException(
        statusCode: 500,
        message: 'Formato de respuesta inesperado para citas por fecha'
      );
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<List<Cita>> getCitasPorEstado(String estado) async {
    try {
      final response = await get('/appointments/citas/estado/$estado');
      
      if (response is List) {
        return response.map((c) => Cita.fromJson(c)).toList();
      }
      throw ApiException(
        statusCode: 500,
        message: 'Formato de respuesta inesperado para citas por estado'
      );
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<Cita> createCita({
    required String fecha,
    required String hora,
    required int duracion,
    required int mascotaId,
    String notas = '',
    List<int> servicios = const [],
  }) async {
    try {
      final response = await post('/appointments/citas', {
        'fecha': fecha,
        'hora': hora,
        'duracion': duracion,
        'mascotaId': mascotaId,
        'notas': notas,
        'servicios': servicios,
      });
      return Cita.fromJson(response);
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<Cita> getCitaById(int id) async {
    try {
      final response = await get('/appointments/citas/$id');
      return Cita.fromJson(response);
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<void> cambiarEstadoCita(int id, String nuevoEstado) async {
    try {
      await patch('/appointments/citas/$id/status', {
        'estado': nuevoEstado,
      });
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<void> deleteCita(int id) async {
    try {
      await delete('/appointments/citas/$id');
    } catch (e) {
      throw _convertException(e);
    }
  }

  // ---------------------------
  // Servicios
  // ---------------------------
  Future<List<dynamic>> getServicios() async {
    try {
      return await get('/services/servicios') as List;
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<Map<String, dynamic>> getServicioById(int servicioId) async {
    try {
      return await get('/services/servicios/$servicioId') as Map<String, dynamic>;
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<List<dynamic>> searchServicios(String query) async {
    try {
      return await get('/services/servicios/search?q=$query') as List;
    } catch (e) {
      throw _convertException(e);
    }
  }

  // ---------------------------
  // Usuarios
  // ---------------------------
  Future<int> getUserId() async {
    final token = await getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Token JWT inválido');
    
    final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
    return payload['userId'] as int;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userId = await getUserId();
      return await get('/auth/usuarios/$userId') as Map<String, dynamic>;
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final userId = await getUserId();
      await put('/auth/usuarios/$userId', userData);
    } catch (e) {
      throw _convertException(e);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final userId = await getUserId();
      await post('/auth/usuarios/$userId/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      throw _convertException(e);
    }
  }

  // ---------------------------
  // Notificaciones
  // ---------------------------
  Future<int> getUnreadNotificacionesCount() async {
    try {
      final response = await get('/notifications/notificaciones/unread/count');
      return response['count'] as int;
    } catch (e) {
      // Retorna 0 si falla
      return 0;
    }
  }

  Future<List<dynamic>> getNotificaciones() async {
    try {
      return await get('/notifications/notificaciones') as List;
    } catch (e) {
      // Retorna lista vacía si falla
      return [];
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await post('/notifications/notificaciones/mark-all-read', {});
    } catch (e) {
      // Silencia el error
      print('Error marcando notificaciones como leídas: $e');
    }
  }

  Future<void> markNotificationAsRead(int notificacionId) async {
    try {
      await patch('/notifications/notificaciones/$notificacionId/read', {});
    } catch (e) {
      // Silencia el error
      print('Error marcando notificación como leída: $e');
    }
  }

  // ---------------------------
  // Informes y Métricas
  // ---------------------------
  Future<Map<String, dynamic>> getMetricasCitas() async {
    try {
      print('🐾 Obteniendo métricas de citas');
      final response = await get('/reports/citas/metricas');
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      // Calcular métricas localmente si falla
      return await _calcularMetricasCitas();
    } catch (e) {
      print('❌ Error en getMetricasCitas: $e');
      return await _calcularMetricasCitas();
    }
  }

  Future<Map<String, dynamic>> getMetricasVentas() async {
    try {
      print('🐾 Obteniendo métricas de ventas');
      final response = await get('/reports/ventas/metricas');
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      // Calcular métricas localmente si falla
      return await _calcularMetricasVentas();
    } catch (e) {
      print('❌ Error en getMetricasVentas: $e');
      return await _calcularMetricasVentas();
    }
  }

  // Métodos auxiliares para calcular métricas localmente
  Future<Map<String, dynamic>> _calcularMetricasCitas() async {
    try {
      final citas = await getCitas();
      final hoy = DateTime.now();
      final citasHoy = citas.where((c) => 
        c.fecha.year == hoy.year && 
        c.fecha.month == hoy.month && 
        c.fecha.day == hoy.day
      ).toList();
      
      final citasPendientes = citas.where((c) => c.estado == 'Programada').length;
      final citasCompletadas = citas.where((c) => c.estado == 'Completada').length;
      final citasCanceladas = citas.where((c) => c.estado == 'Cancelada').length;
      
      double ingresosCitas = 0;
      for (var cita in citas.where((c) => c.estado == 'Completada')) {
        ingresosCitas += cita.getPrecioTotal() ?? 0;
      }
      
      return {
        'total_citas': citas.length,
        'citas_hoy': citasHoy.length,
        'citas_pendientes': citasPendientes,
        'citas_completadas': citasCompletadas,
        'citas_canceladas': citasCanceladas,
        'ingresos_citas': ingresosCitas,
        'promedio_diario': citas.isNotEmpty ? (citas.length / 30).toDouble() : 0,
      };
    } catch (e) {
      print('❌ Error calculando métricas de citas: $e');
      return {
        'total_citas': 0,
        'citas_hoy': 0,
        'citas_pendientes': 0,
        'citas_completadas': 0,
        'citas_canceladas': 0,
        'ingresos_citas': 0.0,
        'promedio_diario': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> _calcularMetricasVentas() async {
    try {
      final ventas = await getVentas();
      final hoy = DateTime.now();
      final ventasHoy = ventas.where((v) => 
        v.fecha.year == hoy.year && 
        v.fecha.month == hoy.month && 
        v.fecha.day == hoy.day
      ).toList();
      
      double ingresosTotales = 0;
      double ingresosHoy = 0;
      int productosVendidos = 0;
      int serviciosVendidos = 0;
      
      for (var venta in ventas) {
        ingresosTotales += venta.total;
        
        if (venta.fecha.year == hoy.year && 
            venta.fecha.month == hoy.month && 
            venta.fecha.day == hoy.day) {
          ingresosHoy += venta.total;
        }
        
        if (venta.detalles != null) {
          productosVendidos += venta.detalles!.length;
        }
        
        if (venta.servicios != null) {
          serviciosVendidos += venta.servicios!.length;
        }
      }
      
      return {
        'total_ventas': ventas.length,
        'ventas_hoy': ventasHoy.length,
        'ingresos_totales': ingresosTotales,
        'ingresos_hoy': ingresosHoy,
        'ticket_promedio': ventas.isNotEmpty ? (ingresosTotales / ventas.length) : 0,
        'productos_vendidos': productosVendidos,
        'servicios_vendidos': serviciosVendidos,
      };
    } catch (e) {
      print('❌ Error calculando métricas de ventas: $e');
      return {
        'total_ventas': 0,
        'ventas_hoy': 0,
        'ingresos_totales': 0.0,
        'ingresos_hoy': 0.0,
        'ticket_promedio': 0.0,
        'productos_vendidos': 0,
        'servicios_vendidos': 0,
      };
    }
  }

  // ---------------------------
  // Métodos que faltaban para home_screen
  // ---------------------------
  Future<List<dynamic>> getVentasRecientes({int limit = 5}) async {
    try {
      print('🐾 Obteniendo ventas recientes (límite: $limit)');
      
      // Obtener todas las ventas y tomar las más recientes
      final todasLasVentas = await getVentas();
      final ventasOrdenadas = todasLasVentas.toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      
      return ventasOrdenadas.take(limit).map((venta) => {
        'id': venta.id,
        'cliente': venta.cliente ?? 'Cliente',
        'fecha': venta.fecha.toIso8601String(),
        'total': venta.total,
        'estado': venta.estado,
      }).toList();
    } catch (e) {
      print('❌ Error en getVentasRecientes: $e');
      return [];
    }
  }

  Future<List<dynamic>> getCitasRecientes({int limit = 5}) async {
    try {
      print('🐾 Obteniendo citas recientes (límite: $limit)');
      
      // Obtener todas las citas y tomar las más recientes
      final todasLasCitas = await getCitas();
      final citasOrdenadas = todasLasCitas.toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      
      return citasOrdenadas.take(limit).map((cita) => {
        'id': cita.id,
        'mascota': cita.mascota?.nombre ?? 'Mascota',
        'fecha': cita.fecha.toIso8601String(),
        'estado': cita.estado,
        'hora': cita.hora,
      }).toList();
    } catch (e) {
      print('❌ Error en getCitasRecientes: $e');
      return [];
    }
  }

  // ---------------------------
  // Métodos para notificaciones de stock
  // ---------------------------
  Future<List<dynamic>> getNotificacionesStock() async {
    try {
      print('🐾 Obteniendo notificaciones de stock');
      final response = await get('/inventory/stock/notifications');
      
      if (response is List) {
        return response;
      } else if (response is Map && response.containsKey('data')) {
        return response['data'] as List;
      }
      
      // Si no hay endpoint específico, generar notificaciones de prueba
      return _getNotificacionesStockPrueba();
    } catch (e) {
      print('❌ Error en getNotificacionesStock: $e');
      return _getNotificacionesStockPrueba();
    }
  }

  Future<List<dynamic>> getProductosProximosVencer() async {
    try {
      print('🐾 Obteniendo productos próximos a vencer');
      final response = await get('/inventory/productos/proximos-vencer');
      
      if (response is List) {
        return response;
      } else if (response is Map && response.containsKey('data')) {
        return response['data'] as List;
      }
      
      return _getProductosProximosVencerPrueba();
    } catch (e) {
      print('❌ Error en getProductosProximosVencer: $e');
      return _getProductosProximosVencerPrueba();
    }
  }

  Future<List<dynamic>> getProductosStockBajo() async {
    try {
      print('🐾 Obteniendo productos con stock bajo');
      final response = await get('/inventory/productos/stock-bajo');
      
      if (response is List) {
        return response;
      } else if (response is Map && response.containsKey('data')) {
        return response['data'] as List;
      }
      
      return _getProductosStockBajoPrueba();
    } catch (e) {
      print('❌ Error en getProductosStockBajo: $e');
      return _getProductosStockBajoPrueba();
    }
  }

  // ---------------------------
  // Datos de prueba para notificaciones de stock
  // ---------------------------
  List<dynamic> _getNotificacionesStockPrueba() {
    return [
      {
        'id_notificacion': 100,
        'tipo_notificacion': 'Stock',
        'titulo': 'Stock bajo: Alimento Premium Gatos',
        'mensaje': 'Quedan solo 5 unidades de Alimento Premium Gatos. Es recomendable realizar un nuevo pedido.',
        'prioridad': 'Alta',
        'estado': 'Pendiente',
        'fecha_creacion': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'tabla_referencia': 'productos',
        'id_referencia': 1,
      },
      {
        'id_notificacion': 101,
        'tipo_notificacion': 'Vencimiento',
        'titulo': 'Producto próximo a vencer',
        'mensaje': 'El lote de Antibiótico para perros vence en 7 días (${DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 7)))})',
        'prioridad': 'Media',
        'estado': 'Pendiente',
        'fecha_creacion': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'tabla_referencia': 'productos',
        'id_referencia': 2,
      },
      {
        'id_notificacion': 102,
        'tipo_notificacion': 'Stock',
        'titulo': 'Stock crítico: Vacuna Antirrábica',
        'mensaje': 'Solo quedan 2 dosis de Vacuna Antirrábica. Stock crítico.',
        'prioridad': 'Alta',
        'estado': 'Pendiente',
        'fecha_creacion': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        'tabla_referencia': 'productos',
        'id_referencia': 3,
      },
    ];
  }

  List<dynamic> _getProductosProximosVencerPrueba() {
    return [
      {
        'id': 1,
        'nombre': 'Antibiótico para perros',
        'lote': 'AB2024001',
        'fecha_vencimiento': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'cantidad': 15,
        'dias_restantes': 7,
      },
      {
        'id': 2,
        'nombre': 'Vitaminas para gatos',
        'lote': 'VIT2024002',
        'fecha_vencimiento': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'cantidad': 8,
        'dias_restantes': 14,
      },
    ];
  }

  List<dynamic> _getProductosStockBajoPrueba() {
    return [
      {
        'id': 1,
        'nombre': 'Alimento Premium Gatos',
        'stock_actual': 5,
        'stock_minimo': 10,
        'categoria': 'Alimentos',
        'precio': 35000.0,
      },
      {
        'id': 2,
        'nombre': 'Vacuna Antirrábica',
        'stock_actual': 2,
        'stock_minimo': 5,
        'categoria': 'Medicamentos',
        'precio': 45000.0,
      },
    ];
  }

  // ---------------------------
  // Método para crear notificaciones automáticas
  // ---------------------------
  Future<void> crearNotificacionesAutomaticas() async {
    try {
      print('🐾 Creando notificaciones automáticas de stock');
      
      // Obtener productos con stock bajo
      final productosStockBajo = await getProductosStockBajo();
      
      for (var producto in productosStockBajo) {
        await post('/notifications/notificaciones', {
          'tipo_notificacion': 'Stock',
          'titulo': 'Stock bajo: ${producto['nombre']}',
          'mensaje': 'Quedan solo ${producto['stock_actual']} unidades de ${producto['nombre']}. Stock mínimo: ${producto['stock_minimo']}',
          'prioridad': producto['stock_actual'] <= 2 ? 'Alta' : 'Media',
          'tabla_referencia': 'productos',
          'id_referencia': producto['id'],
        });
      }
      
      print('✅ Notificaciones automáticas creadas');
    } catch (e) {
      print('❌ Error creando notificaciones automáticas: $e');
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $message (status code: $statusCode)';
}

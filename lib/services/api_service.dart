// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
    ).timeout(Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.post(
      Uri.parse(url),
      headers: _buildHeaders(token),
      body: json.encode(data),
    ).timeout(Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.put(
      Uri.parse(url),
      headers: _buildHeaders(token),
      body: json.encode(data),
    ).timeout(Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.delete(
      Uri.parse(url),
      headers: _buildHeaders(token),
    ).timeout(Duration(seconds: requestTimeout));

    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, dynamic data) async {
    final url = '$baseUrl$endpoint';
    final token = await getToken();

    final response = await http.patch(
      Uri.parse(url),
      headers: _buildHeaders(token),
      body: json.encode(data),
    ).timeout(Duration(seconds: requestTimeout));

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
  // Ventas
  // ---------------------------
  Future<List<dynamic>> getVentas() async {
    try {
      return await get('/ventas') as List;
    } catch (_) {
      try {
        return await get('/sales/ventas') as List;
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se pudieron obtener las ventas.');
      }
    }
  }

  Future<Map<String, dynamic>> getVentaById(int id) async {
    try {
      return await get('/ventas/$id') as Map<String, dynamic>;
    } catch (_) {
      try {
        return await get('/sales/ventas/$id') as Map<String, dynamic>;
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se encontró la venta con ID $id.');
      }
    }
  }

  Future<void> changeVentaStatus(int id, String newStatus) async {
    try {
      await patch('/ventas/$id', {'estado': newStatus});
    } catch (_) {
      try {
        await patch('/sales/ventas/$id/status', {'Estado': newStatus});
      } catch (e) {
        throw _convertException(e);
      }
    }
  }

  // ---------------------------
  // Servicios
  // ---------------------------
  Future<List<dynamic>> getServicios() async {
    try {
      return await get('/servicios') as List;
    } catch (_) {
      try {
        return await get('/services/servicios') as List;
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se pudieron obtener los servicios.');
      }
    }
  }

  Future<Map<String, dynamic>> getServicioById(int id) async {
    try {
      return await get('/servicios/$id') as Map<String, dynamic>;
    } catch (_) {
      try {
        return await get('/services/servicios/$id') as Map<String, dynamic>;
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se encontró el servicio con ID $id.');
      }
    }
  }

  Future<List<dynamic>> searchServicios(String query) async {
    try {
      return await get('/servicios/search?q=$query') as List;
    } catch (_) {
      try {
        return await get('/services/servicios/search?q=$query') as List;
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se pudieron buscar servicios.');
      }
    }
  }

  // ---------------------------
  // Notificaciones
  // ---------------------------
  Future<List<dynamic>> getNotificaciones() async {
    try {
      final userId = await getUserId();
      return await get('/notifications/notificaciones/usuario/$userId') as List;
    } catch (_) {
      try {
        return await get('/notifications/notificaciones') as List;
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se pudieron obtener las notificaciones.');
      }
    }
  }

  Future<List<dynamic>> getUnreadNotificaciones() async {
    try {
      return await get('/notifications/notificaciones/unread') as List;
    } catch (_) {
      try {
        final userId = await getUserId();
        return await get('/notifications/notificaciones/usuario/$userId/unread') as List;
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se pudieron obtener las notificaciones no leídas.');
      }
    }
  }

  Future<int> getUnreadNotificacionesCount() async {
    try {
      final response = await get('/notifications/notificaciones/unread/count');
      return response['count'] as int;
    } catch (_) {
      try {
        final userId = await getUserId();
        final response = await get('/notifications/notificaciones/usuario/$userId/unread/count');
        return response['count'] as int;
      } catch (e) {
        print('Error al obtener conteo de notificaciones: $e');
        return 0;
      }
    }
  }

  Future<void> markNotificationAsRead(int notificacionId) async {
    try {
      await patch('/notifications/notificaciones/$notificacionId/read', {});
    } catch (_) {
      try {
        await patch('/notifications/notificaciones/$notificacionId/read', {});
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se pudo marcar la notificación como leída.');
      }
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await post('/notifications/notificaciones/mark-all-read', {});
    } catch (_) {
      try {
        await post('/notifications/notificaciones/mark-all-read', {});
      } catch (e) {
        throw ApiException(statusCode: 404, message: 'No se pudieron marcar todas las notificaciones como leídas.');
      }
    }
  }

  // ---------------------------
  // Citas (Versión Corregida)
  // ---------------------------
  Future<List<Cita>> getCitas() async {
    try {
      final response = await get('/appointments/citas');
      return List<Cita>.from(response.map((cita) => Cita.fromJson(cita)));
    } catch (e) {
      print('Error al obtener citas: $e');
      throw ApiException(
        statusCode: 404, 
        message: 'No se pudieron obtener las citas. Error: ${e.toString()}'
      );
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
      // Verificar disponibilidad primero
      final disponibilidad = await checkDisponibilidad(fecha, hora, duracion);
      
      if (disponibilidad['disponible'] != true) {
        throw ApiException(
          statusCode: 400,
          message: 'No hay disponibilidad: ${disponibilidad['mensaje'] ?? 'Horario no disponible'}'
        );
      }

      // Crear el objeto cita
      final citaData = {
        'fecha': fecha,
        'hora': hora,
        'duracion': duracion,
        'mascotaId': mascotaId,
        'notas': notas,
        'servicios': servicios,
      };

      // Enviar la solicitud
      final response = await post('/appointments/citas', citaData);
      
      // Procesar la respuesta
      if (response is Map<String, dynamic>) {
        return Cita.fromJson(response);
      } else {
        throw ApiException(
          statusCode: 500,
          message: 'Formato de respuesta inválido al crear cita'
        );
      }
    } catch (e) {
      print('Error al crear cita: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 500, 
        message: 'Error al crear la cita: ${e.toString()}'
      );
    }
  }

  Future<Cita> getCitaById(int id) async {
    try {
      final response = await get('/appointments/citas/$id');
      return Cita.fromJson(response);
    } catch (e) {
      print('Error al obtener cita por ID: $e');
      throw ApiException(statusCode: 404, message: 'No se encontró la cita con ID $id.');
    }
  }

  Future<List<Cita>> getCitasByCliente(int clienteId) async {
    try {
      final response = await get('/appointments/citas/cliente/$clienteId');
      return List<Cita>.from(response.map((cita) => Cita.fromJson(cita)));
    } catch (e) {
      print('Error al obtener citas por cliente: $e');
      throw ApiException(statusCode: 404, message: 'No se pudieron obtener las citas del cliente.');
    }
  }

  Future<List<Cita>> getCitasByMascota(int mascotaId) async {
    try {
      final response = await get('/appointments/citas/mascota/$mascotaId');
      return List<Cita>.from(response.map((cita) => Cita.fromJson(cita)));
    } catch (e) {
      print('Error al obtener citas por mascota: $e');
      throw ApiException(statusCode: 404, message: 'No se pudieron obtener las citas de la mascota.');
    }
  }

  Future<List<Cita>> getCitasByFecha(String fecha) async {
    try {
      final response = await get('/appointments/citas/fecha/$fecha');
      return List<Cita>.from(response.map((cita) => Cita.fromJson(cita)));
    } catch (e) {
      print('Error al obtener citas por fecha: $e');
      throw ApiException(statusCode: 404, message: 'No se pudieron obtener las citas para la fecha especificada.');
    }
  }

  Future<List<Cita>> getCitasByRangoFechas(String fechaInicio, String fechaFin) async {
    try {
      final response = await get('/appointments/citas/rango-fechas?fechaInicio=$fechaInicio&fechaFin=$fechaFin');
      return List<Cita>.from(response.map((cita) => Cita.fromJson(cita)));
    } catch (e) {
      print('Error al obtener citas por rango de fechas: $e');
      throw ApiException(statusCode: 404, message: 'No se pudieron obtener las citas para el rango de fechas especificado.');
    }
  }

  Future<List<Cita>> getCitasByEstado(String estado) async {
    try {
      final response = await get('/appointments/citas/estado/$estado');
      return List<Cita>.from(response.map((cita) => Cita.fromJson(cita)));
    } catch (e) {
      print('Error al obtener citas por estado: $e');
      throw ApiException(statusCode: 404, message: 'No se pudieron obtener las citas con el estado especificado.');
    }
  }

  Future<Map<String, dynamic>> checkDisponibilidad(String fecha, String hora, int duracion) async {
    try {
      final response = await post('/appointments/citas/disponibilidad', {
        'fecha': fecha,
        'hora': hora,
        'duracion': duracion,
      });
      
      return {
        'disponible': response['disponible'] ?? false,
        'mensaje': response['mensaje'] ?? '',
      };
    } catch (e) {
      print('Error al verificar disponibilidad: $e');
      throw ApiException(
        statusCode: 500, 
        message: 'Error verificando disponibilidad: ${e.toString()}'
      );
    }
  }

  Future<Cita> updateCita(int id, Map<String, dynamic> citaData) async {
    try {
      final response = await put('/appointments/citas/$id', citaData);
      return Cita.fromJson(response);
    } catch (e) {
      print('Error al actualizar cita: $e');
      throw ApiException(
        statusCode: 500, 
        message: 'No se pudo actualizar la cita. Error: ${e.toString()}'
      );
    }
  }

  Future<void> cambiarEstadoCita(int id, String nuevoEstado) async {
    try {
      await patch('/appointments/citas/$id/status', {
        'estado': nuevoEstado,
      });
    } catch (e) {
      print('Error al cambiar estado de cita: $e');
      throw ApiException(
        statusCode: 500, 
        message: 'No se pudo cambiar el estado. Error: ${e.toString()}'
      );
    }
  }

  Future<void> deleteCita(int id) async {
    try {
      await delete('/appointments/citas/$id');
    } catch (e) {
      print('Error al eliminar cita: $e');
      throw ApiException(
        statusCode: 500, 
        message: 'No se pudo eliminar la cita. Error: ${e.toString()}'
      );
    }
  }

  Future<List<dynamic>> getServiciosByCita(int citaId) async {
    try {
      return await get('/appointments/citas/$citaId/servicios') as List;
    } catch (e) {
      print('Error al obtener servicios de cita: $e');
      throw ApiException(
        statusCode: 404, 
        message: 'No se pudieron obtener los servicios. Error: ${e.toString()}'
      );
    }
  }

  Future<void> addServicioToCita(int citaId, int servicioId) async {
    try {
      await post('/appointments/citas/$citaId/servicios/$servicioId', {});
    } catch (e) {
      print('Error al agregar servicio a cita: $e');
      throw ApiException(
        statusCode: 500, 
        message: 'No se pudo agregar el servicio. Error: ${e.toString()}'
      );
    }
  }

  Future<void> removeServicioFromCita(int citaId, int servicioId) async {
    try {
      await delete('/appointments/citas/$citaId/servicios/$servicioId');
    } catch (e) {
      print('Error al eliminar servicio de cita: $e');
      throw ApiException(
        statusCode: 500, 
        message: 'No se pudo eliminar el servicio. Error: ${e.toString()}'
      );
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
      return await get('/users/usuarios/$userId') as Map<String, dynamic>;
    } catch (e) {
      print('Error al obtener perfil de usuario: $e');
      throw ApiException(statusCode: 404, message: 'No se pudo obtener el perfil del usuario.');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final userId = await getUserId();
      await put('/users/usuarios/$userId', userData);
    } catch (e) {
      print('Error al actualizar perfil de usuario: $e');
      throw ApiException(statusCode: 500, message: 'No se pudo actualizar el perfil del usuario.');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final userId = await getUserId();
      await post('/users/usuarios/$userId/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      print('Error al cambiar contraseña: $e');
      throw ApiException(statusCode: 500, message: 'No se pudo cambiar la contraseña.');
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
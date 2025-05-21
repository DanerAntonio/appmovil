import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;
  
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;
  
  // Verificar si hay una sesión activa
  Future<bool> checkAuth() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        _isAuthenticated = false;
        _userData = null;
        return false;
      }
      
      // Verificar token con el servidor
      final response = await _apiService.get('/auth/verify');
      _userData = response['usuario'];
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      _userData = null;
      await _apiService.removeToken();
      notifyListeners();
      return false;
    }
  }
  
  // Iniciar sesión
  Future<bool> login(String correo, String password) async {
    try {
      final response = await _apiService.login(correo, password);
      
      _userData = response['usuario'];
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      _userData = null;
      notifyListeners();
      rethrow;
    }
  }
  
  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      print('Error al cerrar sesión en el servidor: $e');
    } finally {
      _isAuthenticated = false;
      _userData = null;
      notifyListeners();
    }
  }
  
  // Registrar usuario
  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      await _apiService.post('/auth/register', userData);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
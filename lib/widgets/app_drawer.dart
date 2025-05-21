import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../screens/notificacion/notificaciones_list_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  int _unreadCount = 0;
  final ApiService _apiService = ApiService();
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingCount = true;
    });
    
    try {
      final count = await _apiService.getUnreadNotificacionesCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      print('Error al cargar conteo de notificaciones: $e');
      if (mounted) {
        setState(() {
          _isLoadingCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.userData;
    
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Encabezado del drawer
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                image: DecorationImage(
                  image: AssetImage('assets/images/fondo teo.jpeg'),
                  fit: BoxFit.cover,
                  opacity: 0.2,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Image.asset(
                  'assets/images/logo teocat.jpg',
                  height: 51,
                ),
              ),
              accountName: Text(
                userData != null ? '${userData['nombre']} ${userData['apellido']}' : 'Usuario',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                userData != null ? userData['correo'] : 'bbladimir146@gmail.com',
              ),
            ),
            
            // Elementos del menú
            _buildMenuItem(
              context,
              icon: Icons.home,
              title: 'Inicio',
              route: '/home',
            ),
            
            _buildMenuItem(
              context,
              icon: Icons.shopping_cart,
              title: 'Ventas',
              route: '/ventas',
            ),
            
            _buildMenuItem(
              context,
              icon: Icons.pets,
              title: 'Servicios',
              route: '/servicios',
            ),
            
            _buildMenuItem(
              context,
              icon: Icons.pets,
              title: 'Cita',
              route: '/citas',
            ),
            // Notificaciones con contador
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ModalRoute.of(context)?.settings.name == '/notificaciones' 
                    ? AppTheme.primaryColor.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Stack(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: ModalRoute.of(context)?.settings.name == '/notificaciones'
                          ? AppTheme.primaryColor
                          : Colors.grey[700],
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (_isLoadingCount)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          child: const CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  'Notificaciones',
                  style: TextStyle(
                    color: ModalRoute.of(context)?.settings.name == '/notificaciones'
                        ? AppTheme.primaryColor
                        : Colors.grey[800],
                    fontWeight: ModalRoute.of(context)?.settings.name == '/notificaciones'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (ModalRoute.of(context)?.settings.name != '/notificaciones') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificacionesListScreen(),
                        settings: const RouteSettings(name: '/notificaciones'),
                      ),
                    ).then((_) => _loadUnreadCount());
                  }
                },
              ),
            ),
            
           
            
            const Divider(),
            
            // Cerrar sesión
            ListTile(
              leading: const Icon(
                Icons.exit_to_app,
                color: AppTheme.errorColor,
              ),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: AppTheme.errorColor,
                ),
              ),
              onTap: () async {
                // Mostrar diálogo de confirmación
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isCurrentRoute = ModalRoute.of(context)?.settings.name == route;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrentRoute ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isCurrentRoute ? AppTheme.primaryColor : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isCurrentRoute ? AppTheme.primaryColor : Colors.grey[800],
            fontWeight: isCurrentRoute ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (!isCurrentRoute) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
    );
  }
}

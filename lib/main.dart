import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/notificacion/notificaciones_list_screen.dart';
import 'screens/ventas/ventas_list_screen.dart';
import 'screens/servicios/servicios_list_screen.dart';
import 'screens/citas/citas_list_screen.dart'; // Nueva importación
import 'services/auth_service.dart';
import 'utils/theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeoCat',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/ventas': (context) => const VentasListScreen(),
        '/servicios': (context) => const ServiciosListScreen(),
        '/notificaciones': (context) => const NotificacionesListScreen(),
        '/citas': (context) => const CitasListScreen(), // Nueva ruta
      },
    );
  }
}
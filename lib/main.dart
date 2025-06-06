import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teocatapp/models/cita.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/notificacion/notificaciones_list_screen.dart';
import 'screens/ventas/ventas_list_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/citas/cita_detalle_screen.dart';
import 'screens/citas/citas_create_screen.dart';
import 'screens/citas/citas_list_screen.dart';
import 'screens/informes/informes_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar localización para español
  try {
    await initializeDateFormatting('es', null);
    print('✅ Localización inicializada correctamente');
  } catch (e) {
    print('⚠️ Error inicializando localización: $e');
  }
  
  // Configurar orientación
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => ApiService()),
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
      
      // Configuración de localización
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/ventas': (context) => const VentasScreen(),
        '/notificaciones': (context) => const NotificacionesListScreen(),
        '/informes': (context) => const InformesScreen(),
        '/citas': (context) => const CitasListScreen(),
        '/citas/create': (context) => const CitasCreateScreen(),
        '/citas/detalle': (context) => CitaDetalleScreen(
              cita: ModalRoute.of(context)!.settings.arguments as Cita,
            ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/citas/detalle') {
          final cita = settings.arguments as Cita;
          return MaterialPageRoute(
            builder: (context) => CitaDetalleScreen(cita: cita),
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const InformesScreen(),
        );
      },
    );
  }
}

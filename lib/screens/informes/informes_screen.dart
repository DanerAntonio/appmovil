import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/cita.dart';
import '../../models/venta.dart';
import '../../models/notificacion.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';

class InformesScreen extends StatefulWidget {
  const InformesScreen({Key? key}) : super(key: key);

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  DateTime _fechaSeleccionada = DateTime.now();
  List<Cita> _citasDelDia = [];
  List<Venta> _ventasDelDia = [];
  List<Notificacion> _notificaciones = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _errorMessage;
  
  // Métricas calculadas
  double _ingresosTotales = 0.0;
  double _ingresosCitas = 0.0;
  double _ingresosVentas = 0.0;
  int _clientesAtendidos = 0;
  
  // Datos para gráficos de ganancias diarias
  List<GananciasDiarias> _gananciasDiarias = [];
  List<Venta> _todasLasVentas = [];
  List<Cita> _todasLasCitas = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    
    // Timer cada 1 minutos
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted && !_isLoading) {
        _cargarDatos();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('🐾 Iniciando carga completa de datos...');
      
      // Cargar todos los datos
      await Future.wait([
        _cargarTodasLasVentas(),
        _cargarTodasLasCitas(),
        _cargarNotificaciones(),
      ]);
      
      // Filtrar por fecha seleccionada
      _filtrarDatosPorFecha();
      
      // Calcular métricas y ganancias
      _calcularMetricas();
      _calcularGananciasDiarias();
      
      print('✅ Datos cargados exitosamente');
      
    } catch (e) {
      print('❌ Error general en _cargarDatos: $e');
     // setState(() {
     //   _errorMessage = 'Error al cargar algunos datos. Verifica tu conexión.';
     // });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cargarTodasLasVentas() async {
    try {
      print('🐾 Cargando todas las ventas...');
      final ventas = await _apiService.getVentas();
      
      if (mounted) {
        setState(() {
          _todasLasVentas = ventas;
        });
      }
      
      print('✅ Ventas cargadas: ${ventas.length}');
    } catch (e) {
      print('❌ Error cargando ventas: $e');
      if (mounted) {
        setState(() {
          _todasLasVentas = [];
        });
      }
    }
  }

  Future<void> _cargarTodasLasCitas() async {
    try {
      print('🐾 Cargando todas las citas...');
      final citas = await _apiService.getCitas();
      
      if (mounted) {
        setState(() {
          _todasLasCitas = citas;
        });
      }
      
      print('✅ Citas cargadas: ${citas.length}');
    } catch (e) {
      print('❌ Error cargando citas: $e');
      if (mounted) {
        setState(() {
          _todasLasCitas = [];
        });
      }
    }
  }

  Future<void> _cargarNotificaciones() async {
    try {
      print('🐾 Cargando notificaciones...');
      
      final notificacionesData = await _apiService.getNotificaciones();
      final unreadCount = await _apiService.getUnreadNotificacionesCount();
      
      final notificaciones = notificacionesData
          .map((n) => Notificacion.fromJson(n))
          .toList();
      
      if (mounted) {
        setState(() {
          _notificaciones = notificaciones;
          _unreadCount = unreadCount;
        });
      }
      
      print('✅ Notificaciones cargadas: ${notificaciones.length}, no leídas: $unreadCount');
      
    } catch (e) {
      print('⚠️ Error cargando notificaciones: $e');
      if (mounted) {
        setState(() {
          _notificaciones = [];
          _unreadCount = 0;
        });
      }
    }
  }

  void _filtrarDatosPorFecha() {
    // Filtrar ventas por fecha seleccionada
    _ventasDelDia = _todasLasVentas.where((venta) {
      return venta.fecha.year == _fechaSeleccionada.year &&
             venta.fecha.month == _fechaSeleccionada.month &&
             venta.fecha.day == _fechaSeleccionada.day;
    }).toList();
    
    // Filtrar citas por fecha seleccionada
    _citasDelDia = _todasLasCitas.where((cita) {
      return cita.fecha.year == _fechaSeleccionada.year &&
             cita.fecha.month == _fechaSeleccionada.month &&
             cita.fecha.day == _fechaSeleccionada.day;
    }).toList();
    
    print('📊 Datos filtrados - Ventas: ${_ventasDelDia.length}, Citas: ${_citasDelDia.length}');
  }

  void _calcularMetricas() {
    // Calcular ingresos de citas completadas del día
    _ingresosCitas = _citasDelDia
        .where((c) => c.estado.toLowerCase() == 'completada')
        .fold(0.0, (sum, c) => sum + (c.getPrecioTotal() ?? 0.0));
    
    // Calcular ingresos de ventas efectivas del día
    _ingresosVentas = _ventasDelDia
        .where((v) => v.estado.toLowerCase() == 'efectiva')
        .fold(0.0, (sum, v) => sum + v.total);
    
    _ingresosTotales = _ingresosCitas + _ingresosVentas;
    
    // Calcular clientes únicos atendidos
    final clientesCitas = _citasDelDia
        .where((c) => c.estado.toLowerCase() == 'completada')
        .map((c) => c.idCliente)
        .toSet();
    
    final clientesVentas = _ventasDelDia
        .where((v) => v.estado.toLowerCase() == 'efectiva' && v.cliente != null)
        .map((v) => v.cliente)
        .toSet();
    
    _clientesAtendidos = {...clientesCitas, ...clientesVentas}.length;
    
    print('💰 Métricas calculadas:');
    print('   - Ingresos citas: \$${NumberFormat('#,###').format(_ingresosCitas)}');
    print('   - Ingresos ventas: \$${NumberFormat('#,###').format(_ingresosVentas)}');
    print('   - Total: \$${NumberFormat('#,###').format(_ingresosTotales)}');
    print('   - Clientes atendidos: $_clientesAtendidos');
  }

  void _calcularGananciasDiarias() {
    final Map<String, double> gananciasPorDia = {};
    final ahora = DateTime.now();
    
    // Calcular ganancias de los últimos 7 días
    for (int i = 6; i >= 0; i--) {
      final fecha = ahora.subtract(Duration(days: i));
      final fechaKey = DateFormat('dd/MM').format(fecha);
      
      // Ventas del día
      final ventasDelDia = _todasLasVentas.where((venta) {
        return venta.fecha.year == fecha.year &&
               venta.fecha.month == fecha.month &&
               venta.fecha.day == fecha.day &&
               venta.estado.toLowerCase() == 'efectiva';
      });
      
      // Citas del día
      final citasDelDia = _todasLasCitas.where((cita) {
        return cita.fecha.year == fecha.year &&
               cita.fecha.month == fecha.month &&
               cita.fecha.day == fecha.day &&
               cita.estado.toLowerCase() == 'completada';
      });
      
      final ingresosVentas = ventasDelDia.fold(0.0, (sum, v) => sum + v.total);
      final ingresosCitas = citasDelDia.fold(0.0, (sum, c) => sum + (c.getPrecioTotal() ?? 0.0));
      
      gananciasPorDia[fechaKey] = ingresosVentas + ingresosCitas;
    }
    
    _gananciasDiarias = gananciasPorDia.entries
        .map((e) => GananciasDiarias(e.key, e.value))
        .toList();
    
    print('📈 Ganancias diarias calculadas: ${_gananciasDiarias.length} días');
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 76, 142, 147),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() => _fechaSeleccionada = picked);
      _filtrarDatosPorFecha();
      _calcular;  {
      setState(() => _fechaSeleccionada = picked);
      _filtrarDatosPorFecha();
      _calcularMetricas();
      _calcularGananciasDiarias();
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Dashboard TeoCat',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 76, 142, 147),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _seleccionarFecha(context),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM').format(_fechaSeleccionada),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _cargarDatos,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Badge(
                    label: Text(_unreadCount.toString()),
                    isLabelVisible: _unreadCount > 0,
                    backgroundColor: const Color(0xFFEF4444),
                    child: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: const Color.fromARGB(255, 76, 142, 147),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFF59E0B)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFF59E0B)),
                        onPressed: () => setState(() => _errorMessage = null),
                      ),
                    ],
                  ),
                ),
              
              _buildWelcomeHeader(),
              const SizedBox(height: 24),
              _buildMetricasGenerales(),
              const SizedBox(height: 24),
              _buildResumenFinanciero(),
              const SizedBox(height: 24),
              
              // Gráfico de ganancias diarias
              _buildGraficaGananciasDiarias(),
              const SizedBox(height: 24),
              
              // Solo mostrar gráfico de distribución si hay datos del día
              if (_ventasDelDia.isNotEmpty || _citasDelDia.isNotEmpty) ...[
                _buildGraficaDistribucionIngresos(),
                const SizedBox(height: 24),
              ],
              
              _buildEstadisticasCitas(),
              const SizedBox(height: 24),
              _buildEstadisticasVentas(),
              const SizedBox(height: 24),
              _buildNotificacionesRecientes(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 76, 142, 147), Color.fromARGB(255, 96, 162, 167)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🐾 ¡Bienvenida a TeoCat!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resumen del ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isLoading ? 'Actualizando...' : 'Datos en tiempo real',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pets,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasGenerales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métricas del Día',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricaCard(
              'Citas', 
              _citasDelDia.length.toString(), 
              Icons.calendar_today, 
              const Color(0xFF3B82F6), 
              const Color(0xFFDBEAFE)
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricaCard(
              'Ventas', 
              _ventasDelDia.length.toString(), 
              Icons.shopping_cart, 
              const Color(0xFF10B981), 
              const Color(0xFFD1FAE5)
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricaCard(
              'Clientes', 
              _clientesAtendidos.toString(), 
              Icons.people, 
              const Color(0xFF8B5CF6), 
              const Color(0xFFE9D5FF)
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricaCard(
              'Alertas', 
              _unreadCount.toString(), 
              Icons.notifications_active, 
              const Color(0xFFF59E0B), 
              const Color(0xFFFEF3C7)
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildResumenFinanciero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Ganancias del Día',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            NumberFormat.currency(locale: 'es-CO', symbol: '\$', decimalDigits: 0)
                .format(_ingresosTotales),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIngresoItem(
                  'Servicios',
                  _ingresosCitas,
                  Icons.medical_services,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIngresoItem(
                  'Productos',
                  _ingresosVentas,
                  Icons.inventory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngresoItem(String label, double amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'es-CO', symbol: '\$', decimalDigits: 0)
                .format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficaGananciasDiarias() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color.fromARGB(255, 76, 142, 147),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ganancias de los Últimos 7 Días',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_gananciasDiarias.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No hay datos de ganancias disponibles',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compactCurrency(
                    locale: 'es-CO',
                    symbol: '\$',
                  ),
                  majorGridLines: const MajorGridLines(
                    width: 1,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<GananciasDiarias, String>(
                    dataSource: _gananciasDiarias,
                    xValueMapper: (GananciasDiarias data, _) => data.fecha,
                    yValueMapper: (GananciasDiarias data, _) => data.ganancias,
                    color: const Color.fromARGB(255, 76, 142, 147),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      textStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: point.y',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGraficaDistribucionIngresos() {
    if (_ingresosTotales == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.pie_chart, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              'No hay ingresos registrados para esta fecha',
              style: TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final chartData = [
      ChartData('Servicios', _ingresosCitas),
      ChartData('Productos', _ingresosVentas),
    ].where((data) => data.y > 0).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Color.fromARGB(255, 76, 142, 147),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Distribución de Ingresos del Día',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: SfCircularChart(
              series: <CircularSeries>[
                PieSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                  enableTooltip: true,
                  pointColorMapper: (ChartData data, _) {
                    return data.x == 'Servicios' 
                        ? const Color.fromARGB(255, 76, 142, 147)
                        : const Color(0xFF10B981);
                  },
                ),
              ],
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x: point.y',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCitas() {
    final citasCompletadas = _citasDelDia.where((c) => c.estado.toLowerCase() == 'completada').length;
    final citasPendientes = _citasDelDia.where((c) => c.estado.toLowerCase() == 'programada').length;
    final citasCanceladas = _citasDelDia.where((c) => c.estado.toLowerCase() == 'cancelada').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Estado de las Citas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_citasDelDia.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hay citas registradas para esta fecha',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadisticaItem('Completadas', citasCompletadas, const Color(0xFF10B981), const Color(0xFFD1FAE5)),
                _buildEstadisticaItem('Pendientes', citasPendientes, const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
                _buildEstadisticaItem('Canceladas', citasCanceladas, const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasVentas() {
    final ventasEfectivas = _ventasDelDia.where((v) => v.estado.toLowerCase() == 'efectiva').length;
    final ventasPendientes = _ventasDelDia.where((v) => v.estado.toLowerCase() == 'pendiente').length;
    final ventasCanceladas = _ventasDelDia.where((v) => v.estado.toLowerCase() == 'cancelado').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Estado de las Ventas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_ventasDelDia.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hay ventas registradas para esta fecha',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadisticaItem('Efectivas', ventasEfectivas, const Color(0xFF10B981), const Color(0xFFD1FAE5)),
                _buildEstadisticaItem('Pendientes', ventasPendientes, const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
                _buildEstadisticaItem('Canceladas', ventasCanceladas, const Color(0xFFEF4444), const Color(0xFFFEE2E2)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem(String label, int value, Color color, Color backgroundColor) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificacionesRecientes() {
    final notificacionesRecientes = _notificaciones
        .where((n) => n.fechaCreacion.isAfter(DateTime.now().subtract(const Duration(days: 3))))
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Actividad Reciente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (_unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount nuevas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (notificacionesRecientes.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay notificaciones recientes',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ...notificacionesRecientes.map((notif) => _buildNotificacionItem(notif)).toList(),
                if (_notificaciones.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/notificaciones');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          backgroundColor: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
                          foregroundColor: const Color.fromARGB(255, 76, 142, 147),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ver todas las notificaciones',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNotificacionItem(Notificacion notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notif.estado.toLowerCase() == 'pendiente' 
            ? const Color(0xFFFEF3C7).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notif.estado.toLowerCase() == 'pendiente' 
              ? const Color(0xFFF59E0B).withOpacity(0.2)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notif.getPriorityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              notif.getIconData(),
              color: notif.getPriorityColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.titulo,
                  style: TextStyle(
                    fontWeight: notif.estado.toLowerCase() == 'pendiente' 
                        ? FontWeight.w600 
                        : FontWeight.w500,
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notif.mensaje,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                notif.getTimeAgo(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              if (notif.estado.toLowerCase() == 'pendiente')
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: notif.getPriorityColor(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    notif.prioridad,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaCard(String titulo, String valor, IconData icono, Color primaryColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: backgroundColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, size: 24, color: primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

extension on Object? {
  operator +(double other) {}
}

class _calcular {
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}

class GananciasDiarias {
  final String fecha;
  final double ganancias;

  GananciasDiarias(this.fecha, this.ganancias);

  
}


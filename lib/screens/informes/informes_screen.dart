import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class InformesScreen extends StatefulWidget {
  const InformesScreen({Key? key}) : super(key: key);

  @override
  _InformesScreenState createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;
  
  // Datos simulados para los gráficos
  final List<Map<String, dynamic>> _ventasPorDia = [
    {'dia': 'Lun', 'ventas': 1200.0},
    {'dia': 'Mar', 'ventas': 1500.0},
    {'dia': 'Mié', 'ventas': 1000.0},
    {'dia': 'Jue', 'ventas': 1800.0},
    {'dia': 'Vie', 'ventas': 1300.0},
    {'dia': 'Sáb', 'ventas': 2000.0},
    {'dia': 'Dom', 'ventas': 900.0},
  ];
  
  final List<Map<String, dynamic>> _serviciosPorCategoria = [
    {'categoria': 'Baños', 'cantidad': 35},
    {'categoria': 'Paseos', 'cantidad': 25},
    {'categoria': 'Cortes', 'cantidad': 15},
    {'categoria': 'Veterinaria', 'cantidad': 10},
    {'categoria': 'Otros', 'cantidad': 5},
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Simulamos carga de datos
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar informes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ventas'),
            Tab(text: 'Servicios'),
            Tab(text: 'Resumen'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVentasTab(),
                    _buildServiciosTab(),
                    _buildResumenTab(),
                  ],
                ),
    );
  }
  
  Widget _buildVentasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas por Día',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.5,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 2500,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '\$${rod.toY.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(_ventasPorDia[value.toInt()]['dia']),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                value == 0 ? '0' : '\$${value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: _ventasPorDia.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data['ventas'],
                            color: AppTheme.secondaryColor,
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Resumen de Ventas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Total Ventas',
                  value: '\$9,700.00',
                  icon: Icons.attach_money,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Promedio Diario',
                  value: '\$1,385.71',
                  icon: Icons.trending_up,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Ventas Completadas',
                  value: '42',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Ventas Pendientes',
                  value: '8',
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildServiciosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios por Categoría',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.5,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _serviciosPorCategoria.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final colors = [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                        AppTheme.accentColor,
                        AppTheme.catColor,
                        AppTheme.dogColor,
                      ];
                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: data['cantidad'].toDouble(),
                        title: '${data['cantidad']}',
                        radius: 100,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leyenda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._serviciosPorCategoria.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final colors = [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                      AppTheme.accentColor,
                      AppTheme.catColor,
                      AppTheme.dogColor,
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${data['categoria']} (${data['cantidad']})',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Resumen de Servicios',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Total Servicios',
                  value: '90',
                  icon: Icons.pets,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Servicios Hoy',
                  value: '12',
                  icon: Icons.today,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildResumenTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Total Ventas',
                  value: '\$9,700.00',
                  icon: Icons.attach_money,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Total Servicios',
                  value: '90',
                  icon: Icons.pets,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Clientes Activos',
                  value: '45',
                  icon: Icons.people,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  title: 'Mascotas Registradas',
                  value: '78',
                  icon: Icons.pets,
                  color: AppTheme.catColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Actividad Reciente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final icons = [
                  Icons.shopping_cart,
                  Icons.pets,
                  Icons.receipt,
                  Icons.shopping_cart,
                  Icons.pets,
                ];
                final titles = [
                  'Venta #12345',
                  'Servicio de baño',
                  'Comprobante #789',
                  'Venta #12346',
                  'Servicio de paseo',
                ];
                final subtitles = [
                  'Completada - \$200.00',
                  'Programado - Mascota: Luna',
                  'Recibido - Cliente: Juan Pérez',
                  'Pendiente - \$150.00',
                  'Completado - Mascota: Max',
                ];
                final dates = [
                  'Hoy, 14:30',
                  'Mañana, 10:00',
                  'Ayer, 16:45',
                  'Hoy, 11:20',
                  'Ayer, 09:15',
                ];
                final colors = [
                  AppTheme.secondaryColor,
                  AppTheme.accentColor,
                  AppTheme.catColor,
                  AppTheme.secondaryColor,
                  AppTheme.accentColor,
                ];
                
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors[index].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icons[index],
                      color: colors[index],
                    ),
                  ),
                  title: Text(
                    titles[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(subtitles[index]),
                  trailing: Text(
                    dates[index],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
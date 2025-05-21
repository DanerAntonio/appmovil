import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class ComprobantesScreen extends StatefulWidget {
  const ComprobantesScreen({Key? key}) : super(key: key);

  @override
  _ComprobantesScreenState createState() => _ComprobantesScreenState();
}

class _ComprobantesScreenState extends State<ComprobantesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _comprobantes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadComprobantes();
  }
  
  Future<void> _loadComprobantes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Simulamos datos de comprobantes ya que no tenemos el endpoint real
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _comprobantes = [
          {
            'id': 1,
            'cliente': 'Juan Pérez',
            'fecha': '2023-05-10',
            'monto': 150.00,
            'estado': 'Verificado',
            'tipo': 'Transferencia',
          },
          {
            'id': 2,
            'cliente': 'María López',
            'fecha': '2023-05-12',
            'monto': 200.00,
            'estado': 'Pendiente',
            'tipo': 'Efectivo',
          },
          {
            'id': 3,
            'cliente': 'Carlos Rodríguez',
            'fecha': '2023-05-15',
            'monto': 300.00,
            'estado': 'Verificado',
            'tipo': 'Tarjeta',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar comprobantes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verificado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComprobantes,
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
                        onPressed: _loadComprobantes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _comprobantes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay comprobantes disponibles',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadComprobantes,
                            child: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadComprobantes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comprobantes.length,
                        itemBuilder: (context, index) {
                          final comprobante = _comprobantes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Comprobante #${comprobante['id']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(comprobante['estado']).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          comprobante['estado'],
                                          style: TextStyle(
                                            color: _getStatusColor(comprobante['estado']),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cliente: ${comprobante['cliente']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha: ${comprobante['fecha']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tipo: ${comprobante['tipo']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Monto: \$${comprobante['monto'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.visibility),
                                        label: const Text('Ver Comprobante'),
                                        onPressed: () {
                                          // Navegar a detalles del comprobante
                                        },
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) {
                                          // Cambiar estado del comprobante
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'Verificado',
                                            child: Text('Marcar como Verificado'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'Pendiente',
                                            child: Text('Marcar como Pendiente'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'Rechazado',
                                            child: Text('Marcar como Rechazado'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
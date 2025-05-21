// screens/ventas_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/venta.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class VentasListScreen extends StatefulWidget {
  const VentasListScreen({Key? key}) : super(key: key);

  @override
  _VentasListScreenState createState() => _VentasListScreenState();
}

class _VentasListScreenState extends State<VentasListScreen> {
  final ApiService _apiService = ApiService();
  List<Venta> _ventas = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadVentas();
  }
  
  Future<void> _loadVentas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await _apiService.getVentas();
      
      setState(() {
        _ventas = response.map((data) => Venta.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar ventas: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _changeVentaStatus(Venta venta, String newStatus) async {
    try {
      await _apiService.changeVentaStatus(venta.idVenta, newStatus);
      
      // Recargar ventas
      _loadVentas();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado de venta actualizado a: $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'efectiva':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVentas,
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
                        onPressed: _loadVentas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _ventas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay ventas disponibles',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadVentas,
                            child: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVentas,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ventas.length,
                        itemBuilder: (context, index) {
                          final venta = _ventas[index];
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
                                        'Venta #${venta.idVenta}',
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
                                          color: _getStatusColor(venta.estado).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          venta.estado,
                                          style: TextStyle(
                                            color: _getStatusColor(venta.estado),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cliente: ${venta.cliente != null ? "${venta.cliente!['Nombre'] ?? ''} ${venta.cliente!['Apellido'] ?? ''}" : "Consumidor Final"}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha: ${venta.fechaVenta.day}/${venta.fechaVenta.month}/${venta.fechaVenta.year}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: \$${venta.totalMonto.toStringAsFixed(0)}',
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
                                        label: const Text('Detalles'),
                                        onPressed: () {
                                          // Navegar a detalles de venta
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => VentaDetalleScreen(ventaId: venta.idVenta),
                                            ),
                                          );
                                        },
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) {
                                          _changeVentaStatus(venta, value);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'Efectiva',
                                            child: Text('Marcar como Efectiva'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'Pendiente',
                                            child: Text('Marcar como Pendiente'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'Cancelada',
                                            child: Text('Marcar como Cancelada'),
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

class VentaDetalleScreen extends StatefulWidget {
  final int ventaId;
  
  const VentaDetalleScreen({Key? key, required this.ventaId}) : super(key: key);

  @override
  _VentaDetalleScreenState createState() => _VentaDetalleScreenState();
}

class _VentaDetalleScreenState extends State<VentaDetalleScreen> {
  final ApiService _apiService = ApiService();
  Venta? _venta;
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadVentaDetails();
  }
  
  Future<void> _loadVentaDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await _apiService.getVentaById(widget.ventaId);
      
      setState(() {
        _venta = Venta.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar detalles de venta: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Venta #${widget.ventaId}'),
      ),
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
                        onPressed: _loadVentaDetails,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _venta == null
                  ? const Center(
                      child: Text('No se encontró la venta'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información de la venta
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Información de la Venta',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(),
                                  _buildInfoRow('Cliente', _venta!.cliente != null 
                                    ? "${_venta!.cliente!['Nombre'] ?? ''} ${_venta!.cliente!['Apellido'] ?? ''}" 
                                    : "Consumidor Final"),
                                  _buildInfoRow('Fecha', '${_venta!.fechaVenta.day}/${_venta!.fechaVenta.month}/${_venta!.fechaVenta.year}'),
                                  _buildInfoRow('Estado', _venta!.estado),
                                  _buildInfoRow('Método de pago', _venta!.metodoPago ?? 'No especificado'),
                                  _buildInfoRow('Subtotal', '\$${_venta!.subtotal.toStringAsFixed(0)}'),
                                  _buildInfoRow('IVA', '\$${_venta!.totalIva.toStringAsFixed(0)}'),
                                  _buildInfoRow('Total', '\$${_venta!.totalMonto.toStringAsFixed(0)}'),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Detalles de la venta
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Detalles de la Venta',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _venta!.detalles.length,
                                    itemBuilder: (context, index) {
                                      final detalle = _venta!.detalles[index];
                                      return ListTile(
                                        title: Text(detalle.nombreProducto),
                                        subtitle: Text('Cantidad: ${detalle.cantidad}'),
                                        trailing: Text('\$${detalle.subtotal.toStringAsFixed(0)}'),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Comprobante de pago (si existe)
                          if (_venta!.comprobantePago != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Comprobante de Pago',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Divider(),
                                    Text(_venta!.comprobantePago!),
                                    if (_venta!.referenciaPago != null) ...[
                                      const SizedBox(height: 8),
                                      Text('Referencia: ${_venta!.referenciaPago}'),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                          
                          // Notas adicionales (si existen)
                          if (_venta!.notasAdicionales != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Notas Adicionales',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Divider(),
                                    Text(_venta!.notasAdicionales!),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Botones de acción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Marcar Efectiva'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _venta!.estado.toLowerCase() != 'efectiva'
                                    ? () async {
                                        await _apiService.changeVentaStatus(_venta!.idVenta, 'Efectiva');
                                        _loadVentaDetails();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Venta marcada como Efectiva'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancelar Venta'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _venta!.estado.toLowerCase() != 'cancelada'
                                    ? () async {
                                        await _apiService.changeVentaStatus(_venta!.idVenta, 'Cancelada');
                                        _loadVentaDetails();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Venta marcada como Cancelada'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
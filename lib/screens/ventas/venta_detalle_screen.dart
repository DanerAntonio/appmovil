import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta.dart';
import '../../services/api_service.dart';

class VentaDetalleScreen extends StatefulWidget {
  final String ventaId;
  final VoidCallback? onStatusChange;

  const VentaDetalleScreen({
    Key? key,
    required this.ventaId,
    this.onStatusChange,
  }) : super(key: key);

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
    _cargarDetalleVenta();
  }

  Future<void> _cargarDetalleVenta() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🐾 Cargando detalle de venta ID: ${widget.ventaId}');
      final venta = await _apiService.getVentaById(widget.ventaId);
      
      setState(() {
        _venta = venta;
        _isLoading = false;
      });
      
      print('✅ Detalle de venta cargado: ${venta.id}');
      print('📦 Productos: ${venta.detalles?.length ?? 0}');
      print('🏥 Servicios: ${venta.servicios?.length ?? 0}');
    } catch (e) {
      print('❌ Error cargando detalle: $e');
      setState(() {
        _errorMessage = 'Error al cargar detalles: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    try {
      await _apiService.cambiarEstadoVenta(widget.ventaId, nuevoEstado);
      
      if (widget.onStatusChange != null) {
        widget.onStatusChange!();
      }
      
      await _cargarDetalleVenta();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🐾 Estado actualizado a: $nuevoEstado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.pets, color: Colors.white),
            const SizedBox(width: 8),
            Text('Venta #${widget.ventaId.length > 6 ? widget.ventaId.substring(0, 6) : widget.ventaId}'),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 76, 142, 147),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_venta != null && _venta!.estado.toLowerCase() != 'efectiva')
            PopupMenuButton<String>(
              onSelected: _cambiarEstado,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'efectiva',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Marcar como Efectiva'),
                    ],
                  ),
                ),
                if (_venta!.estado.toLowerCase() != 'pendiente')
                  const PopupMenuItem(
                    value: 'pendiente',
                    child: Row(
                      children: [
                        Icon(Icons.pending, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Marcar como Pendiente'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'cancelado',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancelar Venta'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color.fromARGB(255, 76, 142, 147),
            ),
            SizedBox(height: 16),
            Text('Cargando detalles de la venta...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarDetalleVenta,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 76, 142, 147),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_venta == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No se encontraron datos de la venta'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDetalleVenta,
      color: const Color.fromARGB(255, 76, 142, 147),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildClienteMascotaCard(),
            const SizedBox(height: 16),
            if (_venta!.detalles != null && _venta!.detalles!.isNotEmpty)
              _buildProductosCard(),
            if (_venta!.servicios != null && _venta!.servicios!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildServiciosCard(),
            ],
            const SizedBox(height: 16),
            _buildTotalesCard(),
            if (_venta!.notas != null && _venta!.notas!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotasCard(),
            ],
            const SizedBox(height: 16),
            _buildAccionesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venta #${_venta!.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(_venta!.fecha)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getEstadoColor(_venta!.estado),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _venta!.estado.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _getTipoIcon(_venta!.tipo),
                color: const Color.fromARGB(255, 76, 142, 147),
              ),
              const SizedBox(width: 8),
              Text(
                'Tipo: ${_venta!.tipo.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClienteMascotaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(Icons.person_pin, color: Color.fromARGB(255, 76, 142, 147)),
              SizedBox(width: 8),
              Text(
                'Información del Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person, 'Cliente', _venta!.cliente ?? 'Consumidor Final'),
          if (_venta!.mascota != null)
            _buildInfoRow(Icons.pets, 'Mascota', _venta!.mascota!),
        ],
      ),
    );
  }

  Widget _buildProductosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.inventory, color: Color.fromARGB(255, 76, 142, 147)),
              const SizedBox(width: 8),
              const Text(
                'Productos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_venta!.detalles!.length} items',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 76, 142, 147),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._venta!.detalles!.map((detalle) => _buildProductoItem(detalle)),
        ],
      ),
    );
  }

  Widget _buildProductoItem(DetalleVenta detalle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2, 
              color: Color.fromARGB(255, 76, 142, 147),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.producto,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${detalle.cantidad} x ${NumberFormat.currency(locale: 'es-CO', symbol: '\$', decimalDigits: 0).format(detalle.precio)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'es-CO', symbol: '\$', decimalDigits: 0).format(detalle.subtotal),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 76, 142, 147),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiciosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.medical_services, color: Color.fromARGB(255, 76, 142, 147)),
              const SizedBox(width: 8),
              const Text(
                'Servicios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_venta!.servicios!.length} servicios',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 76, 142, 147),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._venta!.servicios!.map((servicio) => _buildServicioItem(servicio)),
        ],
      ),
    );
  }

  Widget _buildServicioItem(DetalleServicio servicio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_services, 
              color: Color.fromARGB(255, 76, 142, 147),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              servicio.servicio,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'es-CO', symbol: '\$', decimalDigits: 0).format(servicio.precio),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 76, 142, 147),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalesCard() {
    final subtotal = _venta!.total / 1.19; // Asumiendo IVA del 19%
    final iva = _venta!.total - subtotal;
    
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(Icons.receipt, color: Color.fromARGB(255, 76, 142, 147)),
              SizedBox(width: 8),
              Text(
                'Resumen de Pago',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTotalRow('Subtotal', subtotal),
          _buildTotalRow('IVA (19%)', iva),
          const Divider(height: 20),
          _buildTotalRow('Total', _venta!.total, isTotal: true),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.payment, 'Método de Pago', 'Efectivo'),
        ],
      ),
    );
  }

  Widget _buildNotasCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(Icons.note, color: Color.fromARGB(255, 76, 142, 147)),
              SizedBox(width: 8),
              Text(
                'Notas Adicionales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              _venta!.notas!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(Icons.settings, color: Color.fromARGB(255, 76, 142, 147)),
              SizedBox(width: 8),
              Text(
                'Acciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implementar impresión/compartir
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función de impresión próximamente'),
                        backgroundColor: Color.fromARGB(255, 76, 142, 147),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implementar compartir
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función de compartir próximamente'),
                        backgroundColor: Color.fromARGB(255, 76, 142, 147),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 76, 142, 147),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'es-CO', symbol: '\$', decimalDigits: 0).format(value),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? const Color.fromARGB(255, 76, 142, 147) : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'efectiva':
      case 'completado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'productos':
        return Icons.inventory;
      case 'servicios':
        return Icons.medical_services;
      case 'mixta':
        return Icons.shopping_cart;
      default:
        return Icons.receipt;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cita.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class CitaDetalleScreen extends StatefulWidget {
  final Cita cita;
  
  const CitaDetalleScreen({Key? key, required this.cita}) : super(key: key);

  @override
  State<CitaDetalleScreen> createState() => _CitaDetalleScreenState();
}

class _CitaDetalleScreenState extends State<CitaDetalleScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  late Cita _cita;
  
  @override
  void initState() {
    super.initState();
    _cita = widget.cita;
    _loadCitaDetails();
  }
  
  Future<void> _loadCitaDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final cita = await _apiService.getCitaById(_cita.idCita);
      setState(() {
        _cita = cita;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar detalles de la cita: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar detalles de la cita'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarCita() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cita'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteCita(_cita.idCita);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volver a la pantalla anterior
        }
      } catch (e) {
        print('Error al eliminar cita: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar la cita'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Cita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _eliminarCita,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEstadoCard(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  if (_cita.servicios != null && _cita.servicios!.isNotEmpty)
                    _buildServiciosCard(),
                  const SizedBox(height: 16),
                  if (_cita.notas != null && _cita.notas!.isNotEmpty)
                    _buildNotasCard(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildEstadoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _cita.getStatusColor().withOpacity(0.1),
        ),
        child: Column(
          children: [
            Text(
              _cita.estado,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _cita.getStatusColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEstadoDescripcion(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la Cita',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.pets,
              title: 'Mascota',
              value: _cita.nombreMascota ?? 'Mascota #${_cita.idMascota}',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.person,
              title: 'Cliente',
              value: _cita.getClienteNombreCompleto(),
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.calendar_today,
              title: 'Fecha',
              value: _cita.getFormattedDate(),
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.access_time,
              title: 'Hora',
              value: _cita.getFormattedTime(),
            ),
            if (_cita.servicios != null && _cita.servicios!.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow(
                icon: Icons.monetization_on,
                title: 'Precio Total',
                value: NumberFormat.currency(
                  locale: 'es-CO',
                  symbol: '\$',
                  decimalDigits: 0,
                ).format(_cita.getPrecioTotal()),
              ),
            ]
          ],
        ),
      ),
    );
  }
  
  Widget _buildServiciosCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Servicios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cita.servicios!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final servicio = _cita.servicios![index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.spa,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    servicio.nombreServicio ?? 'Servicio #${servicio.idServicio}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Duración: ${servicio.duracion ?? 60} minutos',
                  ),
                  trailing: Text(
                    NumberFormat.currency(
                      locale: 'es-CO',
                      symbol: '\$',
                      decimalDigits: 0,
                    ).format(servicio.precio ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotasCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _cita.notas!,
              style: TextStyle(
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getEstadoDescripcion() {
    switch (_cita.estado.toLowerCase()) {
      case 'programada':
        return 'Agendada para el ${_cita.getFormattedDate()} a las ${_cita.getFormattedTime()}';
      case 'completada':
        return 'Completada exitosamente';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Estado desconocido';
    }
  }
}
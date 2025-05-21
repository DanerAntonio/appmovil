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
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cita = await _apiService.getCitaById(_cita.idCita);
      setState(() {
        _cita = cita;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar detalles de la cita: $e');
      setState(() {
        _isLoading = false;
      });
      
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
  
  Future<void> _cambiarEstadoCita(String nuevoEstado) async {
    try {
      await _apiService.cambiarEstadoCita(_cita.idCita, nuevoEstado);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cita marcada como $nuevoEstado'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadCitaDetails();
    } catch (e) {
      print('Error al cambiar estado de cita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cambiar estado de la cita'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Cita'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'eliminar') {
                _mostrarDialogoEliminar();
              } else if (value == 'editar') {
                // Navegar a la pantalla de edición
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad de editar cita próximamente'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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
                  _buildServiciosCard(),
                  const SizedBox(height: 16),
                  if (_cita.notas != null && _cita.notas!.isNotEmpty)
                    _buildNotasCard(),
                  const SizedBox(height: 24),
                  _buildAccionesCard(),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cita.getStatusColor().withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _cita.estado.toLowerCase() == 'programada'
                    ? Icons.event
                    : _cita.estado.toLowerCase() == 'completada'
                        ? Icons.check_circle
                        : Icons.cancel,
                color: _cita.getStatusColor(),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _cita.estado,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _cita.getStatusColor(),
              ),
            ),
            const SizedBox(height: 4),
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
            const Divider(),
            _buildInfoRow(
              icon: Icons.timelapse,
              title: 'Duración',
              value: '${_cita.getDuracionTotal()} minutos',
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Servicios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cita.servicios != null)
                  Text(
                    '${_cita.servicios!.length} ${_cita.servicios!.length == 1 ? 'servicio' : 'servicios'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cita.servicios == null || _cita.servicios!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay servicios asociados a esta cita',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
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
  
  Widget _buildAccionesCard() {
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
              'Acciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_cita.estado.toLowerCase() == 'programada')
                  _buildActionButton(
                    icon: Icons.check_circle,
                    label: 'Completar',
                    color: Colors.green,
                    onPressed: () => _cambiarEstadoCita('Completada'),
                  ),
                if (_cita.estado.toLowerCase() == 'programada')
                  _buildActionButton(
                    icon: Icons.cancel,
                    label: 'Cancelar',
                    color: Colors.red,
                    onPressed: () => _cambiarEstadoCita('Cancelada'),
                  ),
                if (_cita.estado.toLowerCase() == 'cancelada')
                  _buildActionButton(
                    icon: Icons.restore,
                    label: 'Reprogramar',
                    color: Colors.blue,
                    onPressed: () => _cambiarEstadoCita('Programada'),
                  ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Compartir',
                  color: Colors.purple,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad de compartir próximamente'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
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
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _getEstadoDescripcion() {
    switch (_cita.estado.toLowerCase()) {
      case 'programada':
        return 'Esta cita está agendada para el ${_cita.getFormattedDate()} a las ${_cita.getFormattedTime()}';
      case 'completada':
        return 'Esta cita fue completada exitosamente';
      case 'cancelada':
        return 'Esta cita fue cancelada';
      default:
        return 'Estado desconocido';
    }
  }
  
  void _mostrarDialogoEliminar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cita'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cita? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteCita(_cita.idCita);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cita eliminada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                Navigator.pop(context); // Volver a la pantalla anterior
              } catch (e) {
                print('Error al eliminar cita: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al eliminar la cita'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

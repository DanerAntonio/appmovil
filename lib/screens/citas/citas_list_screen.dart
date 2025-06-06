import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cita.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import 'cita_detalle_screen.dart';

class CitasListScreen extends StatefulWidget {
  const CitasListScreen({Key? key}) : super(key: key);

  @override
  State<CitasListScreen> createState() => _CitasListScreenState();
}

class _CitasListScreenState extends State<CitasListScreen> {
  final ApiService _apiService = ApiService();
  List<Cita> _citas = [];
  List<Cita> _citasFiltradas = [];
  bool _isLoading = true;
  String _busqueda = '';
  
  // Modo de visualización
  bool _modoUltimos7Dias = true;
  DateTime _fechaEspecifica = DateTime.now();
  
  // Fechas para el rango de 7 días
  late DateTime _fechaInicio;
  late DateTime _fechaFin;

  @override
  void initState() {
    super.initState();
    _inicializarFechas();
    _loadCitas();
  }
  
  void _inicializarFechas() {
    // Configurar el rango de los últimos 7 días
    _fechaFin = DateTime.now();
    _fechaInicio = _fechaFin.subtract(const Duration(days: 6)); // 7 días incluyendo hoy
  }

  Future<void> _loadCitas() async {
    setState(() => _isLoading = true);
    
    try {
      final citas = await _apiService.getCitas();
      setState(() {
        _citas = citas;
        _aplicarFiltros();
        _isLoading = false;
      });
      
      print('✅ Citas cargadas: ${citas.length}');
      print('📅 Modo: ${_modoUltimos7Dias ? "Últimos 7 días" : "Fecha específica"}');
      if (_modoUltimos7Dias) {
        print('📆 Rango: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}');
      } else {
        print('📆 Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaEspecifica)}');
      }
    } catch (e) {
      print('❌ Error al cargar citas: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al cargar citas: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _aplicarFiltros() {
    _citasFiltradas = _citas.where((cita) {
      // Filtro por fecha según el modo
      bool cumpleFecha = false;
      
      if (_modoUltimos7Dias) {
        // Modo últimos 7 días: verificar si está en el rango
        final fechaCita = DateTime(
          cita.fecha.year,
          cita.fecha.month,
          cita.fecha.day,
        );
        
        final fechaInicioComparar = DateTime(
          _fechaInicio.year,
          _fechaInicio.month,
          _fechaInicio.day,
        );
        
        final fechaFinComparar = DateTime(
          _fechaFin.year,
          _fechaFin.month,
          _fechaFin.day,
        );
        
        cumpleFecha = (fechaCita.isAtSameMomentAs(fechaInicioComparar) || 
                       fechaCita.isAfter(fechaInicioComparar)) && 
                      (fechaCita.isAtSameMomentAs(fechaFinComparar) || 
                       fechaCita.isBefore(fechaFinComparar));
      } else {
        // Modo fecha específica
        final fechaCita = DateTime(
          cita.fecha.year,
          cita.fecha.month,
          cita.fecha.day,
        );
        
        final fechaSeleccionada = DateTime(
          _fechaEspecifica.year,
          _fechaEspecifica.month,
          _fechaEspecifica.day,
        );
        
        cumpleFecha = fechaCita.isAtSameMomentAs(fechaSeleccionada);
      }
      
      // Filtro por búsqueda
      bool cumpleBusqueda = true;
      if (_busqueda.isNotEmpty) {
        final busquedaLower = _busqueda.toLowerCase();
        cumpleBusqueda = 
          (cita.nombreMascota?.toLowerCase().contains(busquedaLower) ?? false) ||
          (cita.nombreCliente?.toLowerCase().contains(busquedaLower) ?? false) ||
          (cita.apellidoCliente?.toLowerCase().contains(busquedaLower) ?? false);
      }
      
      return cumpleFecha && cumpleBusqueda;
    }).toList();
    
    // Ordenar por fecha más reciente primero
    _citasFiltradas.sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> _mostrarSelectorFecha() async {
    // Mostrar diálogo con opciones
    final opcion = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar modo de visualización'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'ultimos7dias'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: Color.fromARGB(255, 76, 142, 147)),
                  SizedBox(width: 12),
                  Text('Últimos 7 días'),
                ],
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'fechaespecifica'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Color.fromARGB(255, 76, 142, 147)),
                  SizedBox(width: 12),
                  Text('Fecha específica'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (opcion == 'ultimos7dias') {
      setState(() {
        _modoUltimos7Dias = true;
        _inicializarFechas();
        _aplicarFiltros();
      });
    } else if (opcion == 'fechaespecifica') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _fechaEspecifica,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
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
      
      if (picked != null) {
        setState(() {
          _modoUltimos7Dias = false;
          _fechaEspecifica = picked;
          _aplicarFiltros();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Citas TeoCat',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 76, 142, 147),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _modoUltimos7Dias ? Icons.date_range : Icons.calendar_today, 
              color: Colors.white
            ),
            tooltip: 'Filtrar por fecha',
            onPressed: _mostrarSelectorFecha,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: _loadCitas,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            tooltip: 'Regresar al inicio',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/informes');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFiltrosHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color.fromARGB(255, 76, 142, 147),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando citas...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _citasFiltradas.isEmpty
                    ? _buildEmptyState()
                    : _buildCitasList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _busqueda = value;
                        _aplicarFiltros();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Buscar por mascota o cliente...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _mostrarSelectorFecha,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 76, 142, 147),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _modoUltimos7Dias ? Icons.date_range : Icons.calendar_today,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _modoUltimos7Dias
                            ? 'Últimos 7 días'
                            : DateFormat('dd/MM').format(_fechaEspecifica),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Información del rango de fechas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _modoUltimos7Dias
                        ? 'Mostrando citas del ${DateFormat('dd/MM').format(_fechaInicio)} al ${DateFormat('dd/MM').format(_fechaFin)}'
                        : 'Mostrando citas del ${DateFormat('dd/MM/yyyy').format(_fechaEspecifica)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contador de citas y resumen por estado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadoResumen(
                  'Total',
                  _citasFiltradas.length,
                  const Color.fromARGB(255, 76, 142, 147),
                ),
                _buildEstadoResumen(
                  'Programadas',
                  _citasFiltradas.where((c) => c.estado?.toLowerCase() == 'programada').length,
                  Colors.orange,
                ),
                _buildEstadoResumen(
                  'Completadas',
                  _citasFiltradas.where((c) => c.estado?.toLowerCase() == 'completada').length,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoResumen(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                color: Color.fromARGB(255, 76, 142, 147),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _busqueda.isNotEmpty 
                  ? 'No se encontraron citas'
                  : _modoUltimos7Dias
                      ? 'No hay citas en los últimos 7 días'
                      : 'No hay citas para esta fecha',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _busqueda.isNotEmpty
                  ? 'Intenta con otros términos de búsqueda'
                  : _modoUltimos7Dias
                      ? 'No hay citas programadas en el rango de fechas seleccionado'
                      : 'Selecciona otra fecha para ver las citas programadas',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitasList() {
    return RefreshIndicator(
      onRefresh: _loadCitas,
      color: const Color.fromARGB(255, 76, 142, 147),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _citasFiltradas.length,
        itemBuilder: (context, index) {
          final cita = _citasFiltradas[index];
          return _buildCitaCard(cita);
        },
      ),
    );
  }

  Widget _buildCitaCard(Cita cita) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getEstadoColor(cita.estado ?? '').withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _verDetalle(cita),
          child: Column(
            children: [
              // Header con estado y hora
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _getEstadoColor(cita.estado ?? '').withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getEstadoIcon(cita.estado ?? ''),
                      size: 18,
                      color: _getEstadoColor(cita.estado ?? ''),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cita.estado ?? 'Sin estado',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getEstadoColor(cita.estado ?? ''),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(cita.estado ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cita.getFormattedTime(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.pets,
                          size: 32,
                          color: Color.fromARGB(255, 76, 142, 147),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cita.nombreMascota ?? 'Mascota #${cita.idMascota}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cita.getClienteNombreCompleto(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Información adicional
                          Row(
                            children: [
                              _buildInfoChip(
                                Icons.calendar_today,
                                cita.getFormattedDate(),
                                Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              if (cita.servicios != null && cita.servicios!.isNotEmpty)
                                _buildInfoChip(
                                  Icons.medical_services,
                                  '${cita.servicios!.length} servicios',
                                  Colors.green,
                                ),
                            ],
                          ),
                          
                          // Servicios
                          if (cita.servicios != null && cita.servicios!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: cita.servicios!.take(3).map((servicio) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 76, 142, 147).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    servicio.nombreServicio ?? 'Servicio #${servicio.idServicio}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color.fromARGB(255, 76, 142, 147),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (cita.servicios!.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '+${cita.servicios!.length - 3} servicios más',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Footer con botón de ver detalle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Toca para ver más detalles',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return Colors.green;
      case 'programada':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      default:
        return const Color.fromARGB(255, 76, 142, 147);
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return Icons.check_circle;
      case 'programada':
        return Icons.schedule;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.pets;
    }
  }

  void _verDetalle(Cita cita) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CitaDetalleScreen(cita: cita),
      ),
    ).then((_) => _loadCitas());
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cita.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import 'cita_detalle_screen.dart';

class CitasListScreen extends StatefulWidget {
  const CitasListScreen({Key? key}) : super(key: key);

  @override
  State<CitasListScreen> createState() => _CitasListScreenState();
}

class _CitasListScreenState extends State<CitasListScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Cita> _citas = [];
  bool _isLoading = true;
  String _selectedFilter = 'Todas';
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCitas();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCitas() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final citas = await _apiService.getCitas();
      setState(() {
        _citas = citas;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar citas: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar citas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadCitasByFecha(DateTime fecha) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(fecha);
      final citas = await _apiService.getCitasByFecha(formattedDate);
      setState(() {
        _citas = citas;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar citas por fecha: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar citas por fecha'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadCitasByEstado(String estado) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final citas = await _apiService.getCitasByEstado(estado);
      setState(() {
        _citas = citas;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar citas por estado: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar citas por estado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _cambiarEstadoCita(Cita cita, String nuevoEstado) async {
    try {
      await _apiService.cambiarEstadoCita(cita.idCita, nuevoEstado);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cita marcada como $nuevoEstado'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadCitas();
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
  
  Future<void> _eliminarCita(Cita cita) async {
    try {
      await _apiService.deleteCita(cita.idCita);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadCitas();
    } catch (e) {
      print('Error al eliminar cita: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar la cita'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadCitasByFecha(picked);
    }
  }
  
  List<Cita> _getFilteredCitas() {
    if (_selectedFilter == 'Todas') {
      return _citas;
    } else if (_selectedFilter == 'Hoy') {
      return _citas.where((cita) => cita.isToday()).toList();
    } else if (_selectedFilter == 'Futuras') {
      return _citas.where((cita) => cita.isFuture()).toList();
    } else if (_selectedFilter == 'Pasadas') {
      return _citas.where((cita) => cita.isPast()).toList();
    } else {
      // Filtrar por estado
      return _citas.where((cita) => cita.estado.toLowerCase() == _selectedFilter.toLowerCase()).toList();
    }
  }
  
  List<Cita> _getCitasByTab(int tabIndex) {
    switch (tabIndex) {
      case 0: // Programadas
        return _citas.where((cita) => cita.estado.toLowerCase() == 'programada').toList();
      case 1: // Completadas
        return _citas.where((cita) => cita.estado.toLowerCase() == 'completada').toList();
      case 2: // Canceladas
        return _citas.where((cita) => cita.estado.toLowerCase() == 'cancelada').toList();
      default:
        return _citas;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filtrar por fecha',
            onPressed: () => _selectDate(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) {
              return [
                'Todas',
                'Hoy',
                'Futuras',
                'Pasadas',
                'Programada',
                'Completada',
                'Cancelada',
              ].map((filter) {
                return PopupMenuItem<String>(
                  value: filter,
                  child: Row(
                    children: [
                      if (_selectedFilter == filter)
                        const Icon(Icons.check, color: AppTheme.primaryColor, size: 18),
                      if (_selectedFilter == filter)
                        const SizedBox(width: 8),
                      Text(filter),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Programadas'),
            Tab(text: 'Completadas'),
            Tab(text: 'Canceladas'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [0, 1, 2].map((tabIndex) {
                final citasFiltradas = _getCitasByTab(tabIndex);
                
                if (citasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay citas ${tabIndex == 0 ? 'programadas' : tabIndex == 1 ? 'completadas' : 'canceladas'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar'),
                          onPressed: _loadCitas,
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadCitas,
                  child: ListView.builder(
                    itemCount: citasFiltradas.length,
                    itemBuilder: (context, index) {
                      final cita = citasFiltradas[index];
                      return _buildCitaCard(cita, tabIndex);
                    },
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de creación de cita
          // Navigator.push(context, MaterialPageRoute(builder: (context) => CrearCitaScreen()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidad de crear cita próximamente'),
              backgroundColor: Colors.blue,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCitaCard(Cita cita, int tabIndex) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cita.getStatusColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CitaDetalleScreen(cita: cita),
            ),
          ).then((_) => _loadCitas());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cita.getStatusColor().withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pets,
                      color: cita.getStatusColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cita.nombreMascota ?? 'Mascota #${cita.idMascota}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cita.getStatusColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                cita.estado,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cita.getStatusColor(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cita.getClienteNombreCompleto(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cita.getFormattedDate(),
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cita.getFormattedTime(),
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (cita.servicios != null && cita.servicios!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servicios: ${cita.servicios!.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: cita.servicios!.map((servicio) {
                          return Chip(
                            label: Text(
                              servicio.nombreServicio ?? 'Servicio #${servicio.idServicio}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.grey[200],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (tabIndex == 0) // Programadas
                    TextButton.icon(
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text('Completar', style: TextStyle(color: Colors.green)),
                      onPressed: () => _cambiarEstadoCita(cita, 'Completada'),
                    ),
                  if (tabIndex == 0) // Programadas
                    TextButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                      onPressed: () => _cambiarEstadoCita(cita, 'Cancelada'),
                    ),
                  if (tabIndex == 2) // Canceladas
                    TextButton.icon(
                      icon: const Icon(Icons.restore, color: Colors.blue),
                      label: const Text('Reprogramar', style: TextStyle(color: Colors.blue)),
                      onPressed: () => _cambiarEstadoCita(cita, 'Programada'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
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
                              onPressed: () {
                                Navigator.pop(context);
                                _eliminarCita(cita);
                              },
                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

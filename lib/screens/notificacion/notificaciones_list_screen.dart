import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notificacion.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';

class NotificacionesListScreen extends StatefulWidget {
  const NotificacionesListScreen({Key? key}) : super(key: key);

  @override
  _NotificacionesListScreenState createState() => _NotificacionesListScreenState();
}

class _NotificacionesListScreenState extends State<NotificacionesListScreen> {
  final ApiService _apiService = ApiService();
  List<Notificacion> _notificaciones = [];
  List<Notificacion> _notificacionesFiltradas = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filtroSeleccionado = 'Todas';
  String _busqueda = '';
  
  @override
  void initState() {
    super.initState();
    _loadNotificaciones();
  }
  
  Future<void> _loadNotificaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      print('🐾 Cargando notificaciones...');
      final response = await _apiService.getNotificaciones();
      
      setState(() {
        _notificaciones = response.map((data) => Notificacion.fromJson(data)).toList();
        _aplicarFiltros();
        _isLoading = false;
      });
      
      print('✅ Notificaciones cargadas: ${_notificaciones.length}');
    } catch (e) {
      print('❌ Error cargando notificaciones: $e');
      setState(() {
        _errorMessage = 'Error al cargar notificaciones: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    _notificacionesFiltradas = _notificaciones.where((notif) {
      // Filtro por estado
      bool cumpleFiltro = true;
      if (_filtroSeleccionado == 'Pendientes') {
        cumpleFiltro = notif.estado.toLowerCase() == 'pendiente';
      } else if (_filtroSeleccionado == 'Leídas') {
        cumpleFiltro = notif.estado.toLowerCase() == 'vista';
      } else if (_filtroSeleccionado == 'Resueltas') {
        cumpleFiltro = notif.estado.toLowerCase() == 'resuelta';
      }
      
      // Filtro por búsqueda
      if (_busqueda.isNotEmpty) {
        cumpleFiltro = cumpleFiltro && (
          notif.titulo.toLowerCase().contains(_busqueda.toLowerCase()) ||
          notif.mensaje.toLowerCase().contains(_busqueda.toLowerCase()) ||
          notif.tipoNotificacion.toLowerCase().contains(_busqueda.toLowerCase())
        );
      }
      
      return cumpleFiltro;
    }).toList();
    
    // Ordenar por fecha (más recientes primero)
    _notificacionesFiltradas.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }
  
  Future<void> _markAsRead(int notificacionId) async {
    try {
      await _apiService.markNotificationAsRead(notificacionId);
      
      setState(() {
        final index = _notificaciones.indexWhere((n) => n.idNotificacion == notificacionId);
        if (index != -1) {
          _notificaciones[index] = _notificaciones[index].copyWith(
            estado: 'Vista',
            fechaVista: DateTime.now(),
          );
        }
        _aplicarFiltros();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Notificación marcada como leída'),
            ],
          ),
          backgroundColor: Color.fromARGB(255, 76, 142, 147),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      
      setState(() {
        _notificaciones = _notificaciones.map((n) {
          if (n.estado.toLowerCase() == 'pendiente') {
            return n.copyWith(
              estado: 'Vista',
              fechaVista: DateTime.now(),
            );
          }
          return n;
        }).toList();
        _aplicarFiltros();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.done_all, color: Colors.white),
              SizedBox(width: 8),
              Text('Todas las notificaciones marcadas como leídas'),
            ],
          ),
          backgroundColor: Color.fromARGB(255, 76, 142, 147),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final pendientesCount = _notificaciones.where((n) => n.estado.toLowerCase() == 'pendiente').length;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Notificaciones ',
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
          if (pendientesCount > 0)
            IconButton(
              icon: Badge(
                label: Text(pendientesCount.toString()),
                child: const Icon(Icons.done_all, color: Colors.white),
              ),
              tooltip: 'Marcar todas como leídas',
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: _loadNotificaciones,
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
                          'Cargando notificaciones...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : _notificacionesFiltradas.isEmpty
                        ? _buildEmptyWidget()
                        : _buildNotificacionesList(),
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
        children: [
          // Barra de búsqueda
          Container(
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
                hintText: 'Buscar notificaciones...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filtros por estado
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroChip('Todas', _notificaciones.length),
                      const SizedBox(width: 8),
                      _buildFiltroChip('Pendientes', _notificaciones.where((n) => n.estado.toLowerCase() == 'pendiente').length),
                      const SizedBox(width: 8),
                      _buildFiltroChip('Leídas', _notificaciones.where((n) => n.estado.toLowerCase() == 'vista').length),
                      const SizedBox(width: 8),
                      _buildFiltroChip('Resueltas', _notificaciones.where((n) => n.estado.toLowerCase() == 'resuelta').length),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String filtro, int count) {
    final isSelected = _filtroSeleccionado == filtro;
    
    return FilterChip(
      label: Text(
        '$filtro ($count)',
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroSeleccionado = filtro;
          _aplicarFiltros();
        });
      },
      backgroundColor: const Color(0xFFF8FAFC),
      selectedColor: const Color.fromARGB(255, 76, 142, 147),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected 
            ? const Color.fromARGB(255, 76, 142, 147)
            : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildErrorWidget() {
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
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotificaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 76, 142, 147),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
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
                  ? 'No se encontraron notificaciones'
                  : 'No tienes notificaciones',
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
                  : 'Las notificaciones de TeoCat aparecerán aquí',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotificaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 76, 142, 147),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificacionesList() {
    return RefreshIndicator(
      onRefresh: _loadNotificaciones,
      color: const Color.fromARGB(255, 76, 142, 147),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _notificacionesFiltradas.length,
        itemBuilder: (context, index) {
          final notificacion = _notificacionesFiltradas[index];
          return _buildNotificacionCard(notificacion);
        },
      ),
    );
  }

  Widget _buildNotificacionCard(Notificacion notificacion) {
    final isPendiente = notificacion.estado.toLowerCase() == 'pendiente';
    final isResuelta = notificacion.estado.toLowerCase() == 'resuelta';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPendiente 
              ? notificacion.getPriorityColor().withOpacity(0.3)
              : const Color(0xFFE2E8F0),
          width: isPendiente ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPendiente 
                ? notificacion.getPriorityColor().withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _mostrarDetalleNotificacion(notificacion),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: notificacion.getPriorityColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        notificacion.getIconData(),
                        color: notificacion.getPriorityColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notificacion.titulo,
                                  style: TextStyle(
                                    fontWeight: isPendiente 
                                        ? FontWeight.bold 
                                        : FontWeight.w600,
                                    fontSize: 16,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (isPendiente)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: notificacion.getPriorityColor(),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: notificacion.getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${notificacion.tipoNotificacion} • ${notificacion.estado}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: notificacion.getStatusColor(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notificacion.mensaje,
                            style: TextStyle(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: isPendiente 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notificacion.getFormattedDate(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          notificacion.getTimeAgo(),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: notificacion.getPriorityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notificacion.prioridad,
                            style: TextStyle(
                              fontSize: 10,
                              color: notificacion.getPriorityColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isPendiente) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _markAsRead(notificacion.idNotificacion),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: notificacion.getPriorityColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Marcar leída',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleNotificacion(Notificacion notificacion) {
    final isPendiente = notificacion.estado.toLowerCase() == 'pendiente';
    
    if (isPendiente) {
      _markAsRead(notificacion.idNotificacion);
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: notificacion.getPriorityColor(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      notificacion.getIconData(),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notificacion.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        notificacion.mensaje,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Detalles de la Notificación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetalleRow('Tipo', notificacion.tipoNotificacion),
                    _buildDetalleRow('Prioridad', notificacion.prioridad),
                    _buildDetalleRow('Estado', notificacion.estado),
                    _buildDetalleRow('Fecha de Creación', notificacion.getFormattedDate()),
                    if (notificacion.fechaVista != null)
                      _buildDetalleRow('Fecha de Lectura', DateFormat('dd/MM/yyyy HH:mm').format(notificacion.fechaVista!)),
                    if (notificacion.fechaResuelta != null)
                      _buildDetalleRow('Fecha de Resolución', DateFormat('dd/MM/yyyy HH:mm').format(notificacion.fechaResuelta!)),
                    if (notificacion.tablaReferencia != null && notificacion.tablaReferencia!.isNotEmpty)
                      _buildDetalleRow('Referencia', '${notificacion.tablaReferencia} #${notificacion.idReferencia}'),
                    if (notificacion.nombreUsuario != null && notificacion.apellidoUsuario != null)
                      _buildDetalleRow('Usuario', '${notificacion.nombreUsuario} ${notificacion.apellidoUsuario}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: TextStyle(
                color: notificacion.getPriorityColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// screens/notificaciones_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/notificacion.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class NotificacionesListScreen extends StatefulWidget {
  const NotificacionesListScreen({Key? key}) : super(key: key);

  @override
  _NotificacionesListScreenState createState() => _NotificacionesListScreenState();
}

class _NotificacionesListScreenState extends State<NotificacionesListScreen> {
  final ApiService _apiService = ApiService();
  List<Notificacion> _notificaciones = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
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
      final response = await _apiService.getNotificaciones();
      
      setState(() {
        _notificaciones = response.map((data) => Notificacion.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar notificaciones: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _markAsRead(int notificacionId) async {
    try {
      await _apiService.markNotificationAsRead(notificacionId);
      
      // Actualizar la notificación en la lista local
      setState(() {
        final index = _notificaciones.indexWhere((n) => n.idNotificacion == notificacionId);
        if (index != -1) {
          final updatedNotificacion = Notificacion(
            idNotificacion: _notificaciones[index].idNotificacion,
            tipoNotificacion: _notificaciones[index].tipoNotificacion,
            titulo: _notificaciones[index].titulo,
            mensaje: _notificaciones[index].mensaje,
            prioridad: _notificaciones[index].prioridad,
            estado: 'Vista',
            fechaCreacion: _notificaciones[index].fechaCreacion,
            fechaVista: DateTime.now(),
            fechaResuelta: _notificaciones[index].fechaResuelta,
            tablaReferencia: _notificaciones[index].tablaReferencia,
            idReferencia: _notificaciones[index].idReferencia,
            nombreUsuario: _notificaciones[index].nombreUsuario,
            apellidoUsuario: _notificaciones[index].apellidoUsuario,
          );
          _notificaciones[index] = updatedNotificacion;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación marcada como leída'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar notificación: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  Future<void> _markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      
      // Actualizar todas las notificaciones en la lista local
      setState(() {
        _notificaciones = _notificaciones.map((n) {
          if (n.estado.toLowerCase() == 'pendiente') {
            return Notificacion(
              idNotificacion: n.idNotificacion,
              tipoNotificacion: n.tipoNotificacion,
              titulo: n.titulo,
              mensaje: n.mensaje,
              prioridad: n.prioridad,
              estado: 'Vista',
              fechaCreacion: n.fechaCreacion,
              fechaVista: DateTime.now(),
              fechaResuelta: n.fechaResuelta,
              tablaReferencia: n.tablaReferencia,
              idReferencia: n.idReferencia,
              nombreUsuario: n.nombreUsuario,
              apellidoUsuario: n.apellidoUsuario,
            );
          }
          return n;
        }).toList();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las notificaciones marcadas como leídas'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar notificaciones: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  Widget _buildNotificationIcon(Notificacion notificacion) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: notificacion.getPriorityColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        notificacion.getIconData(),
        color: notificacion.getPriorityColor(),
        size: 24,
      ),
    );
  }
  
  Widget _buildStatusBadge(Notificacion notificacion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: notificacion.getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        notificacion.estado,
        style: TextStyle(
          color: notificacion.getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas como leídas',
            onPressed: _notificaciones.any((n) => n.estado.toLowerCase() == 'pendiente')
                ? _markAllAsRead
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadNotificaciones,
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
                        onPressed: _loadNotificaciones,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _notificaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_off,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes notificaciones',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadNotificaciones,
                            child: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotificaciones,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notificaciones.length,
                        itemBuilder: (context, index) {
                          final notificacion = _notificaciones[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Navegar a detalles de notificación o marcar como leída
                                if (notificacion.estado.toLowerCase() == 'pendiente') {
                                  _markAsRead(notificacion.idNotificacion);
                                }
                                
                                // Mostrar detalles en un diálogo
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(notificacion.titulo),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(notificacion.mensaje),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Tipo: ${notificacion.tipoNotificacion}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          Text(
                                            'Prioridad: ${notificacion.prioridad}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          Text(
                                            'Fecha: ${notificacion.fechaCreacion.day}/${notificacion.fechaCreacion.month}/${notificacion.fechaCreacion.year}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildNotificationIcon(notificacion),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notificacion.titulo,
                                                  style: TextStyle(
                                                    fontWeight: notificacion.estado.toLowerCase() == 'pendiente'
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              _buildStatusBadge(notificacion),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notificacion.mensaje,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontWeight: notificacion.estado.toLowerCase() == 'pendiente'
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                notificacion.getFormattedDate(),
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (notificacion.estado.toLowerCase() == 'pendiente')
                                                TextButton(
                                                  onPressed: () => _markAsRead(notificacion.idNotificacion),
                                                  child: const Text('Marcar como leída'),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
// models/notificacion.dart
import 'package:flutter/material.dart';

class Notificacion {
  final int idNotificacion;
  final String tipoNotificacion;
  final String titulo;
  final String mensaje;
  final String prioridad;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaVista;
  final DateTime? fechaResuelta;
  final String? tablaReferencia;
  final int? idReferencia;
  final String? nombreUsuario;
  final String? apellidoUsuario;

  Notificacion({
    required this.idNotificacion,
    required this.tipoNotificacion,
    required this.titulo,
    required this.mensaje,
    required this.prioridad,
    required this.estado,
    required this.fechaCreacion,
    this.fechaVista,
    this.fechaResuelta,
    this.tablaReferencia,
    this.idReferencia,
    this.nombreUsuario,
    this.apellidoUsuario,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      idNotificacion: json['IdNotificacion'] ?? 0,
      tipoNotificacion: json['TipoNotificacion'] ?? '',
      titulo: json['Titulo'] ?? '',
      mensaje: json['Mensaje'] ?? '',
      prioridad: json['Prioridad'] ?? 'Media',
      estado: json['Estado'] ?? 'Pendiente',
      fechaCreacion: json['FechaCreacion'] != null 
        ? DateTime.parse(json['FechaCreacion']) 
        : DateTime.now(),
      fechaVista: json['FechaVista'] != null 
        ? DateTime.parse(json['FechaVista']) 
        : null,
      fechaResuelta: json['FechaResuelta'] != null 
        ? DateTime.parse(json['FechaResuelta']) 
        : null,
      tablaReferencia: json['TablaReferencia'],
      idReferencia: json['IdReferencia'],
      nombreUsuario: json['NombreUsuario'],
      apellidoUsuario: json['ApellidoUsuario'],
    );
  }

  // Método para obtener el ícono según el tipo de notificación
  IconData getIconData() {
    switch (tipoNotificacion) {
      case 'StockBajo':
        return Icons.inventory_2;
      case 'Vencimiento':
        return Icons.event_busy;
      case 'Comprobante':
        return Icons.receipt;
      case 'ReseñaProducto':
        return Icons.star;
      case 'ReseñaServicio':
        return Icons.star_half;
      case 'ReseñaGeneral':
        return Icons.star_border;
      case 'Cita':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  // Método para obtener el color según la prioridad
  Color getPriorityColor() {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // Método para obtener el color según el estado
  Color getStatusColor() {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'vista':
        return Colors.blue;
      case 'resuelta':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Método para formatear la fecha de creación de forma relativa
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(fechaCreacion);

    if (difference.inDays > 7) {
      return '${fechaCreacion.day}/${fechaCreacion.month}/${fechaCreacion.year}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Hace un momento';
    }
  }
}
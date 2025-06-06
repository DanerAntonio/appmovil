import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      idNotificacion: json['id_notificacion'] ?? json['id'] ?? 0,
      tipoNotificacion: json['tipo_notificacion'] ?? json['tipo'] ?? 'Sistema',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      prioridad: json['prioridad'] ?? 'Media',
      estado: json['estado'] ?? 'Pendiente',
      fechaCreacion: DateTime.parse(
        json['fecha_creacion'] ?? 
        json['fechaCreacion'] ?? 
        DateTime.now().toIso8601String()
      ),
      fechaVista: json['fecha_vista'] != null 
          ? DateTime.parse(json['fecha_vista']) 
          : null,
      fechaResuelta: json['fecha_resuelta'] != null 
          ? DateTime.parse(json['fecha_resuelta']) 
          : null,
      tablaReferencia: json['tabla_referencia'],
      idReferencia: json['id_referencia'],
      nombreUsuario: json['nombre_usuario'],
      apellidoUsuario: json['apellido_usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_notificacion': idNotificacion,
      'tipo_notificacion': tipoNotificacion,
      'titulo': titulo,
      'mensaje': mensaje,
      'prioridad': prioridad,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_vista': fechaVista?.toIso8601String(),
      'fecha_resuelta': fechaResuelta?.toIso8601String(),
      'tabla_referencia': tablaReferencia,
      'id_referencia': idReferencia,
      'nombre_usuario': nombreUsuario,
      'apellido_usuario': apellidoUsuario,
    };
  }

  // Métodos auxiliares para la UI
  Color getPriorityColor() {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return const Color(0xFFEF4444);
      case 'media':
        return const Color(0xFFF59E0B);
      case 'baja':
        return const Color(0xFF10B981);
      default:
        return const Color.fromARGB(255, 76, 142, 147);
    }
  }

  Color getStatusColor() {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFF59E0B);
      case 'vista':
        return const Color(0xFF10B981);
      case 'resuelta':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData getIconData() {
    switch (tipoNotificacion.toLowerCase()) {
      case 'venta':
        return Icons.shopping_cart;
      case 'cita':
        return Icons.calendar_today;
      case 'sistema':
        return Icons.pets;
      case 'recordatorio':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  String getFormattedDate() {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaCreacion);
  }

  // Método que faltaba implementar
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(fechaCreacion);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(fechaCreacion);
    }
  }

  bool get isUnread => estado.toLowerCase() == 'pendiente';
  bool get isRead => estado.toLowerCase() != 'pendiente';

  Notificacion copyWith({
    int? idNotificacion,
    String? tipoNotificacion,
    String? titulo,
    String? mensaje,
    String? prioridad,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaVista,
    DateTime? fechaResuelta,
    String? tablaReferencia,
    int? idReferencia,
    String? nombreUsuario,
    String? apellidoUsuario,
  }) {
    return Notificacion(
      idNotificacion: idNotificacion ?? this.idNotificacion,
      tipoNotificacion: tipoNotificacion ?? this.tipoNotificacion,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaVista: fechaVista ?? this.fechaVista,
      fechaResuelta: fechaResuelta ?? this.fechaResuelta,
      tablaReferencia: tablaReferencia ?? this.tablaReferencia,
      idReferencia: idReferencia ?? this.idReferencia,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      apellidoUsuario: apellidoUsuario ?? this.apellidoUsuario,
    );
  }
}

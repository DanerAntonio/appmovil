import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Cita {
  final int idCita;
  final int idCliente;
  final int idMascota;
  final DateTime fecha;
  final String estado;
  final String? notas;
  final String? nombreCliente;
  final String? apellidoCliente;
  final String? nombreMascota;
  final List<ServicioCita>? servicios;

  Cita({
    required this.idCita,
    required this.idCliente,
    required this.idMascota,
    required this.fecha,
    required this.estado,
    this.notas,
    this.nombreCliente,
    this.apellidoCliente,
    this.nombreMascota,
    this.servicios,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    List<ServicioCita> serviciosList = [];
    if (json['servicios'] != null) {
      serviciosList = List<ServicioCita>.from(
        json['servicios'].map((servicio) => ServicioCita.fromJson(servicio)),
      );
    }

    return Cita(
      idCita: json['IdCita'] ?? 0,
      idCliente: json['IdCliente'] ?? 0,
      idMascota: json['IdMascota'] ?? 0,
      fecha: json['Fecha'] != null 
        ? DateTime.parse(json['Fecha']) 
        : DateTime.now(),
      estado: json['Estado'] ?? 'Programada',
      notas: json['Notas'],
      nombreCliente: json['NombreCliente'],
      apellidoCliente: json['ApellidoCliente'],
      nombreMascota: json['NombreMascota'],
      servicios: serviciosList,
    );
  }

  get id => null;

  get mascotaNombre => null;

  get hora => null;

  get mascota => null;

  Map<String, dynamic> toJson() {
    return {
      'IdCliente': idCliente,
      'IdMascota': idMascota,
      'Fecha': DateFormat('yyyy-MM-dd HH:mm:ss').format(fecha),
      'Estado': estado,
      'Notas': notas,
    };
  }

  // Método para obtener el color según el estado
  Color getStatusColor() {
    switch (estado.toLowerCase()) {
      case 'programada':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Método para formatear la fecha
  String getFormattedDate() {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  // Método para formatear la hora
  String getFormattedTime() {
    return DateFormat('HH:mm').format(fecha);
  }

  // Método para obtener el nombre completo del cliente
  String getClienteNombreCompleto() {
    if (nombreCliente != null && apellidoCliente != null) {
      return '$nombreCliente $apellidoCliente';
    } else {
      return 'Cliente #$idCliente';
    }
  }

  // Método para calcular si la cita es hoy
  bool isToday() {
    final now = DateTime.now();
    return fecha.year == now.year && 
           fecha.month == now.month && 
           fecha.day == now.day;
  }

  // Método para calcular si la cita es futura
  bool isFuture() {
    final now = DateTime.now();
    return fecha.isAfter(now);
  }

  // Método para calcular si la cita es pasada
  bool isPast() {
    final now = DateTime.now();
    return fecha.isBefore(now) && !isToday();
  }

  // Método para calcular la duración total de la cita
  int getDuracionTotal() {
    if (servicios == null || servicios!.isEmpty) {
      return 60; // Duración por defecto: 60 minutos
    }
    
    int duracionTotal = 0;
    for (var servicio in servicios!) {
      duracionTotal += servicio.duracion ?? 60;
    }
    
    return duracionTotal;
  }

  // Método para calcular la hora de fin de la cita
  DateTime getHoraFin() {
    return fecha.add(Duration(minutes: getDuracionTotal()));
  }

  // Método para obtener el precio total de los servicios
  double getPrecioTotal() {
    if (servicios == null || servicios!.isEmpty) {
      return 0.0;
    }
    
    double total = 0.0;
    for (var servicio in servicios!) {
      total += servicio.precio ?? 0.0;
    }
    
    return total;
  }
}

class ServicioCita {
  final int idServicio;
  final String? nombreServicio;
  final double? precio;
  final int? duracion;

  ServicioCita({
    required this.idServicio,
    this.nombreServicio,
    this.precio,
    this.duracion,
  });

  factory ServicioCita.fromJson(Map<String, dynamic> json) {
    return ServicioCita(
      idServicio: json['IdServicio'] ?? 0,
      nombreServicio: json['NombreServicio'],
      precio: json['Precio'] != null ? double.parse(json['Precio'].toString()) : 0.0,
      duracion: json['Duracion'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IdServicio': idServicio,
    };
  }
}

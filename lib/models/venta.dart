class Venta {
  final int id;
  final String? cliente;
  final String? mascota;
  final DateTime fecha;
  final double total;
  final String estado;
  final String tipo;
  final String? notas;
  List<DetalleVenta>? detalles;
  List<DetalleServicio>? servicios;

  Venta({
    required this.id,
    this.cliente,
    this.mascota,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.tipo,
    this.notas,
    this.detalles,
    this.servicios,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando venta desde JSON: $json');
    
    return Venta(
      id: _parseInt(json['IdVenta'] ?? json['id'] ?? 0),
      cliente: _getClienteName(json),
      mascota: _getMascotaName(json),
      fecha: _parseDate(json['FechaVenta'] ?? json['fecha']),
      total: _parseDouble(json['TotalMonto'] ?? json['total'] ?? 0),
      estado: json['Estado'] ?? json['estado'] ?? 'Pendiente',
      tipo: json['Tipo'] ?? json['tipo'] ?? 'Mixta',
      notas: json['NotasAdicionales'] ?? json['notas'],
      detalles: _parseDetalles(json['detalles'] ?? json['detallesProductos'] ?? json['productos']),
      servicios: _parseServicios(json['servicios'] ?? json['detallesServicios']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String? _getClienteName(Map<String, dynamic> json) {
    // Intentar obtener el nombre del cliente de diferentes formas
    if (json['cliente'] != null) {
      final cliente = json['cliente'];
      if (cliente is Map) {
        final nombre = cliente['Nombre'] ?? cliente['nombre'] ?? '';
        final apellido = cliente['Apellido'] ?? cliente['apellido'] ?? '';
        return '$nombre $apellido'.trim();
      }
      return cliente.toString();
    }
    
    // Intentar con campos directos
    final nombre = json['NombreCliente'] ?? json['nombreCliente'] ?? '';
    final apellido = json['ApellidoCliente'] ?? json['apellidoCliente'] ?? '';
    if (nombre.isNotEmpty || apellido.isNotEmpty) {
      return '$nombre $apellido'.trim();
    }
    
    return null;
  }

  static String? _getMascotaName(Map<String, dynamic> json) {
    if (json['mascota'] != null) {
      final mascota = json['mascota'];
      if (mascota is Map) {
        return mascota['Nombre'] ?? mascota['nombre'];
      }
      return mascota.toString();
    }
    return json['NombreMascota'] ?? json['nombreMascota'];
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is DateTime) return dateValue;
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('Error parseando fecha: $dateValue');
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static List<DetalleVenta>? _parseDetalles(dynamic detalles) {
    if (detalles == null) return null;
    if (detalles is! List) return null;
    
    try {
      return detalles.map((item) => DetalleVenta.fromJson(item)).toList();
    } catch (e) {
      print('Error parseando detalles: $e');
      return null;
    }
  }

  static List<DetalleServicio>? _parseServicios(dynamic servicios) {
    if (servicios == null) return null;
    if (servicios is! List) return null;
    
    try {
      return servicios.map((item) => DetalleServicio.fromJson(item)).toList();
    } catch (e) {
      print('Error parseando servicios: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente': cliente,
      'mascota': mascota,
      'fecha': fecha.toIso8601String(),
      'total': total,
      'estado': estado,
      'tipo': tipo,
      'notas': notas,
      'detalles': detalles?.map((d) => d.toJson()).toList(),
      'servicios': servicios?.map((s) => s.toJson()).toList(),
    };
  }
}

class DetalleVenta {
  final int id;
  final String producto;
  final int cantidad;
  final double precio;
  final double subtotal;

  DetalleVenta({
    required this.id,
    required this.producto,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      id: _parseInt(json['IdDetalleVenta'] ?? json['id'] ?? 0),
      producto: json['NombreProducto'] ?? json['producto'] ?? 'Producto',
      cantidad: _parseInt(json['Cantidad'] ?? json['cantidad'] ?? 1),
      precio: _parseDouble(json['PrecioUnitario'] ?? json['precio'] ?? 0),
      subtotal: _parseDouble(json['SubtotalConIva'] ?? json['Subtotal'] ?? json['subtotal'] ?? 0),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto': producto,
      'cantidad': cantidad,
      'precio': precio,
      'subtotal': subtotal,
    };
  }
}

class DetalleServicio {
  final int id;
  final String servicio;
  final double precio;

  DetalleServicio({
    required this.id,
    required this.servicio,
    required this.precio,
  });

  factory DetalleServicio.fromJson(Map<String, dynamic> json) {
    return DetalleServicio(
      id: _parseInt(json['IdDetalleVentasServicios'] ?? json['id'] ?? 0),
      servicio: json['NombreServicio'] ?? json['servicio'] ?? 'Servicio',
      precio: _parseDouble(json['SubtotalConIva'] ?? json['PrecioUnitario'] ?? json['precio'] ?? 0),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'servicio': servicio,
      'precio': precio,
    };
  }
}

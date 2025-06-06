class DetalleServicio {
  final int id;
  final String servicioId;
  final String nombre;
  final double precio;
  final double descuento;
  final double subtotal;

  DetalleServicio({
    required this.id,
    required this.servicioId,
    required this.nombre,
    required this.precio,
    this.descuento = 0.0,
    required this.subtotal,
  });

  factory DetalleServicio.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando DetalleServicio desde JSON: $json');
    
    return DetalleServicio(
      id: _parseInt(json['IdDetalleVentasServicios'] ?? json['id'] ?? json['detalleId'] ?? 0),
      servicioId: _parseString(json['IdServicio'] ?? json['servicioId'] ?? json['servicio_id'] ?? ''),
      nombre: _parseString(json['NombreServicio'] ?? json['nombre'] ?? json['servicio'] ?? 'Servicio sin nombre'),
      precio: _parseDouble(json['PrecioUnitario'] ?? json['precio'] ?? json['precioServicio'] ?? 0),
      descuento: _parseDouble(json['Descuento'] ?? json['descuento'] ?? 0),
      subtotal: _parseDouble(json['SubtotalConIva'] ?? json['Subtotal'] ?? json['subtotal'] ?? 0),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
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

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  double get subtotalCalculado {
    return precio - descuento;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'servicioId': servicioId,
    'nombre': nombre,
    'precio': precio,
    'descuento': descuento,
    'subtotal': subtotal,
  };

  @override
  String toString() {
    return 'DetalleServicio(id: $id, nombre: $nombre, precio: $precio, subtotal: $subtotal)';
  }
}

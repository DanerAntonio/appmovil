class DetalleVenta {
  final int id;
  final String productoId;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;

  DetalleVenta({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    this.descuento = 0.0,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando DetalleVenta desde JSON: $json');
    
    return DetalleVenta(
      id: _parseInt(json['IdDetalleVenta'] ?? json['id'] ?? json['detalleId'] ?? 0),
      productoId: _parseString(json['IdProducto'] ?? json['productoId'] ?? json['producto_id'] ?? ''),
      nombre: _parseString(json['NombreProducto'] ?? json['nombre'] ?? json['producto'] ?? 'Producto sin nombre'),
      cantidad: _parseInt(json['Cantidad'] ?? json['cantidad'] ?? 1),
      precioUnitario: _parseDouble(json['PrecioUnitario'] ?? json['precioUnitario'] ?? json['precio'] ?? 0),
      descuento: _parseDouble(json['Descuento'] ?? json['descuento'] ?? 0),
      subtotal: _parseDouble(json['SubtotalConIva'] ?? json['Subtotal'] ?? json['subtotal'] ?? 0),
    );
  }

  // Métodos auxiliares para parsing seguro
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

  // Calcular subtotal si no viene del servidor
  double get subtotalCalculado {
    return (precioUnitario * cantidad) - descuento;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productoId': productoId,
        'nombre': nombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'descuento': descuento,
        'subtotal': subtotal,
      };

  @override
  String toString() {
    return 'DetalleVenta(id: $id, nombre: $nombre, cantidad: $cantidad, precio: $precioUnitario, subtotal: $subtotal)';
  }
}

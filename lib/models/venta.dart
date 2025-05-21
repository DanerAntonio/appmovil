// models/venta.dart
class Venta {
  final int idVenta;
  final DateTime fechaVenta;
  final double totalMonto;
  final String estado;
  final String? metodoPago;
  final String? comprobantePago;
  final String? referenciaPago;
  final Map<String, dynamic>? cliente;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double totalIva;
  final String? notasAdicionales;

  Venta({
    required this.idVenta,
    required this.fechaVenta,
    required this.totalMonto,
    required this.estado,
    this.metodoPago,
    this.comprobantePago,
    this.referenciaPago,
    this.cliente,
    required this.detalles,
    required this.subtotal,
    required this.totalIva,
    this.notasAdicionales,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    List<DetalleVenta> detallesList = [];
    
    if (json['detalles'] != null) {
      detallesList = List<DetalleVenta>.from(
        json['detalles'].map((x) => DetalleVenta.fromJson(x))
      );
    }

    return Venta(
      idVenta: json['IdVenta'] ?? 0,
      fechaVenta: json['FechaVenta'] != null 
        ? DateTime.parse(json['FechaVenta']) 
        : DateTime.now(),
      totalMonto: double.tryParse(json['TotalMonto']?.toString() ?? '0') ?? 0,
      estado: json['Estado'] ?? 'Pendiente',
      metodoPago: json['MetodoPago'],
      comprobantePago: json['ComprobantePago'],
      referenciaPago: json['ReferenciaPago'],
      cliente: json['cliente'],
      detalles: detallesList,
      subtotal: double.tryParse(json['Subtotal']?.toString() ?? '0') ?? 0,
      totalIva: double.tryParse(json['TotalIva']?.toString() ?? '0') ?? 0,
      notasAdicionales: json['NotasAdicionales'],
    );
  }
}

class DetalleVenta {
  final int idDetalleVenta;
  final int idVenta;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVenta({
    required this.idDetalleVenta,
    required this.idVenta,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      idDetalleVenta: json['IdDetalleVenta'] ?? 0,
      idVenta: json['IdVenta'] ?? 0,
      nombreProducto: json['NombreProducto'] ?? 'Producto sin nombre',
      cantidad: json['Cantidad'] ?? 0,
      precioUnitario: double.tryParse(json['PrecioUnitario']?.toString() ?? '0') ?? 0,
      subtotal: double.tryParse(json['Subtotal']?.toString() ?? '0') ?? 0,
    );
  }
}
class VentaResumen {
  final String fecha;
  final double total;

  VentaResumen({required this.fecha, required this.total});

  factory VentaResumen.fromJson(Map<String, dynamic> json) {
    return VentaResumen(
      fecha: json['FechaVenta'],
      total: (json['TotalMonto'] ?? 0).toDouble(),
    );
  }
}
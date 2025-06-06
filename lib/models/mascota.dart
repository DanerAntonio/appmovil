class Mascota {
  final int id;
  final String nombre;
  final String especie;
  final String? raza;
  final int? edad;
  final String? sexo;
  final double? peso;
  final int idCliente;
  final String? nombreCliente;
  final String? apellidoCliente;

  Mascota({
    required this.id,
    required this.nombre,
    required this.especie,
    this.raza,
    this.edad,
    this.sexo,
    this.peso,
    required this.idCliente,
    this.nombreCliente,
    this.apellidoCliente,
  });

  factory Mascota.fromJson(Map<String, dynamic> json) {
    return Mascota(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      especie: json['especie'] ?? '',
      raza: json['raza'],
      edad: json['edad'],
      sexo: json['sexo'],
      peso: json['peso']?.toDouble(),
      idCliente: json['id_cliente'] ?? json['idCliente'] ?? 0,
      nombreCliente: json['nombre_cliente'] ?? json['nombreCliente'],
      apellidoCliente: json['apellido_cliente'] ?? json['apellidoCliente'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'especie': especie,
      'raza': raza,
      'edad': edad,
      'sexo': sexo,
      'peso': peso,
      'id_cliente': idCliente,
      'nombre_cliente': nombreCliente,
      'apellido_cliente': apellidoCliente,
    };
  }

  String getNombreCompleto() {
    return '$nombre ($especie${raza != null ? ' - $raza' : ''})';
  }

  String getNombreCliente() {
    if (nombreCliente != null && apellidoCliente != null) {
      return '$nombreCliente $apellidoCliente';
    }
    return 'Cliente #$idCliente';
  }
}
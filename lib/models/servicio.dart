// lib/models/servicio.dart
class Servicio {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final bool estado;
  final String? foto;
  final int duracion;
  final int idTipoServicio;
  final String? nombreTipoServicio;
  final String? beneficios;
  final String? queIncluye;

  Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.estado,
    this.foto,
    required this.duracion,
    required this.idTipoServicio,
    this.nombreTipoServicio,
    this.beneficios,
    this.queIncluye,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['IdServicio'],
      nombre: json['Nombre'],
      descripcion: json['Descripcion'] ?? '',
      precio: double.parse(json['Precio'].toString()),
      estado: json['Estado'] == 1 || json['Estado'] == true,
      foto: json['Foto'],
      duracion: json['Duracion'] ?? 0,
      idTipoServicio: json['IdTipoServicio'],
      nombreTipoServicio: json['NombreTipoServicio'],
      beneficios: json['Beneficios'],
      queIncluye: json['Que_incluye'],
    );
  }

  get idServicio => null;
}
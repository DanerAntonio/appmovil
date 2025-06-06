class Servicio {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int duracion; // en minutos
  final String? categoria;
  final bool activo;
  final bool estado; // Para compatibilidad con tu código existente
  final String? foto;
  final String? nombreTipoServicio;
  final String? beneficios;
  final String? queIncluye;

  Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.duracion,
    this.categoria,
    this.activo = true,
    this.estado = true,
    this.foto,
    this.nombreTipoServicio,
    this.beneficios,
    this.queIncluye,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'] ?? json['idServicio'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] ?? 0.0).toDouble(),
      duracion: json['duracion'] ?? 60,
      categoria: json['categoria'],
      activo: json['activo'] ?? json['estado'] ?? true,
      estado: json['estado'] ?? json['activo'] ?? true,
      foto: json['foto'] ?? json['imagen'],
      nombreTipoServicio: json['nombreTipoServicio'] ?? json['tipo_servicio'],
      beneficios: json['beneficios'],
      queIncluye: json['queIncluye'] ?? json['que_incluye'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'duracion': duracion,
      'categoria': categoria,
      'activo': activo,
      'estado': estado,
      'foto': foto,
      'nombreTipoServicio': nombreTipoServicio,
      'beneficios': beneficios,
      'queIncluye': queIncluye,
    };
  }

  String getPrecioFormateado() {
    return '\$${precio.toStringAsFixed(0)}';
  }

  String getDuracionFormateada() {
    if (duracion < 60) return '${duracion}min';
    final horas = duracion ~/ 60;
    final minutos = duracion % 60;
    if (minutos == 0) return '${horas}h';
    return '${horas}h ${minutos}min';
  }
}
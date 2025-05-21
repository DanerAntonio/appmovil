class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final String? documento;
  final Rol rol;
  final List<String> permisos;
  
  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.documento,
    required this.rol,
    required this.permisos,
  });
  
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      correo: json['correo'],
      documento: json['documento'],
      rol: Rol.fromJson(json['rol']),
      permisos: List<String>.from(json['permisos'] ?? []),
    );
  }
}

class Rol {
  final int id;
  final String nombre;
  
  Rol({
    required this.id,
    required this.nombre,
  });
  
  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}

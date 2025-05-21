// lib/screens/servicios_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/servicio.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class ServiciosListScreen extends StatefulWidget {
  const ServiciosListScreen({Key? key}) : super(key: key);

  @override
  _ServiciosListScreenState createState() => _ServiciosListScreenState();
}

class _ServiciosListScreenState extends State<ServiciosListScreen> {
  final ApiService _apiService = ApiService();
  List<Servicio> _servicios = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadServicios();
  }
  
  Future<void> _loadServicios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await _apiService.getServicios();
      
      setState(() {
        _servicios = response.map((data) => Servicio.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar servicios: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implementar búsqueda
              showSearch(
                context: context,
                delegate: ServicioSearchDelegate(_apiService),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadServicios,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadServicios,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _servicios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.pets,
                            color: Colors.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay servicios disponibles',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadServicios,
                            child: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadServicios,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _servicios.length,
                        itemBuilder: (context, index) {
                          final servicio = _servicios[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Navegar a detalles del servicio
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ServicioDetalleScreen(servicioId: servicio.idServicio),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Imagen del servicio
                                  AspectRatio(
                                    aspectRatio: 1.5,
                                    child: servicio.foto != null
                                        ? CachedNetworkImage(
                                            imageUrl: servicio.foto!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.pets,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.pets,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                  // Información del servicio
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            servicio.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${servicio.precio.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: AppTheme.secondaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            servicio.descripcion ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class ServicioSearchDelegate extends SearchDelegate<String> {
  final ApiService _apiService;
  
  ServicioSearchDelegate(this._apiService);
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }
  
  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Ingresa un término de búsqueda'),
      );
    }
    
    return FutureBuilder<List<dynamic>>(
      future: _apiService.searchServicios(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No se encontraron resultados'),
          );
        } else {
          final servicios = snapshot.data!.map((data) => Servicio.fromJson(data)).toList();
          
          return ListView.builder(
            itemCount: servicios.length,
            itemBuilder: (context, index) {
              final servicio = servicios[index];
              return ListTile(
                leading: servicio.foto != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(servicio.foto!),
                      )
                    : const CircleAvatar(
                        child: Icon(Icons.pets),
                      ),
                title: Text(servicio.nombre),
                subtitle: Text('\$${servicio.precio.toStringAsFixed(0)}'),
                onTap: () {
                  close(context, servicio.idServicio.toString());
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ServicioDetalleScreen(servicioId: servicio.idServicio),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}

class ServicioDetalleScreen extends StatefulWidget {
  final int servicioId;
  
  const ServicioDetalleScreen({Key? key, required this.servicioId}) : super(key: key);

  @override
  _ServicioDetalleScreenState createState() => _ServicioDetalleScreenState();
}

class _ServicioDetalleScreenState extends State<ServicioDetalleScreen> {
  final ApiService _apiService = ApiService();
  Servicio? _servicio;
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadServicioDetails();
  }
  
  Future<void> _loadServicioDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await _apiService.getServicioById(widget.servicioId);
      
      setState(() {
        _servicio = Servicio.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar detalles del servicio: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_servicio?.nombre ?? 'Detalle de Servicio'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadServicioDetails,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _servicio == null
                  ? const Center(
                      child: Text('No se encontró el servicio'),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen del servicio
                          _servicio!.foto != null
                              ? AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: CachedNetworkImage(
                                    imageUrl: _servicio!.foto!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.pets,
                                        color: Colors.grey,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                )
                              : AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.pets,
                                        color: Colors.grey,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                          
                          // Información del servicio
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _servicio!.nombre,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '\$${_servicio!.precio.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Estado
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _servicio!.estado ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _servicio!.estado ? 'Disponible' : 'No disponible',
                                    style: TextStyle(
                                      color: _servicio!.estado ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Descripción
                                const Text(
                                  'Descripción',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _servicio!.descripcion ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                
                                // Duración
                                const SizedBox(height: 16),
                                const Text(
                                  'Duración',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_servicio!.duracion} minutos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                
                                // Tipo de servicio
                                if (_servicio!.nombreTipoServicio != null) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tipo de servicio',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _servicio!.nombreTipoServicio!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                                
                                // Beneficios
                                if (_servicio!.beneficios != null) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Beneficios',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _servicio!.beneficios!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                                
                                // Qué incluye
                                if (_servicio!.queIncluye != null) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Qué incluye',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _servicio!.queIncluye!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 24),
                                
                                // Botón de solicitar servicio
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _servicio!.estado ? () {
                                      // Implementar solicitud de servicio
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Servicio agregado al carrito'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } : null,
                                    child: const Text(
                                      'Solicitar Servicio',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
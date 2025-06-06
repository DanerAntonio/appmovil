import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/venta.dart';
import '../../services/api_service.dart';

class CreateVentaScreen extends StatefulWidget {
  const CreateVentaScreen({Key? key}) : super(key: key);

  @override
  _CreateVentaScreenState createState() => _CreateVentaScreenState();
}

class _CreateVentaScreenState extends State<CreateVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Controladores
  final _notasController = TextEditingController();
  
  // Estado del formulario
  Map<String, dynamic>? _clienteSeleccionado;
  Map<String, dynamic>? _mascotaSeleccionada;
  List<Map<String, dynamic>> _productosSeleccionados = [];
  List<Map<String, dynamic>> _serviciosSeleccionados = [];
  String _metodoPago = 'efectivo';
  String _tipoVenta = 'mixta';
  bool _isLoading = false;
  
  // Listas para dropdowns
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _mascotas = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _servicios = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar datos necesarios para el formulario
      final futures = await Future.wait([
        _apiService.get('/customers/clientes'),
        _apiService.get('/products/productos'),
        _apiService.get('/services/servicios'),
      ]);
      
      setState(() {
        _clientes = List<Map<String, dynamic>>.from(futures[0] ?? []);
        _productos = List<Map<String, dynamic>>.from(futures[1] ?? []);
        _servicios = List<Map<String, dynamic>>.from(futures[2] ?? []);
      });
    } catch (e) {
      _mostrarError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarMascotasCliente(int clienteId) async {
    try {
      final mascotas = await _apiService.get('/customers/clientes/$clienteId/mascotas');
      setState(() {
        _mascotas = List<Map<String, dynamic>>.from(mascotas ?? []);
        _mascotaSeleccionada = null;
      });
    } catch (e) {
      _mostrarError('Error cargando mascotas: $e');
    }
  }

  double get _subtotal {
    double total = 0;
    
    // Sumar productos
    for (var producto in _productosSeleccionados) {
      total += (producto['cantidad'] ?? 1) * (producto['precio'] ?? 0.0);
    }
    
    // Sumar servicios
    for (var servicio in _serviciosSeleccionados) {
      total += servicio['precio'] ?? 0.0;
    }
    
    return total;
  }

  double get _iva => _subtotal * 0.19; // 19% IVA
  double get _total => _subtotal + _iva;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: Colors.white),
            SizedBox(width: 8),
            Text('Nueva Venta'),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 76, 142, 147),
        foregroundColor: Colors.white,
      ),
      body: _isLoading ? _buildLoadingWidget() : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color.fromARGB(255, 76, 142, 147),
          ),
          SizedBox(height: 16),
          Text('Cargando datos para la venta...'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClienteSection(),
            const SizedBox(height: 20),
            _buildMascotaSection(),
            const SizedBox(height: 20),
            _buildTipoVentaSection(),
            const SizedBox(height: 20),
            if (_tipoVenta == 'productos' || _tipoVenta == 'mixta')
              _buildProductosSection(),
            if (_tipoVenta == 'servicios' || _tipoVenta == 'mixta')
              _buildServiciosSection(),
            const SizedBox(height: 20),
            _buildMetodoPagoSection(),
            const SizedBox(height: 20),
            _buildNotasSection(),
            const SizedBox(height: 20),
            _buildResumenSection(),
            const SizedBox(height: 100), // Espacio para el bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildClienteSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Color.fromARGB(255, 76, 142, 147)),
                SizedBox(width: 8),
                Text('Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _clienteSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Consumidor Final'),
                ),
                ..._clientes.map((cliente) => DropdownMenuItem(
                  value: cliente,
                  child: Text(cliente['nombre'] ?? 'Sin nombre'),
                )),
              ],
              onChanged: (cliente) {
                setState(() {
                  _clienteSeleccionado = cliente;
                  if (cliente != null) {
                    _cargarMascotasCliente(cliente['id']);
                  } else {
                    _mascotas = [];
                    _mascotaSeleccionada = null;
                  }
                });
              },
              validator: (value) => null, // Cliente es opcional
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pets, color: Color.fromARGB(255, 76, 142, 147)),
                SizedBox(width: 8),
                Text('Mascota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _mascotaSeleccionada,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Mascota',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Mascota Genérica'),
                ),
                ..._mascotas.map((mascota) => DropdownMenuItem(
                  value: mascota,
                  child: Text('${mascota['nombre']} (${mascota['especie']})'),
                )),
              ],
              onChanged: (mascota) {
                setState(() => _mascotaSeleccionada = mascota);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoVentaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, color: Color.fromARGB(255, 76, 142, 147)),
                SizedBox(width: 8),
                Text('Tipo de Venta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'productos', label: Text('Productos'), icon: Icon(Icons.inventory)),
                ButtonSegment(value: 'servicios', label: Text('Servicios'), icon: Icon(Icons.medical_services)),
                ButtonSegment(value: 'mixta', label: Text('Mixta'), icon: Icon(Icons.shopping_cart)),
              ],
              selected: {_tipoVenta},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _tipoVenta = selection.first;
                  if (_tipoVenta == 'servicios') {
                    _productosSeleccionados.clear();
                  } else if (_tipoVenta == 'productos') {
                    _serviciosSeleccionados.clear();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory, color: Color.fromARGB(255, 76, 142, 147)),
                    SizedBox(width: 8),
                    Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _agregarProducto,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 76, 142, 147),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_productosSeleccionados.isEmpty)
              const Text('No hay productos seleccionados')
            else
              ..._productosSeleccionados.asMap().entries.map((entry) {
                final index = entry.key;
                final producto = entry.value;
                return _buildProductoItem(producto, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoItem(Map<String, dynamic> producto, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.inventory_2, color: Color.fromARGB(255, 76, 142, 147)),
        title: Text(producto['nombre'] ?? 'Producto'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Precio: \$${producto['precio']?.toStringAsFixed(2)}'),
            Row(
              children: [
                const Text('Cantidad: '),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: producto['cantidad'].toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onChanged: (value) {
                      setState(() {
                        producto['cantidad'] = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${((producto['cantidad'] ?? 1) * (producto['precio'] ?? 0.0)).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _productosSeleccionados.removeAt(index);
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiciosSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_services, color: Color.fromARGB(255, 76, 142, 147)),
                    SizedBox(width: 8),
                    Text('Servicios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _agregarServicio,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 76, 142, 147),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_serviciosSeleccionados.isEmpty)
              const Text('No hay servicios seleccionados')
            else
              ..._serviciosSeleccionados.asMap().entries.map((entry) {
                final index = entry.key;
                final servicio = entry.value;
                return _buildServicioItem(servicio, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildServicioItem(Map<String, dynamic> servicio, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.medical_services, color: Color.fromARGB(255, 76, 142, 147)),
        title: Text(servicio['nombre'] ?? 'Servicio'),
        subtitle: Text('Precio: \$${servicio['precio']?.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${servicio['precio']?.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _serviciosSeleccionados.removeAt(index);
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoPagoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Color.fromARGB(255, 76, 142, 147)),
                SizedBox(width: 8),
                Text('Método de Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _metodoPago,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              items: const [
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'mixto', child: Text('Mixto')),
              ],
              onChanged: (value) {
                setState(() => _metodoPago = value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotasSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: Color.fromARGB(255, 76, 142, 147)),
                SizedBox(width: 8),
                Text('Notas Adicionales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: 'Observaciones sobre la venta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt, color: Color.fromARGB(255, 76, 142, 147)),
                SizedBox(width: 8),
                Text('Resumen de Venta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildResumenRow('Subtotal:', _subtotal),
            _buildResumenRow('IVA (19%):', _iva),
            const Divider(),
            _buildResumenRow('Total:', _total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? const Color.fromARGB(255, 76, 142, 147) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total a Pagar:', style: TextStyle(fontSize: 12)),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 76, 142, 147),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _total > 0 ? _guardarVenta : null,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Venta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 76, 142, 147),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _agregarProducto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Producto'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _productos.length,
            itemBuilder: (context, index) {
              final producto = _productos[index];
              return ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(producto['nombre'] ?? 'Producto'),
                subtitle: Text('\$${producto['precio']?.toStringAsFixed(2)}'),
                onTap: () {
                  setState(() {
                    _productosSeleccionados.add({
                      ...producto,
                      'cantidad': 1,
                    });
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _agregarServicio() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Servicio'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _servicios.length,
            itemBuilder: (context, index) {
              final servicio = _servicios[index];
              return ListTile(
                leading: const Icon(Icons.medical_services),
                title: Text(servicio['nombre'] ?? 'Servicio'),
                subtitle: Text('\$${servicio['precio']?.toStringAsFixed(2)}'),
                onTap: () {
                  setState(() {
                    _serviciosSeleccionados.add(servicio);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarVenta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_total <= 0) {
      _mostrarError('Debe agregar al menos un producto o servicio');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ventaData = {
        'clienteId': _clienteSeleccionado?['id'],
        'mascotaId': _mascotaSeleccionada?['id'],
        'tipo': _tipoVenta,
        'metodoPago': _metodoPago,
        'subtotal': _subtotal,
        'totalIva': _iva,
        'total': _total,
        'estado': 'pendiente',
        'notas': _notasController.text,
        'productos': _productosSeleccionados.map((p) => {
          'productoId': p['id'],
          'cantidad': p['cantidad'],
          'precio': p['precio'],
        }).toList(),
        'servicios': _serviciosSeleccionados.map((s) => {
          'servicioId': s['id'],
          'precio': s['precio'],
        }).toList(),
      };

      await _apiService.createVenta(ventaData);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🐾 Venta creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al crear venta: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
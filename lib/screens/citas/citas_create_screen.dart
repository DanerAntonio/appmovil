// screens/citas/citas_create_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/cita.dart';

class CitasCreateScreen extends StatefulWidget {
  const CitasCreateScreen({Key? key}) : super(key: key);

  @override
  _CitasCreateScreenState createState() => _CitasCreateScreenState();
}

class _CitasCreateScreenState extends State<CitasCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _citaData = {
    'fecha': '',
    'hora': '',
    'duracion': 60,
    'mascotaId': 0,
    'notas': '',
    'servicios': [],
  };

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<int> _selectedServicios = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _citaData['fecha'] = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _citaData['hora'] = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona fecha y hora')),
      );
      return;
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.createCita; _citaData;
      Navigator.pop(context, true); // Retorna true indicando éxito
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear cita: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Selección de fecha
              ListTile(
                title: Text(
                  _selectedDate == null 
                    ? 'Seleccionar fecha' 
                    : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              
              // Selección de hora
              ListTile(
                title: Text(
                  _selectedTime == null 
                    ? 'Seleccionar hora' 
                    : 'Hora: ${_selectedTime!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              
              // Duración
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Duración (minutos)',
                  icon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                initialValue: '60',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la duración';
                  }
                  return null;
                },
                onSaved: (value) => _citaData['duracion'] = int.parse(value!),
              ),
              
              // ID de mascota (deberías usar un selector real en producción)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'ID de Mascota',
                  icon: Icon(Icons.pets),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el ID de la mascota';
                  }
                  return null;
                },
                onSaved: (value) => _citaData['mascotaId'] = int.parse(value!),
              ),
              
              // Notas
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  icon: Icon(Icons.note),
                ),
                maxLines: 3,
                onSaved: (value) => _citaData['notas'] = value ?? '',
              ),
              
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Crear Cita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
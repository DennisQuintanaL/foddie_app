import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/producto_repository.dart';

class AddProductoPage extends StatefulWidget {
  const AddProductoPage({super.key});

  @override
  State<AddProductoPage> createState() => _AddProductoPageState();
}

class _AddProductoPageState extends State<AddProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _stockMinimoController = TextEditingController(text: '1');
  
  int? _categoriaSeleccionadaId;
  DateTime? _fechaCaducidad;
  File? _imagenSeleccionada;

  final ImagePicker _picker = ImagePicker();
  final ProductoRepository _productoRepo = ProductoRepository();

  // Función para capturar foto desde cámara o galería
  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80, // Optimiza el tamaño de la imagen
    );

    if (pickedFile != null) {
      setState(() {
        _imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Artículo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Vista previa de la imagen
              Center(
                child: GestureDetector(
                  onTap: _mostrarOpcionesImagen,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _imagenSeleccionada != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                              SizedBox(height: 4),
                              Text('Agregar Foto', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del producto'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_fechaCaducidad == null
                    ? 'Seleccionar Fecha de Caducidad'
                    : 'Caduca: ${_fechaCaducidad!.day}/${_fechaCaducidad!.month}/${_fechaCaducidad!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _fechaCaducidad = picked);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _fechaCaducidad != null) {
                    await _productoRepo.registrarProductoConLote(
                      nombre: _nombreController.text,
                      categoriaId: _categoriaSeleccionadaId ?? 1,
                      unidad: 'pieza',
                      stockMinimo: int.parse(_stockMinimoController.text),
                      imagenPath: _imagenSeleccionada?.path,
                      cantidadInicial: int.parse(_cantidadController.text),
                      fechaCaducidad: _fechaCaducidad!,
                    );
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Guardar Producto'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../data/categoria_repository.dart';
import '../data/notificaciones_service.dart';
import '../data/producto_repository.dart';
import '../models/categoria.dart';
import '../models/producto.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final ProductoRepository _productoRepository = ProductoRepository();
  final CategoriaRepository _categoriaRepository = CategoriaRepository();

  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        _productoRepository.obtenerTodos(),
        _categoriaRepository.obtenerTodas(),
      ]);

      if (!mounted) return;

      setState(() {
        _productos = resultados[0] as List<Producto>;
        _categorias = resultados[1] as List<Categoria>;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mensaje('No se pudieron cargar los productos: $e');
    }
  }

  Future<bool> _actualizarAlertasSeguro() async {
    try {
      await NotificacionesService.instance.programarAlertasInventario();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar las alertas: $e');
      return false;
    }
  }

  Future<String?> _guardarImagenEnLaApp(XFile imagen) async {
    final directorio = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${directorio.path}/imagenes_productos');

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    final extension = imagen.name.contains('.')
        ? imagen.name.split('.').last
        : 'jpg';

    final nombreArchivo =
        'producto_${DateTime.now().microsecondsSinceEpoch}.$extension';

    final destino = '${carpeta.path}/$nombreArchivo';
    await File(imagen.path).copy(destino);

    return destino;
  }

  Future<void> _mostrarFormulario({Producto? producto}) async {
    if (_categorias.isEmpty) {
      _mensaje('Primero registra al menos una categoría.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: producto?.nombre ?? '',
    );
    final descripcionController = TextEditingController(
      text: producto?.descripcion ?? '',
    );
    final unidadController = TextEditingController(
      text: producto?.unidad ?? 'pieza',
    );
    final stockMinimoController = TextEditingController(
      text: (producto?.stockMinimo ?? 1).toString(),
    );

    int? categoriaId = producto?.categoriaId ?? _categorias.first.id;
    String? imagenPath = producto?.imagenPath;
    bool notificacionesHabilitadas =
        producto?.notificacionesHabilitadas ?? true;

    try {
      final resultado = await showDialog<Producto>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  producto == null ? 'Nuevo producto' : 'Editar producto',
                ),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              try {
                                final seleccionada =
                                    await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 80,
                                  maxWidth: 1200,
                                );

                                if (seleccionada == null) return;

                                final ruta =
                                    await _guardarImagenEnLaApp(seleccionada);

                                if (ruta != null) {
                                  setDialogState(() => imagenPath = ruta);
                                }
                              } catch (e) {
                                _mensaje('No se pudo seleccionar la imagen.');
                              }
                            },
                            child: Container(
                              height: 130,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: imagenPath != null &&
                                      File(imagenPath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(imagenPath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, size: 36),
                                        SizedBox(height: 8),
                                        Text('Seleccionar imagen'),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                    ? 'Ingresa el nombre'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descripcionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: categoriaId,
                            decoration: const InputDecoration(
                              labelText: 'Categoría *',
                              border: OutlineInputBorder(),
                            ),
                            items: _categorias
                                .where((c) => c.id != null)
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Text(c.nombre),
                                  ),
                                )
                                .toList(),
                            onChanged: (valor) {
                              setDialogState(() => categoriaId = valor);
                            },
                            validator: (valor) => valor == null
                                ? 'Selecciona una categoría'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: unidadController,
                            decoration: const InputDecoration(
                              labelText: 'Unidad (pieza, kg, litro...) *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                    ? 'Ingresa una unidad'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: stockMinimoController,
                            decoration: const InputDecoration(
                              labelText: 'Stock mínimo *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (valor) {
                              final cantidad = int.tryParse(valor ?? '');
                              if (cantidad == null || cantidad < 0) {
                                return 'Ingresa un número igual o mayor a 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Notificaciones del producto'),
                            subtitle: const Text(
                              'Avisos de caducidad y niveles de existencias',
                            ),
                            value: notificacionesHabilitadas,
                            onChanged: (valor) {
                              setDialogState(
                                () => notificacionesHabilitadas = valor,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;

                      Navigator.pop(
                        dialogContext,
                        Producto(
                          id: producto?.id,
                          nombre: nombreController.text.trim(),
                          descripcion:
                              descripcionController.text.trim().isEmpty
                                  ? null
                                  : descripcionController.text.trim(),
                          categoriaId: categoriaId!,
                          imagenPath: imagenPath,
                          unidad: unidadController.text.trim(),
                          stockMinimo:
                              int.parse(stockMinimoController.text.trim()),
                          ultimaTiendaId: producto?.ultimaTiendaId,
                          notificacionesHabilitadas:
                              notificacionesHabilitadas,
                        ),
                      );
                    },
                    child: Text(producto == null ? 'Guardar' : 'Actualizar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (resultado == null || !mounted) return;

      try {
        if (producto == null) {
          await _productoRepository.crear(resultado);
        } else {
          await _productoRepository.editar(resultado);
        }

        await _cargarDatos();

        final alertasActualizadas = await _actualizarAlertasSeguro();

        if (!mounted) return;

        final mensaje = producto == null
            ? 'Producto registrado correctamente.'
            : 'Producto actualizado correctamente.';

        _mensaje(
          alertasActualizadas
              ? mensaje
              : '$mensaje No se pudieron actualizar las alertas.',
        );
      } catch (e) {
        _mensaje('No se pudo guardar el producto: $e');
      }
    } finally {
      nombreController.dispose();
      descripcionController.dispose();
      unidadController.dispose();
      stockMinimoController.dispose();
    }
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Deseas eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _productoRepository.eliminar(producto.id!);
      await _cargarDatos();

      final alertasActualizadas = await _actualizarAlertasSeguro();

      if (!mounted) return;

      _mensaje(
        alertasActualizadas
            ? 'Producto eliminado correctamente.'
            : 'Producto eliminado, pero no se pudieron actualizar las alertas.',
      );
    } catch (e) {
      _mensaje(
        'No se puede eliminar este producto porque podría tener lotes, '
        'compras u otros registros relacionados.',
      );
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay productos registrados.\nPulsa + para agregar uno.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final producto = _productos[index];
                      final categoria = _categorias
                          .where((c) => c.id == producto.categoriaId)
                          .firstOrNull;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: SizedBox(
                            width: 54,
                            height: 54,
                            child: producto.imagenPath != null &&
                                    File(producto.imagenPath!).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(producto.imagenPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.inventory_2_outlined),
                                  ),
                          ),
                          title: Text(producto.nombre),
                          subtitle: Text(
                            '${categoria?.nombre ?? 'Sin categoría'}\n'
                            'Unidad: ${producto.unidad} · '
                            'Stock mínimo: ${producto.stockMinimo}\n'
                            'Alertas: ${producto.notificacionesHabilitadas ? 'Activadas' : 'Desactivadas'}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (opcion) {
                              if (opcion == 'editar') {
                                _mostrarFormulario(producto: producto);
                              } else if (opcion == 'eliminar') {
                                _eliminarProducto(producto);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'eliminar',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

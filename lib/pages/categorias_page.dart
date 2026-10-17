import 'package:flutter/material.dart';

import '../data/categoria_repository.dart';
import '../models/categoria.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final CategoriaRepository _repository = CategoriaRepository();

  List<Categoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await _repository.obtenerTodas();

      if (!mounted) return;

      setState(() {
        _categorias = categorias;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar las categorías: $e');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _mostrarFormulario({Categoria? categoria}) async {
    final nombreController = TextEditingController(
      text: categoria?.nombre ?? '',
    );

    final descripcionController = TextEditingController(
      text: categoria?.descripcion ?? '',
    );

    final formularioKey = GlobalKey<FormState>();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            categoria == null
                ? 'Nueva categoría'
                : 'Editar categoría',
          ),
          content: Form(
            key: formularioKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej. Frutas y verduras',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Escribe el nombre de la categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descripcionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formularioKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (resultado != true || !mounted) {
      nombreController.dispose();
      descripcionController.dispose();
      return;
    }

    try {
      final nuevaCategoria = Categoria(
        id: categoria?.id,
        nombre: nombreController.text.trim(),
        descripcion: descripcionController.text.trim().isEmpty
            ? null
            : descripcionController.text.trim(),
      );

      if (categoria == null) {
        await _repository.crear(nuevaCategoria);
        _mostrarMensaje('Categoría registrada correctamente');
      } else {
        await _repository.editar(nuevaCategoria);
        _mostrarMensaje('Categoría actualizada correctamente');
      }

      await _cargarCategorias();
    } catch (e) {
      _mostrarMensaje(
        'No se pudo guardar la categoría. '
        'Verifica que el nombre no esté repetido.',
      );
    } finally {
      nombreController.dispose();
      descripcionController.dispose();
    }
  }

  Future<void> _eliminarCategoria(Categoria categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Deseas eliminar "${categoria.nombre}"? '
          'Esta acción no se puede deshacer.',
        ),
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
      await _repository.eliminar(categoria.id!);
      _mostrarMensaje('Categoría eliminada');
      await _cargarCategorias();
    } catch (e) {
      _mostrarMensaje(
        'No se puede eliminar esta categoría porque '
        'puede estar relacionada con productos existentes.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
              ? const Center(
                  child: Text(
                    'Todavía no hay categorías.\n'
                    'Pulsa + para registrar la primera.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarCategorias,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = _categorias[index];

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.category),
                          ),
                          title: Text(categoria.nombre),
                          subtitle: Text(
                            categoria.descripcion?.isNotEmpty == true
                                ? categoria.descripcion!
                                : 'Sin descripción',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (opcion) {
                              if (opcion == 'editar') {
                                _mostrarFormulario(categoria: categoria);
                              } else if (opcion == 'eliminar') {
                                _eliminarCategoria(categoria);
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
        tooltip: 'Agregar categoría',
        child: const Icon(Icons.add),
      ),
    );
  }
}

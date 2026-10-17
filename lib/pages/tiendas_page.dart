import 'package:flutter/material.dart';

import '../data/tienda_repository.dart';
import '../models/tienda.dart';

class TiendasPage extends StatefulWidget {
  const TiendasPage({super.key});

  @override
  State<TiendasPage> createState() => _TiendasPageState();
}

class _TiendasPageState extends State<TiendasPage> {
  final TiendaRepository _repository = TiendaRepository();

  List<Tienda> _tiendas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTiendas();
  }

  Future<void> _cargarTiendas() async {
    try {
      final tiendas = await _repository.obtenerTodas();

      if (!mounted) return;

      setState(() {
        _tiendas = tiendas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar las tiendas: $e');
    }
  }

  Future<void> _mostrarFormulario({Tienda? tienda}) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: tienda?.nombre ?? '',
    );
    final direccionController = TextEditingController(
      text: tienda?.direccion ?? '',
    );
    final telefonoController = TextEditingController(
      text: tienda?.telefono ?? '',
    );

    try {
      final resultado = await showDialog<Tienda>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              tienda == null ? 'Registrar tienda' : 'Editar tienda',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la tienda *',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Ingresa el nombre de la tienda';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
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

                  final nuevaTienda = Tienda(
                    id: tienda?.id,
                    nombre: nombreController.text.trim(),
                    direccion: direccionController.text.trim().isEmpty
                        ? null
                        : direccionController.text.trim(),
                    telefono: telefonoController.text.trim().isEmpty
                        ? null
                        : telefonoController.text.trim(),
                  );

                  Navigator.pop(dialogContext, nuevaTienda);
                },
                child: Text(tienda == null ? 'Guardar' : 'Actualizar'),
              ),
            ],
          );
        },
      );

      if (resultado == null || !mounted) return;

      try {
        if (tienda == null) {
          await _repository.crear(resultado);
          _mostrarMensaje('Tienda registrada correctamente');
        } else {
          await _repository.editar(resultado);
          _mostrarMensaje('Tienda actualizada correctamente');
        }

        await _cargarTiendas();
      } catch (e) {
        _mostrarMensaje('No se pudo guardar la tienda: $e');
      }
    } finally {
      nombreController.dispose();
      direccionController.dispose();
      telefonoController.dispose();
    }
  }

  Future<void> _eliminarTienda(Tienda tienda) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tienda'),
        content: Text(
          '¿Deseas eliminar "${tienda.nombre}"? '
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
      await _repository.eliminar(tienda.id!);
      _mostrarMensaje('Tienda eliminada correctamente');
      await _cargarTiendas();
    } catch (e) {
      _mostrarMensaje(
        'No se pudo eliminar la tienda. '
        'Es posible que tenga compras o lotes relacionados.',
      );
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiendas'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _tiendas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 72,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Todavía no hay tiendas registradas.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pulsa el botón + para agregar la primera.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarTiendas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tiendas.length,
                    itemBuilder: (context, index) {
                      final tienda = _tiendas[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: const Icon(Icons.store),
                          ),
                          title: Text(tienda.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tienda.direccion != null &&
                                  tienda.direccion!.isNotEmpty)
                                Text(tienda.direccion!),
                              if (tienda.telefono != null &&
                                  tienda.telefono!.isNotEmpty)
                                Text('Teléfono: ${tienda.telefono}'),
                            ],
                          ),
                          isThreeLine:
                              (tienda.direccion?.isNotEmpty ?? false) &&
                              (tienda.telefono?.isNotEmpty ?? false),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Opciones',
                            onSelected: (opcion) {
                              if (opcion == 'editar') {
                                _mostrarFormulario(tienda: tienda);
                              } else if (opcion == 'eliminar') {
                                _eliminarTienda(tienda);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Editar'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'eliminar',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Eliminar'),
                                  contentPadding: EdgeInsets.zero,
                                ),
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
        tooltip: 'Agregar tienda',
        child: const Icon(Icons.add),
      ),
    );
  }
}

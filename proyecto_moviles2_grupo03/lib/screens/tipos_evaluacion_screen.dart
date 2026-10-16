import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/unidad.dart';

class TiposEvaluacionScreen extends StatefulWidget {
  final String cursoId;
  final Unidad unidad;

  const TiposEvaluacionScreen({
    super.key,
    required this.cursoId,
    required this.unidad,
  });

  @override
  State<TiposEvaluacionScreen> createState() => _TiposEvaluacionScreenState();
}

class _TiposEvaluacionScreenState extends State<TiposEvaluacionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _guardando = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _tiposRef {
    final uid = _uid;
    if (uid == null) return null;

    return _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('cursos')
        .doc(widget.cursoId)
        .collection('unidades')
        .doc(widget.unidad.id)
        .collection('tiposEvaluacion');
  }

  void _mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  double? _numero(dynamic valor) {
    if (valor is num && valor.toDouble().isFinite) {
      return valor.toDouble();
    }
    return null;
  }

  Future<void> _mostrarFormulario({
    String? id,
    String? nombre,
    double? porcentaje,
  }) async {
    final nombreController = TextEditingController(text: nombre ?? '');

    final porcentajeController = TextEditingController(
      text: porcentaje == null ? '' : porcentaje.toString(),
    );

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            id == null
                ? 'Nuevo tipo de evaluación'
                : 'Editar tipo de evaluación',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej. Prácticas, Examen parcial',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el nombre';
                      }
                      if (value.trim().length < 2) {
                        return 'Ingresa al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: porcentajeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Porcentaje',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final numero = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );

                      if (numero == null || !numero.isFinite) {
                        return 'Ingresa un número válido';
                      }
                      if (numero <= 0 || numero > 100) {
                        return 'Debe ser mayor que 0 y máximo 100';
                      }
                      return null;
                    },
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
              onPressed: _guardando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final referencia = _tiposRef;

                      if (referencia == null) {
                        _mensaje('Inicia sesión para continuar.');
                        return;
                      }

                      final nuevoNombre = nombreController.text.trim();

                      final nuevoPorcentaje = double.parse(
                        porcentajeController.text.trim().replaceAll(',', '.'),
                      );

                      setState(() {
                        _guardando = true;
                      });

                      try {
                        final existentes = await referencia.get();

                        double sumaOtros = 0;

                        for (final documento in existentes.docs) {
                          if (documento.id == id) continue;

                          final peso = _numero(documento.data()['porcentaje']);

                          if (peso != null) {
                            sumaOtros += peso;
                          }
                        }

                        if (sumaOtros + nuevoPorcentaje > 100.1) {
                          _mensaje(
                            'La suma de los porcentajes no puede '
                            'superar 100%.',
                          );
                          return;
                        }

                        final datos = <String, dynamic>{
                          'nombre': nuevoNombre,
                          'porcentaje': nuevoPorcentaje,
                        };

                        if (id == null) {
                          await referencia.add(datos);
                        } else {
                          await referencia.doc(id).update(datos);
                        }

                        if (!mounted || !dialogContext.mounted) {
                          return;
                        }

                        Navigator.pop(dialogContext);

                        _mensaje(
                          id == null
                              ? 'Tipo de evaluación registrado.'
                              : 'Tipo de evaluación actualizado.',
                        );
                      } catch (e) {
                        _mensaje('Error al guardar: $e');
                      } finally {
                        if (mounted) {
                          setState(() {
                            _guardando = false;
                          });
                        }
                      }
                    },
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      );
    } finally {
      nombreController.dispose();
      porcentajeController.dispose();
    }
  }

  Future<void> _eliminarTipo(String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tipo de evaluación'),
        content: Text('¿Deseas eliminar "$nombre" y sus notas registradas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final referencia = _tiposRef;

    if (referencia == null) {
      _mensaje('Inicia sesión para continuar.');
      return;
    }

    try {
      final tipoRef = referencia.doc(id);
      final notas = await tipoRef.collection('notas').get();

      final batch = _firestore.batch();

      for (final nota in notas.docs) {
        batch.delete(nota.reference);
      }

      batch.delete(tipoRef);
      await batch.commit();

      if (!mounted) return;
      _mensaje('Tipo de evaluación eliminado.');
    } catch (e) {
      _mensaje('Error al eliminar: $e');
    }
  }

  Future<void> _mostrarSimulador() async {
    final referencia = _tiposRef;

    if (referencia == null) {
      _mensaje('Inicia sesión para continuar.');
      return;
    }

    try {
      final snapshot = await referencia.get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        _mensaje('Primero registra los tipos de evaluación.');
        return;
      }

      final tipos = <Map<String, dynamic>>[];
      double totalPesos = 0;

      for (final documento in snapshot.docs) {
        final datos = documento.data();
        final peso = _numero(datos['porcentaje']);

        if (peso == null || peso <= 0 || peso > 100) {
          _mensaje('Hay un porcentaje inválido.');
          return;
        }

        final notasSnapshot = await documento.reference
            .collection('notas')
            .get();

        double sumaNotas = 0;
        int cantidadNotas = 0;

        for (final notaDoc in notasSnapshot.docs) {
          final valor = _numero(notaDoc.data()['valor']);

          if (valor == null || valor < 0 || valor > 20) {
            _mensaje('Existe una nota inválida. Revisa las notas registradas.');
            return;
          }

          sumaNotas += valor;
          cantidadNotas++;
        }

        tipos.add({
          'id': documento.id,
          'nombre': datos['nombre']?.toString() ?? 'Sin nombre',
          'peso': peso,
          'cantidadNotas': cantidadNotas,
          'promedio': cantidadNotas == 0 ? 0.0 : sumaNotas / cantidadNotas,
        });

        totalPesos += peso;
      }

      if (!mounted) return;

      if ((totalPesos - 100).abs() > 0.1) {
        _mensaje(
          'Los porcentajes deben sumar 100%. '
          'Actualmente suman ${totalPesos.toStringAsFixed(1)}%.',
        );
        return;
      }

      final pendientes = tipos
          .where((tipo) => tipo['cantidadNotas'] == 0)
          .toList();

      if (pendientes.isEmpty) {
        _mensaje(
          'Todas las evaluaciones tienen notas. '
          'No hay evaluaciones pendientes para simular.',
        );
        return;
      }

      String tipoSeleccionado = pendientes.first['id'] as String;

      final objetivoController = TextEditingController(text: '14');

      String resultado = '';
      bool resultadoPosible = false;

      try {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, actualizarDialogo) {
              return AlertDialog(
                title: const Text('Simulador de nota H15'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecciona una evaluación pendiente e '
                        'indica el promedio objetivo de la unidad.',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: tipoSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Evaluación pendiente',
                          border: OutlineInputBorder(),
                        ),
                        items: pendientes.map((tipo) {
                          final peso = tipo['peso'] as double;

                          return DropdownMenuItem<String>(
                            value: tipo['id'] as String,
                            child: Text(
                              '${tipo['nombre']} '
                              '(${peso.toStringAsFixed(1)}%)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          if (valor == null) return;

                          actualizarDialogo(() {
                            tipoSeleccionado = valor;
                            resultado = '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: objetivoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Promedio objetivo (0 a 20)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final objetivo = double.tryParse(
                              objetivoController.text.trim().replaceAll(
                                ',',
                                '.',
                              ),
                            );

                            if (objetivo == null ||
                                !objetivo.isFinite ||
                                objetivo < 0 ||
                                objetivo > 20) {
                              actualizarDialogo(() {
                                resultado =
                                    'Ingresa un objetivo válido entre '
                                    '0 y 20.';
                                resultadoPosible = false;
                              });
                              return;
                            }

                            double aporteActual = 0;
                            double pesoPendienteTotal = 0;

                            for (final tipo in tipos) {
                              final peso = tipo['peso'] as double;
                              final cantidad = tipo['cantidadNotas'] as int;

                              if (cantidad > 0) {
                                aporteActual +=
                                    (tipo['promedio'] as double) * peso / 100;
                              } else {
                                pesoPendienteTotal += peso / 100;
                              }
                            }

                            final seleccionado = pendientes.firstWhere(
                              (tipo) => tipo['id'] == tipoSeleccionado,
                            );

                            final pesoSeleccionado =
                                (seleccionado['peso'] as double) / 100;

                            final notaNecesaria =
                                (objetivo - aporteActual) / pesoSeleccionado;

                            final maximoPosible =
                                aporteActual + pesoPendienteTotal * 20;

                            late String mensaje;
                            late bool posible;

                            if (objetivo > maximoPosible + 0.000001) {
                              mensaje =
                                  'OBJETIVO IMPOSIBLE\n\n'
                                  'El promedio máximo posible es '
                                  '${maximoPosible.toStringAsFixed(2)}/20.\n\n'
                                  'Incluso obteniendo 20 en todas las '
                                  'evaluaciones pendientes, no '
                                  'alcanzarías el objetivo.';
                              posible = false;
                            } else if (notaNecesaria > 20) {
                              mensaje =
                                  'La evaluación seleccionada no basta '
                                  'por sí sola.\n\n'
                                  'Necesitarías '
                                  '${notaNecesaria.toStringAsFixed(2)}/20 '
                                  'si las demás evaluaciones pendientes '
                                  'aportaran cero.\n\n'
                                  'Promedio máximo posible: '
                                  '${maximoPosible.toStringAsFixed(2)}/20.\n\n'
                                  'El objetivo podría alcanzarse con '
                                  'notas suficientes en las otras '
                                  'evaluaciones.';
                              posible = true;
                            } else if (notaNecesaria <= 0) {
                              mensaje =
                                  'Ya alcanzas el objetivo con las '
                                  'notas actuales, incluso si las demás '
                                  'evaluaciones pendientes aportan cero.\n\n'
                                  'Nota necesaria: 0/20.\n'
                                  'Promedio máximo posible: '
                                  '${maximoPosible.toStringAsFixed(2)}/20.';
                              posible = true;
                            } else {
                              mensaje =
                                  'Necesitas '
                                  '${notaNecesaria.toStringAsFixed(2)}/20 '
                                  'en "${seleccionado['nombre']}".\n\n'
                                  'Este cálculo supone que las otras '
                                  'evaluaciones pendientes aportan cero.\n\n'
                                  'Promedio máximo posible: '
                                  '${maximoPosible.toStringAsFixed(2)}/20.';
                              posible = true;
                            }

                            actualizarDialogo(() {
                              resultado = mensaje;
                              resultadoPosible = posible;
                            });
                          },
                          icon: const Icon(Icons.calculate_outlined),
                          label: const Text('Calcular nota'),
                        ),
                      ),
                      if (resultado.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: resultadoPosible
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            resultado,
                            style: TextStyle(
                              color: resultadoPosible
                                  ? null
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            },
          ),
        );
      } finally {
        objetivoController.dispose();
      }
    } catch (e) {
      _mensaje('No se pudo calcular la simulación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final referencia = _tiposRef;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Evaluaciones: ${widget.unidad.nombre}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Simular nota de la unidad',
            icon: const Icon(Icons.calculate_outlined),
            onPressed: _mostrarSimulador,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardando ? null : () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: referencia == null
          ? const Center(
              child: Text('Inicia sesión para ver las evaluaciones.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: referencia.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'No se pudieron cargar los tipos de evaluación.',
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final documentos = snapshot.data?.docs ?? [];
                double total = 0;

                for (final documento in documentos) {
                  total += _numero(documento.data()['porcentaje']) ?? 0;
                }

                final porcentajeValido = (total - 100).abs() <= 0.1;

                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.pie_chart_outline, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Porcentaje asignado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${total.toStringAsFixed(1)}% '
                                    'de 100%',
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: (total / 100).clamp(0.0, 1.0),
                                    color: porcentajeValido
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              porcentajeValido
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              color: porcentajeValido
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (documentos.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Todavía no hay tipos de evaluación.\n'
                            'Presiona "Agregar" para registrar uno.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                          itemCount: documentos.length,
                          itemBuilder: (context, index) {
                            final documento = documentos[index];
                            final datos = documento.data();
                            final nombre =
                                datos['nombre']?.toString() ?? 'Sin nombre';
                            final porcentaje =
                                _numero(datos['porcentaje']) ?? 0;

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(nombre),
                                subtitle: Text(
                                  'Peso: '
                                  '${porcentaje.toStringAsFixed(1)}%',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (opcion) {
                                    if (opcion == 'editar') {
                                      _mostrarFormulario(
                                        id: documento.id,
                                        nombre: nombre,
                                        porcentaje: porcentaje,
                                      );
                                    } else if (opcion == 'eliminar') {
                                      _eliminarTipo(documento.id, nombre);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'eliminar',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Eliminar'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

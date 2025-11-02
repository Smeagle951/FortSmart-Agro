
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../../shared/providers/providers.dart';
import '../../../../core/database/app_database.dart';

class OrganismoFormPage extends ConsumerStatefulWidget {
  final int culturaId;
  final Organismo? organismo; // Para edição
  const OrganismoFormPage({super.key, required this.culturaId, this.organismo});

  @override
  ConsumerState<OrganismoFormPage> createState() => _OrganismoFormPageState();
}

class _OrganismoFormPageState extends ConsumerState<OrganismoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeComumController = TextEditingController();
  final _nomeCientController = TextEditingController();
  String? _tipo = 'PRAGA';
  File? _photo;

  @override
  void initState() {
    super.initState();
    // Se estiver editando, preencher os campos
    if (widget.organismo != null) {
      _tipo = widget.organismo!.tipo;
      _nomeComumController.text = widget.organismo!.nomeComum;
      _nomeCientController.text = widget.organismo!.nomeCientifico ?? '';
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera);
    if (xFile != null) {
      setState(() => _photo = File(xFile.path));
      // TODO: converter em ícone (remover fundo / reduzir)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Organismo')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _tipo,
                items: const [
                  DropdownMenuItem(value: 'PRAGA', child: Text('Praga')),
                  DropdownMenuItem(value: 'DOENCA', child: Text('Doença')),
                  DropdownMenuItem(value: 'PLANTA_DANINHA', child: Text('Planta Daninha')),
                ],
                onChanged: (v)=> setState(()=> _tipo = v),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextFormField(
                controller: _nomeComumController,
                decoration: const InputDecoration(labelText: 'Nome comum'),
                validator: (v)=> v==null || v.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _nomeCientController,
                decoration: const InputDecoration(labelText: 'Nome científico'),
              ),
              const SizedBox(height: 16),
              if (_photo != null) Image.file(_photo!, height: 160),
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera),
                label: const Text('Tirar foto e converter em ícone'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final repository = ref.read(organismRepositoryProvider);
                      
                      if (widget.organismo != null) {
                        // Atualizar organismo existente
                        final organismoAtualizado = Organismo(
                          id: widget.organismo!.id,
                          tipo: _tipo!,
                          nomeComum: _nomeComumController.text.trim(),
                          nomeCientifico: _nomeCientController.text.trim().isEmpty ? null : _nomeCientController.text.trim(),
                          categoria: widget.organismo!.categoria,
                          iconePath: widget.organismo!.iconePath,
                          sintomaDescricao: widget.organismo!.sintomaDescricao,
                          danoEconomico: widget.organismo!.danoEconomico,
                          partesAfetadas: widget.organismo!.partesAfetadas,
                          fenologia: widget.organismo!.fenologia,
                          niveisAcao: widget.organismo!.niveisAcao,
                          manejoQuimico: widget.organismo!.manejoQuimico,
                          manejoBiologico: widget.organismo!.manejoBiologico,
                          manejoCultural: widget.organismo!.manejoCultural,
                          observacoes: widget.organismo!.observacoes,
                        );
                        
                        await repository.updateOrganismo(organismoAtualizado);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Organismo atualizado com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      } else {
                        // Criar novo organismo
                        final organismoCompanion = OrganismosCompanion.insert(
                          tipo: _tipo!,
                          nomeComum: _nomeComumController.text.trim(),
                          nomeCientifico: Value(_nomeCientController.text.trim().isEmpty ? null : _nomeCientController.text.trim()),
                          categoria: const Value(null),
                          iconePath: const Value(null),
                          sintomaDescricao: const Value(null),
                          danoEconomico: const Value(null),
                          partesAfetadas: const Value(null),
                          fenologia: const Value(null),
                          niveisAcao: const Value(null),
                          manejoQuimico: const Value(null),
                          manejoBiologico: const Value(null),
                          manejoCultural: const Value(null),
                          observacoes: const Value(null),
                        );
                        
                        final organismoId = await repository.insertOrganismo(organismoCompanion);
                        
                        // Criar a relação com a cultura
                        final db = ref.read(databaseProvider);
                        await db.into(db.culturaOrganismo).insert(
                          CulturaOrganismoCompanion.insert(
                            culturaId: widget.culturaId,
                            organismoId: organismoId,
                            severidadeMedia: const Value(null),
                            observacoesEspecificas: const Value(null),
                          ),
                        );
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Organismo salvo com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao salvar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Salvar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

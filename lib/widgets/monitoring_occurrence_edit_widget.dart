import 'package:flutter/material.dart';
import 'safe_dropdown.dart';

/// Widget para edição de ocorrências no monitoramento
class MonitoringOccurrenceEditWidget extends StatefulWidget {
  final Map<String, dynamic> occurrence;
  final Function(Map<String, dynamic>) onSave;
  final Function() onDelete;
  final VoidCallback? onCancel;

  const MonitoringOccurrenceEditWidget({
    Key? key,
    required this.occurrence,
    required this.onSave,
    required this.onDelete,
    this.onCancel,
  }) : super(key: key);

  @override
  _MonitoringOccurrenceEditWidgetState createState() => _MonitoringOccurrenceEditWidgetState();
}

class _MonitoringOccurrenceEditWidgetState extends State<MonitoringOccurrenceEditWidget> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  
  String? _selectedType;
  String? _selectedSeverity;
  String? _selectedPhase;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.occurrence['name'] ?? '');
    _quantityController = TextEditingController(text: widget.occurrence['quantity']?.toString() ?? '0');
    _notesController = TextEditingController(text: widget.occurrence['notes'] ?? '');
    
    // Validar e definir valores seguros para os dropdowns
    _selectedType = _validateDropdownValue(
      widget.occurrence['type']?.toString(),
      ['pest', 'disease', 'weed']
    );
    
    _selectedSeverity = _validateDropdownValue(
      widget.occurrence['severity']?.toString(),
      ['Baixo', 'Médio', 'Alto', 'Crítico']
    );
    
    _selectedPhase = _validateDropdownValue(
      widget.occurrence['phase']?.toString(),
      ['Larva', 'Ninfal', 'Adulto', 'Ovo']
    );
  }

  /// Valida se o valor existe na lista, caso contrário retorna null
  String? _validateDropdownValue(String? value, List<String> validValues) {
    if (value == null || !validValues.contains(value)) {
      return null;
    }
    return value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Editar Ocorrência',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Formulário
            Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do organismo
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Organismo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bug_report),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tipo de organismo
                  SafeDropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pest', child: Text('Praga')),
                      DropdownMenuItem(value: 'disease', child: Text('Doença')),
                      DropdownMenuItem(value: 'weed', child: Text('Planta Daninha')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Tipo é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Severidade
                  SafeDropdownButtonFormField<String>(
                    value: _selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Severidade',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Baixo', child: Text('Baixo')),
                      DropdownMenuItem(value: 'Médio', child: Text('Médio')),
                      DropdownMenuItem(value: 'Alto', child: Text('Alto')),
                      DropdownMenuItem(value: 'Crítico', child: Text('Crítico')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSeverity = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Severidade é obrigatória';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fase
                  SafeDropdownButtonFormField<String>(
                    value: _selectedPhase,
                    decoration: const InputDecoration(
                      labelText: 'Fase (Opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timeline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Larva', child: Text('Larva')),
                      DropdownMenuItem(value: 'Ninfal', child: Text('Ninfal')),
                      DropdownMenuItem(value: 'Adulto', child: Text('Adulto')),
                      DropdownMenuItem(value: 'Ovo', child: Text('Ovo')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPhase = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantidade
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Quantidade é obrigatória';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity < 0) {
                        return 'Quantidade deve ser um número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Observações
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _deleteOccurrence,
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveOccurrence,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOccurrence() async {
    if (_nameController.text.isEmpty || _selectedType == null || _selectedSeverity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedOccurrence = {
        ...widget.occurrence,
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'severity': _selectedSeverity,
        'phase': _selectedPhase,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'notes': _notesController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await widget.onSave(updatedOccurrence);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteOccurrence() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta ocorrência? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await widget.onDelete();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocorrência excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

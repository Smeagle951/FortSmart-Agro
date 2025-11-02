import 'package:flutter/material.dart';
import '../../../models/infestacao_model.dart';
import '../../../widgets/new_occurrence_card.dart';

class PointMonitoringOccurrencesList extends StatefulWidget {
  final List<InfestacaoModel> ocorrencias;
  final Function(String) onDelete;
  final Function({
    required String tipo,
    required String subtipo,
    required String nivel,
    required int numeroInfestacao,
    String? observacao,
    List<String>? fotoPaths,
  }) onSaveOccurrence;

  const PointMonitoringOccurrencesList({
    Key? key,
    required this.ocorrencias,
    required this.onDelete,
    required this.onSaveOccurrence,
  }) : super(key: key);

  @override
  State<PointMonitoringOccurrencesList> createState() => _PointMonitoringOccurrencesListState();
}

class _PointMonitoringOccurrencesListState extends State<PointMonitoringOccurrencesList> {
  final Set<String> _expandedItems = {};
  
  // Controllers para o formulário integrado
  final _formKey = GlobalKey<FormState>();
  String _selectedTipo = 'Praga';
  String _selectedSubtipo = '';
  int _numeroInfestacao = 0;
  String _observacao = '';
  List<String> _fotoPaths = [];
  
  // Opções para os dropdowns
  final List<String> _tipos = ['Praga', 'Doença', 'Daninha', 'Outro'];
  Map<String, List<String>> _subtipos = {
    'Praga': ['Lagarta-do-cartucho', 'Percevejo', 'Mosca-branca', 'Ácaro', 'Outro'],
    'Doença': ['Ferrugem', 'Mancha', 'Míldio', 'Antracnose', 'Outro'],
    'Daninha': ['Buva', 'Capim-amargoso', 'Caruru', 'Picão-preto', 'Outro'],
    'Outro': ['Outro'],
  };

  @override
  Widget build(BuildContext context) {
    if (widget.ocorrencias.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.ocorrencias.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        color: Color(0xFFE0E0E0),
      ),
      itemBuilder: (context, index) {
        final ocorrencia = widget.ocorrencias[index];
        final isExpanded = _expandedItems.contains(ocorrencia.id);
        
        return _buildOccurrenceItem(ocorrencia, isExpanded);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bug_report_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma ocorrência registrada neste ponto.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em "Nova Ocorrência" para começar o registro.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccurrenceItem(InfestacaoModel ocorrencia, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          // Ícone do tipo
          Text(
            _getTipoIcon(ocorrencia.tipo),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          
          // Informações principais
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ocorrencia.subtipo,
                  style: const TextStyle(
                    color: Color(0xFF2C2C2C),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getNivelColor(ocorrencia.nivel),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ocorrencia.nivel} (${ocorrencia.percentual > 0 ? ocorrencia.percentual : 1}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (ocorrencia.observacao != null && ocorrencia.observacao!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Obs: ${ocorrencia.observacao}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Botões de ação
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _editOccurrence(ocorrencia),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D9CDB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF2D9CDB),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteOccurrence(ocorrencia),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB5757).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete,
                    size: 16,
                    color: Color(0xFFEB5757),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF95A5A6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(InfestacaoModel ocorrencia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos',
          style: TextStyle(
            color: Color(0xFF95A5A6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ocorrencia.localPhotoPaths.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showPhoto(ocorrencia.localPhotoPaths[index]),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/placeholder.png', // Placeholder
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF95A5A6),
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(InfestacaoModel ocorrencia) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _editOccurrence(ocorrencia),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2D9CDB),
              side: const BorderSide(color: Color(0xFF2D9CDB)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _deleteOccurrence(ocorrencia),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Deletar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEB5757),
              side: const BorderSide(color: Color(0xFFEB5757)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTipoBackgroundColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return const Color(0xFFF2994A).withOpacity(0.15);
      case 'doença':
        return const Color(0xFF9B51E0).withOpacity(0.15);
      case 'daninha':
        return const Color(0xFF27AE60).withOpacity(0.15);
      default:
        return const Color(0xFF2D9CDB).withOpacity(0.15);
    }
  }

  Color _getNivelColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'crítico':
        return const Color(0xFFEB5757);
      case 'alto':
        return const Color(0xFFF2C94C);
      case 'médio':
        return const Color(0xFF2D9CDB);
      case 'baixo':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _toggleExpansion(String id) {
    setState(() {
      if (_expandedItems.contains(id)) {
        _expandedItems.remove(id);
      } else {
        _expandedItems.add(id);
      }
    });
  }

  void _showPhoto(String photoPath) {
    // Implementar visualizador de foto
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  photoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(
                        Icons.image,
                        color: Color(0xFF95A5A6),
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editOccurrence(InfestacaoModel ocorrencia) {
    // ✅ ABRIR O NewOccurrenceCard COM DADOS PRÉ-PREENCHIDOS
    // Converter tipo de inglês para português se necessário
    String tipoConvertido = _converterTipoParaPortugues(ocorrencia.tipo);
    
    // Preparar dados para o card de edição
    final dadosEdicao = {
      'id': ocorrencia.id, // ✅ ID para identificar que é edição
      'tipo': tipoConvertido,
      'subtipo': ocorrencia.subtipo,
      'organism_name': ocorrencia.subtipo,
      'nivel': ocorrencia.nivel,
      'percentual': ocorrencia.percentual,
      'quantidade': ocorrencia.percentual, // ✅ Quantidade de pragas
      'observacao': ocorrencia.observacao ?? '',
      'observacoes': ocorrencia.observacao ?? '',
      'foto_paths': ocorrencia.localPhotoPaths,
      'fotoPaths': ocorrencia.localPhotoPaths,
      'isEdit': true, // ✅ Flag indicando que é edição
    };
    
    // Abrir modal com NewOccurrenceCard
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext modalContext) {
        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle para arrastar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Conteúdo do modal - NewOccurrenceCard
              Expanded(
                child: NewOccurrenceCard(
                  cropName: 'Soja', // TODO: Passar cultura real
                  fieldId: ocorrencia.talhaoId.toString(),
                  initialData: dadosEdicao, // ✅ Passar dados iniciais para edição
                  onOccurrenceAdded: (data) async {
                    // ✅ ATUALIZAR OCORRÊNCIA EXISTENTE
                    await _updateOccurrence(ocorrencia.id, data);
                    Navigator.of(modalContext).pop();
                  },
                  onClose: () {
                    Navigator.of(modalContext).pop();
                  },
                  onSaveAndAdvance: () async {
                    // Em modo de edição, apenas salvar e fechar
                    Navigator.of(modalContext).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Converte tipo de inglês para português
  String _converterTipoParaPortugues(String tipo) {
    final tipoLower = tipo.toLowerCase();
    if (tipoLower.contains('pest') || tipoLower == 'praga') return 'Praga';
    if (tipoLower.contains('disease') || tipoLower == 'doença') return 'Doença';
    if (tipoLower.contains('weed') || tipoLower == 'daninha') return 'Daninha';
    if (tipoLower.contains('deficiency') || tipoLower == 'deficiência') return 'Deficiência';
    return 'Outro';
  }
  
  /// Atualiza ocorrência no banco de dados
  Future<void> _updateOccurrence(String occurrenceId, Map<String, dynamic> data) async {
    try {
      // ✅ PERSISTIR DADOS ALTERADOS
      final nivel = _getNivelFromNumber(data['quantity'] ?? data['percentual'] ?? 0);
      
      await widget.onSaveOccurrence(
        tipo: data['tipo'] ?? data['type'] ?? 'Outro',
        subtipo: data['subtipo'] ?? data['organism_name'] ?? '',
        nivel: nivel,
        numeroInfestacao: data['quantity'] ?? data['percentual'] ?? 0,
        observacao: data['observacao'] ?? data['observacoes'],
        fotoPaths: data['foto_paths'] ?? data['fotoPaths'],
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorrência atualizada com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar ocorrência: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _deleteOccurrence(InfestacaoModel ocorrencia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a ocorrência "${ocorrencia.subtipo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete(ocorrencia.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares para o formulário integrado
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D9CDB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInfestationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de Infestação',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _numeroInfestacao.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2D9CDB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  _numeroInfestacao = int.tryParse(value) ?? 0;
                  setState(() {});
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o número de infestação';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getNivelColor(_getNivelFromNumber(_numeroInfestacao)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getNivelFromNumber(_numeroInfestacao),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D9CDB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintText: maxLines > 1 ? 'Descreva a ocorrência observada...' : null,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }


  String _getNivelFromNumber(int numero) {
    if (numero <= 2) return 'Baixo';
    if (numero <= 5) return 'Médio';
    if (numero <= 10) return 'Alto';
    return 'Crítico';
  }

  String _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return '🐛';
      case 'doença':
        return '🦠';
      case 'daninha':
        return '🌿';
      default:
        return '📋';
    }
  }

  void _clearForm() {
    setState(() {
      _selectedTipo = 'Praga';
      _selectedSubtipo = '';
      _numeroInfestacao = 0;
      _observacao = '';
      _fotoPaths.clear();
    });
  }

  void _saveOccurrence() {
    if (_formKey.currentState!.validate()) {
      final nivel = _getNivelFromNumber(_numeroInfestacao);
      
      widget.onSaveOccurrence(
        tipo: _selectedTipo,
        subtipo: _selectedSubtipo,
        nivel: nivel,
        numeroInfestacao: _numeroInfestacao,
        observacao: _observacao.isEmpty ? null : _observacao,
        fotoPaths: _fotoPaths.isEmpty ? null : _fotoPaths,
      );
      
      _clearForm();
    }
  }

  void _addPhoto() {
    // Implementar captura de foto
    setState(() {
      _fotoPaths.add('assets/images/placeholder.png'); // Placeholder
    });
  }

  void _addPhotoFromGallery() {
    // Implementar seleção da galeria
    setState(() {
      _fotoPaths.add('assets/images/placeholder.png'); // Placeholder
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _fotoPaths.removeAt(index);
    });
  }

  Widget _buildEditModal(InfestacaoModel ocorrencia) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle do modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.edit,
                  color: Color(0xFF2D9CDB),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Editar Ocorrência',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Formulário
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo
                    _buildDropdownField(
                      label: 'Tipo',
                      value: _selectedTipo,
                      items: _tipos,
                      onChanged: (value) {
                        setState(() {
                          _selectedTipo = value!;
                          _selectedSubtipo = ''; // Reset subtipo
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subtipo
                    _buildDropdownField(
                      label: 'Subtipo',
                      value: _selectedSubtipo.isEmpty ? null : _selectedSubtipo,
                      items: (_subtipos[_selectedTipo] ?? []).toSet().toList(), // Remover duplicatas
                      onChanged: (value) {
                        setState(() {
                          _selectedSubtipo = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecione um subtipo';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Número de Infestação
                    _buildNumberInfestationField(),
                    
                    const SizedBox(height: 16),
                    
                    // Observação
                    _buildTextField(
                      label: 'Observação (opcional)',
                      value: _observacao,
                      onChanged: (value) => _observacao = value,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fotos
                    _buildPhotosSection(ocorrencia),
                    
                    const SizedBox(height: 24),
                    
                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _saveEditedOccurrence(ocorrencia),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D9CDB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Salvar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveEditedOccurrence(InfestacaoModel ocorrencia) {
    if (_formKey.currentState!.validate()) {
      final nivel = _getNivelFromNumber(_numeroInfestacao);
      
      // Criar ocorrência editada
      final editedOccurrence = InfestacaoModel(
        id: ocorrencia.id,
        talhaoId: ocorrencia.talhaoId,
        pontoId: ocorrencia.pontoId,
        latitude: ocorrencia.latitude,
        longitude: ocorrencia.longitude,
        tipo: _selectedTipo,
        subtipo: _selectedSubtipo,
        nivel: nivel,
        percentual: _numeroInfestacao,
        observacao: _observacao.isEmpty ? null : _observacao,
        fotoPaths: _fotoPaths.join(';'),
        dataHora: ocorrencia.dataHora,
        sincronizado: false, // Marcar como não sincronizado após edição
      );
      
      // Chamar callback para salvar no banco
      widget.onSaveOccurrence(
        tipo: _selectedTipo,
        subtipo: _selectedSubtipo,
        nivel: nivel,
        numeroInfestacao: _numeroInfestacao,
        observacao: _observacao.isEmpty ? null : _observacao,
        fotoPaths: _fotoPaths.isEmpty ? null : _fotoPaths,
      );
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorrência editada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _clearForm();
    }
  }
}

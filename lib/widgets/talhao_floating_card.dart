import 'package:flutter/material.dart';
import '../models/cultura_model.dart';
import '../models/talhao_model.dart';
import '../screens/plantio/subarea_routes.dart';
import '../models/experimento_talhao_model.dart';

/// Card flutuante para edição rápida de talhão
class TalhaoFloatingCard extends StatefulWidget {
  final TalhaoModel talhao;
  final List<CulturaModel> culturas;
  final List<String> safras;
  final Function(TalhaoModel) onSave;
  final Function(TalhaoModel) onDelete;
  final VoidCallback onClose;

  const TalhaoFloatingCard({
    Key? key,
    required this.talhao,
    required this.culturas,
    required this.safras,
    required this.onSave,
    required this.onDelete,
    required this.onClose,
  }) : super(key: key);

  @override
  State<TalhaoFloatingCard> createState() => _TalhaoFloatingCardState();
}

class _TalhaoFloatingCardState extends State<TalhaoFloatingCard> {
  late TextEditingController _nameController;
  late TextEditingController _areaController;
  String? _selectedCulturaId;
  String? _selectedSafra;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.talhao.name);
    _areaController = TextEditingController(text: widget.talhao.area.toStringAsFixed(2));
    
    // CORREÇÃO: Validar se o ID da cultura é válido antes de usar
    _selectedCulturaId = _getValidCulturaId(widget.talhao.culturaId);
    _selectedSafra = _getValidSafra(widget.talhao.safra?.safra ?? widget.safras.first);
    
    print('🚨 DEBUG TALHAO FLOATING CARD - initState:');
    print('  - Talhão: ${widget.talhao.name}');
    print('  - Cultura ID original: ${widget.talhao.culturaId}');
    print('  - Cultura ID selecionada: $_selectedCulturaId');
    print('  - Safra selecionada: $_selectedSafra');
    print('  - Culturas disponíveis: ${widget.culturas.map((c) => '${c.id}: ${c.name}').join(', ')}');
  }
  
  /// Obtém um ID de cultura válido
  String? _getValidCulturaId(String? culturaId) {
    if (culturaId == null) {
      return widget.culturas.isNotEmpty ? widget.culturas.first.id.toString() : null;
    }
    
    // Verificar se o ID existe na lista de culturas disponíveis
    final culturaExiste = widget.culturas.any((c) => c.id.toString() == culturaId);
    if (culturaExiste) {
      return culturaId;
    }
    
    // Se for um ID custom_ que não existe, tentar encontrar por nome
    if (culturaId.startsWith('custom_')) {
      print('🚨 DEBUG: ID custom_ detectado: $culturaId');
      
      // Tentar extrair o nome da cultura do ID custom_
      String? nomeCultura;
      if (culturaId.contains('_')) {
        final partes = culturaId.split('_');
        if (partes.length > 1) {
          nomeCultura = partes.sublist(1).join('_');
        }
      }
      
      // Tentar encontrar por nome extraído do ID
      if (nomeCultura != null && nomeCultura.isNotEmpty) {
        try {
          final culturaEncontrada = widget.culturas.firstWhere(
            (c) => c.name.toLowerCase().contains(nomeCultura?.toLowerCase() ?? '') ||
                   (nomeCultura?.toLowerCase() ?? '').contains(c.name.toLowerCase()),
          );
          print('✅ DEBUG: Cultura encontrada por nome do ID: ${culturaEncontrada.name} (ID: ${culturaEncontrada.id})');
          return culturaEncontrada.id.toString();
        } catch (e) {
          print('⚠️ DEBUG: Cultura não encontrada por nome do ID: $nomeCultura');
        }
      }
    }
    
    // Fallback: usar primeira cultura disponível
    if (widget.culturas.isNotEmpty) {
      print('🚨 DEBUG: Usando primeira cultura disponível: ${widget.culturas.first.name} (ID: ${widget.culturas.first.id})');
      return widget.culturas.first.id.toString();
    }
    
    return null;
  }
  
  /// Obtém uma safra válida
  String? _getValidSafra(String? safra) {
    if (safra == null || !widget.safras.contains(safra)) {
      return widget.safras.isNotEmpty ? widget.safras.first : null;
    }
    return safra;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE8F5E8), // Verde muito claro
              const Color(0xFFF0F8F0), // Verde claro
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com título e botão fechar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.agriculture,
                    color: const Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Talhão',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'ID: ${widget.talhao.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Informações do talhão
            _buildInfoSection(),
            
            const SizedBox(height: 20),
            
            // Botões de ação
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    if (_isEditing) {
      return _buildEditForm();
    } else {
      return _buildDisplayInfo();
    }
  }

  Widget _buildDisplayInfo() {
    final cultura = widget.culturas.firstWhere(
      (c) => c.id.toString() == _selectedCulturaId,
      orElse: () => widget.culturas.first,
    );

    return Column(
      children: [
        // Nome do talhão
        _buildInfoRow(
          icon: Icons.label,
          label: 'Nome',
          value: widget.talhao.name,
          color: Colors.blue,
        ),
        
        const SizedBox(height: 12),
        
        // Área
        _buildInfoRow(
          icon: Icons.area_chart,
          label: 'Área',
          value: '${widget.talhao.area.toStringAsFixed(2)} ha',
          color: Colors.green,
        ),
        
        const SizedBox(height: 12),
        
        // Cultura
        _buildInfoRow(
          icon: Icons.eco,
          label: 'Cultura',
          value: cultura.name,
          color: Colors.grey[600]!, // Cor neutra para melhor legibilidade
        ),
        
        const SizedBox(height: 12),
        
        // Safra
        _buildInfoRow(
          icon: Icons.calendar_today,
          label: 'Safra',
          value: _selectedSafra ?? 'Não definida',
          color: Colors.orange,
        ),
        
        const SizedBox(height: 12),
        
        // Polígonos
        _buildInfoRow(
          icon: Icons.terrain,
          label: 'Polígonos',
          value: '${widget.talhao.poligonos.length}',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        // Nome
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome do Talhão',
            prefixIcon: Icon(Icons.label, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Área
        TextField(
          controller: _areaController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Área (hectares)',
            prefixIcon: Icon(Icons.area_chart, color: Colors.green),
            suffixText: 'ha',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Cultura
        DropdownButtonFormField<String>(
          value: _selectedCulturaId != null && widget.culturas.any((c) => c.id.toString() == _selectedCulturaId) 
              ? _selectedCulturaId 
              : (widget.culturas.isNotEmpty ? widget.culturas.first.id.toString() : null),
          decoration: InputDecoration(
            labelText: 'Cultura',
            prefixIcon: Icon(Icons.eco, color: Colors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.orange, width: 2),
            ),
          ),
          items: widget.culturas.map((cultura) {
            return DropdownMenuItem(
              value: cultura.id.toString(),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[600]!, // Cor neutra
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(cultura.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCulturaId = value;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Safra
        DropdownButtonFormField<String>(
          value: _selectedSafra != null && widget.safras.contains(_selectedSafra) 
              ? _selectedSafra 
              : (widget.safras.isNotEmpty ? widget.safras.first : null),
          decoration: InputDecoration(
            labelText: 'Safra',
            prefixIcon: Icon(Icons.calendar_today, color: Colors.purple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.purple, width: 2),
            ),
          ),
          items: widget.safras.map((safra) {
            return DropdownMenuItem(
              value: safra,
              child: Text(safra),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSafra = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _cancelEdit,
              icon: Icon(Icons.cancel, color: Colors.grey.shade600),
              label: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: _isLoading 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.save, color: Colors.white),
              label: Text('Salvar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _startEdit,
              icon: Icon(Icons.edit, color: Colors.blue),
              label: Text('Editar', style: TextStyle(color: Colors.blue)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _abrirSubareas,
              icon: Icon(Icons.map, color: Colors.white),
              label: Text('Subáreas', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _confirmDelete,
              icon: Icon(Icons.delete, color: Colors.white),
              label: Text('Remover', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  void _abrirSubareas() {
    try {
      // Criar um experimento baseado no talhão
      final experimento = Experimento(
        id: 'exp_${widget.talhao.id}_${DateTime.now().millisecondsSinceEpoch}',
        nome: 'Experimento ${widget.talhao.name}',
        talhaoId: widget.talhao.id.toString(),
        talhaoNome: widget.talhao.name,
        dataInicio: DateTime.now(),
        status: 'ativo',
        criadoEm: DateTime.now(),
        cultura: widget.talhao.crop?.name,
        variedade: widget.talhao.crop?.description,
      );

      // Fechar o card e navegar para subáreas
      widget.onClose();
      SubareaRoutes.navigateToTalhaoDetalhes(context, experimento);
    } catch (e) {
      _showSnackBar('Erro ao abrir subáreas: $e', Colors.red);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      // Restaurar valores originais
      _nameController.text = widget.talhao.name;
      _areaController.text = widget.talhao.area.toStringAsFixed(2);
        _selectedCulturaId = widget.talhao.culturaId;
      _selectedSafra = widget.talhao.safra?.safra ?? widget.safras.first;
    });
  }

  void _saveChanges() {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Nome do talhão é obrigatório', Colors.red);
      return;
    }

    if (_selectedCulturaId == null) {
      _showSnackBar('Selecione uma cultura', Colors.red);
      return;
    }

    if (_selectedSafra == null) {
      _showSnackBar('Selecione uma safra', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Criar talhão atualizado
    final updatedTalhao = TalhaoModel(
      id: widget.talhao.id,
      name: _nameController.text.trim(),
      poligonos: widget.talhao.poligonos,
      area: double.tryParse(_areaController.text) ?? widget.talhao.area,
      fazendaId: widget.talhao.fazendaId,
      dataCriacao: widget.talhao.dataCriacao,
      dataAtualizacao: DateTime.now(),
      sincronizado: false,
      observacoes: widget.talhao.observacoes,
      metadados: widget.talhao.metadados,
      safras: widget.talhao.safras,
      culturaId: _selectedCulturaId!,
      safraId: null,
      crop: null,
    );

    widget.onSave(updatedTalhao);
    
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    _showSnackBar('Talhão atualizado com sucesso!', Colors.green);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirmar Exclusão'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja remover o talhão "${widget.talhao.name}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(widget.talhao);
              _showSnackBar('Talhão removido com sucesso!', Colors.orange);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

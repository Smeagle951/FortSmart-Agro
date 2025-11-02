import 'package:flutter/material.dart';
import '../../models/organism_catalog.dart';
import '../../repositories/organism_catalog_repository.dart';
import '../../utils/enums.dart';
import '../../utils/app_colors.dart';
import '../../scripts/fix_organism_catalog.dart';
import '../../scripts/force_reload_organism_catalog.dart';
import '../../scripts/fix_organism_catalog_data.dart';

/// Tela de configuração do catálogo de organismos
/// Permite ao usuário definir limites de controle para pragas, doenças e plantas daninhas
class OrganismCatalogScreen extends StatefulWidget {
  const OrganismCatalogScreen({Key? key}) : super(key: key);

  @override
  State<OrganismCatalogScreen> createState() => _OrganismCatalogScreenState();
}

class _OrganismCatalogScreenState extends State<OrganismCatalogScreen> {
  final OrganismCatalogRepository _repository = OrganismCatalogRepository();
  
  List<OrganismCatalog> _organisms = [];
  List<OrganismCatalog> _filteredOrganisms = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Filtros
  OccurrenceType _selectedType = OccurrenceType.pest;
  String _selectedCrop = 'Todas';
  String _searchQuery = '';
  
  // Controladores para o formulário
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lowLimitController = TextEditingController();
  final _mediumLimitController = TextEditingController();
  final _highLimitController = TextEditingController();
  final _unitController = TextEditingController();
  
  OccurrenceType _formType = OccurrenceType.pest;
  String _formCropId = 'soja';
  String _formCropName = 'Soja';

  @override
  void initState() {
    super.initState();
    _loadOrganisms();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _lowLimitController.dispose();
    _mediumLimitController.dispose();
    _highLimitController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  /// Carrega os organismos do banco de dados
  Future<void> _loadOrganisms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.initialize();
      
      // Verifica se o catálogo está vazio e insere dados padrão
      if (await _repository.isEmpty()) {
        await _repository.insertDefaultData();
      }
      
      final organisms = await _repository.getAll();
      
      setState(() {
        _organisms = organisms;
        _filteredOrganisms = organisms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Tratamento específico para erro de constraint de chave estrangeira
      String errorMessage = 'Erro ao carregar organismos';
      if (e.toString().contains('FOREIGN KEY constraint failed')) {
        errorMessage = 'Erro de integridade do banco de dados. Tentando corrigir automaticamente...';
        // Tentar corrigir o problema
        await _fixDatabaseIntegrity();
      } else {
        errorMessage = 'Erro ao carregar organismos: $e';
      }
      
      _showErrorMessage(errorMessage);
    }
  }

  /// Tenta corrigir problemas de integridade do banco de dados
  Future<void> _fixDatabaseIntegrity() async {
    try {
      // Recriar o repositório e inserir dados padrão
      await _repository.initialize();
      await _repository.insertDefaultData();
      
      // Tentar carregar novamente
      final organisms = await _repository.getAll();
      
      setState(() {
        _organisms = organisms;
        _filteredOrganisms = organisms;
      });
      
      _showSuccessMessage('Problema corrigido automaticamente!');
    } catch (e) {
      _showErrorMessage('Não foi possível corrigir automaticamente. Erro: $e');
    }
  }

  /// Aplica filtros na lista de organismos
  void _applyFilters() {
    setState(() {
      _filteredOrganisms = _organisms.where((organism) {
        // Filtro por tipo
        if (organism.type != _selectedType) return false;
        
        // Filtro por cultura
        if (_selectedCrop != 'Todas' && organism.cropName != _selectedCrop) return false;
        
        // Filtro por busca
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return organism.name.toLowerCase().contains(query) ||
                 organism.scientificName.toLowerCase().contains(query);
        }
        
        return true;
      }).toList();
    });
  }
  
  /// Valida e corrige o tipo de ocorrência
  OccurrenceType _validateOccurrenceType(OccurrenceType type) {
    // Verificar se o tipo é válido
    if (OccurrenceType.values.contains(type)) {
      return type;
    }
    
    // Se não for válido, usar fallback
    print('⚠️ Tipo de ocorrência inválido: $type, usando fallback: ${OccurrenceType.pest}');
    return OccurrenceType.pest;
  }
  
  /// Valida e corrige o cropId
  String _validateCropId(String cropId) {
    final validCropIds = ['soja', 'milho', 'algodao', 'feijao'];
    
    if (validCropIds.contains(cropId)) {
      return cropId;
    }
    
    // Se não for válido, usar fallback
    print('⚠️ CropId inválido: $cropId, usando fallback: soja');
    return 'soja';
  }

  /// Mostra o formulário para adicionar/editar organismo
  void _showOrganismForm([OrganismCatalog? organism]) {
    final isEditing = organism != null;
    
    if (isEditing) {
      _nameController.text = organism.name;
      _scientificNameController.text = organism.scientificName;
      _descriptionController.text = organism.description ?? '';
      _lowLimitController.text = organism.lowLimit.toString();
      _mediumLimitController.text = organism.mediumLimit.toString();
      _highLimitController.text = organism.highLimit.toString();
      _unitController.text = organism.unit;
      
      // Validar e corrigir o tipo do organismo
      _formType = _validateOccurrenceType(organism.type);
      
      // Validar e corrigir o cropId
      _formCropId = _validateCropId(organism.cropId);
      _formCropName = organism.cropName;
    } else {
      _nameController.clear();
      _scientificNameController.clear();
      _descriptionController.clear();
      _lowLimitController.clear();
      _mediumLimitController.clear();
      _highLimitController.clear();
      _unitController.clear();
      _formType = OccurrenceType.pest;
      _formCropId = 'soja';
      _formCropName = 'Soja';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrganismForm(isEditing, organism),
    );
  }

  /// Constrói o formulário de organismo
  Widget _buildOrganismForm(bool isEditing, OrganismCatalog? organism) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Editar Organismo' : 'Novo Organismo',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Campos do formulário
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Nome comum
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Comum *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Nome científico
                      TextFormField(
                        controller: _scientificNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Científico',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tipo de organismo
                      DropdownButtonFormField<OccurrenceType>(
                        value: _validateOccurrenceType(_formType),
                        decoration: const InputDecoration(
                          labelText: 'Tipo *',
                          border: OutlineInputBorder(),
                        ),
                        items: OccurrenceType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeDisplayName(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _formType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Cultura
                      DropdownButtonFormField<String>(
                        value: _validateCropId(_formCropId),
                        decoration: const InputDecoration(
                          labelText: 'Cultura *',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'soja', child: Text('Soja')),
                          DropdownMenuItem(value: 'milho', child: Text('Milho')),
                          DropdownMenuItem(value: 'algodao', child: Text('Algodão')),
                          DropdownMenuItem(value: 'feijao', child: Text('Feijão')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _formCropId = value!;
                            _formCropName = _getCropDisplayName(value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Unidade de medição
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unidade de Medição *',
                          hintText: 'Ex: indivíduos/ponto, % folhas, plantas/m²',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Unidade é obrigatória';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Limites
                      const Text(
                        'Limites de Controle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lowLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Baixo',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _mediumLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Médio',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _highLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Alto',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Descrição
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botões
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveOrganism(organism),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Atualizar' : 'Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Salva o organismo
  Future<void> _saveOrganism(OrganismCatalog? organism) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final newOrganism = OrganismCatalog(
        id: organism?.id,
        name: _nameController.text.trim(),
        scientificName: _scientificNameController.text.trim(),
        type: _formType,
        cropId: _formCropId,
        cropName: _formCropName,
        unit: _unitController.text.trim(),
        lowLimit: int.parse(_lowLimitController.text),
        mediumLimit: int.parse(_mediumLimitController.text),
        highLimit: int.parse(_highLimitController.text),
        description: _descriptionController.text.trim(),
      );

      if (organism != null) {
        await _repository.update(newOrganism);
        _showSuccessMessage('Organismo atualizado com sucesso!');
      } else {
        await _repository.create(newOrganism);
        _showSuccessMessage('Organismo criado com sucesso!');
      }

      Navigator.pop(context);
      await _loadOrganisms();
      _applyFilters();
    } catch (e) {
      _showErrorMessage('Erro ao salvar organismo: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Exclui um organismo
  Future<void> _deleteOrganism(OrganismCatalog organism) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir "${organism.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.delete(organism.id);
        _showSuccessMessage('Organismo excluído com sucesso!');
        await _loadOrganisms();
        _applyFilters();
      } catch (e) {
        _showErrorMessage('Erro ao excluir organismo: $e');
      }
    }
  }

  /// Constrói o card de um organismo
  Widget _buildOrganismCard(OrganismCatalog organism) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(organism.type),
          child: Icon(
            _getTypeIcon(organism.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          organism.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(organism.scientificName),
            Text('${organism.cropName} • ${organism.unit}'),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildLimitChip('Baixo', organism.lowLimit, Colors.green),
                const SizedBox(width: 4),
                _buildLimitChip('Médio', organism.mediumLimit, Colors.orange),
                const SizedBox(width: 4),
                _buildLimitChip('Alto', organism.highLimit, Colors.red),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showOrganismForm(organism);
            } else if (value == 'delete') {
              _deleteOrganism(organism);
            }
          },
        ),
      ),
    );
  }

  /// Constrói chip de limite
  Widget _buildLimitChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Obtém nome de exibição do tipo
  String _getTypeDisplayName(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Planta Daninha';
      default:
        return 'Outro';
    }
  }

  /// Obtém nome de exibição da cultura
  String _getCropDisplayName(String cropId) {
    switch (cropId) {
      case 'soja':
        return 'Soja';
      case 'milho':
        return 'Milho';
      case 'algodao':
        return 'Algodão';
      case 'feijao':
        return 'Feijão';
      default:
        return 'Soja';
    }
  }

  /// Obtém cor do tipo
  Color _getTypeColor(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Colors.red;
      case OccurrenceType.disease:
        return Colors.orange;
      case OccurrenceType.weed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Obtém ícone do tipo
  IconData _getTypeIcon(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Icons.bug_report;
      case OccurrenceType.disease:
        return Icons.coronavirus;
      case OccurrenceType.weed:
        return Icons.grass;
      default:
        return Icons.help;
    }
  }

  /// Mostra mensagem de sucesso
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Mostra mensagem de erro
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Mostra opções de correção
  void _showFixOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corrigir Problemas'),
        content: const Text(
          'Esta opção irá corrigir problemas de integridade do banco de dados. '
          'Isso pode recriar a tabela de organismos. Deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeFix();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Corrigir'),
          ),
        ],
      ),
    );
  }

  /// Executa a correção
  Future<void> _executeFix() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await fixOrganismCatalog();
      await _loadOrganisms();
      _showSuccessMessage('Problemas corrigidos com sucesso!');
    } catch (e) {
      _showErrorMessage('Erro durante a correção: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Força a recriação completa do catálogo
  Future<void> _forceReloadCatalog() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Mostrar diálogo de confirmação
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🔄 Atualizar Catálogo de Organismos'),
          content: Text(
            'Isso irá recarregar o catálogo com os dados atualizados:\n\n'
            '🌱 9 culturas principais (Soja, Milho, Sorgo, Algodão, Feijão, Girassol, Aveia, Trigo, Gergelim)\n'
            '🦗 Pragas específicas por cultura (incluindo Torrãozinho na soja)\n'
            '🦠 Doenças específicas por cultura\n'
            '🌿 Plantas daninhas\n\n'
            'Todos os dados atuais serão substituídos. Deseja continuar?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('✅ Atualizar'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Executar recriação forçada
      final reloader = ForceReloadOrganismCatalog();
      await reloader.forceReload();

      // Recarregar organismos
      await _loadOrganisms();
      
      _showSuccessMessage('✅ Catálogo atualizado com sucesso!\n🌱 9 culturas principais\n🦗 Pragas específicas por cultura\n🦠 Doenças específicas por cultura\n🌿 Plantas daninhas\n🐛 Torrãozinho adicionado à soja');
    } catch (e) {
      _showErrorMessage('Erro ao recarregar catálogo: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Organismos'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: _showFixOptions,
            tooltip: 'Corrigir Problemas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceReloadCatalog,
            tooltip: '🔄 Atualizar Catálogo',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Barra de busca
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar organismos...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Filtros de tipo e cultura
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<OccurrenceType>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
                                border: OutlineInputBorder(),
                              ),
                              items: OccurrenceType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_getTypeDisplayName(type)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCrop,
                              decoration: const InputDecoration(
                                labelText: 'Cultura',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                                const DropdownMenuItem(value: 'Soja', child: Text('🌱 Soja')),
                                const DropdownMenuItem(value: 'Milho', child: Text('🌽 Milho')),
                                const DropdownMenuItem(value: 'Sorgo', child: Text('🌾 Sorgo')),
                                const DropdownMenuItem(value: 'Algodão', child: Text('👕 Algodão')),
                                const DropdownMenuItem(value: 'Feijão', child: Text('🫘 Feijão')),
                                const DropdownMenuItem(value: 'Girassol', child: Text('🌻 Girassol')),
                                const DropdownMenuItem(value: 'Aveia', child: Text('🌾 Aveia')),
                                const DropdownMenuItem(value: 'Trigo', child: Text('🌾 Trigo')),
                                const DropdownMenuItem(value: 'Gergelim', child: Text('🌿 Gergelim')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCrop = value!;
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Lista de organismos
                Expanded(
                  child: _filteredOrganisms.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum organismo encontrado',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredOrganisms.length,
                          itemBuilder: (context, index) {
                            return _buildOrganismCard(_filteredOrganisms[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrganismForm(),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

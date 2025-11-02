import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/cultura_talhao_service.dart';
import '../../../utils/enums.dart';
import '../../../services/culture_import_service.dart';
import '../../../models/pest.dart';
import '../../../models/disease.dart';
import '../../../models/weed.dart';
import '../../../utils/media_helper.dart';

class NewOccurrenceModal extends StatefulWidget {
  final Function({
    required List<Map<String, dynamic>> infestacoes,
    bool saveAndContinue,
  }) onSave;
  
  final int culturaId;
  final List<Map<String, dynamic>> ocorrenciasRegistradas;
  final bool isLastPoint;

  const NewOccurrenceModal({
    Key? key,
    required this.onSave,
    required this.culturaId,
    this.ocorrenciasRegistradas = const [],
    this.isLastPoint = false,
  }) : super(key: key);

  @override
  State<NewOccurrenceModal> createState() => _NewOccurrenceModalState();
}

class _NewOccurrenceModalState extends State<NewOccurrenceModal> {
  final _formKey = GlobalKey<FormState>();
  final _observacaoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _infestacaoController = TextEditingController();
  final _totalPlantasController = TextEditingController(text: '100'); // Valor padrão: 100 plantas
  
  OccurrenceType _selectedTipo = OccurrenceType.pest;
  String _selectedTercoPlanta = 'Baixeiro';
  List<String> _fotoPaths = [];
  
  // Lista de infestações adicionadas
  List<Map<String, dynamic>> _infestacoesAdicionadas = [];
  
  // Variáveis para autocomplete de infestação
  List<Map<String, dynamic>> _availableOrganisms = [];
  List<Map<String, dynamic>> _filteredOrganisms = [];
  bool _isLoadingOrganisms = false;
  bool _showSuggestions = false;
  
  bool _isLoading = false;
  bool _saveAndContinue = false;

  // Serviço para carregar organismos do módulo culturas da fazenda
  final CulturaTalhaoService _culturaService = CulturaTalhaoService();
  final CultureImportService _cultureImportService = CultureImportService();

  final List<Map<String, dynamic>> _tipos = [
    {'type': OccurrenceType.pest, 'name': 'Praga', 'icon': '🐛'},
    {'type': OccurrenceType.disease, 'name': 'Doença', 'icon': '🦠'},
    {'type': OccurrenceType.weed, 'name': 'Daninha', 'icon': '🌿'},
  ];

  final List<Map<String, dynamic>> _tercosPlanta = [
    {'value': 'Baixeiro', 'label': 'Baixeiro', 'icon': '🌱'},
    {'value': 'Terço médio', 'label': 'Terço médio', 'icon': '🌿'},
    {'value': 'Ponteiro', 'label': 'Ponteiro', 'icon': '🍃'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrganismsFromCultures();
    _infestacaoController.addListener(_filterOrganisms);
  }

  /// Carrega organismos diretamente do módulo culturas da fazenda
  Future<void> _loadOrganismsFromCultures() async {
    setState(() {
      _isLoadingOrganisms = true;
    });

    try {
      print('🔄 Carregando organismos para cultura ID: ${widget.culturaId}');
      
      // Carregar diretamente do CultureImportService (estrutura real do módulo culturas)
      final List<Map<String, dynamic>> organisms = [];
      
      // Carregar pragas
      final pests = await _cultureImportService.getPestsByCrop(widget.culturaId);
      for (final pest in pests) {
        organisms.add({
          'id': pest.id.toString(),
          'nome': pest.name,
          'nome_cientifico': pest.scientificName,
          'tipo': 'praga',
          'categoria': 'Praga',
          'cultura_id': widget.culturaId.toString(),
          'cultura_nome': 'Cultura ${widget.culturaId}',
          'descricao': pest.description,
          'icone': '🐛',
          'ativo': true,
        });
      }
      
      // Carregar doenças
      final diseases = await _cultureImportService.getDiseasesByCrop(widget.culturaId);
      for (final disease in diseases) {
        organisms.add({
          'id': disease.id.toString(),
          'nome': disease.name,
          'nome_cientifico': disease.scientificName,
          'tipo': 'doenca',
          'categoria': 'Doença',
          'cultura_id': widget.culturaId.toString(),
          'cultura_nome': 'Cultura ${widget.culturaId}',
          'descricao': disease.description,
          'icone': '🦠',
          'ativo': true,
        });
      }
      
      // Carregar plantas daninhas
      final weeds = await _cultureImportService.getWeedsByCrop(widget.culturaId);
      for (final weed in weeds) {
        organisms.add({
          'id': weed.id.toString(),
          'nome': weed.name,
          'nome_cientifico': weed.scientificName,
          'tipo': 'daninha',
          'categoria': 'Planta Daninha',
          'cultura_id': widget.culturaId.toString(),
          'cultura_nome': 'Cultura ${widget.culturaId}',
          'descricao': weed.description,
          'icone': '🌿',
          'ativo': true,
        });
      }
      
      print('📊 Organismos carregados do módulo culturas: ${organisms.length}');
      print('  - Pragas: ${pests.length}');
      print('  - Doenças: ${diseases.length}');
      print('  - Plantas daninhas: ${weeds.length}');
      
      // Se não encontrou organismos, mostrar mensagem para o usuário
      if (organisms.isEmpty) {
        print('⚠️ Nenhum organismo encontrado para esta cultura');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nenhuma praga/doença cadastrada para esta cultura. Cadastre primeiro no módulo Culturas da Fazenda.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ir para Culturas',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/farm-crops');
                },
              ),
            ),
          );
        }
        
        setState(() {
          _availableOrganisms = [];
          _filteredOrganisms = [];
          _isLoadingOrganisms = false;
        });
        return;
      }
      
      // Filtrar organismos pelo tipo selecionado
      final filteredOrganisms = organisms.where((org) {
        final tipo = org['tipo']?.toString().toLowerCase() ?? '';
        switch (_selectedTipo) {
          case OccurrenceType.pest:
            return tipo == 'praga';
          case OccurrenceType.disease:
            return tipo == 'doenca';
          case OccurrenceType.weed:
            return tipo == 'daninha';
          default:
            return false;
        }
      }).toList();

      print('🎯 Organismos filtrados para tipo $_selectedTipo: ${filteredOrganisms.length}');
      for (var org in filteredOrganisms) {
        print('  - ${org['nome']} (${org['tipo']})');
      }

      setState(() {
        _availableOrganisms = filteredOrganisms;
        _filteredOrganisms = filteredOrganisms;
        _isLoadingOrganisms = false;
      });

    } catch (e) {
      print('❌ Erro ao carregar organismos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar organismos: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      setState(() {
        _availableOrganisms = [];
        _filteredOrganisms = [];
        _isLoadingOrganisms = false;
      });
    }
  }


  /// Filtra organismos baseado na busca
  void _filterOrganisms() {
    final query = _infestacaoController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredOrganisms = _availableOrganisms;
        _showSuggestions = false;
      });
      return;
    }

    final filtered = _availableOrganisms.where((organism) {
      final name = organism['nome']?.toString().toLowerCase() ?? '';
      final scientificName = organism['nome_cientifico']?.toString().toLowerCase() ?? '';
      
      return name.contains(query) || scientificName.contains(query);
    }).toList();

    setState(() {
      _filteredOrganisms = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    _quantidadeController.dispose();
    _infestacaoController.dispose();
    _totalPlantasController.dispose();
    super.dispose();
  }

  /// Adiciona uma nova infestação à lista
  void _adicionarInfestacao() {
    if (_formKey.currentState!.validate()) {
      final organismName = _infestacaoController.text.trim();
      final quantidade = int.tryParse(_quantidadeController.text) ?? 0;
      final totalPlantas = int.tryParse(_totalPlantasController.text) ?? 100;
      
      // Buscar ID do organismo no catálogo carregado
      String? organismoId;
      try {
        final organism = _availableOrganisms.firstWhere(
          (org) => org['nome'].toString().toLowerCase() == organismName.toLowerCase(),
          orElse: () => {},
        );
        organismoId = organism['id']?.toString();
      } catch (e) {
        // Se não encontrar, deixa null (cálculo simples será usado)
      }
      
      // Calcular percentual preview: (quantidade / total) * 100
      // Este é apenas para exibição - o cálculo real será no mapa de infestação
      final percentualPreview = totalPlantas > 0 
          ? ((quantidade / totalPlantas) * 100).round() 
          : 0;
      
      final novaInfestacao = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'tipo': _selectedTipo.name,
        'organismo': organismName,
        // Campos de compatibilidade para outros módulos
        'organism_name': organismName,
        'name': organismName,
        'subtipo': organismName,
        // DADOS BRUTOS para cálculo avançado
        'organismo_id': organismoId, // ID do catálogo JSON
        'quantidade': quantidade, // Quantidade bruta
        'quantidade_bruta': quantidade, // Alias
        'total_plantas_avaliadas': totalPlantas,
        'percentual': percentualPreview, // Preview simples
        'tercoPlanta': _selectedTercoPlanta,
        'terco_planta': _selectedTercoPlanta, // Alias
        'observacao': _observacaoController.text.trim(),
        'fotoPaths': List<String>.from(_fotoPaths),
      };
      
      setState(() {
        _infestacoesAdicionadas.add(novaInfestacao);
        // Limpar campos para próxima infestação (mas manter total de plantas)
        _infestacaoController.clear();
        _quantidadeController.clear();
        _observacaoController.clear();
        _fotoPaths.clear();
        _selectedTipo = OccurrenceType.pest;
        _selectedTercoPlanta = 'Baixeiro';
        // NÃO limpar _totalPlantasController - mantém o valor para próxima ocorrência
      });
    }
  }

  /// Remove uma infestação da lista
  void _removerInfestacao(String id) {
    setState(() {
      _infestacoesAdicionadas.removeWhere((inf) => inf['id'] == id);
    });
  }

  /// Edita uma infestação existente
  void _editarInfestacao(Map<String, dynamic> infestacao) {
    setState(() {
      _selectedTipo = OccurrenceType.values.firstWhere(
        (e) => e.name == infestacao['tipo'],
        orElse: () => OccurrenceType.pest,
      );
      _infestacaoController.text = infestacao['organismo'];
      _quantidadeController.text = infestacao['quantidade'].toString();
      _totalPlantasController.text = (infestacao['total_plantas_avaliadas'] ?? 100).toString();
      _selectedTercoPlanta = infestacao['tercoPlanta'];
      _observacaoController.text = infestacao['observacao'] ?? '';
      _fotoPaths = List<String>.from(infestacao['fotoPaths'] ?? []);
    });
    
    // Remover da lista para re-adicionar depois
    _removerInfestacao(infestacao['id']);
  }

  /// Constrói o card de uma infestação
  Widget _buildInfestacaoCard(Map<String, dynamic> infestacao) {
    final tipo = infestacao['tipo'];
    final organismo = infestacao['organismo'];
    final terco = infestacao['tercoPlanta'];
    final quantidade = infestacao['quantidade'];
    final percentual = infestacao['percentual'] ?? 0;
    final totalPlantas = infestacao['total_plantas_avaliadas'] ?? 100;
    final fotoPaths = List<String>.from(infestacao['fotoPaths'] ?? []);
    
    // Ícone baseado no tipo
    IconData icon;
    Color color;
    switch (tipo) {
      case 'pest':
        icon = Icons.bug_report;
        color = Colors.orange;
        break;
      case 'disease':
        icon = Icons.coronavirus;
        color = Colors.red;
        break;
      case 'weed':
        icon = Icons.local_florist;
        color = Colors.green;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Ícone do tipo
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          
          // Miniaturas de fotos (se houver)
          if (fotoPaths.isNotEmpty) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                children: [
                  // Primeira foto
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: FutureBuilder<bool>(
                      future: _checkImageExists(fotoPaths[0]),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Image.file(
                            File(fotoPaths[0]),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 16),
                              );
                            },
                          );
                        } else {
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 16),
                          );
                        }
                      },
                    ),
                  ),
                  // Indicador de múltiplas fotos
                  if (fotoPaths.length > 1)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '+${fotoPaths.length - 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Informações da infestação
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organismo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$terco • Qtde: $quantidade/$totalPlantas',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: percentual >= 50 ? Colors.red[50] : 
                            percentual >= 25 ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: percentual >= 50 ? Colors.red[300]! : 
                              percentual >= 25 ? Colors.orange[300]! : Colors.green[300]!,
                    ),
                  ),
                  child: Text(
                    '$percentual% de infestação',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: percentual >= 50 ? Colors.red[700] : 
                              percentual >= 25 ? Colors.orange[700] : Colors.green[700],
                    ),
                  ),
                ),
                if (fotoPaths.isNotEmpty)
                  Text(
                    '${fotoPaths.length} foto${fotoPaths.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          
          // Botões de ação
          IconButton(
            onPressed: () => _editarInfestacao(infestacao),
            icon: const Icon(Icons.edit, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _removerInfestacao(infestacao['id']),
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Métodos de carregamento e filtro de organismos removidos
  // Será implementada nova busca direta do módulo culturas

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle do modal
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '➕ Nova Ocorrência',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                // Lista de infestações adicionadas
                if (_infestacoesAdicionadas.isNotEmpty) ...[
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Infestacoes Adicionadas (${_infestacoesAdicionadas.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildGroupedInfestacoesList(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                
                // Formulário para adicionar nova infestação
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Botões de Tipo
                          _buildSectionTitle('Selecione o Tipo:'),
                          _buildTipoButtons(),
                          const SizedBox(height: 20),
                          
                          // Campo de Infestação com Autocomplete
                          _buildSectionTitle('Infestação:'),
                          _buildInfestacaoField(),
                          const SizedBox(height: 16),
                          
                          // Terço da Planta Afetada
                          _buildSectionTitle('Terço da planta afetada:'),
                          _buildTercoPlantaField(),
                          const SizedBox(height: 16),
                          
                          // Quantidade
                          _buildSectionTitle('Quantidade encontrada:'),
                          _buildQuantidadeField(),
                          const SizedBox(height: 16),
                          
                          // Total de Plantas Avaliadas
                          _buildSectionTitle('Total de plantas avaliadas:'),
                          _buildTotalPlantasField(),
                          const SizedBox(height: 4),
                          Text(
                            'ℹ️ Percentual será calculado automaticamente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Observação
                          _buildSectionTitle('Observação (opcional):'),
                          _buildObservacaoField(),
                          const SizedBox(height: 16),
                          
                          // Fotos
                          _buildSectionTitle('Fotos (opcional):'),
                          _buildPhotosSection(),
                          const SizedBox(height: 20),
                          
                          // Botão Adicionar Infestação
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _adicionarInfestacao,
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Infestação'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Ocorrências Registradas
                          if (widget.ocorrenciasRegistradas.isNotEmpty) ...[
                            _buildSectionTitle('Ocorrências Registradas neste Ponto:'),
                            _buildOcorrenciasList(),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveOccurrence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D9CDB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || _infestacoesAdicionadas.isEmpty ? null : _saveAndContinueOccurrence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _infestacoesAdicionadas.isEmpty 
                          ? Colors.grey[400] 
                          : const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.isLastPoint ? 'Salvar & Finalizar' : 'Salvar e avançar ⏩'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C2C2C),
        ),
      ),
    );
  }

  Widget _buildTipoButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _tipos.map((tipoData) {
        final tipo = tipoData['type'] as OccurrenceType;
        final nome = tipoData['name'] as String;
        final icon = tipoData['icon'] as String;
        final isSelected = _selectedTipo == tipo;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTipo = tipo;
              _infestacaoController.clear(); // Limpar campo de infestação
            });
            // Recarregar organismos para o novo tipo
            _loadOrganismsFromCultures();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _getTipoBackgroundColor(tipo) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _getTipoColor(tipo) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: _getTipoColor(tipo).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  nome,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? _getTipoColor(tipo) : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // NOVA SEÇÃO DE INFESTAÇÃO - IMPLEMENTADA
  /// Campo de infestação com autocomplete
  Widget _buildInfestacaoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _infestacaoController,
          decoration: InputDecoration(
            hintText: 'Digite o nome da infestação...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Digite o nome da infestação';
            }
            return null;
          },
        ),
        
        // Lista de sugestões
        if (_showSuggestions && _filteredOrganisms.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredOrganisms.length,
              itemBuilder: (context, index) {
                final organism = _filteredOrganisms[index];
                return ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getTipoBackgroundColor(_selectedTipo).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTipoIcon(_selectedTipo.toString()),
                      style: TextStyle(
                        fontSize: 18,
                        color: _getTipoBackgroundColor(_selectedTipo),
                      ),
                    ),
                  ),
                  title: Text(
                    organism['nome']?.toString() ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: organism['nome_cientifico']?.toString().isNotEmpty == true
                      ? Text(
                          organism['nome_cientifico']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                      : null,
                  onTap: () {
                    _infestacaoController.text = organism['nome']?.toString() ?? '';
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Campo de terço da planta afetada
  Widget _buildTercoPlantaField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SegmentedButton<String>(
        segments: _tercosPlanta.map((terco) {
          return ButtonSegment<String>(
            value: terco['value'],
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(terco['icon']),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    terco['label'],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        selected: {_selectedTercoPlanta},
        onSelectionChanged: (Set<String> selection) {
          setState(() {
            _selectedTercoPlanta = selection.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.green.withOpacity(0.1);
            }
            return Colors.transparent;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.green[700]!;
            }
            return Colors.grey[600]!;
          }),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          minimumSize: MaterialStateProperty.all(const Size(0, 40)),
        ),
      ),
    );
  }


  /// Obtém ícone baseado no tipo de organismo
  IconData _getTypeIcon(OccurrenceType tipo) {
    switch (tipo) {
      case OccurrenceType.pest:
        return Icons.bug_report;
      case OccurrenceType.disease:
        return Icons.coronavirus;
      case OccurrenceType.weed:
        return Icons.local_florist;
      case OccurrenceType.deficiency:
        return Icons.warning;
      case OccurrenceType.other:
        return Icons.help_outline;
    }
  }

  Widget _buildQuantidadeField() {
    return TextFormField(
      controller: _quantidadeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: '☐ Número de indivíduos (ex: 3)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _getTipoColor(_selectedTipo), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Informe a quantidade encontrada';
        }
        if (int.tryParse(value) == null) {
          return 'Digite um número válido';
        }
        return null;
      },
    );
  }

  Widget _buildTotalPlantasField() {
    return TextFormField(
      controller: _totalPlantasController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: '🌱 Total de plantas (ex: 100)',
        prefixIcon: Icon(Icons.eco, color: Colors.green[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Informe o total de plantas avaliadas';
        }
        final num = int.tryParse(value);
        if (num == null) {
          return 'Digite um número válido';
        }
        if (num <= 0) {
          return 'O total deve ser maior que zero';
        }
        return null;
      },
    );
  }

  Widget _buildOcorrenciasList() {
    return Column(
      children: widget.ocorrenciasRegistradas.map((ocorrencia) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Text(
                _getTipoIcon(ocorrencia['tipo'] ?? 'Praga'),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ocorrencia['organismo'] ?? 'Organismo',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${ocorrencia['quantidade'] ?? 0} indivíduos',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTipoBackgroundColor(ocorrencia['tipo'] ?? 'Praga'),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nível calculado pelo catálogo',
                  style: TextStyle(
                    color: _getTipoColor(ocorrencia['tipo'] ?? 'Praga'),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildObservacaoField() {
    return TextFormField(
      controller: _observacaoController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Descreva a ocorrência observada...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _getTipoColor(_selectedTipo), width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildPhotosSection() {
    print('🖼️ Construindo seção de fotos com ${_fotoPaths.length} fotos');
    for (int i = 0; i < _fotoPaths.length; i++) {
      print('🖼️ Foto $i: ${_fotoPaths[i]}');
    }
    
    return Column(
      children: [
        // Grid de fotos
        if (_fotoPaths.isNotEmpty)
          Container(
            height: 120, // Altura fixa para o GridView
            padding: const EdgeInsets.all(4),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0, // Proporção quadrada para as imagens
              ),
              itemCount: _fotoPaths.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Stack(
                    children: [
                      // Imagem principal
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<bool>(
                          future: _checkImageExists(_fotoPaths[index]),
                          builder: (context, snapshot) {
                            print('📸 DEBUG: Carregando imagem index $index');
                            print('📸 DEBUG: Caminho: ${_fotoPaths[index]}');
                            print('📸 DEBUG: ConnectionState: ${snapshot.connectionState}');
                            print('📸 DEBUG: Snapshot data: ${snapshot.data}');
                            print('📸 DEBUG: Snapshot error: ${snapshot.error}');
                            
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            
                            // Mostrar erro se houver
                            if (snapshot.hasError) {
                              print('❌ Erro no FutureBuilder: ${snapshot.error}');
                              return Container(
                                color: Colors.red[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Erro',
                                      style: TextStyle(
                                        color: Colors.red[800],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            if (snapshot.data == true) {
                              print('✅ Arquivo existe, carregando Image.file()');
                              return Image.file(
                                File(_fotoPaths[index]),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ ERROR no Image.file()');
                                  print('❌ Erro: $error');
                                  print('❌ Caminho: ${_fotoPaths[index]}');
                                  print('❌ Stack: $stackTrace');
                                  return Container(
                                    color: Colors.orange[100],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.broken_image,
                                          color: Colors.orange,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Erro ao carregar',
                                          style: TextStyle(
                                            color: Colors.orange[800],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } else {
                              print('⚠️ Arquivo não existe ou está vazio');
                              return Container(
                                color: Colors.yellow[100],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Não encontrado',
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      // Botão de remover
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        // Botões de adicionar foto
        if (_fotoPaths.length < 4)
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        print('📷 Botão câmera pressionado');
                        final imagePath = await MediaHelper.captureImage(context);
                        print('📷 Retorno do MediaHelper.captureImage: $imagePath');
                        
                        if (imagePath != null) {
                          // Verificar se o arquivo realmente existe antes de adicionar
                          final file = File(imagePath);
                          final exists = await file.exists();
                          print('📷 Arquivo existe? $exists');
                          
                          if (exists) {
                            final size = await file.length();
                            print('📷 Tamanho do arquivo: $size bytes');
                            
                            if (size > 0) {
                              setState(() {
                                _fotoPaths.add(imagePath);
                                print('✅ Imagem adicionada à lista. Total: ${_fotoPaths.length}');
                              });
                            } else {
                              print('❌ Arquivo vazio (0 bytes)');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro: Arquivo de imagem vazio'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } else {
                            print('❌ Arquivo não existe no caminho: $imagePath');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erro: Arquivo não encontrado'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          print('❌ MediaHelper retornou null');
                        }
                      },
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('📷 Câmera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getTipoColor(_selectedTipo),
                        side: BorderSide(color: _getTipoColor(_selectedTipo)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        print('🖼 Botão galeria pressionado');
                        final imagePath = await MediaHelper.pickImage(context);
                        print('🖼 Retorno do MediaHelper.pickImage: $imagePath');
                        
                        if (imagePath != null) {
                          // Verificar se o arquivo realmente existe antes de adicionar
                          final file = File(imagePath);
                          final exists = await file.exists();
                          print('🖼 Arquivo existe? $exists');
                          
                          if (exists) {
                            final size = await file.length();
                            print('🖼 Tamanho do arquivo: $size bytes');
                            
                            if (size > 0) {
                              setState(() {
                                _fotoPaths.add(imagePath);
                                print('✅ Imagem adicionada à lista. Total: ${_fotoPaths.length}');
                              });
                            } else {
                              print('❌ Arquivo vazio (0 bytes)');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro: Arquivo de imagem vazio'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } else {
                            print('❌ Arquivo não existe no caminho: $imagePath');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erro: Arquivo não encontrado'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          print('❌ MediaHelper retornou null');
                        }
                      },
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text('🖼 Galeria'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getTipoColor(_selectedTipo),
                        side: BorderSide(color: _getTipoColor(_selectedTipo)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  String _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'Praga':
        return '🐛';
      case 'Doença':
        return '🦠';
      case 'Planta Daninha':
        return '🌿';
      case 'Deficiência Nutricional':
        return '🌱';
      default:
        return '❓';
    }
  }

  Color _getTipoColor(OccurrenceType tipo) {
    switch (tipo) {
      case OccurrenceType.pest:
        return const Color(0xFF27AE60); // Verde
      case OccurrenceType.disease:
        return const Color(0xFFF2C94C); // Amarelo
      case OccurrenceType.weed:
        return const Color(0xFF2D9CDB); // Azul
      case OccurrenceType.deficiency:
        return const Color(0xFF9B59B6); // Roxo
      case OccurrenceType.other:
        return const Color(0xFF95A5A6); // Cinza
    }
  }

  Color _getTipoBackgroundColor(OccurrenceType tipo) {
    switch (tipo) {
      case OccurrenceType.pest:
        return const Color(0xFFDFF5E1); // Verde suave
      case OccurrenceType.disease:
        return const Color(0xFFFFF6D1); // Amarelo pastel
      case OccurrenceType.weed:
        return const Color(0xFFE1F0FF); // Azul claro
      case OccurrenceType.deficiency:
        return const Color(0xFFF3E5F5); // Roxo claro
      case OccurrenceType.other:
        return const Color(0xFFF5F5F5); // Cinza claro
    }
  }

  String _getTipoString(OccurrenceType tipo) {
    switch (tipo) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Daninha';
      case OccurrenceType.deficiency:
        return 'Deficiência Nutricional';
      case OccurrenceType.other:
        return 'Outro';
    }
  }


  Future<void> _pickImage(ImageSource source) async {
    try {
      print('📷 Iniciando captura de imagem...');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        print('✅ Imagem capturada: ${image.path}');
        print('✅ Tamanho do arquivo: ${await image.length()} bytes');
        
        // Verificar se o arquivo existe e tem conteúdo
        final file = File(image.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          print('✅ Arquivo existe no caminho: ${image.path}');
          print('✅ Tamanho do arquivo: $fileSize bytes');
          
          if (fileSize > 0) {
            setState(() {
              _fotoPaths.add(image.path);
            });
            
            print('✅ Imagem adicionada à lista. Total de fotos: ${_fotoPaths.length}');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Foto adicionada com sucesso!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          } else {
            print('❌ Arquivo está vazio (0 bytes)');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro: Arquivo de imagem está vazio'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          print('❌ Arquivo não existe no caminho: ${image.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro: Arquivo não encontrado'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('❌ Nenhuma imagem selecionada');
      }
    } catch (e) {
      print('❌ Erro ao capturar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _fotoPaths.removeAt(index);
    });
  }

  /// Verifica se a imagem existe no caminho especificado
  Future<bool> _checkImageExists(String path) async {
    try {
      final file = File(path);
      final exists = await file.exists();
      print('🔍 Verificando imagem: $path - Existe: $exists');
      if (exists) {
        final size = await file.length();
        print('📏 Tamanho do arquivo: $size bytes');
        return size > 0;
      }
      return false;
    } catch (e) {
      print('❌ Erro ao verificar imagem: $e');
      return false;
    }
  }

  /// Constrói a lista agrupada de infestações por tipo
  Widget _buildGroupedInfestacoesList() {
    // Agrupar infestações por tipo
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final infestacao in _infestacoesAdicionadas) {
      final tipo = infestacao['tipo'];
      if (!grouped.containsKey(tipo)) {
        grouped[tipo] = [];
      }
      grouped[tipo]!.add(infestacao);
    }

    // Ordenar tipos: pest, disease, weed
    final tiposOrdenados = ['pest', 'disease', 'weed'];
    final tiposExistentes = tiposOrdenados.where((tipo) => grouped.containsKey(tipo)).toList();

    return ListView.builder(
      itemCount: tiposExistentes.length,
      itemBuilder: (context, index) {
        final tipo = tiposExistentes[index];
        final infestacoes = grouped[tipo]!;
        
        return _buildTipoGroup(tipo, infestacoes);
      },
    );
  }

  /// Constrói o grupo de infestações por tipo
  Widget _buildTipoGroup(String tipo, List<Map<String, dynamic>> infestacoes) {
    // Configurações do tipo
    String titulo;
    IconData icon;
    Color color;
    
    switch (tipo) {
      case 'pest':
        titulo = '🐛 Pragas (${infestacoes.length})';
        icon = Icons.bug_report;
        color = Colors.orange;
        break;
      case 'disease':
        titulo = '🦠 Doencas (${infestacoes.length})';
        icon = Icons.coronavirus;
        color = Colors.red;
        break;
      case 'weed':
        titulo = '🌱 Daninhas (${infestacoes.length})';
        icon = Icons.local_florist;
        color = Colors.green;
        break;
      default:
        titulo = '❓ Outros (${infestacoes.length})';
        icon = Icons.help;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do grupo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Lista de infestações do tipo
          ...infestacoes.map((infestacao) => 
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: _buildInfestacaoCard(infestacao),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _saveOccurrence() async {
    if (_infestacoesAdicionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma infestação antes de salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _saveAndContinue = false;
    });

    try {
      await widget.onSave(
        infestacoes: _infestacoesAdicionadas,
        saveAndContinue: false, // Apenas salvar, não avançar
      );
      
      // Fechar o modal após salvamento bem-sucedido
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndContinueOccurrence() async {
    if (_infestacoesAdicionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma infestação antes de salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _saveAndContinue = true;
    });

    try {
      await widget.onSave(
        infestacoes: _infestacoesAdicionadas,
        saveAndContinue: true, // Salvar e avançar para próximo ponto
      );
      
      // Fechar o modal após salvamento bem-sucedido
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    // Validação do campo de infestação
    if (_infestacaoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome da infestação'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_quantidadeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a quantidade encontrada'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (int.tryParse(_quantidadeController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um número válido para a quantidade'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }
}

import 'package:flutter/material.dart';
import '../services/cultura_talhao_service.dart';
import '../utils/logger.dart';

/// Widget Seletor de Organismos com Busca e Filtros
/// Permite selecionar organismos do catálogo com interface intuitiva
class OrganismSelector extends StatefulWidget {
  final String? selectedOrganismId;
  final String? cropId;
  final Function(String organismId) onOrganismSelected;
  final bool enabled;
  final String? errorText;
  final String? hintText;
  final bool showFilters;

  const OrganismSelector({
    Key? key,
    this.selectedOrganismId,
    this.cropId,
    required this.onOrganismSelected,
    this.enabled = true,
    this.errorText,
    this.hintText,
    this.showFilters = true,
  }) : super(key: key);

  @override
  State<OrganismSelector> createState() => _OrganismSelectorState();
}

class _OrganismSelectorState extends State<OrganismSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Map<String, dynamic>> _allOrganisms = [];
  List<Map<String, dynamic>> _filteredOrganisms = [];
  Map<String, dynamic>? _selectedOrganism;
  
  String _searchQuery = '';
  String _selectedType = 'todos';
  bool _isLoading = false;
  bool _isExpanded = false;

  final List<String> _organismTypes = [
    'todos',
    'praga',
    'doenca',
    'daninha',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrganisms();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(OrganismSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropId != widget.cropId) {
      _loadOrganisms();
    }
    if (oldWidget.selectedOrganismId != widget.selectedOrganismId) {
      _loadSelectedOrganism();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Carrega organismos específicos da cultura da fazenda
  Future<void> _loadOrganisms() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.cropId == null) {
        throw Exception('CropId é obrigatório para carregar organismos específicos da cultura');
      }
      
      final culturaService = CulturaTalhaoService();
      final organisms = await culturaService.getOrganismsByCrop(widget.cropId!);
      
      setState(() {
        _allOrganisms = organisms;
        _isLoading = false;
      });
      
      Logger.info('OrganismSelector: ${organisms.length} organismos carregados para cultura ${widget.cropId}');
      _filterOrganisms();
      _loadSelectedOrganism();
    } catch (e) {
      Logger.error('OrganismSelector: Erro ao carregar organismos: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Carrega o organismo selecionado
  Future<void> _loadSelectedOrganism() async {
    if (widget.selectedOrganismId == null) {
      setState(() => _selectedOrganism = null);
      return;
    }

    try {
      // Buscar o organismo selecionado na lista já carregada
      final selectedOrg = _allOrganisms.firstWhere(
        (org) => org['id']?.toString() == widget.selectedOrganismId,
        orElse: () => {},
      );
      
      if (selectedOrg.isNotEmpty) {
        setState(() => _selectedOrganism = selectedOrg);
      } else {
        setState(() => _selectedOrganism = null);
      }
    } catch (e) {
      Logger.error('OrganismSelector: Erro ao carregar organismo selecionado: $e');
      setState(() => _selectedOrganism = null);
    }
  }

  /// Filtra organismos baseado na busca e tipo
  void _filterOrganisms() {
    List<Map<String, dynamic>> filtered = _allOrganisms;

    // Filtrar por tipo
    if (_selectedType != 'todos') {
      filtered = filtered.where((org) => org['tipo'] == _selectedType).toList();
    }

    // Filtrar por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((org) {
        final query = _searchQuery.toLowerCase();
        return org['nome']?.toString().toLowerCase().contains(query) == true ||
               org['nomeCientifico']?.toString().toLowerCase().contains(query) == true ||
               org['descricao']?.toString().toLowerCase().contains(query) == true;
      }).toList();
    }

    setState(() => _filteredOrganisms = filtered);
  }

  /// Callback quando a busca muda
  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
    _filterOrganisms();
  }

  /// Obtém o ícone baseado no tipo de organismo
  IconData _getOrganismIcon(String tipo) {
    switch (tipo) {
      case 'praga':
        return Icons.bug_report;
      case 'doenca':
        return Icons.coronavirus;
      case 'daninha':
        return Icons.local_florist;
      default:
        return Icons.bug_report;
    }
  }

  /// Obtém a cor baseada no tipo de organismo
  Color _getOrganismColor(String tipo) {
    switch (tipo) {
      case 'praga':
        return Colors.red;
      case 'doenca':
        return Colors.orange;
      case 'daninha':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Obtém o nome do tipo em português
  String _getTypeName(String tipo) {
    switch (tipo) {
      case 'praga':
        return 'Praga';
      case 'doenca':
        return 'Doença';
      case 'daninha':
        return 'Daninha';
      default:
        return 'Todos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de seleção principal
        GestureDetector(
          onTap: widget.enabled ? () => setState(() => _isExpanded = !_isExpanded) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.errorText != null ? Colors.red : Colors.grey[300]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: widget.enabled ? Colors.white : Colors.grey[100],
            ),
            child: Row(
              children: [
                // Ícone do organismo selecionado
                if (_selectedOrganism != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getOrganismColor(_selectedOrganism!['tipo']?.toString() ?? '').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getOrganismIcon(_selectedOrganism!['tipo']?.toString() ?? ''),
                      color: _getOrganismColor(_selectedOrganism!['tipo']?.toString() ?? ''),
                      size: 20,
                    ),
                  )
                else
                  Icon(
                    Icons.bug_report,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                
                const SizedBox(width: 12),
                
                // Texto do organismo selecionado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedOrganism?['nome']?.toString() ?? widget.hintText ?? 'Selecionar organismo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedOrganism != null ? FontWeight.w600 : FontWeight.normal,
                          color: _selectedOrganism != null ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      if (_selectedOrganism != null)
                        Text(
                          '${_selectedOrganism!['nomeCientifico']?.toString() ?? ''} • ${_selectedOrganism!['unidade']?.toString() ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Indicador de loading ou seta
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),
        ),
        
        // Mensagem de erro
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        
        // Dropdown expandido
        if (_isExpanded && widget.enabled)
          Container(
            margin: const EdgeInsets.only(top: 8),
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
            child: Column(
              children: [
                // Campo de busca
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Buscar organismos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                
                // Filtros por tipo (se habilitado)
                if (widget.showFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: _organismTypes.map((type) {
                        final isSelected = _selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getTypeName(type)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedType = type);
                              _filterOrganisms();
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: _getOrganismColor(type).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? _getOrganismColor(type) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                // Lista de organismos
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _filteredOrganisms.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Nenhum organismo encontrado',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredOrganisms.length,
                              itemBuilder: (context, index) {
                                final organism = _filteredOrganisms[index];
                                final isSelected = widget.selectedOrganismId == organism['id']?.toString();
                                
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getOrganismColor(organism['tipo']?.toString() ?? '').withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getOrganismIcon(organism['tipo']?.toString() ?? ''),
                                      color: _getOrganismColor(organism['tipo']?.toString() ?? ''),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    organism['nome']?.toString() ?? '',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        organism['nome_cientifico']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      Text(
                                        '${organism['unidade']?.toString() ?? ''} • ${_getTypeName(organism['tipo']?.toString() ?? '')}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : null,
                                  onTap: () {
                                    widget.onOrganismSelected(organism['id']?.toString() ?? '');
                                    setState(() => _isExpanded = false);
                                    _searchController.clear();
                                    _searchFocusNode.unfocus();
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

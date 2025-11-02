import 'package:flutter/material.dart';
import '../models/organism_catalog.dart';
import '../utils/enums.dart';

/// Widget para busca avançada no catálogo de organismos
class OrganismCatalogAdvancedSearch extends StatefulWidget {
  final List<OrganismCatalog> organisms;
  final Function(List<OrganismCatalog>) onResultsChanged;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const OrganismCatalogAdvancedSearch({
    Key? key,
    required this.organisms,
    required this.onResultsChanged,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<OrganismCatalogAdvancedSearch> createState() => _OrganismCatalogAdvancedSearchState();
}

class _OrganismCatalogAdvancedSearchState extends State<OrganismCatalogAdvancedSearch> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filtros
  String _searchQuery = '';
  OccurrenceType? _selectedType;
  String? _selectedCrop;
  bool _showOnlyActive = true;
  bool _showAdvancedFilters = false;
  
  // Listas para dropdowns
  List<String> _availableCrops = [];
  List<OccurrenceType> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeFilters() {
    // Extrai culturas únicas
    _availableCrops = widget.organisms
        .map((org) => org.cropName)
        .toSet()
        .toList()
      ..sort();
    
    // Extrai tipos únicos
    _availableTypes = widget.organisms
        .map((org) => org.type)
        .toSet()
        .toList();
  }

  void _applyFilters() {
    List<OrganismCatalog> filtered = widget.organisms.where((organism) {
      // Filtro por busca textual
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!organism.name.toLowerCase().contains(query) &&
            !organism.scientificName.toLowerCase().contains(query) &&
            !organism.cropName.toLowerCase().contains(query) &&
            !(organism.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      
      // Filtro por tipo
      if (_selectedType != null && organism.type != _selectedType) {
        return false;
      }
      
      // Filtro por cultura
      if (_selectedCrop != null && organism.cropName != _selectedCrop) {
        return false;
      }
      
      // Filtro por status ativo
      if (_showOnlyActive && !organism.isActive) {
        return false;
      }
      
      return true;
    }).toList();
    
    widget.onResultsChanged(filtered);
    widget.onFiltersChanged(_getCurrentFilters());
  }

  Map<String, dynamic> _getCurrentFilters() {
    return {
      'search_query': _searchQuery,
      'type': _selectedType,
      'crop': _selectedCrop,
      'show_only_active': _showOnlyActive,
    };
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _selectedCrop = null;
      _showOnlyActive = true;
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com título e botão de filtros avançados
            Row(
              children: [
                const Icon(Icons.search, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Busca Avançada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showAdvancedFilters = !_showAdvancedFilters;
                    });
                  },
                  icon: Icon(
                    _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
                  ),
                  tooltip: _showAdvancedFilters ? 'Ocultar filtros' : 'Mostrar filtros',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Campo de busca principal
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, nome científico, cultura ou descrição...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
            
            // Filtros avançados
            if (_showAdvancedFilters) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Filtros em linha
              Row(
                children: [
                  // Filtro por tipo
                  Expanded(
                    child: DropdownButtonFormField<OccurrenceType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<OccurrenceType>(
                          value: null,
                          child: Text('Todos os tipos'),
                        ),
                        ..._availableTypes.map((type) {
                          return DropdownMenuItem<OccurrenceType>(
                            value: type,
                            child: Text(_getTypeDisplayName(type)),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Filtro por cultura
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCrop,
                      decoration: const InputDecoration(
                        labelText: 'Cultura',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas as culturas'),
                        ),
                        ..._availableCrops.map((crop) {
                          return DropdownMenuItem<String>(
                            value: crop,
                            child: Text(crop),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCrop = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Filtros adicionais
              Row(
                children: [
                  Checkbox(
                    value: _showOnlyActive,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyActive = value ?? true;
                      });
                      _applyFilters();
                    },
                  ),
                  const Text('Mostrar apenas organismos ativos'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpar Filtros'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Planta Daninha';
      default:
        return type.toString().split('.').last;
    }
  }
}

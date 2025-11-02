import 'package:flutter/material.dart';
import '../models/inventory_product_model.dart';
import '../../shared/utils/app_colors.dart';

class InventoryFilterBar extends StatefulWidget {
  final String searchQuery;
  final int? typeFilter;
  final bool lowStockFilter;
  final bool criticalStockFilter;
  final bool expiringFilter;
  final bool expiredFilter;
  final String orderBy;
  final bool descending;
  final Function({
    String? searchQuery,
    int? typeFilter,
    bool? lowStockFilter,
    bool? criticalStockFilter,
    bool? expiringFilter,
    bool? expiredFilter,
    String? orderBy,
    bool? descending,
  }) onApplyFilters;
  final VoidCallback onClearFilters;

  const InventoryFilterBar({
    Key? key,
    required this.searchQuery,
    required this.typeFilter,
    required this.lowStockFilter,
    required this.criticalStockFilter,
    required this.expiringFilter,
    required this.expiredFilter,
    required this.orderBy,
    required this.descending,
    required this.onApplyFilters,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  _InventoryFilterBarState createState() => _InventoryFilterBarState();
}

class _InventoryFilterBarState extends State<InventoryFilterBar> {
  late TextEditingController _searchController;
  late int? _typeFilter;
  late bool _lowStockFilter;
  late bool _criticalStockFilter;
  late bool _expiringFilter;
  late bool _expiredFilter;
  late String _orderBy;
  late bool _descending;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _typeFilter = widget.typeFilter;
    _lowStockFilter = widget.lowStockFilter;
    _criticalStockFilter = widget.criticalStockFilter;
    _expiringFilter = widget.expiringFilter;
    _expiredFilter = widget.expiredFilter;
    _orderBy = widget.orderBy;
    _descending = widget.descending;
  }

  @override
  void didUpdateWidget(InventoryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
    _typeFilter = widget.typeFilter;
    _lowStockFilter = widget.lowStockFilter;
    _criticalStockFilter = widget.criticalStockFilter;
    _expiringFilter = widget.expiringFilter;
    _expiredFilter = widget.expiredFilter;
    _orderBy = widget.orderBy;
    _descending = widget.descending;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onApplyFilters(
      searchQuery: _searchController.text,
      typeFilter: _typeFilter,
      lowStockFilter: _lowStockFilter,
      criticalStockFilter: _criticalStockFilter,
      expiringFilter: _expiringFilter,
      expiredFilter: _expiredFilter,
      orderBy: _orderBy,
      descending: _descending,
    );
  }

  String _getOrderByText() {
    switch (_orderBy) {
      case 'name':
        return 'Nome';
      case 'quantity':
        return 'Quantidade';
      case 'expirationDate':
        return 'Vencimento';
      case 'unitCost':
        return 'Custo';
      case 'updatedAt':
        return 'Atualização';
      default:
        return 'Nome';
    }
  }

  String _getProductTypeText(int? type) {
    if (type == null) return 'Todos';
    
    switch (type) {
      case 0:
        return 'Inseticida';
      case 1:
        return 'Herbicida';
      case 2:
        return 'Fungicida';
      case 3:
        return 'Fertilizante';
      case 4:
        return 'Semente';
      case 5:
        return 'Adjuvante';
      case 6:
        return 'Outro';
      default:
        return 'Todos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de pesquisa e botões de expansão
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                // Campo de busca
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar produto...',
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Botão de filtros
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.filter_list_off : Icons.filter_list,
                    color: _hasActiveFilters()
                        ? AppColors.primary
                        : AppColors.textLight,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  tooltip: _isExpanded ? 'Ocultar filtros' : 'Mostrar filtros',
                ),
                // Botão de limpar filtros
                if (_hasActiveFilters())
                  IconButton(
                    icon: Icon(Icons.clear_all, color: AppColors.danger),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _typeFilter = null;
                        _lowStockFilter = false;
                        _criticalStockFilter = false;
                        _expiringFilter = false;
                        _expiredFilter = false;
                        _orderBy = 'name';
                        _descending = false;
                      });
                      widget.onClearFilters();
                    },
                    tooltip: 'Limpar filtros',
                  ),
              ],
            ),
          ),
          
          // Filtros expandidos
          if (_isExpanded)
            Container(
              color: Colors.grey[50],
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de produto
                  Text(
                    'Tipo de Produto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTypeFilterChip(null, 'Todos'),
                        _buildTypeFilterChip(0, 'Inseticida'),
                        _buildTypeFilterChip(1, 'Herbicida'),
                        _buildTypeFilterChip(2, 'Fungicida'),
                        _buildTypeFilterChip(3, 'Fertilizante'),
                        _buildTypeFilterChip(4, 'Semente'),
                        _buildTypeFilterChip(5, 'Adjuvante'),
                        _buildTypeFilterChip(6, 'Outro'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Status de estoque
                  Text(
                    'Status de Estoque',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        'Estoque Baixo',
                        _lowStockFilter,
                        AppColors.warning,
                        (value) {
                          setState(() {
                            _lowStockFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                      _buildFilterChip(
                        'Estoque Crítico',
                        _criticalStockFilter,
                        AppColors.danger,
                        (value) {
                          setState(() {
                            _criticalStockFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                      _buildFilterChip(
                        'Vencimento Próximo',
                        _expiringFilter,
                        AppColors.warning,
                        (value) {
                          setState(() {
                            _expiringFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                      _buildFilterChip(
                        'Vencido',
                        _expiredFilter,
                        AppColors.secondary,
                        (value) {
                          setState(() {
                            _expiredFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Ordenação
                  Row(
                    children: [
                      Text(
                        'Ordenar por:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _orderBy,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _orderBy = value;
                            });
                            _applyFilters();
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Nome'),
                          ),
                          DropdownMenuItem(
                            value: 'quantity',
                            child: Text('Quantidade'),
                          ),
                          DropdownMenuItem(
                            value: 'expirationDate',
                            child: Text('Vencimento'),
                          ),
                          DropdownMenuItem(
                            value: 'unitCost',
                            child: Text('Custo'),
                          ),
                          DropdownMenuItem(
                            value: 'updatedAt',
                            child: Text('Atualização'),
                          ),
                        ],
                      ),
                      SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          _descending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _descending = !_descending;
                          });
                          _applyFilters();
                        },
                        tooltip: _descending
                            ? 'Ordem decrescente'
                            : 'Ordem crescente',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
          // Chips de filtros ativos (visíveis quando os filtros estão recolhidos)
          if (!_isExpanded && _hasActiveFilters())
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_typeFilter != null)
                      _buildActiveFilterChip(
                        'Tipo: ${_getProductTypeText(_typeFilter)}',
                        () {
                          setState(() {
                            _typeFilter = null;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_lowStockFilter)
                      _buildActiveFilterChip(
                        'Estoque Baixo',
                        () {
                          setState(() {
                            _lowStockFilter = false;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_criticalStockFilter)
                      _buildActiveFilterChip(
                        'Estoque Crítico',
                        () {
                          setState(() {
                            _criticalStockFilter = false;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_expiringFilter)
                      _buildActiveFilterChip(
                        'Vencimento Próximo',
                        () {
                          setState(() {
                            _expiringFilter = false;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_expiredFilter)
                      _buildActiveFilterChip(
                        'Vencido',
                        () {
                          setState(() {
                            _expiredFilter = false;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_orderBy != 'name' || _descending)
                      _buildActiveFilterChip(
                        'Ordem: ${_getOrderByText()} ${_descending ? '↓' : '↑'}',
                        () {
                          setState(() {
                            _orderBy = 'name';
                            _descending = false;
                          });
                          _applyFilters();
                        },
                      ),
                  ],
                ),
              ),
            ),
          
          Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(int? type, String label) {
    final isSelected = _typeFilter == type;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary.withOpacity(0.2),
        onSelected: (selected) {
          setState(() {
            _typeFilter = selected ? type : null;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    Color color,
    Function(bool?) onChanged,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      onSelected: onChanged,
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
        deleteIcon: Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        // backgroundColor: AppColors.primary.withOpacity(0.1), // backgroundColor não é suportado em flutter_map 5.0.0
        deleteIconColor: AppColors.primary,
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _typeFilter != null ||
        _lowStockFilter ||
        _criticalStockFilter ||
        _expiringFilter ||
        _expiredFilter ||
        _orderBy != 'name' ||
        _descending;
  }
}

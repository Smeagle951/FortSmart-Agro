import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/inventory_movement.dart';
import '../../models/inventory_item.dart';
import '../../repositories/inventory_repository.dart';
import '../../repositories/inventory_movement_repository.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar_helper.dart';
import 'dart:math' as math;

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({Key? key}) : super(key: key);

  @override
  _InventoryReportScreenState createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> with SingleTickerProviderStateMixin {
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final InventoryMovementRepository _movementRepository = InventoryMovementRepository();
  late TabController _tabController;
  
  List<InventoryItem> _items = [];
  List<InventoryMovement> _movements = [];
  bool _isLoading = true;
  
  // Filtros
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedCategory = 'Todas';
  List<String> _categories = ['Todas'];
  
  // Estatísticas
  double _totalValue = 0;
  int _totalItems = 0;
  Map<String, double> _valueByCategory = {};
  Map<String, int> _countByCategory = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar itens de estoque
      final dbItems = await _inventoryRepository.getAllItems();
      
      // Converter para o modelo de aplicação
      final items = dbItems.map((dbItem) => InventoryItem.fromDbModel(dbItem)).toList();
      
      // Extrair categorias únicas (usando type como category)
      final Set<String> categoriesSet = {'Todas'};
      for (var item in items) {
        categoriesSet.add(item.type);
      }
      
      // Carregar movimentações no período
      final dbMovements = await _movementRepository.getMovementsByDateRange(
        _startDate.toIso8601String(),
        _endDate.toIso8601String(),
      );
      
      // As movimentações já estão no formato do modelo de aplicação
      final movements = dbMovements;
      
      // Calcular estatísticas
      _calculateStatistics(items);
      
      setState(() {
        _items = items;
        _movements = movements;
        _categories = categoriesSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(context, 'Erro ao carregar dados: $e');
      }
    }
  }
  
  void _calculateStatistics(List<InventoryItem> items) {
    double totalValue = 0;
    Map<String, double> valueByCategory = {};
    Map<String, int> countByCategory = {};
    
    for (var item in items) {
      final category = item.type; // Usando type como category
      final value = item.quantity * 0; // Não temos unitPrice no modelo adaptado, usando 0 como padrão
      
      // Total geral
      totalValue += value;
      
      // Por categoria
      valueByCategory[category] = (valueByCategory[category] ?? 0) + value;
      countByCategory[category] = (countByCategory[category] ?? 0) + 1;
    }
    
    setState(() {
      _totalValue = totalValue;
      _totalItems = items.length;
      _valueByCategory = valueByCategory;
      _countByCategory = countByCategory;
    });
  }
  
  // Método removido: agora usando SnackbarHelper.showErrorSnackbar
  
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Estoque'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumo'),
            Tab(text: 'Por Categoria'),
            Tab(text: 'Movimentações'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showCategoryFilterDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildCategoryTab(),
                _buildMovementsTab(),
              ],
            ),
    );
  }
  
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do Estoque',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildSummaryRow('Total de itens', _totalItems.toString()),
                  _buildSummaryRow('Valor total em estoque', 'R\$ ${formatCurrency(_totalValue)}'),
                  _buildSummaryRow('Categorias', _categories.length > 0 ? (_categories.length - 1).toString() : '0'),
                  _buildSummaryRow('Período do relatório', 
                    '${DateFormat('dd/MM/yyyy').format(_startDate)} a ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itens com Estoque Baixo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildLowStockList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itens Próximos do Vencimento',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildExpiringItemsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valor por Categoria',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    height: 200,
                    child: _buildCategoryChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhamento por Categoria',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildCategoryDetailsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMovementsTab() {
    // Filtrar movimentações por categoria se necessário
    final filteredMovements = _selectedCategory == 'Todas'
        ? _movements
        : _movements.where((m) {
            // Converter o ID do item de String para int
            final itemId = int.tryParse(m.inventoryItemId) ?? 0;
            final item = _items.firstWhere(
              (i) => i.id == itemId.toString(),
              orElse: () => _items.isNotEmpty ? _items.first : InventoryItem(
                id: '0',
                name: 'Item não encontrado',
                type: '',
                formulation: '',
                unit: 'un',
                quantity: 0,
                location: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            return item.type == _selectedCategory;
          }).toList();
    
    if (filteredMovements.isEmpty) {
      return const Center(
        child: Text('Nenhuma movimentação no período selecionado'),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Período: ${DateFormat('dd/MM/yyyy').format(_startDate)} a ${DateFormat('dd/MM/yyyy').format(_endDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (_selectedCategory != 'Todas')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Chip(
              label: Text('Categoria: $_selectedCategory'),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                setState(() {
                  _selectedCategory = 'Todas';
                });
                _loadData();
              },
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredMovements.length,
            itemBuilder: (context, index) {
              final movement = filteredMovements[index];
              // Converter o ID do item de String para int
              final itemId = int.tryParse(movement.inventoryItemId) ?? 0;
              final item = _items.firstWhere(
                (i) => i.id == itemId.toString(),
                orElse: () => _items.isNotEmpty ? _items.first : InventoryItem(
                  id: '0',
                  name: 'Item não encontrado',
                  type: '',
                  formulation: '',
                  unit: 'un',
                  quantity: 0,
                  location: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              
              final isPositive = movement.type == MovementType.entry;
              
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    // backgroundColor: isPositive ? Colors.green : Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                    child: Icon(
                      isPositive ? Icons.add : Icons.remove,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatDateTime(movement.date)),
                      if (movement.purpose.isNotEmpty)
                        Text('Motivo: ${movement.purpose}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isPositive ? '+' : '-'}${movement.quantity.abs()} ${item.unit}',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: ${movement.newQuantity ?? 0} ${item.unit}',
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
  }
  
  Widget _buildLowStockList() {
    final lowStockItems = _items.where((item) => item.quantity < 10).toList();
    
    if (lowStockItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Nenhum item com estoque baixo'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lowStockItems.length,
      itemBuilder: (context, index) {
        final item = lowStockItems[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.type), // Usando type como category
          trailing: Text(
            '${item.quantity} ${item.unit}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildExpiringItemsList() {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));
    
    final expiringItems = _items.where((item) {
      // Verificar se o item tem data de expiração
      if (item.expirationDate == null) return false;
      
      try {
        // Verificar se está dentro do período de 30 dias
        return item.expirationDate!.isAfter(now) && item.expirationDate!.isBefore(thirtyDaysLater);
      } catch (e) {
        return false;
      }
    }).toList();
    
    if (expiringItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Nenhum item próximo do vencimento'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expiringItems.length,
      itemBuilder: (context, index) {
        final item = expiringItems[index];
        String formattedDate = '';
        
        try {
          if (item.expirationDate != null) {
            formattedDate = DateFormat('dd/MM/yyyy').format(item.expirationDate!);
          }
        } catch (e) {
          formattedDate = item.expirationDate.toString();
        }
        
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.type),
          trailing: Text(
            formattedDate,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCategoryChart() {
    // Implementação simplificada de um gráfico de barras
    return LayoutBuilder(
      builder: (context, constraints) {
        final categories = _valueByCategory.keys.toList();
        final maxValue = _valueByCategory.values.fold<double>(0, math.max);
        
        if (categories.isEmpty) {
          return const Center(
            child: Text('Nenhuma categoria encontrada'),
          );
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: categories.map((category) {
            final value = _valueByCategory[category] ?? 0.0;
            final double percentage = maxValue > 0 ? (value / maxValue) : 0.0;
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${formatCurrency(value)}',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      height: 150 * percentage,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      category,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildCategoryDetailsList() {
    final categories = _valueByCategory.keys.toList()..sort();
    
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Nenhuma categoria encontrada'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final value = _valueByCategory[category] ?? 0;
        final count = _countByCategory[category] ?? 0;
        
        return ListTile(
          title: Text(category),
          subtitle: Text('$count itens'),
          trailing: Text(
            'R\$ ${formatCurrency(value)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            setState(() {
              _selectedCategory = category;
              _tabController.animateTo(2); // Ir para a aba de movimentações
            });
            _loadData();
          }
        );
      },
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
  
  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar por Tipo'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return RadioListTile<String>(
                  title: Text(category),
                  value: category,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                    Navigator.pop(context);
                    _loadData();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}

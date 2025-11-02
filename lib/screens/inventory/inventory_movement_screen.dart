import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/inventory_movement.dart';
import 'package:fortsmart_agro/repositories/inventory_movement_repository.dart';
import 'package:fortsmart_agro/repositories/inventory_repository.dart';
import 'package:fortsmart_agro/widgets/loading_overlay.dart';
import 'package:fortsmart_agro/utils/snackbar_helper.dart';
import 'package:fortsmart_agro/widgets/date_range_picker.dart';
import 'package:fortsmart_agro/widgets/empty_state.dart';
import 'package:fortsmart_agro/widgets/search_bar.dart';
import 'package:fortsmart_agro/widgets/filter_chip_group.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class InventoryMovementScreen extends StatefulWidget {
  const InventoryMovementScreen({Key? key}) : super(key: key);
  
  @override
  _InventoryMovementScreenState createState() => _InventoryMovementScreenState();
}

class _InventoryMovementScreenState extends State<InventoryMovementScreen> with SingleTickerProviderStateMixin {
  final InventoryMovementRepository _movementRepository = InventoryMovementRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();
  
  late TabController _tabController;
  List<InventoryMovement> _allMovements = [];
  List<InventoryMovement> _filteredMovements = [];
  Map<String, dynamic> _movementStats = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedType = 'Todos';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMovements();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carrega as movimentações no período selecionado
      final movements = await _movementRepository.getMovementsByDateRange(_startDate, _endDate);
      
      // Converter movimentações do banco de dados para o modelo adaptado
      List<InventoryMovement> adaptedMovements = [];
      for (var dbMovement in movements) {
        // dbMovement já está no formato do modelo de aplicação
        final adaptedMovement = dbMovement;
        
        // Carregar informações complementares
        final item = await _inventoryRepository.getItemById(int.parse(adaptedMovement.inventoryItemId));
        if (item != null) {
          adaptedMovements.add(adaptedMovement.copyWith(
            itemName: item.name,
            itemFormulation: item.formulation,
            itemUnit: item.unit,
          ));
        } else {
          adaptedMovements.add(adaptedMovement);
        }
      }
      
      // Calcula estatísticas
      _calculateStats(adaptedMovements);
      
      setState(() {
        _allMovements = adaptedMovements;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Erro ao carregar movimentações: ${e.toString()}'
      );
    }
  }
  
  void _calculateStats(List<InventoryMovement> movements) {
    // Inicializa estatísticas
    final stats = {
      'totalEntries': 0.0,
      'totalExits': 0.0,
      'entriesByPurpose': <String, double>{},
      'exitsByPurpose': <String, double>{},
      'movementsByDay': <DateTime, double>{},
      'movementsByProduct': <String, double>{},
    };
    
    // Processa cada movimentação
    for (final movement in movements) {
      final isEntry = movement.type == MovementType.entry;
      final purpose = movement.purpose;
      final date = DateTime(movement.date.year, movement.date.month, movement.date.day);
      final product = movement.itemName ?? 'Desconhecido';
      
      // Atualiza totais
      if (isEntry) {
        stats['totalEntries'] = (stats['totalEntries'] as double) + movement.quantity;
        
        // Atualiza entradas por finalidade
        final entriesByPurpose = stats['entriesByPurpose'] as Map<String, double>;
        entriesByPurpose[purpose] = (entriesByPurpose[purpose] ?? 0.0) + movement.quantity;
      } else {
        stats['totalExits'] = (stats['totalExits'] as double) + movement.quantity;
        
        // Atualiza saídas por finalidade
        final exitsByPurpose = stats['exitsByPurpose'] as Map<String, double>;
        exitsByPurpose[purpose] = (exitsByPurpose[purpose] ?? 0.0) + movement.quantity;
      }
      
      // Atualiza movimentações por dia
      final movementsByDay = stats['movementsByDay'] as Map<DateTime, double>;
      movementsByDay[date] = (movementsByDay[date] ?? 0.0) + (isEntry ? movement.quantity : -movement.quantity);
      
      // Atualiza movimentações por produto
      final movementsByProduct = stats['movementsByProduct'] as Map<String, double>;
      movementsByProduct[product] = (movementsByProduct[product] ?? 0.0) + (isEntry ? movement.quantity : -movement.quantity);
    }
    
    _movementStats = stats;
  }
  
  void _applyFilters() {
    setState(() {
      _filteredMovements = _allMovements.where((movement) {
        // Aplica filtro de pesquisa
        final matchesSearch = 
            (movement.itemName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            movement.purpose.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            movement.responsiblePerson.toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Aplica filtro de tipo
        final matchesType = _selectedType == 'Todos' || 
            (_selectedType == 'Entrada' && movement.type == MovementType.entry) ||
            (_selectedType == 'Saída' && movement.type == MovementType.exit);
        
        return matchesSearch && matchesType;
      }).toList();
      
      // Ordena por data (mais recente primeiro)
      _filteredMovements.sort((a, b) => b.date.compareTo(a.date));
    });
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }
  
  void _onTypeFilterChanged(String type) {
    setState(() {
      _selectedType = type;
      _applyFilters();
    });
  }
  
  Future<void> _onDateRangeChanged(DateTime start, DateTime end) async {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    
    await _loadMovements();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Movimentações'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Movimentações'),
            Tab(text: 'Estatísticas'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Seletor de período
                      DateRangePicker(
                        startDate: _startDate,
                        endDate: _endDate,
                        onDateRangeChanged: _onDateRangeChanged,
                      ),
                      SizedBox(height: 16),
                      
                      // Barra de pesquisa
                      AppSearchBar(
                        onChanged: _onSearchChanged,
                        hintText: 'Buscar movimentações...',
                      ),
                      SizedBox(height: 8),
                      
                      // Filtro de tipo
                      FilterChipGroup(
                        items: ['Todos', 'Entrada', 'Saída'],
                        selectedItem: _selectedType,
                        onSelected: _onTypeFilterChanged,
                      ),
                    ],
                  ),
                ),
                
                // Conteúdo das abas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMovementsTab(),
                      _buildStatsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildMovementsTab() {
    if (_filteredMovements.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        message: _searchQuery.isNotEmpty || _selectedType != 'Todos'
            ? 'Nenhuma movimentação encontrada com os filtros atuais'
            : 'Nenhuma movimentação registrada no período selecionado',
      );
    }
    
    return ListView.builder(
      itemCount: _filteredMovements.length,
      itemBuilder: (context, index) {
        final movement = _filteredMovements[index];
        return _buildMovementCard(movement);
      },
    );
  }
  
  Widget _buildMovementCard(InventoryMovement movement) {
    final isEntry = movement.type == MovementType.entry;
    final itemName = movement.itemName ?? 'Produto não encontrado';
    final itemFormulation = movement.itemFormulation ?? '';
    final itemUnit = movement.itemUnit ?? '';
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEntry ? Icons.add_circle : Icons.remove_circle,
                      color: isEntry ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isEntry ? 'Entrada' : 'Saída',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEntry ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(movement.date),
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '$itemName $itemFormulation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Quantidade: ${movement.quantity.toStringAsFixed(2)} $itemUnit',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Finalidade: ${movement.purpose}',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Responsável: ${movement.responsiblePerson}',
              style: TextStyle(fontSize: 14),
            ),
            if (movement.documentNumber != null) ...[
              SizedBox(height: 4),
              Text(
                'Documento: ${movement.documentNumber}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsTab() {
    final totalEntries = _movementStats['totalEntries'] as double;
    final totalExits = _movementStats['totalExits'] as double;
    final entriesByPurpose = _movementStats['entriesByPurpose'] as Map<String, double>;
    final exitsByPurpose = _movementStats['exitsByPurpose'] as Map<String, double>;
    final movementsByDay = _movementStats['movementsByDay'] as Map<DateTime, double>;
    final movementsByProduct = _movementStats['movementsByProduct'] as Map<String, double>;
    
    // Ordena os dias para o gráfico
    final sortedDays = movementsByDay.keys.toList()..sort();
    
    // Prepara dados para o gráfico de movimentações diárias
    final dailySpots = sortedDays.map((date) {
      final dayIndex = sortedDays.indexOf(date).toDouble();
      return FlSpot(dayIndex, movementsByDay[date]!);
    }).toList();
    
    // Prepara dados para o gráfico de produtos mais movimentados
    final productEntries = <String, double>{};
    final productExits = <String, double>{};
    
    for (final movement in _allMovements) {
      final product = movement.itemName ?? 'Desconhecido';
      if (movement.type == MovementType.entry) {
        productEntries[product] = (productEntries[product] ?? 0.0) + movement.quantity;
      } else {
        productExits[product] = (productExits[product] ?? 0.0) + movement.quantity;
      }
    }
    
    // Ordena produtos por volume de movimentação
    final sortedProducts = movementsByProduct.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    
    // Limita a 5 produtos para o gráfico
    final topProducts = sortedProducts.take(5).toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do Período',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Entradas',
                        totalEntries.toStringAsFixed(2),
                        Icons.add_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Saídas',
                        totalExits.toStringAsFixed(2),
                        Icons.remove_circle,
                        Colors.red,
                      ),
                      _buildStatCard(
                        'Saldo',
                        (totalEntries - totalExits).toStringAsFixed(2),
                        Icons.compare_arrows,
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Gráfico de movimentações diárias
          if (dailySpots.isNotEmpty) ...[
            Text(
              'Movimentações Diárias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDays.length && index % 5 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd/MM').format(sortedDays[index]),
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toStringAsFixed(1),
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailySpots,
                      isCurved: false,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
          
          // Produtos mais movimentados
          if (topProducts.isNotEmpty) ...[
            Text(
              'Produtos Mais Movimentados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: topProducts.map((entry) {
                final product = entry.key;
                final value = entry.value;
                final isPositive = value >= 0;
                
                return ListTile(
                  leading: Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  title: Text(product),
                  trailing: Text(
                    '${isPositive ? '+' : ''}${value.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
          ],
          
          // Finalidades de entrada
          if (entriesByPurpose.isNotEmpty) ...[
            Text(
              'Entradas por Finalidade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: entriesByPurpose.entries.map((entry) {
                return ListTile(
                  leading: Icon(Icons.label, color: Colors.green),
                  title: Text(entry.key),
                  trailing: Text(
                    entry.value.toStringAsFixed(2),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
          ],
          
          // Finalidades de saída
          if (exitsByPurpose.isNotEmpty) ...[
            Text(
              'Saídas por Finalidade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: exitsByPurpose.entries.map((entry) {
                return ListTile(
                  leading: Icon(Icons.label, color: Colors.red),
                  title: Text(entry.key),
                  trailing: Text(
                    entry.value.toStringAsFixed(2),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


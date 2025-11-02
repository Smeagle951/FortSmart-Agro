import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/inventory_item.dart';
import '../../models/inventory_status.dart';
import '../../models/inventory_movement.dart';
import '../../repositories/inventory_repository.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_dialog.dart';

class InventoryDetailsScreen extends StatefulWidget {
  final String inventoryId;
  
  const InventoryDetailsScreen({
    Key? key,
    required this.inventoryId,
  }) : super(key: key);

  @override
  _InventoryDetailsScreenState createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  final InventoryRepository _inventoryRepository = InventoryRepository();
  
  bool _isLoading = true;
  String _errorMessage = '';
  InventoryItem? _inventoryItem;
  InventoryStatus? _inventoryStatus;
  List<InventoryMovement> _movements = [];
  
  @override
  void initState() {
    super.initState();
    _loadInventoryDetails();
  }
  
  Future<void> _loadInventoryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Carregar dados do item de inventário
      final item = await _inventoryRepository.getInventoryItemById(widget.inventoryId);
      
      // Carregar status atual
      final status = await _inventoryRepository.getInventoryStatusById(widget.inventoryId);
      
      // Carregar movimentos
      final movements = await _inventoryRepository.getInventoryMovementsByItemId(widget.inventoryId);
      
      setState(() {
        _inventoryItem = item;
        _inventoryStatus = status;
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar detalhes do inventário: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Inventário'),
        backgroundColor: const Color(0xFF2A4F3D),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? LoadingIndicator(message: 'Carregando detalhes do inventário...')
          : _errorMessage.isNotEmpty
              ? ErrorDialog(
                  message: _errorMessage,
                  onRetry: _loadInventoryDetails,
                )
              : _buildInventoryDetails(),
    );
  }
  
  Widget _buildInventoryDetails() {
    if (_inventoryItem == null || _inventoryStatus == null) {
      return Center(
        child: Text(
          'Item de inventário não encontrado',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A4F3D).withOpacity(0.8),
            const Color(0xFF1A2A20).withOpacity(0.9),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            _buildInventoryHeader(),
            
            // Detalhes do inventário
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 16),
                  _buildStatusCard(),
                  SizedBox(height: 16),
                  _buildMovementsCard(),
                  SizedBox(height: 16),
                  _buildInventoryUsageChart(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInventoryHeader() {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (_inventoryStatus!.currentAmount <= _inventoryStatus!.criticalLevel) {
      statusColor = Colors.red;
      statusText = 'Nível Crítico';
      statusIcon = Icons.error_outline;
    } else if (_inventoryStatus!.currentAmount <= _inventoryStatus!.warningLevel) {
      statusColor = Colors.orange;
      statusText = 'Nível Baixo';
      statusIcon = Icons.warning_amber_outlined;
    } else {
      statusColor = Colors.green;
      statusText = 'Nível OK';
      statusIcon = Icons.check_circle_outline;
    }
    
    final percentage = (_inventoryStatus!.currentAmount / _inventoryStatus!.maxCapacity * 100)
        .clamp(0.0, 100.0);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 76,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _inventoryItem!.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Categoria: ${_inventoryItem!.category}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return _buildGlassmorphicCard(
      title: 'Informações do Produto',
      child: Column(
        children: [
          _buildInfoRow('Nome', _inventoryItem!.name),
          Divider(color: Colors.white24),
          _buildInfoRow('Categoria', _inventoryItem!.category),
          Divider(color: Colors.white24),
          _buildInfoRow('Unidade', _inventoryItem!.unit),
          Divider(color: Colors.white24),
          _buildInfoRow('Código', _inventoryItem!.code ?? 'Não informado'),
          if (_inventoryItem!.manufacturer != null) ...[
            Divider(color: Colors.white24),
            _buildInfoRow('Fabricante', _inventoryItem!.manufacturer!),
          ],
          if (_inventoryItem!.batchNumber != null) ...[
            Divider(color: Colors.white24),
            _buildInfoRow('Número do Lote', _inventoryItem!.batchNumber!),
          ],
          if (_inventoryItem!.expirationDate != null) ...[
            Divider(color: Colors.white24),
            _buildInfoRow('Data de Validade', 
                DateFormat('dd/MM/yyyy').format(_inventoryItem!.expirationDate!)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusCard() {
    Color statusColor;
    
    if (_inventoryStatus!.currentAmount <= _inventoryStatus!.criticalLevel) {
      statusColor = Colors.red;
    } else if (_inventoryStatus!.currentAmount <= _inventoryStatus!.warningLevel) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }
    
    return _buildGlassmorphicCard(
      title: 'Status Atual',
      child: Column(
        children: [
          _buildStatusRow(
            label: 'Quantidade Atual',
            value: '${_inventoryStatus!.currentAmount} ${_inventoryItem!.unit}',
            color: statusColor,
          ),
          Divider(color: Colors.white24),
          _buildStatusRow(
            label: 'Capacidade Máxima',
            value: '${_inventoryStatus!.maxCapacity} ${_inventoryItem!.unit}',
            color: Colors.white,
          ),
          Divider(color: Colors.white24),
          _buildStatusRow(
            label: 'Nível de Alerta',
            value: '${_inventoryStatus!.warningLevel} ${_inventoryItem!.unit}',
            color: Colors.orange,
          ),
          Divider(color: Colors.white24),
          _buildStatusRow(
            label: 'Nível Crítico',
            value: '${_inventoryStatus!.criticalLevel} ${_inventoryItem!.unit}',
            color: Colors.red,
          ),
          Divider(color: Colors.white24),
          _buildStatusRow(
            label: 'Última Atualização',
            value: DateFormat('dd/MM/yyyy HH:mm').format(_inventoryStatus!.lastUpdated),
            color: Colors.white70,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMovementsCard() {
    if (_movements.isEmpty) {
      return _buildGlassmorphicCard(
        title: 'Movimentações Recentes',
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma movimentação registrada',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Ordenar movimentos por data (mais recentes primeiro)
    _movements.sort((a, b) => b.date.compareTo(a.date));
    
    return _buildGlassmorphicCard(
      title: 'Movimentações Recentes',
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _movements.length > 5 ? 5 : _movements.length,
        separatorBuilder: (context, index) => Divider(color: Colors.white24),
        itemBuilder: (context, index) {
          final movement = _movements[index];
          
          Color typeColor;
          IconData typeIcon;
          
          if (movement.type == 'entrada') {
            typeColor = Colors.green;
            typeIcon = Icons.add_circle_outline;
          } else {
            typeColor = Colors.red;
            typeIcon = Icons.remove_circle_outline;
          }
          
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                typeIcon,
                color: typeColor,
              ),
            ),
            title: Text(
              movement.type == 'entrada' ? 'Entrada' : 'Saída',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${movement.quantity} ${_inventoryItem!.unit} - ${movement.reason ?? "Sem descrição"}',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(movement.date),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(movement.date),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInventoryUsageChart() {
    // Se não tivermos histórico suficiente, mostrar mensagem
    if (_movements.length < 2) {
      return _buildGlassmorphicCard(
        title: 'Histórico de Uso',
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.timeline_outlined,
                  size: 48,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Histórico insuficiente para gerar gráfico',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Agrupar movimentos por mês
    final monthlyData = <DateTime, double>{};
    
    for (var movement in _movements) {
      final month = DateTime(movement.date.year, movement.date.month, 1);
      
      if (movement.type == 'saida') {
        monthlyData[month] = (monthlyData[month] ?? 0) + movement.quantity;
      }
    }
    
    // Ordenar por mês
    final sortedMonths = monthlyData.keys.toList()..sort();
    
    return _buildGlassmorphicCard(
      title: 'Histórico de Uso',
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white24,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < sortedMonths.length) {
                      final month = sortedMonths[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MMM/yy').format(month),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
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
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.white24, width: 1),
                left: BorderSide(color: Colors.white24, width: 1),
              ),
            ),
            barGroups: List.generate(sortedMonths.length, (index) {
              final month = sortedMonths[index];
              final value = monthlyData[month] ?? 0;
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: Color(0xFF9C27B0),
                    width: 16,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }),
            maxY: monthlyData.values.isEmpty
                ? 10
                : monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2,
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlassmorphicCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

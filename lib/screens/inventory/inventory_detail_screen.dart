import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/inventory_movement.dart';
import 'package:fortsmart_agro/database/models/inventory.dart';
import 'package:fortsmart_agro/repositories/inventory_repository.dart';
import 'package:fortsmart_agro/repositories/inventory_movement_repository.dart';
import 'package:fortsmart_agro/services/auth_service.dart';
import 'package:fortsmart_agro/services/pdf_viewer_service.dart';
import 'package:fortsmart_agro/utils/snackbar_helper.dart';
import 'package:fortsmart_agro/screens/inventory/inventory_form_screen.dart';
import 'package:fortsmart_agro/screens/inventory/inventory_movement_form_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class InventoryDetailScreen extends StatefulWidget {
  final InventoryItem item;
  
  const InventoryDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  _InventoryDetailScreenState createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> with SingleTickerProviderStateMixin {
  final InventoryRepository _repository = InventoryRepository();
  final InventoryMovementRepository _movementRepository = InventoryMovementRepository();
  final AuthService _authService = AuthService();
  final PdfViewerService _pdfViewerService = PdfViewerService();
  
  late TabController _tabController;
  InventoryItem? _item;
  List<InventoryMovement> _movements = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _item = widget.item;
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
      // Recarrega o item para ter os dados mais atualizados
      final updatedItem = await _repository.getItemById(_item!.id!);
      if (updatedItem != null) {
        _item = updatedItem;
      }
      
      // Carrega as movimentações do banco de dados
      final dbMovements = await _movementRepository.getMovementsByItemId(_item!.id!);
      
      // As movimentações já estão no formato do modelo de aplicação
      _movements = dbMovements;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Erro ao carregar dados: ${e.toString()}'
      );
    }
  }
  
  Future<void> _editItem() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InventoryFormScreen(item: _item),
      ),
    );
    
    if (result == true) {
      await _loadData();
    }
  }
  
  Future<void> _registerMovement(MovementType type) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InventoryMovementFormScreen(
          item: _item!,
          movementType: type,
        ),
      ),
    );
    
    if (result == true) {
      await _loadData();
    }
  }
  
  Future<void> _viewPdf() async {
    if (_item?.pdfPath == null || _item!.pdfPath!.isEmpty) {
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Nenhum PDF cadastrado para este produto'
      );
      return;
    }
    
    try {
      final pdfWidget = await _pdfViewerService.openPdf(context, _item!.pdfPath!);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => pdfWidget),
      );
    } catch (e) {
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Erro ao abrir PDF: ${e.toString()}'
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item?.name ?? 'Detalhes do Produto'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: _editItem,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Informações'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildHistoryTab(),
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.add_circle),
                label: Text('Entrada'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
                ),
                onPressed: () => _registerMovement(MovementType.entry),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.remove_circle),
                label: Text('Saída'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                ),
                onPressed: () => _registerMovement(MovementType.exit),
              ),
              if (_item?.pdfPath != null && _item!.pdfPath!.isNotEmpty)
                ElevatedButton.icon(
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('PDF'),
                  onPressed: _viewPdf,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoTab() {
    if (_item == null) {
      return Center(child: Text('Produto não encontrado'));
    }
    
    // Define cores de alerta
    Color statusColor = Colors.green;
    String statusText = 'ESTOQUE NORMAL';
    
    if (_item!.isExpired()) {
      statusColor = Colors.red;
      statusText = 'PRODUTO VENCIDO';
    } else if (_item!.isNearExpiration()) {
      statusColor = Colors.orange;
      statusText = 'PRÓXIMO DO VENCIMENTO';
    } else if (_item!.isBelowMinimumLevel()) {
      statusColor = Colors.red;
      statusText = 'ESTOQUE BAIXO';
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Informações principais
          Text(
            'Informações do Produto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow('Nome', _item!.name),
          _buildInfoRow('Tipo', _item!.type),
          _buildInfoRow('Formulação', _item!.formulation),
          _buildInfoRow('Quantidade', _item!.getFormattedQuantity()),
          _buildInfoRow('Local', _item!.location),
          if (_item!.manufacturer != null)
            _buildInfoRow('Fabricante', _item!.manufacturer!),
          if (_item!.expirationDate != null)
            _buildInfoRow('Validade', DateFormat('dd/MM/yyyy').format(DateTime.parse(_item!.expirationDate!))),
          if (_item!.minimumLevel != null)
            _buildInfoRow('Nível Mínimo', '${_item!.minimumLevel} ${_item!.unit}'),
          if (_item!.registrationNumber != null)
            _buildInfoRow('Registro', _item!.registrationNumber!),
          SizedBox(height: 24),
          
          // Gráfico de movimentações (se houver dados suficientes)
          if (_movements.length > 1) ...[
            Text(
              'Histórico de Quantidade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: _buildStockChart(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Não informado',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryTab() {
    if (_movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma movimentação registrada',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }
    
    // Ordena movimentações por data (mais recente primeiro)
    _movements.sort((a, b) => b.date.compareTo(a.date));
    
    return ListView.builder(
      itemCount: _movements.length,
      itemBuilder: (context, index) {
        final movement = _movements[index];
        return _buildMovementCard(movement);
      },
    );
  }
  
  Widget _buildMovementCard(InventoryMovement movement) {
    final isEntry = movement.type == MovementType.entry;
    
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
                      movement.getTypeString(),
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
              'Quantidade: ${movement.getFormattedQuantity(_item!.unit)}',
              style: TextStyle(fontSize: 16),
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
  
  Widget _buildStockChart() {
    // Ordena movimentações por data (mais antiga primeiro)
    final sortedMovements = List<InventoryMovement>.from(_movements)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Calcula o histórico de quantidades
    double currentQuantity = 0;
    final List<FlSpot> spots = [];
    final List<DateTime> dates = [];
    
    for (int i = 0; i < sortedMovements.length; i++) {
      final movement = sortedMovements[i];
      if (movement.type == MovementType.entry) {
        currentQuantity += movement.quantity;
      } else {
        currentQuantity -= movement.quantity;
      }
      
      spots.add(FlSpot(i.toDouble(), currentQuantity));
      dates.add(movement.date);
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(dates[index]),
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
            spots: spots,
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
    );
  }
}


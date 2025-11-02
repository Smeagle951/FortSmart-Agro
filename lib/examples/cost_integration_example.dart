import 'package:flutter/material.dart';
import '../modules/shared/services/cost_integration_service.dart';
import '../modules/shared/models/operation_data.dart';
import '../modules/stock/models/stock_product_model.dart';

/// Exemplo de uso da integração de custos
class CostIntegrationExample extends StatefulWidget {
  const CostIntegrationExample({Key? key}) : super(key: key);

  @override
  State<CostIntegrationExample> createState() => _CostIntegrationExampleState();
}

class _CostIntegrationExampleState extends State<CostIntegrationExample> {
  final CostIntegrationService _costService = CostIntegrationService();
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupExampleData();
  }

  /// Configura dados de exemplo
  void _setupExampleData() {
    // Adiciona produtos ao estoque
    final glifosato = StockProduct(
      name: 'Glifosato 480',
      category: 'Herbicida',
      unit: 'L',
      availableQuantity: 500.0,
      unitValue: 12.50,
      supplier: 'Syngenta',
      lotNumber: 'LOT001',
      storageLocation: 'Galpão A',
      expirationDate: DateTime.now().add(const Duration(days: 365)),
    );

    final adubo = StockProduct(
      name: 'NPK 20-20-20',
      category: 'Fertilizante',
      unit: 'kg',
      availableQuantity: 1000.0,
      unitValue: 3.80,
      supplier: 'Fertilizantes Brasil',
      lotNumber: 'LOT002',
      storageLocation: 'Galpão B',
      expirationDate: DateTime.now().add(const Duration(days: 730)),
    );

    final semente = StockProduct(
      name: 'Semente de Soja RR',
      category: 'Semente',
      unit: 'saca',
      availableQuantity: 50.0,
      unitValue: 180.00,
      supplier: 'Bayer',
      lotNumber: 'LOT003',
      storageLocation: 'Câmara Fria',
      expirationDate: DateTime.now().add(const Duration(days: 180)),
    );

    _costService.addStockProduct(glifosato);
    _costService.addStockProduct(adubo);
    _costService.addStockProduct(semente);

    _addLog('✅ Dados de exemplo configurados');
    _addLog('📦 Produtos no estoque: ${_costService.getTotalStockValue().toStringAsFixed(2)}');
  }

  /// Adiciona log à lista
  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  /// Exemplo: Aplicação de herbicida
  Future<void> _exampleHerbicideApplication() async {
    _addLog('🌱 Iniciando aplicação de herbicida...');

    final operation = OperationData(
      talhaoId: 'TALHAO_A',
      productId: '1', // ID do Glifosato
      dose: 2.0, // 2 L/ha
      talhaoArea: 50.0, // 50 hectares
      operationType: OperationType.application,
      operationDate: DateTime.now(),
      operatorName: 'João Silva',
      equipment: 'Pulverizador autopropelido',
      weatherConditions: 'Ensolarado, 25°C',
    );

    try {
      await _costService.registerOperation(operation);
      _addLog('✅ Aplicação registrada com sucesso!');
    } catch (e) {
      _addLog('❌ Erro: $e');
    }
  }

  /// Exemplo: Fertilização
  Future<void> _exampleFertilization() async {
    _addLog('🌿 Iniciando fertilização...');

    final operation = OperationData(
      talhaoId: 'TALHAO_B',
      productId: '2', // ID do NPK
      dose: 300.0, // 300 kg/ha
      talhaoArea: 30.0, // 30 hectares
      operationType: OperationType.fertilization,
      operationDate: DateTime.now(),
      operatorName: 'Maria Santos',
      equipment: 'Distribuidor de adubo',
      weatherConditions: 'Nublado, 22°C',
    );

    try {
      await _costService.registerOperation(operation);
      _addLog('✅ Fertilização registrada com sucesso!');
    } catch (e) {
      _addLog('❌ Erro: $e');
    }
  }

  /// Exemplo: Plantio
  Future<void> _examplePlanting() async {
    _addLog('🌱 Iniciando plantio...');

    final operation = OperationData(
      talhaoId: 'TALHAO_C',
      productId: '3', // ID da Semente
      dose: 0.8, // 0.8 saca/ha
      talhaoArea: 25.0, // 25 hectares
      operationType: OperationType.planting,
      operationDate: DateTime.now(),
      operatorName: 'Pedro Costa',
      equipment: 'Plantadeira 12 linhas',
      weatherConditions: 'Ensolarado, 28°C',
    );

    try {
      await _costService.registerOperation(operation);
      _addLog('✅ Plantio registrado com sucesso!');
    } catch (e) {
      _addLog('❌ Erro: $e');
    }
  }

  /// Gera relatório de custos
  Future<void> _generateCostReport() async {
    _addLog('📊 Gerando relatório de custos...');

    final filters = CostReportFilters(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );

    try {
      final report = await _costService.generateCostReport(filters);
      _addLog('📈 Relatório gerado:');
      _addLog('   - Total de operações: ${report.operations.length}');
      _addLog('   - Custo total: R\$ ${report.totalCost.toStringAsFixed(2)}');
      _addLog('   - Área total: ${report.totalArea.toStringAsFixed(1)} ha');
      _addLog('   - Custo médio/ha: R\$ ${report.averageCostPerHectare.toStringAsFixed(2)}');
    } catch (e) {
      _addLog('❌ Erro ao gerar relatório: $e');
    }
  }

  /// Mostra produtos com estoque baixo
  void _showLowStockProducts() {
    final lowStockProducts = _costService.getLowStockProducts();
    _addLog('⚠️ Produtos com estoque baixo: ${lowStockProducts.length}');
    
    for (final product in lowStockProducts) {
      _addLog('   - ${product.name}: ${product.availableQuantity} ${product.unit}');
    }
  }

  /// Mostra produtos próximos do vencimento
  void _showNearExpirationProducts() {
    final nearExpirationProducts = _costService.getNearExpirationProducts();
    _addLog('⏰ Produtos próximos do vencimento: ${nearExpirationProducts.length}');
    
    for (final product in nearExpirationProducts) {
      _addLog('   - ${product.name}: vence em ${product.expirationDate?.toString().substring(0, 10)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo - Integração de Custos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Botões de exemplo
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Exemplos de Operações',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _exampleHerbicideApplication,
                        icon: const Icon(Icons.local_florist),
                        label: const Text('Aplicação\nHerbicida'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _exampleFertilization,
                        icon: const Icon(Icons.eco),
                        label: const Text('Fertilização'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _examplePlanting,
                        icon: const Icon(Icons.agriculture),
                        label: const Text('Plantio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generateCostReport,
                        icon: const Icon(Icons.analytics),
                        label: const Text('Relatório'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showLowStockProducts,
                        icon: const Icon(Icons.warning),
                        label: const Text('Estoque Baixo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showNearExpirationProducts,
                        icon: const Icon(Icons.schedule),
                        label: const Text('Vencimento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logs de Operação',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/dashboard_data_service.dart';
import '../utils/logger.dart';

/// Widget para card de estoque com dados em tempo real
class InventoryCardWidget extends StatefulWidget {
  final VoidCallback? onTap;
  
  const InventoryCardWidget({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  State<InventoryCardWidget> createState() => _InventoryCardWidgetState();
}

class _InventoryCardWidgetState extends State<InventoryCardWidget> {
  final DashboardDataService _dashboardDataService = DashboardDataService();
  
  Map<String, dynamic> _inventoryData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Logger.info('🔍 Carregando dados de estoque para o card...');
      
      // Simular carregamento de dados de estoque
      // Em uma implementação real, isso viria de um serviço específico
      await Future.delayed(const Duration(seconds: 1));
      
      // Dados simulados
      final inventoryData = {
        'total_items': 0,
        'low_stock_items': 0,
        'critical_items': 0,
        'total_value': 0.0,
        'categories': <String, int>{},
      };
      
      if (mounted) {
        setState(() {
          _inventoryData = inventoryData;
          _isLoading = false;
        });
      }
      
      Logger.info('✅ Dados de estoque carregados: ${inventoryData['total_items']} itens');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de estoque: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory,
                      color: Colors.orange.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estoque',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (_isLoading)
                          const Text(
                            'Carregando...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          )
                        else if (_error != null)
                          Text(
                            'Erro ao carregar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          )
                        else
                          Text(
                            'Sistema: Funcionando normalmente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _error == null)
                    IconButton(
                      onPressed: _loadInventoryData,
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      tooltip: 'Atualizar dados',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Erro ao carregar dados',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadInventoryData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildInventoryContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryContent() {
    final totalItems = _inventoryData['total_items'] ?? 0;
    final lowStockItems = _inventoryData['low_stock_items'] ?? 0;
    final criticalItems = _inventoryData['critical_items'] ?? 0;
    final totalValue = _inventoryData['total_value'] ?? 0.0;
    
    if (totalItems == 0) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nenhum item cadastrado',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure itens de estoque para começar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navegar para configuração de estoque
                Navigator.of(context).pushNamed('/inventory/setup');
              },
              icon: const Icon(Icons.add),
              label: const Text('Configurar Estoque'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      children: [
        // Contadores principais
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '$totalItems',
                Icons.inventory,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Baixo Estoque',
                '$lowStockItems',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Itens críticos e valor total
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Críticos',
                '$criticalItems',
                Icons.dangerous,
                Colors.red.shade800,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Valor Total',
                'R\$ ${totalValue.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        
        // Alerta se há itens com baixo estoque
        if (lowStockItems > 0 || criticalItems > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lowStockItems > 0 ? Colors.orange.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: lowStockItems > 0 ? Colors.orange.shade200 : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  lowStockItems > 0 ? Icons.warning : Icons.dangerous,
                  color: lowStockItems > 0 ? Colors.orange.shade600 : Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lowStockItems > 0 
                      ? '$lowStockItems itens com baixo estoque'
                      : '$criticalItems itens críticos',
                    style: TextStyle(
                      color: lowStockItems > 0 ? Colors.orange.shade800 : Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

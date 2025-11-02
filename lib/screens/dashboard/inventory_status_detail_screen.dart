import 'package:flutter/material.dart';
import '../../models/inventory_status.dart';

class InventoryStatusDetailScreen extends StatelessWidget {
  final List<InventoryStatus> inventoryStatuses;

  const InventoryStatusDetailScreen({
    Key? key,
    required this.inventoryStatuses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status do Inventário'),
        // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // backgroundColor: const Color(0xFFF4F6F8), // backgroundColor não é suportado em flutter_map 5.0.0
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Visão Geral do Inventário',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildInventorySummary(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Itens do Inventário',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: inventoryStatuses.length,
                        itemBuilder: (context, index) {
                          final item = inventoryStatuses[index];
                          return _buildInventoryItem(item);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Tendência de Consumo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildConsumptionTrend(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings, color: const Color(0xFF39B54A), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Ações Rápidas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        context, 
                        'Adicionar Item ao Inventário', 
                        Icons.add_circle, 
                        const Color(0xFF39B54A),
                        () {
                          // Adicionar item
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Adicionando novo item...')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context, 
                        'Gerar Pedido de Compra', 
                        Icons.shopping_cart, 
                        const Color(0xFF007AFF),
                        () {
                          // Gerar pedido
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gerando pedido de compra...')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context, 
                        'Exportar Relatório de Inventário', 
                        Icons.description, 
                        const Color(0xFFFFD400),
                        () {
                          // Exportar relatório
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exportando relatório...')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context, 
                        'Configurar Alertas de Estoque', 
                        Icons.notifications, 
                        const Color(0xFFFF3B30),
                        () {
                          // Configurar alertas
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Configurando alertas...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventorySummary() {
    // Calcular estatísticas do inventário
    int totalItems = inventoryStatuses.length;
    int lowStockItems = inventoryStatuses.where((item) => 
      item.currentStock != null && 
      item.minimumStock != null && 
      item.currentStock! < item.minimumStock!
    ).length;
    
    double totalValue = 0;
    for (var item in inventoryStatuses) {
      if (item.currentStock != null && item.unitPrice != null) {
        totalValue += item.currentStock! * item.unitPrice!;
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryItem('Total de Itens', '$totalItems', Icons.inventory_2),
            _buildSummaryItem('Itens em Baixa', '$lowStockItems', Icons.warning_amber),
            _buildSummaryItem('Valor Total', 'R\$ ${totalValue.toStringAsFixed(2)}', Icons.attach_money),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Status do Inventário',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.65,
          // backgroundColor: Colors.grey[200], // backgroundColor não é suportado em flutter_map 5.0.0
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF39B54A)),
          minHeight: 10,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estoque Baixo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Estoque Ideal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF39B54A)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(InventoryStatus item) {
    // Calcular porcentagem do estoque
    double stockPercentage = 0.0;
    if (item.currentStock != null && item.maximumStock != null && item.maximumStock! > 0) {
      stockPercentage = item.currentStock! / item.maximumStock!;
      // Limitar a 1.0 para evitar overflow na barra de progresso
      stockPercentage = stockPercentage > 1.0 ? 1.0 : stockPercentage;
    }
    
    // Definir cor com base no nível de estoque
    Color stockColor;
    if (item.currentStock != null && item.minimumStock != null) {
      if (item.currentStock! < item.minimumStock!) {
        stockColor = Colors.red;
      } else if (item.currentStock! < item.minimumStock! * 1.5) {
        stockColor = Colors.orange;
      } else {
        stockColor = Colors.green;
      }
    } else {
      stockColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.itemName ?? 'Item sem nome',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.currentStock != null && item.minimumStock != null && item.currentStock! < item.minimumStock!
                        ? 'Estoque Baixo'
                        : 'Em Estoque',
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Categoria: ${item.category ?? 'Não categorizado'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estoque: ${item.currentStock?.toStringAsFixed(2) ?? '0'} ${item.unit ?? 'un'}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Mínimo: ${item.minimumStock?.toStringAsFixed(2) ?? '0'} ${item.unit ?? 'un'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stockPercentage,
              // backgroundColor: Colors.grey[200], // backgroundColor não é suportado em flutter_map 5.0.0
              valueColor: AlwaysStoppedAnimation<Color>(stockColor),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Valor unitário: R\$ ${item.unitPrice?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Total: R\$ ${(item.currentStock != null && item.unitPrice != null) ? (item.currentStock! * item.unitPrice!).toStringAsFixed(2) : '0.00'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionTrend() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Gráfico de Tendência de Consumo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dados históricos de consumo serão exibidos aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, 
    String label, 
    IconData icon, 
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          // backgroundColor: color, // backgroundColor não é suportado em flutter_map 5.0.0
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

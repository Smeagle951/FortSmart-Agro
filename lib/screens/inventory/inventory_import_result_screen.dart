import 'package:flutter/material.dart';
import 'package:fortsmart_agro/services/excel_import_service.dart';

class InventoryImportResultScreen extends StatelessWidget {
  final ImportResult result;
  
  const InventoryImportResultScreen({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultado da Importação'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo
            _buildSummaryCard(),
            SizedBox(height: 24),
            
            // Produtos criados
            if (result.createdItems.isNotEmpty) ...[
              _buildSectionTitle('Produtos Criados (${result.createdItems.length})'),
              _buildItemsList(result.createdItems, Icons.add_circle, Colors.green),
              SizedBox(height: 24),
            ],
            
            // Produtos atualizados
            if (result.updatedItems.isNotEmpty) ...[
              _buildSectionTitle('Produtos Atualizados (${result.updatedItems.length})'),
              _buildItemsList(result.updatedItems, Icons.update, Colors.blue),
              SizedBox(height: 24),
            ],
            
            // Erros
            if (result.errors.isNotEmpty) ...[
              _buildSectionTitle('Erros (${result.errors.length})'),
              _buildErrorsList(result.errors),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Concluir'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final bool hasErrors = result.errors.isNotEmpty;
    final Color statusColor = hasErrors ? Colors.orange : Colors.green;
    final IconData statusIcon = hasErrors ? Icons.warning : Icons.check_circle;
    final String statusText = hasErrors 
        ? 'Importação concluída com avisos' 
        : 'Importação concluída com sucesso';
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildSummaryRow('Produtos criados:', result.createdItems.length.toString()),
            _buildSummaryRow('Produtos atualizados:', result.updatedItems.length.toString()),
            _buildSummaryRow('Total processado:', result.totalProcessed.toString()),
            if (hasErrors)
              _buildSummaryRow('Erros encontrados:', result.errors.length.toString(), isError: true),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isError ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildItemsList(List<String> items, IconData icon, Color color) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(items[index]),
          );
        },
      ),
    );
  }
  
  Widget _buildErrorsList(List<String> errors) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: errors.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.error, color: Colors.red),
            title: Text(
              errors[index],
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        },
      ),
    );
  }
}


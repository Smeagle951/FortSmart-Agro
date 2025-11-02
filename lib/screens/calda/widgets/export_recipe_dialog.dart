import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/calda/product.dart';
import '../../../models/calda/calda_config.dart';
import '../../../services/calda/calda_calculation_service.dart';

class ExportRecipeDialog extends StatelessWidget {
  final List<Product> products;
  final CaldaConfig config;
  final RecipeCalculationResult? calculationResult;

  const ExportRecipeDialog({
    Key? key,
    required this.products,
    required this.config,
    this.calculationResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar Receita'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Escolha o formato de exportação:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          // Botão PDF
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportToPDF(context),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar para PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botão CSV
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportToCSV(context),
              icon: const Icon(Icons.table_chart),
              label: const Text('Exportar para CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botão Texto
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportToText(context),
              icon: const Icon(Icons.text_snippet),
              label: const Text('Copiar como Texto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  void _exportToPDF(BuildContext context) {
    // Implementar exportação para PDF
    _showMessage(context, 'Funcionalidade de PDF em desenvolvimento');
  }

  void _exportToCSV(BuildContext context) {
    // Implementar exportação para CSV
    _showMessage(context, 'Funcionalidade de CSV em desenvolvimento');
  }

  void _exportToText(BuildContext context) {
    final text = _generateRecipeText();
    Clipboard.setData(ClipboardData(text: text));
    _showMessage(context, 'Receita copiada para a área de transferência!');
  }

  String _generateRecipeText() {
    final buffer = StringBuffer();
    
    buffer.writeln('=== RECEITA DE CALDA ===');
    buffer.writeln();
    buffer.writeln('Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln();
    
    // Configurações
    buffer.writeln('CONFIGURAÇÕES:');
    buffer.writeln('Volume da Calda: ${config.volumeLiters.toStringAsFixed(0)} L');
    buffer.writeln('Vazão: ${config.flowRate.toStringAsFixed(0)} ${config.isFlowPerHectare ? 'L/ha' : 'L/alqueire'}');
    buffer.writeln('Área: ${config.area.toStringAsFixed(2)} ${config.isFlowPerHectare ? 'ha' : 'alqueires'}');
    buffer.writeln();
    
    // Produtos
    buffer.writeln('PRODUTOS:');
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      buffer.writeln('${i + 1}. ${product.name}');
      buffer.writeln('   Fabricante: ${product.manufacturer}');
      buffer.writeln('   Formulação: ${product.formulation.code}');
      buffer.writeln('   Dose: ${product.dose} ${product.doseUnit.symbol}');
      buffer.writeln();
    }
    
    // Ordem de mistura
    final mixingOrder = CaldaCalculationService.getMixingOrder(products);
    buffer.writeln('ORDEM DE MISTURA:');
    for (int i = 0; i < mixingOrder.length; i++) {
      buffer.writeln('${i + 1}. ${mixingOrder[i].name} (${mixingOrder[i].formulation.code})');
    }
    buffer.writeln();
    
    // Instruções
    buffer.writeln('INSTRUÇÕES:');
    buffer.writeln('1. Adicione água limpa no tanque (1/3 do volume final)');
    buffer.writeln('2. Ligue o agitador');
    buffer.writeln('3. Adicione os produtos na ordem sugerida');
    buffer.writeln('4. Complete com água até o volume desejado');
    buffer.writeln('5. Mantenha a agitação por pelo menos 5 minutos');
    buffer.writeln('6. Realize o teste de calda antes da aplicação');
    buffer.writeln();
    
    buffer.writeln('=== FortSmart Agro ===');
    
    return buffer.toString();
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

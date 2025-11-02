import 'package:flutter/material.dart';
import '../widgets/planting_integrated_data_widget.dart';
import '../screens/plantio/submods/planting_cv/planting_cv_calculation_screen.dart';
import '../screens/plantio/submods/planting_stand/planting_stand_registration_screen.dart';

/// Exemplo de como usar o widget de dados integrados
/// Este arquivo demonstra como integrar o widget em diferentes telas
class PlantingIntegrationUsageExample {
  
  /// Exemplo 1: Usar na tela de "Novo Estande de Plantas"
  static Widget buildIntegratedDataForEstandeScreen({
    required String talhaoId,
    required String culturaId,
    required String talhaoNome,
    required String culturaNome,
  }) {
    return Column(
      children: [
        // Widget de dados integrados
        PlantingIntegratedDataWidget(
          talhaoId: talhaoId,
          culturaId: culturaId,
          talhaoNome: talhaoNome,
          culturaNome: culturaNome,
          showFullAnalysis: true,
          onDataUpdated: () {
            // Callback para atualizar dados quando necessário
            print('Dados integrados atualizados');
          },
        ),
        
        const SizedBox(height: 16),
        
        // Botões para acessar os submódulos
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navegar para tela de CV%
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => PlantingCvCalculationScreen(
                  //     fieldId: talhaoId,
                  //     cropId: culturaId,
                  //   ),
                  // ));
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular CV%'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navegar para tela de estande
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => PlantingStandRegistrationScreen(
                  //     fieldId: talhaoId,
                  //     cropId: culturaId,
                  //   ),
                  // ));
                },
                icon: const Icon(Icons.grass),
                label: const Text('Registrar Estande'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Exemplo 2: Usar na tela de "Cálculo de Plantio + Estande"
  static Widget buildIntegratedDataForPlantingScreen({
    required String talhaoId,
    required String culturaId,
    required String talhaoNome,
    required String culturaNome,
  }) {
    return Column(
      children: [
        // Widget de dados integrados (versão compacta)
        PlantingIntegratedDataWidget(
          talhaoId: talhaoId,
          culturaId: culturaId,
          talhaoNome: talhaoNome,
          culturaNome: culturaNome,
          showFullAnalysis: false,
        ),
        
        const SizedBox(height: 16),
        
        // Informações adicionais específicas do submódulo
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Funcionalidades Disponíveis', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFeatureItem('Cálculo de CV%', 'Analise a qualidade do plantio'),
                _buildFeatureItem('Registro de Estande', 'Conte as plantas emergidas'),
                _buildFeatureItem('Análise Integrada', 'IA analisa CV% + Estande'),
                _buildFeatureItem('Recomendações', 'Insights para melhorias'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Exemplo 3: Usar em relatórios de monitoramento
  static Widget buildMonitoringContext({
    required String talhaoId,
    required String culturaId,
    required String talhaoNome,
    required String culturaNome,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contexto de Plantio', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          PlantingIntegratedDataWidget(
            talhaoId: talhaoId,
            culturaId: culturaId,
            talhaoNome: talhaoNome,
            culturaNome: culturaNome,
            showFullAnalysis: false,
          ),
        ],
      ),
    );
  }

  /// Exemplo 4: Usar em dashboard principal
  static Widget buildDashboardSummary({
    required List<Map<String, String>> talhoes,
  }) {
    return Column(
      children: talhoes.map((talhao) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: PlantingIntegratedDataWidget(
            talhaoId: talhao['id']!,
            culturaId: talhao['culturaId']!,
            talhaoNome: talhao['nome']!,
            culturaNome: talhao['culturaNome']!,
            showFullAnalysis: false,
          ),
        );
      }).toList(),
    );
  }

  static Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Exemplo de como integrar na tela existente de estande
class EstandeScreenWithIntegration extends StatelessWidget {
  final String talhaoId;
  final String culturaId;
  final String talhaoNome;
  final String culturaNome;

  const EstandeScreenWithIntegration({
    Key? key,
    required this.talhaoId,
    required this.culturaId,
    required this.talhaoNome,
    required this.culturaNome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estande de Plantas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              // Mostrar análise integrada
              _showIntegratedAnalysis(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Widget de dados integrados no topo
            PlantingIntegrationUsageExample.buildIntegratedDataForEstandeScreen(
              talhaoId: talhaoId,
              culturaId: culturaId,
              talhaoNome: talhaoNome,
              culturaNome: culturaNome,
            ),
            
            const SizedBox(height: 24),
            
            // Conteúdo original da tela de estande
            // ... resto do conteúdo da tela existente
          ],
        ),
      ),
    );
  }

  void _showIntegratedAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Análise Integrada'),
        content: SizedBox(
          width: double.maxFinite,
          child: PlantingIntegratedDataWidget(
            talhaoId: talhaoId,
            culturaId: culturaId,
            talhaoNome: talhaoNome,
            culturaNome: culturaNome,
            showFullAnalysis: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

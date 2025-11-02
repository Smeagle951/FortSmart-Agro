import 'package:flutter/material.dart';
import '../../services/integration_flow_test_service.dart';
import '../../utils/logger.dart';

/// Tela para testar o fluxo completo de integração
class IntegrationFlowTestScreen extends StatefulWidget {
  const IntegrationFlowTestScreen({Key? key}) : super(key: key);

  @override
  State<IntegrationFlowTestScreen> createState() => _IntegrationFlowTestScreenState();
}

class _IntegrationFlowTestScreenState extends State<IntegrationFlowTestScreen> {
  final IntegrationFlowTestService _testService = IntegrationFlowTestService();
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Fluxo de Integração'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho explicativo
            _buildHeader(),
            const SizedBox(height: 20),
            
            // Botão de teste
            _buildTestButton(),
            const SizedBox(height: 20),
            
            // Resultados dos testes
            Expanded(
              child: _buildTestResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.integration_instructions, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Teste de Fluxo Completo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Este teste valida o fluxo completo de integração:\n'
              '1. Carregamento do catálogo de organismos\n'
              '2. Validação com critérios de especialistas\n'
              '3. Integração com mapa de infestação\n'
              '4. Cálculo de níveis de infestação\n'
              '5. Fluxo end-to-end completo',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _runIntegrationTest,
      icon: _isLoading 
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.play_arrow),
      label: Text(_isLoading ? 'Executando Testes...' : 'Executar Teste de Integração'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResults == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.integration_instructions,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Execute o teste para ver os resultados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _testResults!['success'] == true ? Icons.check_circle : Icons.error,
                  color: _testResults!['success'] == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resultados do Teste de Integração',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: _buildTestResultContent(_testResults!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultContent(Map<String, dynamic> results) {
    if (results.containsKey('summary')) {
      return _buildCompleteTestResults(results);
    } else {
      return _buildErrorResults(results);
    }
  }

  Widget _buildCompleteTestResults(Map<String, dynamic> results) {
    final summary = results['summary'] as Map<String, dynamic>;
    final flowTests = results['flow_tests'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumo geral
        _buildSummaryCard(summary),
        const SizedBox(height: 16),
        
        // Detalhes dos testes de fluxo
        Text(
          'Detalhes dos Testes de Fluxo',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        
        _buildFlowTestCard('Carregamento do Catálogo', flowTests['catalog_loading']),
        _buildFlowTestCard('Validação de Dados', flowTests['data_validation']),
        _buildFlowTestCard('Integração com Mapa', flowTests['infestation_integration']),
        _buildFlowTestCard('Cálculo de Infestação', flowTests['infestation_calculation']),
        _buildFlowTestCard('Fluxo End-to-End', flowTests['end_to_end']),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Card(
      color: summary['success_rate'] == '100.0%' ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Teste de Integração',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total de Testes',
                    summary['total_tests'].toString(),
                    Icons.quiz,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Testes Aprovados',
                    summary['passed_tests'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Taxa de Sucesso',
                    summary['success_rate'],
                    Icons.percent,
                    summary['success_rate'] == '100.0%' ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: summary['overall_status'] == 'SUCCESS' ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    summary['overall_status'] == 'SUCCESS' ? Icons.check_circle : Icons.warning,
                    color: summary['overall_status'] == 'SUCCESS' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${summary['overall_status']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: summary['overall_status'] == 'SUCCESS' ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.purple),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.purple,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFlowTestCard(String title, dynamic testData) {
    if (testData == null) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  testData['success'] == true ? Icons.check : Icons.close,
                  color: testData['success'] == true ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (testData is Map<String, dynamic>) ...[
              _buildTestDetail('Status', testData['success'] == true ? 'Sucesso' : 'Falha'),
              if (testData.containsKey('total_organisms'))
                _buildTestDetail('Organismos', testData['total_organisms'].toString()),
              if (testData.containsKey('valid_organisms'))
                _buildTestDetail('Organismos Válidos', testData['valid_organisms'].toString()),
              if (testData.containsKey('load_time_ms'))
                _buildTestDetail('Tempo de Carregamento', '${testData['load_time_ms']}ms'),
              if (testData.containsKey('validation_time_ms'))
                _buildTestDetail('Tempo de Validação', '${testData['validation_time_ms']}ms'),
              if (testData.containsKey('integration_time_ms'))
                _buildTestDetail('Tempo de Integração', '${testData['integration_time_ms']}ms'),
              if (testData.containsKey('calculation_time_ms'))
                _buildTestDetail('Tempo de Cálculo', '${testData['calculation_time_ms']}ms'),
              if (testData.containsKey('end_to_end_time_ms'))
                _buildTestDetail('Tempo Total', '${testData['end_to_end_time_ms']}ms'),
              if (testData.containsKey('error'))
                Text(
                  'Erro: ${testData['error']}',
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorResults(Map<String, dynamic> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Erro no Teste',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          results['error'] ?? 'Erro desconhecido',
          style: const TextStyle(color: Colors.red),
        ),
      ],
    );
  }

  Future<void> _runIntegrationTest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _testService.testCompleteIntegrationFlow();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao executar teste de integração: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
}

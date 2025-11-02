import 'package:flutter/material.dart';
import '../../services/organism_catalog_test_service.dart';
import '../../utils/logger.dart';

/// Tela para testar a funcionalidade do catálogo de organismos
class OrganismCatalogTestScreen extends StatefulWidget {
  const OrganismCatalogTestScreen({Key? key}) : super(key: key);

  @override
  State<OrganismCatalogTestScreen> createState() => _OrganismCatalogTestScreenState();
}

class _OrganismCatalogTestScreenState extends State<OrganismCatalogTestScreen> {
  final OrganismCatalogTestService _testService = OrganismCatalogTestService();
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste do Catálogo de Organismos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botões de teste
            _buildTestButtons(),
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

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runAllTests,
          icon: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
          label: Text(_isLoading ? 'Executando Testes...' : 'Executar Todos os Testes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testLoadAll,
                icon: const Icon(Icons.list),
                label: const Text('Testar Carregamento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testSearch,
                icon: const Icon(Icons.search),
                label: const Text('Testar Busca'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testStatistics,
                icon: const Icon(Icons.analytics),
                label: const Text('Testar Estatísticas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _clearResults,
                icon: const Icon(Icons.clear),
                label: const Text('Limpar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestResults() {
    if (_testResults == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Execute os testes para ver os resultados',
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
                  'Resultados dos Testes',
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
      // Resultados da bateria completa de testes
      return _buildCompleteTestResults(results);
    } else if (results.containsKey('total_organisms')) {
      // Resultados de carregamento
      return _buildLoadTestResults(results);
    } else if (results.containsKey('search_tests')) {
      // Resultados de busca
      return _buildSearchTestResults(results);
    } else if (results.containsKey('statistics')) {
      // Resultados de estatísticas
      return _buildStatisticsResults(results);
    } else {
      // Resultados genéricos
      return _buildGenericResults(results);
    }
  }

  Widget _buildCompleteTestResults(Map<String, dynamic> results) {
    final summary = results['summary'] as Map<String, dynamic>;
    final tests = results['tests'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumo
        _buildSummaryCard(summary),
        const SizedBox(height: 16),
        
        // Detalhes dos testes
        Text(
          'Detalhes dos Testes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        
        _buildTestDetail('Carregamento Geral', tests['load_all']),
        _buildTestDetail('Carregamento por Cultura', tests['load_cultures']),
        _buildTestDetail('Funcionalidade de Busca', tests['search']),
        _buildTestDetail('Estatísticas', tests['statistics']),
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
              'Resumo dos Testes',
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.blue,
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

  Widget _buildTestDetail(String title, dynamic testData) {
    if (testData == null) return const SizedBox.shrink();
    
    return Card(
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
              if (testData.containsKey('total_organisms'))
                Text('Organismos: ${testData['total_organisms']}'),
              if (testData.containsKey('load_time_ms'))
                Text('Tempo: ${testData['load_time_ms']}ms'),
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

  Widget _buildLoadTestResults(Map<String, dynamic> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultItem('Total de Organismos', results['total_organisms'].toString()),
        _buildResultItem('Culturas', results['cultures_count'].toString()),
        _buildResultItem('Tempo de Carregamento', '${results['load_time_ms']}ms'),
        const SizedBox(height: 16),
        
        if (results.containsKey('organisms_by_crop')) ...[
          Text(
            'Organismos por Cultura',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...((results['organisms_by_crop'] as Map<String, dynamic>).entries.map(
            (entry) => _buildResultItem(entry.key, entry.value.toString()),
          )),
        ],
        
        if (results.containsKey('organisms_by_type')) ...[
          const SizedBox(height: 16),
          Text(
            'Organismos por Tipo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...((results['organisms_by_type'] as Map<String, dynamic>).entries.map(
            (entry) => _buildResultItem(entry.key, entry.value.toString()),
          )),
        ],
      ],
    );
  }

  Widget _buildSearchTestResults(Map<String, dynamic> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados da Busca',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...((results['search_tests'] as Map<String, dynamic>).entries.map(
          (entry) => _buildResultItem(
            'Busca por "${entry.key}"',
            '${entry.value['results_count']} resultados (${entry.value['search_time_ms']}ms)',
          ),
        )),
      ],
    );
  }

  Widget _buildStatisticsResults(Map<String, dynamic> results) {
    final stats = results['statistics'] as Map<String, dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultItem('Total de Organismos', stats['total_organisms'].toString()),
        _buildResultItem('Culturas', stats['cultures_count'].toString()),
        _buildResultItem('Tempo de Carregamento', '${results['load_time_ms']}ms'),
        const SizedBox(height: 16),
        
        if (stats.containsKey('by_type')) ...[
          Text(
            'Por Tipo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...((stats['by_type'] as Map<String, dynamic>).entries.map(
            (entry) => _buildResultItem(entry.key, entry.value.toString()),
          )),
        ],
        
        if (stats.containsKey('by_crop')) ...[
          const SizedBox(height: 16),
          Text(
            'Por Cultura',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...((stats['by_crop'] as Map<String, dynamic>).entries.map(
            (entry) => _buildResultItem(entry.key, entry.value.toString()),
          )),
        ],
      ],
    );
  }

  Widget _buildGenericResults(Map<String, dynamic> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...(results.entries.map(
          (entry) => _buildResultItem(entry.key, entry.value.toString()),
        )),
      ],
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _testService.runAllTests();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao executar testes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLoadAll() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _testService.testLoadAllOrganisms();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao testar carregamento: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _testService.testSearchFunctionality();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao testar busca: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _testService.testCatalogStatistics();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao testar estatísticas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults = null;
    });
  }
}

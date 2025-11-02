import 'package:flutter/material.dart';
import '../database/database_test_utility.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  final DatabaseTestUtility _testUtility = DatabaseTestUtility();
  
  bool _isRunning = false;
  Map<String, dynamic> _testResults = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testes do Banco de Dados'),
        // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Testes de Integridade do Banco de Dados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Esta ferramenta executa uma série de testes para verificar a '
                      'integridade do banco de dados e da tabela de talhões.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? null : _runTests,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Executar Testes'),
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isRunning)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2A4F3D)),
                    SizedBox(height: 8),
                    Text('Executando testes...'),
                  ],
                ),
              )
            else if (_testResults.isNotEmpty)
              Expanded(
                child: _buildTestResults(),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
    });
    
    try {
      final results = await _testUtility.runDatabaseTests();
      setState(() {
        _testResults = results;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'success': false,
          'overallStatus': 'Erro: $e',
          'tests': [],
        };
        _isRunning = false;
      });
    }
  }
  
  Widget _buildTestResults() {
    final success = _testResults['success'] as bool;
    final overallStatus = _testResults['overallStatus'] as String;
    final tests = _testResults['tests'] as List;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: success ? Colors.green.shade50 : Colors.red.shade50,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado Geral',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: success ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color: success ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Resultados Detalhados:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index] as Map<String, dynamic>;
              final passed = test['passed'] as bool;
              final name = test['name'] as String;
              final message = test['message'] as String;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: passed ? Colors.green.shade50 : Colors.red.shade50,
                child: ListTile(
                  leading: Icon(
                    passed ? Icons.check_circle : Icons.error,
                    color: passed ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(message),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

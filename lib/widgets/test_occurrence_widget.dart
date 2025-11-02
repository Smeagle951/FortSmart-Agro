import 'package:flutter/material.dart';
import '../test_occurrence_integration.dart';
import '../utils/logger.dart';

/// Widget de teste para verificar a integração de organismos
class TestOccurrenceWidget extends StatefulWidget {
  @override
  _TestOccurrenceWidgetState createState() => _TestOccurrenceWidgetState();
}

class _TestOccurrenceWidgetState extends State<TestOccurrenceWidget> {
  bool _isLoading = false;
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste de Integração - Organismos'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botões de teste
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runBasicTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Teste Básico'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runMultipleCropsTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Teste Múltiplas Culturas'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Executar Todos os Testes'),
            ),
            SizedBox(height: 16),
            
            // Indicador de carregamento
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Executando testes...'),
                  ],
                ),
              ),
            
            // Resultados dos testes
            if (_testResults.isNotEmpty) ...[
              Text(
                'Resultados dos Testes:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _testResults,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runBasicTest() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      // Capturar logs do teste
      final logs = <String>[];
      
      // Interceptar logs do Logger
      // Logger.info é um método estático, não pode ser atribuído
      // Vamos usar print para simular logs
      print('INFO: Teste de ocorrência iniciado');

      await TestOccurrenceIntegration.testOrganismLoading();
      
      // Logger não precisa ser restaurado
      
      setState(() {
        _testResults = logs.join('\n');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = 'Erro no teste: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runMultipleCropsTest() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      final logs = <String>[];
      
      // Logger.info é um método estático, não pode ser atribuído
      print('INFO: Teste de carregamento de organismos iniciado');

      await TestOccurrenceIntegration.testMultipleCrops();
      
      // Logger não precisa ser restaurado
      
      setState(() {
        _testResults = logs.join('\n');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = 'Erro no teste: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      final logs = <String>[];
      
      // Logger.info é um método estático, não pode ser atribuído
      print('INFO: Teste de carregamento de organismos iniciado');

      await TestOccurrenceIntegration.runAllTests();
      
      // Logger não precisa ser restaurado
      
      setState(() {
        _testResults = logs.join('\n');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = 'Erro no teste: $e';
        _isLoading = false;
      });
    }
  }
}

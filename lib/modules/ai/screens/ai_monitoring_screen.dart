import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../utils/fortsmart_theme.dart';
import '../../../utils/logger.dart';

/// Tela para monitorar e testar a IA FortSmart em tempo real
/// Integrada ao módulo AI Agronômica
class AIMonitoringScreen extends StatefulWidget {
  const AIMonitoringScreen({Key? key}) : super(key: key);

  @override
  State<AIMonitoringScreen> createState() => _AIMonitoringScreenState();
}

class _AIMonitoringScreenState extends State<AIMonitoringScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _aiStatus;
  Map<String, dynamic>? _testResults;
  final TextEditingController _testDataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAIStatus();
  }

  @override
  void dispose() {
    _testDataController.dispose();
    super.dispose();
  }

  /// Verifica o status da IA FortSmart
  Future<void> _checkAIStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Logger.info('🤖 Verificando status da IA FortSmart...');
      
      // Tentar conectar com o backend de IA
      final response = await http.get(
        Uri.parse('http://localhost:5000/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _aiStatus = data;
          _isLoading = false;
        });
        Logger.info('✅ IA FortSmart está funcionando');
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('❌ Erro ao conectar com IA: $e');
      setState(() {
        _error = 'Erro ao conectar com IA FortSmart: $e';
        _isLoading = false;
      });
    }
  }

  /// Testa a IA com dados de exemplo
  Future<void> _testAI() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Logger.info('🧪 Testando IA FortSmart com dados de exemplo...');
      
      // Dados de teste para germinação
      final testData = {
        'test_id': 'test_001',
        'lote_id': 'L001',
        'cultura': 'Soja',
        'variedade': 'BMX Potência RR',
        'data_inicio': DateTime.now().toIso8601String(),
        'subtestes': [
          {
            'subtest_id': 'A',
            'registros': [
              {
                'dia': 3,
                'germinadas': 85,
                'nao_germinadas': 15,
                'manchas': 2,
                'podridao': 1,
                'cotiledones_amarelados': 0,
                'vigor': 'Alto',
                'pureza': 98.5,
                'percentual_germinacao': 85.0,
                'categoria_germinacao': 'Boa',
                'data_registro': DateTime.now().toIso8601String(),
              },
              {
                'dia': 5,
                'germinadas': 90,
                'nao_germinadas': 10,
                'manchas': 1,
                'podridao': 0,
                'cotiledones_amarelados': 0,
                'vigor': 'Alto',
                'pureza': 99.0,
                'percentual_germinacao': 90.0,
                'categoria_germinacao': 'Excelente',
                'data_registro': DateTime.now().toIso8601String(),
              },
            ],
          },
        ],
      };

      final response = await http.post(
        Uri.parse('http://localhost:5000/predict_germination'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(testData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _testResults = data;
          _isLoading = false;
        });
        Logger.info('✅ Teste da IA FortSmart concluído com sucesso');
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('❌ Erro ao testar IA: $e');
      setState(() {
        _error = 'Erro ao testar IA FortSmart: $e';
        _isLoading = false;
      });
    }
  }

  /// Testa com dados customizados
  Future<void> _testWithCustomData() async {
    if (_testDataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite dados de teste primeiro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final testData = json.decode(_testDataController.text);
      
      final response = await http.post(
        Uri.parse('http://localhost:5000/predict_germination'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(testData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _testResults = data;
          _isLoading = false;
        });
        Logger.info('✅ Teste customizado da IA FortSmart concluído');
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('❌ Erro no teste customizado: $e');
      setState(() {
        _error = 'Erro no teste customizado da IA FortSmart: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkAIStatus,
        backgroundColor: FortSmartTheme.primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Monitor FortSmart'),
      backgroundColor: FortSmartTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfoDialog,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildTestSection(),
          const SizedBox(height: 16),
          if (_testResults != null) _buildResultsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: _aiStatus != null ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status do Sistema FortSmart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _aiStatus != null ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Verificando conexão...'),
                ],
              ),
            ] else if (_error != null) ...[
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ] else if (_aiStatus != null) ...[
              _buildStatusInfo(),
            ] else ...[
              const Text('Status desconhecido'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            const Text('IA FortSmart está funcionando'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.schedule, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Text('Última verificação: ${DateTime.now().toString().substring(11, 19)}'),
          ],
        ),
        if (_aiStatus!['models_loaded'] != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.model_training, color: Colors.purple, size: 16),
              const SizedBox(width: 8),
              Text('Modelos carregados: ${_aiStatus!['models_loaded']}'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTestSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: FortSmartTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Testes da IA FortSmart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _aiStatus != null ? _testAI : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Teste Rápido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _aiStatus != null ? _testWithCustomData : null,
                    icon: const Icon(Icons.edit),
                    label: const Text('Teste Customizado'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FortSmartTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Dados de Teste Customizado (JSON):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _testDataController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Cole aqui os dados JSON para teste...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    if (_testResults == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Resultados do Teste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultItem(
              'Predição de Regressão',
              '${_testResults!['regression_prediction']?.toStringAsFixed(1) ?? 'N/A'}%',
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildResultItem(
              'Predição de Classificação',
              _testResults!['classification_prediction'] ?? 'N/A',
              Icons.category,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildResultItem(
              'Probabilidade',
              '${(_testResults!['classification_probability'] ?? 0.0).toStringAsFixed(2)}',
              Icons.percent,
              Colors.orange,
            ),
            if (_testResults!['vigor_score'] != null) ...[
              const SizedBox(height: 8),
              _buildResultItem(
                'Score de Vigor',
                '${(_testResults!['vigor_score'] ?? 0.0).toStringAsFixed(2)}',
                Icons.fitness_center,
                Colors.purple,
              ),
            ],
            if (_testResults!['recommendations'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Recomendações:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_testResults!['recommendations'] as List).map((rec) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(rec.toString())),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações da IA FortSmart'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🤖 IA FortSmart para Germinação'),
            SizedBox(height: 8),
            Text('• Modelos treinados com dados sintéticos'),
            Text('• Endpoint: http://localhost:5000'),
            Text('• Predições de regressão e classificação'),
            Text('• Recomendações automáticas'),
            SizedBox(height: 8),
            Text('Para usar em produção:'),
            Text('1. Execute: python germination_prediction_endpoint.py'),
            Text('2. Teste a conexão nesta tela'),
            Text('3. Integre com o módulo de germinação'),
          ],
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

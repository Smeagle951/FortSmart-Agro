import 'package:flutter/material.dart';
import '../../services/talhao_diagnostic_service.dart';
import '../../utils/logger.dart';

/// Tela de diagnóstico para verificar o estado dos talhões
class TalhaoDiagnosticScreen extends StatefulWidget {
  const TalhaoDiagnosticScreen({super.key});

  @override
  State<TalhaoDiagnosticScreen> createState() => _TalhaoDiagnosticScreenState();
}

class _TalhaoDiagnosticScreenState extends State<TalhaoDiagnosticScreen> {
  final TalhaoDiagnosticService _diagnosticService = TalhaoDiagnosticService();
  
  bool _isLoading = false;
  String _diagnosticReport = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _executarDiagnostico();
  }

  /// Executa o diagnóstico completo
  Future<void> _executarDiagnostico() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info('🔍 Iniciando diagnóstico na tela...');
      
      final report = await _diagnosticService.gerarRelatorioDiagnostico();
      
      setState(() {
        _diagnosticReport = report;
        _isLoading = false;
      });
      
      Logger.info('✅ Diagnóstico concluído na tela');
    } catch (e) {
      Logger.error('❌ Erro durante diagnóstico na tela: $e');
      setState(() {
        _errorMessage = 'Erro ao executar diagnóstico: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Diagnóstico dos Talhões'),
        backgroundColor: const Color(0xFF181A1B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _executarDiagnostico,
            tooltip: 'Executar diagnóstico novamente',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF181A1B),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Executando diagnóstico...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildDiagnosticContent(),
    );
  }

  /// Widget de erro
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro durante o diagnóstico',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _executarDiagnostico,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  /// Conteúdo principal do diagnóstico
  Widget _buildDiagnosticContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.analytics,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Status do Diagnóstico',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta tela verifica o estado dos talhões no sistema e identifica possíveis problemas.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Relatório do diagnóstico
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Relatório de Diagnóstico',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: SelectableText(
                    _diagnosticReport,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ações recomendadas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ações Recomendadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionItem(
                  icon: Icons.storage,
                  title: 'Verificar Banco de Dados',
                  description: 'Certifique-se de que as tabelas estão criadas corretamente',
                ),
                _buildActionItem(
                  icon: Icons.save,
                  title: 'Verificar Dados Salvos',
                  description: 'Confirme se os talhões estão sendo salvos no banco',
                ),
                _buildActionItem(
                  icon: Icons.sync,
                  title: 'Verificar Serviço Unificado',
                  description: 'Teste se o serviço está carregando os dados corretamente',
                ),
                _buildActionItem(
                  icon: Icons.map,
                  title: 'Verificar Conversão de Modelos',
                  description: 'Confirme se os dados estão sendo convertidos para o formato do mapa',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _executarDiagnostico,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Executar Diagnóstico'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Item de ação recomendada
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

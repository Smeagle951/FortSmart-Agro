import 'package:flutter/material.dart';
import '../services/crop_diagnostic_service.dart';
import '../utils/logger.dart';

class CropDiagnosticScreen extends StatefulWidget {
  const CropDiagnosticScreen({super.key});

  @override
  State<CropDiagnosticScreen> createState() => _CropDiagnosticScreenState();
}

class _CropDiagnosticScreenState extends State<CropDiagnosticScreen> {
  final CropDiagnosticService _diagnosticService = CropDiagnosticService();
  
  Map<String, dynamic>? _diagnosticResults;
  Map<String, dynamic>? _fixResults;
  bool _isRunningDiagnostic = false;
  bool _isRunningFix = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunningDiagnostic = true;
      _errorMessage = null;
    });

    try {
      final results = await _diagnosticService.runDiagnostic();
      setState(() {
        _diagnosticResults = results;
        _isRunningDiagnostic = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isRunningDiagnostic = false;
      });
    }
  }

  Future<void> _runAutoFix() async {
    setState(() {
      _isRunningFix = true;
      _errorMessage = null;
    });

    try {
      final results = await _diagnosticService.runAutoFix();
      setState(() {
        _fixResults = results;
        _isRunningFix = false;
      });
      
      // Executar diagnóstico novamente após correções
      await _runDiagnostic();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correções aplicadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isRunningFix = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico - Módulo Culturas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunningDiagnostic ? null : _runDiagnostic,
            tooltip: 'Executar diagnóstico',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isRunningDiagnostic) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Executando diagnóstico...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro durante diagnóstico:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ElevatedButton(
              onPressed: _runDiagnostic,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_diagnosticResults == null) {
      return const Center(
        child: Text('Nenhum resultado de diagnóstico disponível'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
          const SizedBox(height: 16),
          _buildDetailedResults(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final hasErrors = _diagnosticResults!['recommendations'] != null &&
        (_diagnosticResults!['recommendations'] as List).any(
          (rec) => rec.toString().contains('❌'),
        );

    return Card(
      color: hasErrors ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasErrors ? Icons.warning : Icons.check_circle,
                  color: hasErrors ? Colors.red : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status do Módulo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasErrors 
                ? 'Foram encontrados problemas que precisam ser corrigidos'
                : 'Módulo funcionando corretamente',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = _diagnosticResults!['recommendations'] as List?;
    
    if (recommendations == null || recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Recomendações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedResults() {
    return ExpansionTile(
      title: const Text('Resultados Detalhados'),
      children: [
        _buildSectionCard('Conexão com Banco', _diagnosticResults!['database_connection']),
        _buildSectionCard('Estrutura das Tabelas', _diagnosticResults!['table_structure']),
        _buildSectionCard('Dados Existentes', _diagnosticResults!['existing_data']),
        _buildSectionCard('Integridade Referencial', _diagnosticResults!['referential_integrity']),
        _buildSectionCard('Operações Básicas', _diagnosticResults!['basic_operations']),
      ],
    );
  }

  Widget _buildSectionCard(String title, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${data['status'] ?? 'N/A'}',
              style: TextStyle(
                color: data['status'] == 'success' ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (data['error'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Erro: ${data['error']}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (data['message'] != null) ...[
              const SizedBox(height: 4),
              Text(
                data['message'],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasErrors = _diagnosticResults!['recommendations'] != null &&
        (_diagnosticResults!['recommendations'] as List).any(
          (rec) => rec.toString().contains('❌'),
        );

    return Column(
      children: [
        if (hasErrors) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunningFix ? null : _runAutoFix,
              icon: _isRunningFix 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.build),
              label: Text(_isRunningFix ? 'Aplicando correções...' : 'Aplicar Correções Automáticas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _runDiagnostic,
            icon: const Icon(Icons.refresh),
            label: const Text('Executar Diagnóstico Novamente'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

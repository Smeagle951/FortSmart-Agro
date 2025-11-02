/// 📊 Tela de Relatório Consolidado de Germinação
/// 
/// Calcula e exibe resultados agronômicos finais
/// seguindo metodologias ABNT NBR 9787

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../widgets/app_bar_widget.dart';
import '../providers/germination_test_provider.dart';
import '../models/germination_test_model.dart';
import '../services/germination_calculation_service.dart';

class GerminationConsolidatedReportScreen extends StatefulWidget {
  final GerminationTest test;
  
  const GerminationConsolidatedReportScreen({
    Key? key,
    required this.test,
  }) : super(key: key);

  @override
  State<GerminationConsolidatedReportScreen> createState() => _GerminationConsolidatedReportScreenState();
}

class _GerminationConsolidatedReportScreenState extends State<GerminationConsolidatedReportScreen> {
  bool _isLoading = true;
  List<GerminationDailyRecord> _allRecords = [];
  Map<String, List<GerminationDailyRecord>> _subtestRecords = {};
  Map<String, Map<String, dynamic>> _subtestResults = {};
  Map<String, dynamic>? _consolidatedResults;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      
      // Carregar todos os registros
      _allRecords = await provider.getDailyRecords(widget.test.id!);
      
      // Separar registros por subteste
      _subtestRecords = _separateRecordsBySubtest(_allRecords);
      
      // Calcular resultados para cada subteste
      _subtestResults = {};
      for (final entry in _subtestRecords.entries) {
        _subtestResults[entry.key] = _calculateSubtestResults(entry.value);
      }
      
      // Calcular resultado consolidado
      _consolidatedResults = _calculateConsolidatedResults(_subtestResults);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Separa registros por subteste
  Map<String, List<GerminationDailyRecord>> _separateRecordsBySubtest(List<GerminationDailyRecord> records) {
    final Map<String, List<GerminationDailyRecord>> result = {};
    
    for (final record in records) {
      final subtestKey = record.subtestId?.toString() ?? 'Individual';
      result.putIfAbsent(subtestKey, () => []).add(record);
    }
    
    return result;
  }

  /// Calcula resultados de um subteste
  Map<String, dynamic> _calculateSubtestResults(List<GerminationDailyRecord> records) {
    if (records.isEmpty) return {};
    
    // Ordenar por data
    records.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    
    final lastRecord = records.last;
    final totalSeeds = widget.test.totalSeeds ~/ (widget.test.useSubtests ? 3 : 1);
    
    return {
      'totalSeeds': totalSeeds,
      'finalGerminated': lastRecord.normalGerminated,
      'finalDiseased': lastRecord.diseasedFungi + lastRecord.diseasedBacteria,
      'finalNotGerminated': lastRecord.notGerminated,
      'germinationPercentage': (lastRecord.normalGerminated / totalSeeds) * 100,
      'diseasedPercentage': ((lastRecord.diseasedFungi + lastRecord.diseasedBacteria) / totalSeeds) * 100,
      'purityPercentage': ((totalSeeds - (lastRecord.otherSeeds + lastRecord.inertMatter)) / totalSeeds) * 100,
      'culturalValue': _calculateCulturalValue(lastRecord, totalSeeds),
      'records': records,
    };
  }

  /// Calcula resultado consolidado
  Map<String, dynamic> _calculateConsolidatedResults(Map<String, Map<String, dynamic>> subtestResults) {
    if (subtestResults.isEmpty) return {};
    
    final results = subtestResults.values.toList();
    
    return {
      'germinationPercentage': _calculateAverage(results.map((r) => r['germinationPercentage'] as double).toList()),
      'diseasedPercentage': _calculateAverage(results.map((r) => r['diseasedPercentage'] as double).toList()),
      'purityPercentage': _calculateAverage(results.map((r) => r['purityPercentage'] as double).toList()),
      'culturalValue': _calculateAverage(results.map((r) => r['culturalValue'] as double).toList()),
      'totalSubtests': results.length,
      'subtestResults': subtestResults,
    };
  }

  /// Calcula média
  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calcula valor cultural
  double _calculateCulturalValue(GerminationDailyRecord record, int totalSeeds) {
    final germination = (record.normalGerminated / totalSeeds) * 100;
    final diseased = ((record.diseasedFungi + record.diseasedBacteria) / totalSeeds) * 100;
    final purity = ((totalSeeds - (record.otherSeeds + record.inertMatter)) / totalSeeds) * 100;
    
    return (germination * purity) / 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Relatório Consolidado',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Calculando resultados...'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestInfoCard(),
          const SizedBox(height: 16),
          _buildConsolidatedResultsCard(),
          const SizedBox(height: 16),
          _buildSubtestResultsSection(),
          const SizedBox(height: 16),
          _buildDetailedRecordsSection(),
          const SizedBox(height: 100), // Espaço para FAB
        ],
      ),
    );
  }

  /// 📋 Card de informações do teste
  Widget _buildTestInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: FortSmartTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Informações do Teste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cultura:', widget.test.culture),
            _buildInfoRow('Variedade:', widget.test.variety),
            _buildInfoRow('Total de Sementes:', '${widget.test.totalSeeds}'),
            _buildInfoRow('Tipo:', widget.test.useSubtests ? 'Com Subtestes (A, B, C)' : 'Individual'),
            _buildInfoRow('Data de Início:', _formatDate(widget.test.startDate)),
          ],
        ),
      ),
    );
  }

  /// 📊 Card de resultados consolidados
  Widget _buildConsolidatedResultsCard() {
    if (_consolidatedResults == null) return const SizedBox();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Resultados Consolidados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultRow(
              'Germinação Final',
              '${(_consolidatedResults!['germinationPercentage'] ?? 0.0).toStringAsFixed(1)}%',
              Colors.green,
            ),
            _buildResultRow(
              'Contaminação',
              '${(_consolidatedResults!['diseasedPercentage'] ?? 0.0).toStringAsFixed(1)}%',
              Colors.red,
            ),
            _buildResultRow(
              'Pureza',
              '${(_consolidatedResults!['purityPercentage'] ?? 0.0).toStringAsFixed(1)}%',
              Colors.blue,
            ),
            _buildResultRow(
              'Valor Cultural',
              '${(_consolidatedResults!['culturalValue'] ?? 0.0).toStringAsFixed(1)}%',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  /// 🧪 Seção de resultados por subteste
  Widget _buildSubtestResultsSection() {
    if (_subtestResults.isEmpty) return const SizedBox();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Resultados por Subteste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._subtestResults.entries.map((entry) => _buildSubtestCard(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  /// 🎯 Card de subteste individual
  Widget _buildSubtestCard(String subtestName, Map<String, dynamic> results) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSubtestColor(subtestName).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getSubtestColor(subtestName).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtestName == 'Individual' ? 'Teste Individual' : 'Subteste $subtestName',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getSubtestColor(subtestName),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMiniResult('Germinação', '${(results['germinationPercentage'] ?? 0.0).toStringAsFixed(1)}%'),
              ),
              Expanded(
                child: _buildMiniResult('Contaminação', '${(results['diseasedPercentage'] ?? 0.0).toStringAsFixed(1)}%'),
              ),
              Expanded(
                child: _buildMiniResult('Pureza', '${(results['purityPercentage'] ?? 0.0).toStringAsFixed(1)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📝 Seção de registros detalhados
  Widget _buildDetailedRecordsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Registros Detalhados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._subtestResults.entries.map((entry) => _buildDetailedSubtest(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  /// 📋 Detalhes de um subteste
  Widget _buildDetailedSubtest(String subtestName, Map<String, dynamic> results) {
    final records = results['records'] as List<GerminationDailyRecord>;
    
    return ExpansionTile(
      title: Text(
        subtestName == 'Individual' ? 'Teste Individual' : 'Subteste $subtestName',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _getSubtestColor(subtestName),
        ),
      ),
      children: records.map((record) => _buildRecordTile(record)).toList(),
    );
  }

  /// 📄 Tile de registro individual
  Widget _buildRecordTile(GerminationDailyRecord record) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getSubtestColor(record.subtestId?.toString() ?? 'Individual'),
        child: Text('${record.day}'),
      ),
      title: Text('Dia ${record.day}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data: ${_formatDate(record.recordDate)}'),
          Text('Germinadas: ${record.normalGerminated}'),
        ],
      ),
    );
  }

  /// 🎨 Cores para cada subteste
  Color _getSubtestColor(String subtest) {
    switch (subtest) {
      case 'A':
        return Colors.blue;
      case 'B':
        return Colors.green;
      case 'C':
        return Colors.orange;
      case 'Individual':
        return FortSmartTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  /// 📊 Linha de resultado
  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Mini resultado
  Widget _buildMiniResult(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 📝 Linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formata data
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}

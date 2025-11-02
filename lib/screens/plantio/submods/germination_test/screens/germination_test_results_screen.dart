import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/germination_test_model.dart';
import '../providers/germination_test_provider.dart';

/// Tela simplificada de resultados do teste de germinação
/// Focada em informações agronômicas essenciais e funcionais
class GerminationTestResultsScreenSimplified extends StatefulWidget {
  final GerminationTest test;

  const GerminationTestResultsScreenSimplified({
    super.key,
    required this.test,
  });

  @override
  State<GerminationTestResultsScreenSimplified> createState() => _GerminationTestResultsScreenSimplifiedState();
}

class _GerminationTestResultsScreenSimplifiedState extends State<GerminationTestResultsScreenSimplified> {
  bool _isLoading = false;
  List<GerminationDailyRecord> _dailyRecords = [];
  double _finalGerminationPercentage = 0.0;
  double _diseasedPercentage = 0.0;
  double _averageGerminationTime = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDailyRecords();
  }

  Future<void> _loadDailyRecords() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      await provider.ensureInitialized();
      
      if (provider.isReady) {
        final records = await provider.getDailyRecords(widget.test.id!);
        setState(() {
          _dailyRecords = records;
          _calculateResults();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Erro ao carregar registros: $e');
    }
  }

  void _calculateResults() {
    if (_dailyRecords.isEmpty) return;

    // Calcular germinação total
    // Usar apenas o ÚLTIMO REGISTRO (mais recente) para o resumo final
    final lastRecord = _dailyRecords.reduce((a, b) => a.recordDate.isAfter(b.recordDate) ? a : b);
    
    final totalNormal = lastRecord.normalGerminated;
    final totalAbnormal = lastRecord.abnormalGerminated;
    final totalGerminated = totalNormal + totalAbnormal;
    
    // Calcular doenças do último registro
    final totalDiseased = lastRecord.diseasedFungi + lastRecord.diseasedBacteria;
    
    // Calcular percentuais baseados no último registro
    _finalGerminationPercentage = widget.test.totalSeeds > 0 
        ? (totalGerminated / widget.test.totalSeeds * 100)
        : 0.0;
    
    _diseasedPercentage = widget.test.totalSeeds > 0 
        ? (totalDiseased / widget.test.totalSeeds * 100)
        : 0.0;
    
    // Calcular tempo médio de germinação (simplificado)
    if (_dailyRecords.isNotEmpty) {
      final maxDay = _dailyRecords.map((r) => r.day).reduce((a, b) => a > b ? a : b);
      _averageGerminationTime = maxDay.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados do Teste'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dailyRecords.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.science_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum registro diário encontrado',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTestHeader(),
                  const SizedBox(height: 16),
                  _buildEssentialMetrics(),
                  const SizedBox(height: 16),
                  _buildDailyRecordsTable(),
                  const SizedBox(height: 16),
                  _buildRecommendations(),
                ],
              ),
            ),
    );
  }

  /// Cabeçalho com informações básicas do teste
  Widget _buildTestHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Teste de Germinação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cultura', widget.test.culture),
            _buildInfoRow('Variedade', widget.test.variety),
            _buildInfoRow('Data de Início', _formatDate(widget.test.startDate)),
            _buildInfoRow('Duração', '${widget.test.expectedEndDate != null ? widget.test.expectedEndDate!.difference(widget.test.startDate).inDays : 7} dias'),
            _buildInfoRow('Temperatura', '25°C'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Métricas essenciais do teste
  Widget _buildEssentialMetrics() {
    final germinacao = _finalGerminationPercentage;
    final vigor = _averageGerminationTime;
    final doencas = _diseasedPercentage;
    final classificacao = _getClassification(germinacao, vigor, doencas);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados Principais',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Germinação',
                    '${(germinacao ?? 0.0).toStringAsFixed(1)}%',
                    _getGerminationColor(germinacao),
                    Icons.eco,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Vigor',
                    '${(vigor ?? 0.0).toStringAsFixed(1)}%',
                    _getVigorColor(vigor),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Doenças',
                    '${(doencas ?? 0.0).toStringAsFixed(1)}%',
                    _getDiseaseColor(doencas),
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Classificação',
                    classificacao,
                    _getClassificationColor(classificacao),
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Tabela de registros diários baseada na imagem 2
  Widget _buildDailyRecordsTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Registros Diários',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_dailyRecords.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum registro diário disponível',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.green.shade50),
                    headingRowHeight: 28,
                    dataRowHeight: 24,
                    columnSpacing: 6,
                  columns: [
                    DataColumn(
                      label: Text(
                        'Dia',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Data',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Normais',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Anormais',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        '%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Fungos',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Bactérias',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                  rows: _buildTableRows(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildTableRows() {
    return _dailyRecords.map((record) {
      // Mostrar cada registro individualmente, não acumulado
      final totalForThisRecord = record.normalGerminated + record.abnormalGerminated;
      final germinationPercentage = widget.test.totalSeeds > 0 
          ? (totalForThisRecord / widget.test.totalSeeds * 100)
          : 0.0;
      
      // Cores baseadas na porcentagem (como na imagem)
      Color percentageColor;
      if (germinationPercentage < 30) {
        percentageColor = Colors.red;
      } else if (germinationPercentage < 70) {
        percentageColor = Colors.orange;
      } else {
        percentageColor = Colors.green;
      }
      
      return DataRow(
        cells: [
          DataCell(
            Center(
              child: Text(
                '${record.day}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          DataCell(
            Text(
              _formatDate(record.recordDate),
              style: const TextStyle(fontSize: 10),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${record.normalGerminated}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${record.abnormalGerminated}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '$totalForThisRecord',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${(germinationPercentage ?? 0.0).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: percentageColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${record.diseasedFungi}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          DataCell(
            Center(
              child: Text(
                '${record.diseasedBacteria}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Recomendações agronômicas
  Widget _buildRecommendations() {
    final germinacao = _finalGerminationPercentage;
    final vigor = _averageGerminationTime;
    final doencas = _diseasedPercentage;

    List<String> recomendacoes = [];

    if (germinacao < 80) {
      recomendacoes.add('• Germinação baixa: verificar qualidade das sementes');
    }
    if (vigor < 70) {
      recomendacoes.add('• Vigor insuficiente: revisar condições de armazenamento');
    }
    if (doencas > 10) {
      recomendacoes.add('• Alta incidência de doenças: aplicar tratamento fitossanitário');
    }
    if (germinacao >= 90 && vigor >= 80 && doencas <= 5) {
      recomendacoes.add('• Excelente qualidade: sementes adequadas para plantio');
    }

    if (recomendacoes.isEmpty) {
      recomendacoes.add('• Resultados dentro dos parâmetros esperados');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Recomendações Agronômicas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recomendacoes.map((recomendacao) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                recomendacao,
                style: const TextStyle(fontSize: 14),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para cores
  Color _getGerminationColor(double value) {
    if (value >= 90) return Colors.green;
    if (value >= 80) return Colors.orange;
    return Colors.red;
  }

  Color _getVigorColor(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getDiseaseColor(double value) {
    if (value <= 5) return Colors.green;
    if (value <= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getClassificationColor(String classification) {
    switch (classification) {
      case 'Excelente':
        return Colors.green;
      case 'Boa':
        return Colors.blue;
      case 'Regular':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _getClassification(double germinacao, double vigor, double doencas) {
    if (germinacao >= 90 && vigor >= 80 && doencas <= 5) {
      return 'Excelente';
    } else if (germinacao >= 80 && vigor >= 70 && doencas <= 10) {
      return 'Boa';
    } else if (germinacao >= 70 && vigor >= 60 && doencas <= 15) {
      return 'Regular';
    } else {
      return 'Baixa';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}
/// 📊 Tela de Relatório de Germinação
/// 
/// Gera relatório completo com tabela de registros diários

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../widgets/app_bar_widget.dart';
import '../providers/germination_test_provider.dart';
import '../models/germination_test_model.dart';

class GerminationReportScreen extends StatefulWidget {
  final GerminationTest test;

  const GerminationReportScreen({
    super.key,
    required this.test,
  });

  @override
  State<GerminationReportScreen> createState() => _GerminationReportScreenState();
}

class _GerminationReportScreenState extends State<GerminationReportScreen> {
  List<GerminationDailyRecord> _dailyRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyRecords();
  }

  Future<void> _loadDailyRecords() async {
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      await provider.ensureInitialized();
      
      if (provider.isReady) {
        final records = await provider.getDailyRecords(widget.test.id!);
        setState(() {
          _dailyRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Erro ao carregar registros: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBarWidget(
        title: 'Relatório de Germinação',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTestInfo(),
                  const SizedBox(height: 24),
                  _buildReportTable(),
                  const SizedBox(height: 24),
                  _buildSummary(),
                ],
              ),
            ),
    );
  }

  Widget _buildTestInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [FortSmartTheme.primaryColor, FortSmartTheme.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Teste de Germinação',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cultura', widget.test.culture),
            _buildInfoRow('Variedade', widget.test.variety),
            _buildInfoRow('Lote', widget.test.seedLot),
            _buildInfoRow('Total de Sementes', '${widget.test.totalSeeds}'),
            _buildInfoRow('Data de Início', _formatDate(widget.test.startDate)),
            _buildInfoRow('Duração', '${_calculateDuration()} dias'),
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
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: Colors.white),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    if (_dailyRecords.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.table_chart, size: 64, color: Colors.grey[400]),
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
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Registros Diários',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                rows: _buildCompactTableRows(),
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
      
      return DataRow(
        cells: [
          DataCell(Text('${record.day}')),
          DataCell(Text(_formatDate(record.recordDate))),
          DataCell(Text('${record.normalGerminated}')),
          DataCell(Text('${record.abnormalGerminated}')),
          DataCell(Text('$totalForThisRecord')),
          DataCell(Text('${(germinationPercentage ?? 0.0).toStringAsFixed(1)}%')),
          DataCell(Text('${record.diseasedFungi}')),
          DataCell(Text('${record.diseasedBacteria}')),
        ],
      );
    }).toList();
  }

  List<DataRow> _buildCompactTableRows() {
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
            Text(
              '${record.day}',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          DataCell(
            Text(
              _formatDate(record.recordDate),
              style: const TextStyle(fontSize: 10),
            ),
          ),
          DataCell(
            Text(
              '${record.normalGerminated}',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          DataCell(
            Text(
              '${record.abnormalGerminated}',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          DataCell(
            Text(
              '$totalForThisRecord',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          DataCell(
            Text(
              '${(germinationPercentage ?? 0.0).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                color: percentageColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataCell(
            Text(
              '${record.diseasedFungi}',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          DataCell(
            Text(
              '${record.diseasedBacteria}',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildSummary() {
    if (_dailyRecords.isEmpty) return const SizedBox.shrink();

    // Pegar o ÚLTIMO REGISTRO (mais recente) para o resumo final
    final lastRecord = _dailyRecords.reduce((a, b) => a.recordDate.isAfter(b.recordDate) ? a : b);
    
    final totalNormal = lastRecord.normalGerminated;
    final totalAbnormal = lastRecord.abnormalGerminated;
    final totalGerminated = totalNormal + totalAbnormal;
    final totalDiseased = lastRecord.diseasedFungi + lastRecord.diseasedBacteria;
    final totalNotGerminated = lastRecord.notGerminated;
    
    final germinationPercentage = widget.test.totalSeeds > 0 
        ? (totalGerminated / widget.test.totalSeeds * 100)
        : 0.0;
    final diseasedPercentage = widget.test.totalSeeds > 0 
        ? (totalDiseased / widget.test.totalSeeds * 100)
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Resumo Final',
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
                  child: _buildSummaryCard(
                    'Germinação',
                    '${(germinationPercentage ?? 0.0).toStringAsFixed(1)}%',
                    Colors.green,
                    Icons.eco,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Doenças',
                    '${(diseasedPercentage ?? 0.0).toStringAsFixed(1)}%',
                    Colors.orange,
                    Icons.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Normais',
                    '$totalNormal',
                    Colors.green[700]!,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Anormais',
                    '$totalAbnormal',
                    Colors.orange[700]!,
                    Icons.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Não Germinadas',
                    '$totalNotGerminated',
                    Colors.red[700]!,
                    Icons.cancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total',
                    '${widget.test.totalSeeds}',
                    Colors.blue[700]!,
                    Icons.all_inclusive,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDuration() {
    if (widget.test.expectedEndDate != null) {
      return widget.test.expectedEndDate!.difference(widget.test.startDate).inDays;
    }
    return _dailyRecords.isNotEmpty 
        ? _dailyRecords.map((r) => r.day).reduce((a, b) => a > b ? a : b)
        : 0;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  void _shareReport() {
    // TODO: Implementar compartilhamento do relatório
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhamento em desenvolvimento'),
      ),
    );
  }
}

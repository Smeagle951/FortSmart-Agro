import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/germination_test_model.dart';

/// Widget moderno para exibir registros diários em formato de tabela
/// Baseado no card "Registros Diários" que estava muito bem feito
class DailyRecordsTableWidget extends StatelessWidget {
  final List<GerminationDailyRecordModel> records;
  final int totalSeeds;
  final Function(GerminationDailyRecordModel)? onEditRecord;
  final Function(GerminationDailyRecordModel)? onDeleteRecord;

  const DailyRecordsTableWidget({
    Key? key,
    required this.records,
    required this.totalSeeds,
    this.onEditRecord,
    this.onDeleteRecord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _buildEmptyState();
    }

    // Ordenar registros por dia
    final sortedRecords = List<GerminationDailyRecordModel>.from(records)
      ..sort((a, b) => a.dia.compareTo(b.dia));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTable(sortedRecords),
            const SizedBox(height: 16),
            _buildSummary(sortedRecords),
          ],
        ),
      ),
    );
  }

  /// Estado vazio quando não há registros
  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum registro diário encontrado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione registros diários para acompanhar o progresso do teste',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cabeçalho do card
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.calendar_today, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Text(
          'Registros Diários',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${records.length} registros',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  /// Tabela de registros diários
  Widget _buildTable(List<GerminationDailyRecordModel> sortedRecords) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ...sortedRecords.map((record) => _buildTableRow(record)),
        ],
      ),
    );
  }

  /// Cabeçalho da tabela
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildHeaderCell('Dia', Icons.calendar_today),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell('Data', Icons.date_range),
          ),
          Expanded(
            flex: 1,
            child: _buildHeaderCell('Normais', Icons.check_circle, Colors.green),
          ),
          Expanded(
            flex: 1,
            child: _buildHeaderCell('Anormais', Icons.warning, Colors.orange),
          ),
          Expanded(
            flex: 1,
            child: _buildHeaderCell('Total', Icons.all_inclusive, Colors.blue),
          ),
          Expanded(
            flex: 1,
            child: _buildHeaderCell('%', Icons.percent, Colors.purple),
          ),
          Expanded(
            flex: 1,
            child: _buildHeaderCell('Fungos', Icons.sick, Colors.red),
          ),
          if (onEditRecord != null || onDeleteRecord != null)
            const Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  'Ações',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Célula do cabeçalho
  Widget _buildHeaderCell(String text, IconData icon, [Color? color]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color ?? Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// Linha da tabela
  Widget _buildTableRow(GerminationDailyRecordModel record) {
    final totalGerminated = record.germinadas;
    final percentage = totalSeeds > 0 ? (totalGerminated / totalSeeds) * 100 : 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildCell(
              '${record.dia}',
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildCell(_formatDate(record.dataRegistro)),
          ),
          Expanded(
            flex: 1,
            child: _buildCell(
              '${record.germinadas}',
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildCell(
              '${record.naoGerminadas}',
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildCell(
              '$totalGerminated',
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildPercentageCell(percentage),
          ),
          Expanded(
            flex: 1,
            child: _buildCell(
              '${record.manchas}',
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onEditRecord != null || onDeleteRecord != null)
            Expanded(
              flex: 1,
              child: _buildActionButtons(record),
            ),
        ],
      ),
    );
  }

  /// Célula da tabela
  Widget _buildCell(
    String text, {
    Color? color,
    FontWeight? fontWeight,
  }) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.grey.shade700,
          fontWeight: fontWeight ?? FontWeight.normal,
        ),
      ),
    );
  }

  /// Célula de percentual com cores
  Widget _buildPercentageCell(double percentage) {
    Color color;
    if (percentage >= 80) {
      color = Colors.green.shade700;
    } else if (percentage >= 60) {
      color = Colors.blue.shade700;
    } else if (percentage >= 40) {
      color = Colors.orange.shade700;
    } else {
      color = Colors.red.shade700;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Botões de ação
  Widget _buildActionButtons(GerminationDailyRecordModel record) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onEditRecord != null)
          IconButton(
            icon: Icon(Icons.edit, size: 16, color: Colors.blue.shade600),
            onPressed: () => onEditRecord!(record),
            tooltip: 'Editar registro',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        if (onDeleteRecord != null)
          IconButton(
            icon: Icon(Icons.delete, size: 16, color: Colors.red.shade600),
            onPressed: () => _showDeleteConfirmation(record),
            tooltip: 'Excluir registro',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  /// Resumo dos registros
  Widget _buildSummary(List<GerminationDailyRecordModel> sortedRecords) {
    if (sortedRecords.isEmpty) return const SizedBox.shrink();

    final lastRecord = sortedRecords.last;
    final totalGerminated = lastRecord.germinadas;
    final finalPercentage = totalSeeds > 0 ? (totalGerminated / totalSeeds) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            'Resumo Final:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Germinadas',
                  '$totalGerminated',
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Percentual Final',
                  '${finalPercentage.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Dias de Teste',
                  '${sortedRecords.length}',
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Item do resumo
  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Mostrar confirmação de exclusão
  void _showDeleteConfirmation(GerminationDailyRecordModel record) {
    // Implementar confirmação de exclusão
    // Por enquanto, apenas chama a função
    if (onDeleteRecord != null) {
      onDeleteRecord!(record);
    }
  }

  /// Formatar data
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

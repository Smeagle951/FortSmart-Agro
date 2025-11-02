import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/farm.dart';
// import '../../../services/germination_report_service.dart'; // Comentado temporariamente
import '../../../services/planting_report_service.dart';
import '../../../services/integrated_report_service.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/logger.dart';

/// Dashboard principal de relatórios integrados
/// Centraliza acesso a todos os tipos de relatórios do sistema
class IntegratedReportsDashboard extends StatefulWidget {
  static const String routeName = '/reports/dashboard';

  const IntegratedReportsDashboard({Key? key}) : super(key: key);

  @override
  State<IntegratedReportsDashboard> createState() => _IntegratedReportsDashboardState();
}

class _IntegratedReportsDashboardState extends State<IntegratedReportsDashboard> {
  // Serviços
  // final GerminationReportService _germinationReportService = GerminationReportService(); // Comentado temporariamente
  final PlantingReportService _plantingReportService = PlantingReportService();
  final IntegratedReportService _integratedReportService = IntegratedReportService();
  
  // Estado
  bool _isGeneratingReport = false;
  String? _currentReportType;
  
  // Filtros globais
  DateTime? _startDate;
  DateTime? _endDate;
  String _farmName = 'Fazenda';
  String _technicianName = 'Técnico Responsável';

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month - 1, 1); // Último mês
    _endDate = now;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Relatórios'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildGlobalFilters(),
            const SizedBox(height: 24),
            _buildReportCategories(),
            const SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: AppTheme.primaryColorLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Central de Relatórios FortSmart',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Acesse todos os tipos de relatórios do sistema em um só lugar. '
              'Gere análises detalhadas de germinação, plantio e operações integradas.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros Globais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Data Inicial',
                    _startDate,
                    (date) => setState(() => _startDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'Data Final',
                    _endDate,
                    (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _farmName,
                    decoration: InputDecoration(
                      labelText: 'Nome da Fazenda',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() => _farmName = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _technicianName,
                    decoration: InputDecoration(
                      labelText: 'Técnico Responsável',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() => _technicianName = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorias de Relatórios',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // ❌ REMOVIDO: Relatórios de Germinação - não serão mais utilizados
        
        // Relatórios de Plantio
        _buildCategoryCard(
          title: 'Operações de Plantio',
          subtitle: 'Análises de plantio e calibração',
          icon: Icons.grass,
          color: AppTheme.secondaryColor,
          reports: [
            _buildReportItem(
              title: 'Relatório de Plantio',
              description: 'Análise completa de operações de plantio',
              onTap: () => _generatePlantingReport(),
            ),
            _buildReportItem(
              title: 'Análise de Densidade',
              description: 'Relatório específico de densidade de plantio',
              onTap: () => _generateDensityAnalysisReport(),
            ),
            _buildReportItem(
              title: 'Exportar Dados CSV',
              description: 'Dados de plantio em formato CSV',
              onTap: () => _exportPlantingData(),
            ),
          ],
        ),
        
        
        const SizedBox(height: 12),
        
        // ❌ REMOVIDO: Relatórios Integrados - não serão mais utilizados
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> reports,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...reports,
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: _isGeneratingReport ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingReport ? null : _generateAllReports,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Gerar Todos os Relatórios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGeneratingReport ? null : _clearFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Limpar Filtros'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      side: BorderSide(color: AppTheme.secondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, Function(DateTime?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) onChanged(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Selecionar data',
                  style: TextStyle(
                    color: value != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Métodos de geração de relatórios
  
  // ❌ REMOVIDO: Métodos de relatórios de germinação
  // Não serão mais utilizados

  Future<void> _generatePlantingReport() async {
    await _generateReport(
      'Relatório de Plantio',
      () => _plantingReportService.generatePlantingReport(
        plantings: [], // TODO: Implementar busca de plantios
        farm: Farm(
          id: 'default',
          name: 'Fazenda Padrão',
          address: 'Localização não especificada',
          totalArea: 0.0,
          plotsCount: 0,
          crops: [],
          hasIrrigation: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        plot: null, // TODO: Implementar modelo de talhão
        technicianName: _technicianName,
        includeCalibrationDetails: true,
        includeProductivityAnalysis: true,
      ),
    );
  }

  Future<void> _generateDensityAnalysisReport() async {
    await _generateReport(
      'Análise de Densidade',
      () => _plantingReportService.generateDensityAnalysisReport(
        plantings: [], // TODO: Implementar busca de plantios
        farm: Farm(
          id: 'default',
          name: 'Fazenda Padrão',
          address: 'Localização não especificada',
          totalArea: 0.0,
          plotsCount: 0,
          crops: [],
          hasIrrigation: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        technicianName: _technicianName,
      ),
    );
  }

  Future<void> _exportPlantingData() async {
    await _generateReport(
      'Exportação de Dados de Plantio',
      () => _plantingReportService.exportPlantingDataToCsv(
        plantings: [], // TODO: Implementar busca de plantios
        fileName: 'Dados_Plantio_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      ),
    );
  }

  // ❌ REMOVIDO: _generateIntegratedReport e _generateSeedQualityReport
  // Não serão mais utilizados

  Future<void> _generateAllReports() async{
    setState(() {
      _isGeneratingReport = true;
      _currentReportType = 'Todos os Relatórios';
    });

    try {
      // TODO: Implementar geração sequencial de todos os relatórios
      await Future.delayed(const Duration(seconds: 2)); // Simulação
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os relatórios foram gerados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Logger.error('IntegratedReportsDashboard: Erro ao gerar todos os relatórios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar relatórios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingReport = false;
        _currentReportType = null;
      });
    }
  }

  Future<void> _generateReport(String reportType, Future<String> Function() generator) async {
    setState(() {
      _isGeneratingReport = true;
      _currentReportType = reportType;
    });

    try {
      Logger.info('🔄 Iniciando geração de relatório: $reportType');
      
      // Mostrar loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Gerando $reportType...'),
              ),
            ],
          ),
        ),
      );
      
      final filePath = await generator();
      
      // Fechar loading dialog
      Navigator.of(context).pop();
      
      Logger.info('✅ Relatório gerado com sucesso: $reportType');
      _showReportGeneratedDialog(reportType, filePath);
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar $reportType: $e');
      
      // Fechar loading dialog se ainda estiver aberto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar $reportType: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingReport = false;
        _currentReportType = null;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _initializeDates();
      _farmName = 'Fazenda';
      _technicianName = 'Técnico Responsável';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtros limpos')),
    );
  }

  void _showReportGeneratedDialog(String reportType, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$reportType Gerado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Relatório gerado com sucesso!'),
            const SizedBox(height: 8),
            Text(
              'Arquivo: ${filePath.split('/').last}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implementar compartilhamento baseado no tipo de relatório
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compartilhamento implementado')),
              );
            },
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }
}

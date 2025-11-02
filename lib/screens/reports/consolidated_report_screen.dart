import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../services/consolidated_report_service.dart';
import '../../providers/user_provider.dart';

/// Tela para geração de relatório consolidado da safra
/// Integra dados de todos os módulos: plantio, monitoramento, aplicações, colheita
class ConsolidatedReportScreen extends StatefulWidget {
  static const String routeName = '/reports/consolidated';
  
  const ConsolidatedReportScreen({Key? key}) : super(key: key);

  @override
  _ConsolidatedReportScreenState createState() => _ConsolidatedReportScreenState();
}

class _ConsolidatedReportScreenState extends State<ConsolidatedReportScreen> {
  final ConsolidatedReportService _reportService = ConsolidatedReportService();
  
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedFarm;
  String? _selectedSeason;
  
  List<String> _farms = [];
  List<String> _seasons = [];
  
  // Filtros de módulos
  bool _includePlanting = true;
  bool _includeMonitoring = true;
  bool _includeApplications = true;
  bool _includeHarvest = true;
  bool _includeInventory = true;
  bool _includeCosts = true;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    setState(() => _isLoading = true);
    
    try {
      final farms = await _reportService.getAvailableFarms();
      final seasons = await _reportService.getAvailableSeasons();
      
      setState(() {
        _farms = farms;
        _seasons = seasons;
        _selectedFarm = farms.isNotEmpty ? farms.first : null;
        _selectedSeason = seasons.isNotEmpty ? seasons.first : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar opções: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Consolidado da Safra'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDateRangeSelector(),
                  const SizedBox(height: 24),
                  _buildFarmAndSeasonSelector(),
                  const SizedBox(height: 24),
                  _buildModuleFilters(),
                  const SizedBox(height: 32),
                  _buildGenerateButton(),
                  const SizedBox(height: 24),
                  _buildPreviewSection(),
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
                  'Relatório Consolidado da Safra',
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
              'Visão completa de todas as operações da safra, incluindo plantio, monitoramento, aplicações, colheita e custos.',
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

  Widget _buildDateRangeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período do Relatório',
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

  Widget _buildFarmAndSeasonSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fazenda e Safra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Fazenda',
                    _selectedFarm,
                    _farms,
                    (value) => setState(() => _selectedFarm = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Safra',
                    _selectedSeason,
                    _seasons,
                    (value) => setState(() => _selectedSeason = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildModuleFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Módulos a Incluir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildModuleCheckbox('Plantio', _includePlanting, (value) => setState(() => _includePlanting = value ?? false)),
            _buildModuleCheckbox('Monitoramento', _includeMonitoring, (value) => setState(() => _includeMonitoring = value ?? false)),
            _buildModuleCheckbox('Aplicações', _includeApplications, (value) => setState(() => _includeApplications = value ?? false)),
            _buildModuleCheckbox('Colheita', _includeHarvest, (value) => setState(() => _includeHarvest = value ?? false)),
            _buildModuleCheckbox('Estoque', _includeInventory, (value) => setState(() => _includeInventory = value ?? false)),
            _buildModuleCheckbox('Custos', _includeCosts, (value) => setState(() => _includeCosts = value ?? false)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCheckbox(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _canGenerateReport() ? _generateReport : null,
        icon: const Icon(Icons.picture_as_pdf, size: 24),
        label: const Text(
          'Gerar Relatório Consolidado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  bool _canGenerateReport() {
    return _startDate != null && 
           _endDate != null && 
           _selectedFarm != null && 
           _selectedSeason != null &&
           (_includePlanting || _includeMonitoring || _includeApplications || _includeHarvest || _includeInventory || _includeCosts);
  }

  Future<void> _generateReport() async {
    if (!_canGenerateReport()) return;

    setState(() => _isLoading = true);

    try {
      final config = ConsolidatedReportConfig(
        startDate: _startDate!,
        endDate: _endDate!,
        farm: _selectedFarm!,
        season: _selectedSeason!,
        includePlanting: _includePlanting,
        includeMonitoring: _includeMonitoring,
        includeApplications: _includeApplications,
        includeHarvest: _includeHarvest,
        includeInventory: _includeInventory,
        includeCosts: _includeCosts,
      );

      final reportPath = await _reportService.generateConsolidatedReport(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relatório gerado com sucesso: $reportPath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar relatório: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPreviewSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prévia do Relatório',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'O relatório consolidado incluirá:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            if (_includePlanting) _buildPreviewItem('✓ Dados de plantio e calibrações'),
            if (_includeMonitoring) _buildPreviewItem('✓ Atividades de monitoramento'),
            if (_includeApplications) _buildPreviewItem('✓ Aplicações de defensivos e fertilizantes'),
            if (_includeHarvest) _buildPreviewItem('✓ Dados de colheita e perdas'),
            if (_includeInventory) _buildPreviewItem('✓ Movimentação de estoque'),
            if (_includeCosts) _buildPreviewItem('✓ Análise de custos e rentabilidade'),
            const SizedBox(height: 12),
            const Text(
              'Formato: PDF profissional com gráficos e análises detalhadas',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

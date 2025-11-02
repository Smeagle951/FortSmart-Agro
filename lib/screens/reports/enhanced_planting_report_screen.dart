import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../../models/farm.dart';
import '../../models/plot.dart';
import '../../models/planting.dart';
import '../../services/report_service.dart';
import '../../repositories/farm_repository.dart';
import '../../repositories/plot_repository.dart';
import '../../repositories/planting_repository.dart';
import '../../utils/app_theme.dart';

/// Tela aprimorada de relatório de plantio com filtros avançados
class EnhancedPlantingReportScreen extends StatefulWidget {
  static const String routeName = '/reports/planting/enhanced';

  const EnhancedPlantingReportScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedPlantingReportScreen> createState() => _EnhancedPlantingReportScreenState();
}

class _EnhancedPlantingReportScreenState extends State<EnhancedPlantingReportScreen> {
  final FarmRepository _farmRepository = FarmRepository();
  final PlotRepository _plotRepository = PlotRepository();
  final PlantingRepository _plantingRepository = PlantingRepository();
  final ReportService _reportService = ReportService();
  
  // Filtros básicos
  Farm? _selectedFarm;
  Plot? _selectedPlot;
  Planting? _selectedPlanting;
  
  // Filtros avançados
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSeason;
  String? _selectedCrop;
  String? _selectedVariety;
  double? _minArea;
  double? _maxArea;
  String? _selectedStatus;
  
  // Dados
  List<Farm> _farms = [];
  List<Plot> _plots = [];
  List<Planting> _plantings = [];
  List<String> _seasons = [];
  List<String> _crops = [];
  List<String> _varieties = [];
  List<String> _statuses = ['Planejado', 'Em andamento', 'Concluído', 'Cancelado'];
  
  bool _isLoading = true;
  bool _isGeneratingReport = false;
  bool _showPreview = false;
  bool _showAdvancedFilters = false;
  Uint8List? _pdfBytes;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final farms = await _farmRepository.getAllFarms();
      final plots = await _plotRepository.getAllPlots();
      final plantings = await _plantingRepository.getAllPlantings();
      
      // Extrair opções únicas
      final seasons = plantings.map((p) => p.season).toSet().toList()..sort();
      final crops = plantings.map((p) => p.crop).toSet().toList()..sort();
      final varieties = plantings.map((p) => p.variety).toSet().toList()..sort();
      
      setState(() {
        _farms = farms;
        _plots = plots;
        _plantings = plantings;
        _seasons = seasons;
        _crops = crops;
        _varieties = varieties;
        
        // Valores padrão
        if (farms.isNotEmpty) _selectedFarm = farms.first;
        if (seasons.isNotEmpty) _selectedSeason = seasons.first;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Plantio - Avançado'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
            tooltip: 'Filtros Avançados',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildBasicFilters(),
                  if (_showAdvancedFilters) ...[
                    const SizedBox(height: 16),
                    _buildAdvancedFilters(),
                  ],
                  const SizedBox(height: 24),
                  _buildReportOptions(),
                  const SizedBox(height: 24),
                  _buildGenerateButton(),
                  if (_showPreview) ...[
                    const SizedBox(height: 24),
                    _buildPreviewSection(),
                  ],
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
                Icon(Icons.grass, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Relatório de Plantio Avançado',
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
              'Gere relatórios detalhados de plantio com filtros avançados e análises personalizadas.',
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

  Widget _buildBasicFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros Básicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Fazenda',
                    _selectedFarm?.name,
                    _farms.map((f) => f.name).toList(),
                    (value) => setState(() {
                      _selectedFarm = _farms.firstWhere((f) => f.name == value);
                      _selectedPlot = null;
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Talhão',
                    _selectedPlot?.name,
                    _plots.where((p) => p.farmId == _selectedFarm?.id).map((p) => p.name).toList(),
                    (value) => setState(() {
                      _selectedPlot = _plots.firstWhere((p) => p.name == value);
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Safra',
                    _selectedSeason,
                    _seasons,
                    (value) => setState(() => _selectedSeason = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Status',
                    _selectedStatus,
                    _statuses,
                    (value) => setState(() => _selectedStatus = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros Avançados',
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
                  child: _buildDropdown(
                    'Cultura',
                    _selectedCrop,
                    _crops,
                    (value) => setState(() => _selectedCrop = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Variedade',
                    _selectedVariety,
                    _varieties,
                    (value) => setState(() => _selectedVariety = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    'Área Mínima (ha)',
                    _minArea,
                    (value) => setState(() => _minArea = value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    'Área Máxima (ha)',
                    _maxArea,
                    (value) => setState(() => _maxArea = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOptions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opções do Relatório',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'O relatório incluirá:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildOptionItem('✓ Resumo executivo com métricas principais'),
            _buildOptionItem('✓ Detalhes de cada plantio filtrado'),
            _buildOptionItem('✓ Gráficos de área plantada por período'),
            _buildOptionItem('✓ Análise de produtividade por talhão'),
            _buildOptionItem('✓ Comparativo entre safras'),
            _buildOptionItem('✓ Recomendações técnicas'),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _canGenerateReport() ? _generateReport : null,
        icon: const Icon(Icons.picture_as_pdf, size: 24),
        label: Text(
          _isGeneratingReport ? 'Gerando...' : 'Gerar Relatório Avançado',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            if (_pdfBytes != null) ...[
              Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Visualização do PDF será implementada'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Implementar compartilhamento
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Compartilhamento será implementado')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Compartilhar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Implementar impressão
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Impressão será implementada')),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text('Nenhum relatório gerado ainda.'),
            ],
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

  Widget _buildNumberField(String label, double? value, Function(double?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixText: 'ha',
          ),
          keyboardType: TextInputType.number,
          onChanged: (text) {
            final parsed = double.tryParse(text);
            onChanged(parsed);
          },
        ),
      ],
    );
  }

  Widget _buildOptionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  bool _canGenerateReport() {
    return _selectedFarm != null && !_isGeneratingReport;
  }

  Future<void> _generateReport() async {
    if (!_canGenerateReport()) return;

    setState(() => _isGeneratingReport = true);

    try {
      // Filtrar plantios baseado nos critérios selecionados
      var filteredPlantings = _plantings.where((p) {
        if (_selectedFarm != null && p.farmId != _selectedFarm!.id) return false;
        if (_selectedPlot != null && p.plotId != _selectedPlot!.id) return false;
        if (_selectedSeason != null && p.season != _selectedSeason) return false;
        if (_selectedCrop != null && p.crop != _selectedCrop) return false;
        if (_selectedVariety != null && p.variety != _selectedVariety) return false;
        if (_startDate != null && p.date.isBefore(_startDate!)) return false;
        if (_endDate != null && p.date.isAfter(_endDate!)) return false;
        if (_minArea != null && p.area < _minArea!) return false;
        if (_maxArea != null && p.area > _maxArea!) return false;
        return true;
      }).toList();

      if (filteredPlantings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum plantio encontrado com os filtros selecionados')),
        );
        return;
      }

      // Gerar relatório
      final reportBytes = await _reportService.generatePlantingReport(
        filteredPlantings,
        _selectedFarm!,
        _selectedPlot,
      );

      setState(() {
        _pdfBytes = reportBytes;
        _showPreview = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relatório gerado com sucesso! ${filteredPlantings.length} plantios incluídos.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar relatório: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGeneratingReport = false);
    }
  }
}

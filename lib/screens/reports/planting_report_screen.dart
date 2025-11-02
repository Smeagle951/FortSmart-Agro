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

class PlantingReportScreen extends StatefulWidget {
  static const String routeName = '/reports/planting';

  const PlantingReportScreen({Key? key}) : super(key: key);

  @override
  State<PlantingReportScreen> createState() => _PlantingReportScreenState();
}

class _PlantingReportScreenState extends State<PlantingReportScreen> {
  final FarmRepository _farmRepository = FarmRepository();
  final PlotRepository _plotRepository = PlotRepository();
  final PlantingRepository _plantingRepository = PlantingRepository();
  final ReportService _reportService = ReportService();
  
  Farm? _selectedFarm;
  Plot? _selectedPlot;
  Planting? _selectedPlanting;
  
  List<Farm> _farms = [];
  List<Plot> _plots = [];
  List<Planting> _plantings = [];
  
  bool _isLoading = true;
  bool _isGeneratingReport = false;
  bool _showPreview = false;
  Uint8List? _pdfBytes;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar fazendas
      final farms = await _farmRepository.getAllFarms();
      setState(() {
        _farms = farms;
        if (farms.isNotEmpty) {
          _selectedFarm = farms.first;
          _loadPlots(farms.first.id);
        }
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar fazendas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  Future<void> _loadPlots(String farmId) async {
    setState(() {
      _isLoading = true;
      _plots = [];
      _selectedPlot = null;
      _plantings = [];
      _selectedPlanting = null;
    });
    
    try {
      final plots = await _plotRepository.getPlotsByFarmId(farmId);
      setState(() {
        _plots = plots;
        if (plots.isNotEmpty) {
          _selectedPlot = plots.first;
          _loadPlantings(plots.first.id!);
        }
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar talhões: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadPlantings(String plotId) async {
    setState(() {
      _isLoading = true;
      _plantings = [];
      _selectedPlanting = null;
    });
    
    try {
      final plantings = await _plantingRepository.getPlantingsByPlotId(plotId);
      setState(() {
        _plantings = plantings;
        if (plantings.isNotEmpty) {
          _selectedPlanting = plantings.first;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar plantios: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _generateReport() async {
    if (_selectedFarm == null || _selectedPlot == null || _selectedPlanting == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a fazenda, talhão e plantio para gerar o relatório')),
      );
      return;
    }
    
    setState(() {
      _isGeneratingReport = true;
    });
    
    try {
      // Simulação de geração de relatório - será implementada quando o ReportService estiver pronto
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _pdfBytes = Uint8List(0); // Placeholder - será substituído pelo PDF real
        _showPreview = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
    }
  }
  
  Future<void> _shareReport() async {
    if (_pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere o relatório primeiro antes de compartilhar')),
      );
      return;
    }
    
    try {
      final date = DateFormat('yyyyMMdd').format(DateTime.now());
      await _reportService.shareReport(
        _pdfBytes!,
        'Plantio_${_selectedPlot!.name}_$date.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao compartilhar relatório: $e')),
      );
    }
  }
  
  Future<void> _saveReport() async {
    if (_pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere o relatório primeiro antes de salvar')),
      );
      return;
    }
    
    try {
      final date = DateFormat('yyyyMMdd').format(DateTime.now());
      final filePath = await _reportService.saveReport(
        _pdfBytes!,
        'Plantio_${_selectedPlot!.name}_$date.pdf',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Relatório salvo em: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar relatório: $e')),
      );
    }
  }
  
  Future<void> _printReport() async {
    if (_pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere o relatório primeiro antes de imprimir')),
      );
      return;
    }
    
    try {
      await _reportService.printReport(_pdfBytes!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao imprimir relatório: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Plantio'),
        // backgroundColor: AppTheme.primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showPreview
              ? _buildReportPreview()
              : _buildSelectionForm(),
    );
  }
  
  Widget _buildSelectionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gerar Relatório de Plantio',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Informações do padrão de relatório
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Padrão FORTSMART Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoItem('Cabeçalho', 'Logo, nome da fazenda, responsável e técnico'),
                _buildInfoItem('Corpo', 'Data, cultivar, população, velocidade e calibragem'),
                _buildInfoItem('Rodapé', 'Assinatura do técnico e data de geração'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Seleção de Fazenda
          const Text(
            'Selecione a Fazenda:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFarmDropdown(),
          
          const SizedBox(height: 16),
          
          // Seleção de Talhão
          const Text(
            'Selecione o Talhão:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildPlotDropdown(),
          
          const SizedBox(height: 16),
          
          // Seleção de Plantio
          const Text(
            'Selecione o Plantio:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildPlantingDropdown(),
          
          const SizedBox(height: 24),
          
          // Mostrar detalhes do plantio selecionado
          if (_selectedPlanting != null) _buildPlantingDetails(),
          
          const SizedBox(height: 24),
          
          // Botão de gerar relatório
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingReport ? null : _generateReport,
              icon: _isGeneratingReport
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGeneratingReport ? 'Gerando...' : 'Gerar Relatório PDF'),
              style: ElevatedButton.styleFrom(
                // backgroundColor: AppTheme.primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.accentColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFarmDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Farm>(
          value: _selectedFarm,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 16,
          hint: const Text('Selecione uma fazenda'),
          onChanged: (Farm? newValue) {
            if (newValue != null && newValue != _selectedFarm) {
              setState(() {
                _selectedFarm = newValue;
                _loadPlots(newValue.id);
              });
            }
          },
          items: _farms.map<DropdownMenuItem<Farm>>((Farm farm) {
            return DropdownMenuItem<Farm>(
              value: farm,
              child: Text(farm.name),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildPlotDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Plot>(
          value: _selectedPlot,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 16,
          hint: const Text('Selecione um talhão'),
          onChanged: _plots.isEmpty
              ? null
              : (Plot? newValue) {
                  if (newValue != null && newValue != _selectedPlot) {
                    setState(() {
                      _selectedPlot = newValue;
                      _loadPlantings(newValue.id!);
                    });
                  }
                },
          items: _plots.map<DropdownMenuItem<Plot>>((Plot plot) {
            return DropdownMenuItem<Plot>(
              value: plot,
              child: Text('${plot.name} - ${plot.cropName}'),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildPlantingDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Planting>(
          value: _selectedPlanting,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 16,
          hint: const Text('Selecione um plantio'),
          onChanged: _plantings.isEmpty
              ? null
              : (Planting? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPlanting = newValue;
                    });
                  }
                },
          items: _plantings.map<DropdownMenuItem<Planting>>((Planting planting) {
            return DropdownMenuItem<Planting>(
              value: planting,
              child: Text(
                '${DateFormat('dd/MM/yyyy').format(planting.plantingDate)} - ${planting.cropName}',
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildPlantingDetails() {
    if (_selectedPlanting == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalhes do Plantio:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // Data e cultivar
          _buildDetailItem(
            'Data:',
            DateFormat('dd/MM/yyyy').format(_selectedPlanting!.plantingDate),
            Icons.calendar_today,
          ),
          _buildDetailItem(
            'Cultivar:',
            '${_selectedPlanting!.cropName} (${_selectedPlanting!.varietyName})',
            Icons.grass,
          ),
          _buildDetailItem(
            'População:',
            '${_selectedPlanting!.seedRate?.toStringAsFixed(0) ?? "0"} plantas/ha',
            Icons.groups,
          ),
          _buildDetailItem(
            'Velocidade:',
            '${_selectedPlanting!.operationSpeed.toStringAsFixed(1)} km/h',
            Icons.speed,
          ),
          
          const Divider(height: 24),
          
          // Informações da calibragem e máquina
          Row(
            children: [
              Expanded(
                child: _buildCountItem(
                  'Espaçamento',
                  '${_selectedPlanting!.rowSpacing?.toStringAsFixed(0) ?? "0"} cm',
                  Icons.space_bar,
                  Colors.brown[100]!,
                  Colors.brown,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCountItem(
                  'Profundidade',
                  '${_selectedPlanting!.seedDepth?.toStringAsFixed(1) ?? "0.0"} cm',
                  Icons.vertical_align_bottom,
                  Colors.blue[100]!,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCountItem(
                  'Máquina',
                  _selectedPlanting!.equipmentName,
                  Icons.agriculture,
                  Colors.green[100]!,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Observações
          if (_selectedPlanting!.notes != null && _selectedPlanting!.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Observações:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPlanting!.notes!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCountItem(
    String label,
    String count,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportPreview() {
    return Column(
      children: [
        Container(
          color: AppTheme.primaryColorLight,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Relatório PDF gerado com sucesso!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showPreview = false;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O que deseja fazer com o relatório?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Ações do relatório
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Compartilhar',
                  description: 'Enviar por e-mail, WhatsApp, etc.',
                  onPressed: _shareReport,
                  color: Colors.blue,
                ),
                
                const SizedBox(height: 16),
                
                _buildActionButton(
                  icon: Icons.save_alt,
                  label: 'Salvar',
                  description: 'Salvar no armazenamento do dispositivo',
                  onPressed: _saveReport,
                  color: Colors.green,
                ),
                
                const SizedBox(height: 16),
                
                _buildActionButton(
                  icon: Icons.print,
                  label: 'Imprimir',
                  description: 'Enviar para impressora',
                  onPressed: _printReport,
                  color: Colors.purple,
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Prévia do Relatório:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Prévia do relatório (mock)
                Container(
                  width: double.infinity,
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: Colors.brown,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Plantio_${_selectedPlot?.name ?? ""}.pdf',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gerado em ${DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now())}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Esse relatório segue o padrão visual FORTSMART Premium',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward),
          ],
        ),
        style: ElevatedButton.styleFrom(
          // backgroundColor: color, // backgroundColor não é suportado em flutter_map 5.0.0
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          // alignment: Alignment.centerLeft, // alignment não é suportado em Marker no flutter_map 5.0.0
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

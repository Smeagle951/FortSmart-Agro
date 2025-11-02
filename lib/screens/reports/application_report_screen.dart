import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../../models/farm.dart';
import '../../models/plot.dart';
import '../../models/pesticide_application.dart';
import '../../services/report_service.dart';
import '../../repositories/farm_repository.dart';
import '../../repositories/plot_repository.dart';
import '../../repositories/pesticide_application_repository.dart';
import '../../utils/app_theme.dart';

class ApplicationReportScreen extends StatefulWidget {
  static const String routeName = '/reports/application';

  const ApplicationReportScreen({Key? key}) : super(key: key);

  @override
  State<ApplicationReportScreen> createState() => _ApplicationReportScreenState();
}

class _ApplicationReportScreenState extends State<ApplicationReportScreen> {
  final FarmRepository _farmRepository = FarmRepository();
  final PlotRepository _plotRepository = PlotRepository();
  final PesticideApplicationRepository _applicationRepository = PesticideApplicationRepository();
  final ReportService _reportService = ReportService();
  
  Farm? _selectedFarm;
  Plot? _selectedPlot;
  PesticideApplication? _selectedApplication;
  
  List<Farm> _farms = [];
  List<Plot> _plots = [];
  List<PesticideApplication> _applications = [];
  
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
      _applications = [];
      _selectedApplication = null;
    });
    
    try {
      final plots = await _plotRepository.getPlotsByFarmId(farmId);
      setState(() {
        _plots = plots;
        if (plots.isNotEmpty) {
          _selectedPlot = plots.first;
          _loadApplications(plots.first.id!);
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
  
  Future<void> _loadApplications(String plotId) async {
    setState(() {
      _isLoading = true;
      _applications = [];
      _selectedApplication = null;
    });
    
    try {
      final applications = await _applicationRepository.getApplicationsByPlotId(plotId);
      setState(() {
        _applications = applications;
        if (applications.isNotEmpty) {
          _selectedApplication = applications.first;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar aplicações: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _generateReport() async {
    if (_selectedFarm == null || _selectedPlot == null || _selectedApplication == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a fazenda, talhão e aplicação para gerar o relatório')),
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
        'Aplicacao_${_selectedPlot!.name}_$date.pdf',
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
        'Aplicacao_${_selectedPlot!.name}_$date.pdf',
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
        title: const Text('Relatório de Aplicação'),
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
            'Gerar Relatório de Aplicação',
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
                _buildInfoItem('Corpo', 'Produto, dose, volume, condições climáticas, etc.'),
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
          
          // Seleção de Aplicação
          const Text(
            'Selecione a Aplicação:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildApplicationDropdown(),
          
          const SizedBox(height: 24),
          
          // Mostrar detalhes da aplicação selecionada
          if (_selectedApplication != null) _buildApplicationDetails(),
          
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
                      _loadApplications(newValue.id!);
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
  
  Widget _buildApplicationDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PesticideApplication>(
          value: _selectedApplication,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 16,
          hint: const Text('Selecione uma aplicação'),
          onChanged: _applications.isEmpty
              ? null
              : (PesticideApplication? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedApplication = newValue;
                    });
                  }
                },
          items: _applications.map<DropdownMenuItem<PesticideApplication>>(
            (PesticideApplication application) {
              return DropdownMenuItem<PesticideApplication>(
                value: application,
                child: Text(
                  '${DateFormat('dd/MM/yyyy').format(application.applicationDate)} - ${application.productList?.isNotEmpty == true ? application.productList!.first.name : "Sem produtos"}',
                ),
              );
            }
          ).toList(),
        ),
      ),
    );
  }
  
  Widget _buildApplicationDetails() {
    if (_selectedApplication == null) {
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
            'Detalhes da Aplicação:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // Data e responsável
          _buildDetailItem(
            'Data:',
            DateFormat('dd/MM/yyyy').format(_selectedApplication!.applicationDate),
            Icons.calendar_today,
          ),
          _buildDetailItem(
            'Responsável:',
            _selectedApplication!.responsiblePerson ?? 'Não especificado',
            Icons.person,
          ),
          _buildDetailItem(
            'Tipo:',
            _selectedApplication!.applicationType != null ? _selectedApplication!.applicationType.toString() : 'Não especificado',
            Icons.local_shipping,
          ),
          _buildDetailItem(
            'Condições:',
            '${_selectedApplication!.weather ?? "Normal"}, ${_selectedApplication!.temperature?.toString() ?? "N/A"}°C, ${_selectedApplication!.humidity?.toString() ?? "N/A"}% umidade',
            Icons.thermostat,
          ),
          
          const Divider(height: 24),
          
          // Lista de produtos aplicados
          const Text(
            'Produtos aplicados:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedApplication!.productList?.length ?? 0,
            itemBuilder: (context, index) {
              final product = _selectedApplication!.productList?[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Dose:',
                              '${_selectedApplication!.applicationRate?.toString() ?? "N/A"} L/ha',
                              Icons.opacity,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              'Alvo:',
                              product?.target ?? "",
                              Icons.bug_report,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Informações da máquina e volume
          Row(
            children: [
              Expanded(
                child: _buildCountItem(
                  'Volume',
                  '${_selectedApplication!.applicationRate?.toString() ?? "N/A"} L/ha',
                  Icons.water_drop,
                  Colors.blue[100]!,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCountItem(
                  'Velocidade',
                  '${_selectedApplication!.operationSpeed?.toString() ?? "N/A"} km/h',
                  Icons.speed,
                  Colors.orange[100]!,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCountItem(
                  'Máquina',
                  _selectedApplication!.equipmentName ?? 'Não especificado',
                  Icons.agriculture,
                  Colors.green[100]!,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Observações
          if (_selectedApplication!.notes != null && _selectedApplication!.notes!.isNotEmpty)
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
                    _selectedApplication!.notes!,
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
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aplicacao_${_selectedPlot?.name ?? ""}.pdf',
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

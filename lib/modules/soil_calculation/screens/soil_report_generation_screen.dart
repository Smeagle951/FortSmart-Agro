import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

import '../models/soil_compaction_point_model.dart';
import '../repositories/soil_compaction_point_repository.dart';
import '../services/soil_report_generator_service.dart';
import '../constants/app_colors.dart';

/// Tela de geração de relatórios premium
class SoilReportGenerationScreen extends StatefulWidget {
  final int talhaoId;
  final String nomeTalhao;
  final String nomeFazenda;
  final List<LatLng> polygonCoordinates;

  const SoilReportGenerationScreen({
    Key? key,
    required this.talhaoId,
    required this.nomeTalhao,
    required this.nomeFazenda,
    required this.polygonCoordinates,
  }) : super(key: key);

  @override
  State<SoilReportGenerationScreen> createState() => _SoilReportGenerationScreenState();
}

class _SoilReportGenerationScreenState extends State<SoilReportGenerationScreen> {
  final _nomeResponsavelController = TextEditingController();
  final _operadorController = TextEditingController();
  final _safraController = TextEditingController();
  
  List<SoilCompactionPointModel> _pontos = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _logoFazendaPath;
  LatLng? _centroTalhao;

  @override
  void initState() {
    super.initState();
    _safraController.text = DateTime.now().year.toString();
    _carregarDados();
    _calcularCentroTalhao();
  }

  @override
  void dispose() {
    _nomeResponsavelController.dispose();
    _operadorController.dispose();
    _safraController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final repository = Provider.of<SoilCompactionPointRepository>(
        context,
        listen: false,
      );

      final pontos = await repository.getByTalhao(widget.talhaoId);
      setState(() => _pontos = pontos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calcularCentroTalhao() {
    if (widget.polygonCoordinates.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      
      for (var coord in widget.polygonCoordinates) {
        sumLat += coord.latitude;
        sumLng += coord.longitude;
      }
      
      _centroTalhao = LatLng(
        sumLat / widget.polygonCoordinates.length,
        sumLng / widget.polygonCoordinates.length,
      );
    }
  }

  Future<void> _selecionarLogoFazenda() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _logoFazendaPath = result.files.single.path;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo selecionado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar logo: $e')),
      );
    }
  }

  Future<void> _gerarRelatorio() async {
    if (_pontos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum ponto de coleta encontrado')),
      );
      return;
    }

    if (_nomeResponsavelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do responsável')),
      );
      return;
    }

    if (_operadorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do operador')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final safraId = int.tryParse(_safraController.text) ?? DateTime.now().year;
      final dataColeta = _pontos.isNotEmpty 
          ? _pontos.first.dataColeta 
          : DateTime.now();

      final areaHectares = _calcularAreaHectares();

      final filePath = await SoilReportGeneratorService.gerarRelatorioPremium(
        talhaoId: widget.talhaoId,
        nomeTalhao: widget.nomeTalhao,
        nomeFazenda: widget.nomeFazenda,
        nomeResponsavel: _nomeResponsavelController.text,
        areaHectares: areaHectares,
        centroTalhao: _centroTalhao ?? LatLng(0, 0),
        safraId: safraId,
        dataColeta: dataColeta,
        operador: _operadorController.text,
        pontos: _pontos,
        polygonCoordinates: widget.polygonCoordinates,
        logoFazendaPath: _logoFazendaPath,
      );

      setState(() => _isGenerating = false);

      if (mounted) {
        _mostrarDialogoSucesso(filePath);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar relatório: $e')),
        );
      }
    }
  }

  double _calcularAreaHectares() {
    // Cálculo simplificado da área do polígono
    if (widget.polygonCoordinates.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < widget.polygonCoordinates.length; i++) {
      final j = (i + 1) % widget.polygonCoordinates.length;
      area += widget.polygonCoordinates[i].latitude * widget.polygonCoordinates[j].longitude;
      area -= widget.polygonCoordinates[j].latitude * widget.polygonCoordinates[i].longitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converte de graus quadrados para hectares (aproximação)
    const double grausParaHectares = 111320 * 111320 / 10000; // Aproximação
    return area * grausParaHectares;
  }

  void _mostrarDialogoSucesso(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 30),
            SizedBox(width: 12),
            Text('Relatório Gerado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O relatório premium foi gerado com sucesso!'),
            const SizedBox(height: 12),
            Text(
              'Arquivo: ${filePath.split('/').last}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Local: $filePath',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _abrirArquivo(filePath);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir Relatório'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirArquivo(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir arquivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Gerar Relatório - ${widget.nomeTalhao}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildFormularioCard(),
                  const SizedBox(height: 16),
                  _buildPreviewCard(),
                  const SizedBox(height: 16),
                  _buildBotoesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.blue.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Relatório Premium FortSmart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '📊 Relatório completo com mapas, gráficos e análises\n'
              '📈 Análises estatísticas e tendências temporais\n'
              '🗺️ Mapa de compactação com heatmap\n'
              '📋 Tabela detalhada de todos os pontos\n'
              '💡 Recomendações agronômicas personalizadas\n'
              '📅 Plano de ação com cronograma',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informações do Relatório',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _nomeResponsavelController,
              decoration: const InputDecoration(
                labelText: 'Nome do Responsável *',
                hintText: 'Ex: João Silva',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _operadorController,
              decoration: const InputDecoration(
                labelText: 'Operador no Campo *',
                hintText: 'Ex: Maria Santos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.engineering),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _safraController,
              decoration: const InputDecoration(
                labelText: 'Safra',
                hintText: 'Ex: 2025',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Logo da fazenda
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logo da Fazenda (Opcional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _logoFazendaPath != null 
                              ? _logoFazendaPath!.split('/').last
                              : 'Nenhum arquivo selecionado',
                          style: TextStyle(
                            color: _logoFazendaPath != null ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _selecionarLogoFazenda,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Selecionar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.preview,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Preview do Relatório',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Estatísticas rápidas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPreview('Pontos', _pontos.length.toString(), Icons.location_on),
                _buildStatPreview('Área', '${_calcularAreaHectares().toStringAsFixed(1)} ha', Icons.area_chart),
                _buildStatPreview('Safra', _safraController.text, Icons.calendar_today),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lista de seções do relatório
            const Text(
              'Seções incluídas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            const Text('• Capa e Sumário'),
            const Text('• Resumo Executivo'),
            const Text('• Informações da Propriedade'),
            const Text('• Metodologia de Coleta'),
            const Text('• Mapa de Compactação'),
            const Text('• Tabela de Pontos'),
            const Text('• Análises Estatísticas'),
            const Text('• Recomendações Agronômicas'),
            const Text('• Plano de Ação'),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _gerarRelatorio,
                icon: _isGenerating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGenerating ? 'Gerando Relatório...' : 'Gerar Relatório Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            if (_pontos.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhum ponto de coleta encontrado. Gere pontos antes de criar o relatório.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatPreview(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/planting.dart';
import '../../services/planting_service.dart';
import '../../services/pdf_report_service.dart';
import '../../models/planting_quality_report_model.dart';
import '../../services/module_integration_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/safe_text.dart';
import '../../utils/snackbar_helper.dart';

class PlantingListScreen extends StatefulWidget {
  const PlantingListScreen({Key? key}) : super(key: key);

  @override
  State<PlantingListScreen> createState() => _PlantingListScreenState();
}

class _PlantingListScreenState extends State<PlantingListScreen> {
  final PlantingService _service = PlantingService();
  final PDFReportService _reportService = PDFReportService();
  final ModuleIntegrationService _integrationService = ModuleIntegrationService();
  List<Planting> _plantings = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeModule();
  }
  
  Future<void> _initializeModule() async {
    try {
      // Inicializar o serviço de integração para garantir que os dados estão sincronizados
      await _integrationService.initialize();
      // Carregar os plantios
      await _loadPlantings();
    } catch (e) {
      print('Erro ao inicializar módulo de plantio: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Erro ao inicializar módulo de plantio: $e');
      }
    }
  }

  Future<void> _loadPlantings() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final plantings = await _service.getAllPlantings();
      setState(() {
        _plantings = plantings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      if (mounted) {
        SnackbarHelper.showError(context, 'Erro ao carregar plantios: $e');
      }
    }
  }

  Future<void> _deletePlanting(Planting planting) async {
    try {
      await _service.deletePlanting(planting.id!);
      SnackbarHelper.showSuccess(context, 'Plantio excluído com sucesso!');
      _loadPlantings();
    } catch (e) {
      SnackbarHelper.showError(context, 'Erro ao excluir plantio: $e');
    }
  }

  Future<void> _generateReport() async {
    if (_plantings.isEmpty) {
      SnackbarHelper.showWarning(context, 'Não há plantios para gerar relatório');
      return;
    }

    try {
      // Converter plantings para relatórios de qualidade (exemplo)
      final relatorios = _plantings.map((planting) => PlantingQualityReportModel(
        talhaoId: planting.plotId,
        talhaoNome: 'Talhão ${planting.plotId}',
        culturaId: planting.cropId ?? '',
        culturaNome: planting.cropName,
        variedade: planting.varietyName ?? '',
        safra: planting.season,
        areaHectares: planting.area ?? 0.0,
        dataPlantio: planting.plantingDate,
        dataAvaliacao: DateTime.now(),
        executor: 'Sistema',
        coeficienteVariacao: 15.0, // Valor exemplo
        classificacaoCV: 'Bom',
        plantasPorMetro: 5.0,
        populacaoEstimadaPorHectare: 50000.0,
        singulacao: 2.0,
        plantasDuplas: 1.0,
        plantasFalhadas: 3.0,
        populacaoAlvo: 50000.0,
        populacaoReal: 48500.0,
        eficaciaEmergencia: 97.0,
        desvioPopulacao: 1500.0,
        analiseAutomatica: 'Análise automática baseada nos dados do plantio.',
        sugestoes: 'Sugestões baseadas na análise do plantio.',
        statusGeral: 'Boa qualidade',
        createdAt: DateTime.now(),
        appVersion: '1.0.0',
        deviceInfo: 'Sistema',
      )).toList();
      
      final filePath = await _reportService.gerarRelatorioComparativo(relatorios);
      SnackbarHelper.showSuccess(
        context, 
        'Relatório gerado com sucesso!\nSalvo em: $filePath',
      );
    } catch (e) {
      SnackbarHelper.showError(context, 'Erro ao gerar relatório: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SafeText('Plantios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlantings,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generateReport,
            tooltip: 'Gerar Relatório',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _plantings.isEmpty
                  ? const EmptyState(
                      icon: Icons.grass,
                      title: 'Nenhum plantio registrado',
                      message: 'Toque no botão + para adicionar um novo plantio',
                    )
                  : _buildPlantingsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implementar navegação para adicionar novo plantio
          SnackbarHelper.showInfo(context, 'Funcionalidade em desenvolvimento');
        },
        child: const Icon(Icons.add),
        tooltip: 'Novo Plantio',
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          const SafeText(
            'Ocorreu um erro ao carregar os dados',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SafeText(
            _errorMessage,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPlantings,
            child: const SafeText('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantingsList() {
    return ListView.builder(
      itemCount: _plantings.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final planting = _plantings[index];
        return _buildPlantingItem(planting);
      },
    );
  }

  Widget _buildPlantingItem(Planting planting) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final plantingDate = dateFormat.format(planting.plantingDate);
    final harvestDate = planting.expectedHarvestDate != null 
        ? dateFormat.format(planting.expectedHarvestDate!) 
        : 'Não definida';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grass, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: SafeText(
                    planting.cropType ?? 'Não informado',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SafeText(
                        'Data de Plantio:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SafeText(
                        plantingDate,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SafeText(
                        'Colheita Prevista:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SafeText(
                        harvestDate,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (planting.variety != null && planting.variety!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.category, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SafeText(
                        'Variedade: ${planting.variety}',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Botões removidos para produção
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Planting planting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const SafeText('Confirmar exclusão'),
        content: const SafeText(
          'Tem certeza que deseja excluir este plantio? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const SafeText('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlanting(planting);
            },
            child: const SafeText(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

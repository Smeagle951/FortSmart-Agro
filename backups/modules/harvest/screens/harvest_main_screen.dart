import 'package:flutter/material.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/empty_state.dart';
import '../../../utils/colors.dart';
import '../../crop_monitoring/models/crop_monitoring_model.dart';
import '../../crop_monitoring/services/crop_monitoring_service.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../repositories/agricultural_product_repository.dart';
import 'package:intl/intl.dart';

class HarvestMainScreen extends StatefulWidget {
  const HarvestMainScreen({Key? key}) : super(key: key);

  @override
  _HarvestMainScreenState createState() => _HarvestMainScreenState();
}

class _HarvestMainScreenState extends State<HarvestMainScreen> {
  final CropMonitoringService _cropMonitoringService = CropMonitoringService();
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final AgriculturalProductRepository _productRepository = AgriculturalProductRepository();
  
  bool _isLoading = true;
  List<CropMonitoringModel> _cropMonitoringRecords = [];
  Map<String, String> _plotNames = {};
  Map<String, String> _cropNames = {};
  Map<String, String> _varietyNames = {};
  
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

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
      // Sincroniza dados do módulo de plantio
      await _cropMonitoringService.syncFromPlantingModule();
      
      // Carrega os registros de acompanhamento
      final records = await _cropMonitoringService.getAllCropMonitoring();
      
      // Carrega os nomes dos talhões
      final talhoes = await _talhaoRepository.getTalhoes();
      final Map<String, String> plotNames = {
        for (var talhao in talhoes) talhao.id.toString(): talhao.nome
      };
      
      // Carrega os nomes das culturas e variedades
      final products = await _productRepository.getAll();
      final cropNames = {
        for (var product in products.where((p) => p.type == 'crop')) 
          product.id: product.name
      };
      final varietyNames = {
        for (var product in products.where((p) => p.type == 'variety')) 
          product.id: product.name
      };
      
      setState(() {
        _cropMonitoringRecords = records;
        _plotNames = plotNames;
        _cropNames = cropNames;
        _varietyNames = varietyNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  void _startHarvest(CropMonitoringModel record) {
    // Aqui você navegaria para a tela de colheita com os dados do registro
    // Navigator.pushNamed(context, '/harvest/start', arguments: record);
    
    // Por enquanto, apenas mostra uma mensagem
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando colheita para o talhão ${_plotNames[record.plotId] ?? record.plotId}'),
        // backgroundColor: record.isReadyForHarvest ? Colors.green : Colors.orange, // backgroundColor não é suportado em flutter_map 5.0.0
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Módulo de Colheita',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implementar filtros aqui
            },
            tooltip: 'Filtrar',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _cropMonitoringRecords.isEmpty
              ? EmptyState(
                  icon: Icons.agriculture,
                  message: 'Nenhum plantio encontrado para colheita',
                  buttonText: 'Cadastrar Plantio',
                  onButtonPressed: () {
                    // Navegar para a tela de cadastro de plantio
                    Navigator.pushNamed(context, '/planting/new');
                  },
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _cropMonitoringRecords.length,
                    itemBuilder: (context, index) {
                      final record = _cropMonitoringRecords[index];
                      return _buildHarvestCard(record);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
        tooltip: 'Atualizar',
      ),
    );
  }

  Widget _buildHarvestCard(CropMonitoringModel record) {
    // Define cores baseadas no estágio fenológico e DAC
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (record.isReadyForHarvest) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Pronto para colheita';
    } else if (record.daysUntilHarvest <= 15) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Próximo da colheita';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
      statusText = 'Em desenvolvimento';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _plotNames[record.plotId] ?? 'Talhão ${record.plotId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                      Text('Cultura: ${_cropNames[record.cropId] ?? record.cropId}'),
                      Text('Variedade: ${_varietyNames[record.varietyId] ?? record.varietyId}'),
                      Text('Data Plantio: ${_dateFormat.format(record.plantingDate)}'),
                      if (record.area != null)
                        Text('Área: ${record.area!.toStringAsFixed(2)} ha'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAE: ${record.daysAfterEmergence}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'DAC: ${record.daysUntilHarvest}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: record.daysUntilHarvest <= 0 ? Colors.red : null,
                        ),
                      ),
                      Text(
                        'Estágio: ${record.phenologicalStage}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startHarvest(record),
                icon: const Icon(Icons.agriculture),
                label: const Text('Iniciar Colheita'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: record.isReadyForHarvest ? Colors.green : AppColors.primary, // backgroundColor não é suportado em flutter_map 5.0.0
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

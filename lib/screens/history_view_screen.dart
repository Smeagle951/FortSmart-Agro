import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../repositories/plot_repository.dart';
import '../repositories/crop_repository.dart';
import '../repositories/seed_calculation_repository.dart';
import '../repositories/planter_calibration_new_repository.dart';
// Imports do modelo removidos e substituídos por lista dinâmica
import '../models/seed_calculation.dart';
import '../models/planter_calibration_new.dart';
import '../utils/logger.dart';
import '../routes.dart';

class HistoryViewScreen extends StatefulWidget {
  const HistoryViewScreen({Key? key}) : super(key: key);

  @override
  _HistoryViewScreenState createState() => _HistoryViewScreenState();
}

class _HistoryViewScreenState extends State<HistoryViewScreen> with SingleTickerProviderStateMixin {
  // Controlador de abas
  TabController? _tabController;
  
  // Repositórios
  final PlotRepository _plotRepository = PlotRepository();
  final CropRepository _cropRepository = CropRepository();
  final SeedCalculationRepository _seedCalcRepository = SeedCalculationRepository();
  final PlanterCalibrationNewRepository _calibrationRepository = PlanterCalibrationNewRepository();
  
  // Dados
  List<dynamic> _plots = [];
  List<dynamic> _crops = [];
  List<SeedCalculation> _seedCalculations = [];
  List<PlanterCalibrationNew> _calibrations = [];
  
  // Filtros
  int? _selectedPlotId;
  int? _selectedCropId;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Estado
  bool _isLoading = true;
  bool _isFilterActive = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Carregar talhões e culturas para filtros
      _plots = await _plotRepository.getAll();
      _crops = await _cropRepository.getAll();
      
      // Carregar dados iniciais sem filtros
      await _loadActivities();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      Logger.error('Erro ao carregar dados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }
  
  Future<void> _loadActivities() async {
    try {
      // Filtros para a busca
      final talhaoId = _selectedPlotId;
      final culturaId = _selectedCropId;
      String? dataInicio;
      String? dataFim;
      
      if (_startDate != null) {
        dataInicio = _startDate!.toIso8601String();
      }
      
      if (_endDate != null) {
        // Ajustar para o final do dia
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, 
                             _endDate!.day, 23, 59, 59);
        dataFim = endOfDay.toIso8601String();
      }
      
      // Carregar cálculos de sementes com filtros
      _seedCalculations = await _seedCalcRepository.getAll();
      
      // Filtrar manualmente
      if (talhaoId != null || culturaId != null || dataInicio != null || dataFim != null) {
        _seedCalculations = _seedCalculations.where((calc) {
          bool match = true;
          if (talhaoId != null) match = match && calc.talhaoId == talhaoId;
          if (culturaId != null) match = match && calc.culturaId == culturaId;
          // Adicionar filtro de data se necessário
          return match;
        }).toList();
      }
      
      // Carregar calibragens de plantadeira com filtros
      _calibrations = await _calibrationRepository.getAll();
      
      // Filtrar manualmente
      if (talhaoId != null || culturaId != null || dataInicio != null || dataFim != null) {
        _calibrations = _calibrations.where((calib) {
          bool match = true;
          if (talhaoId != null) match = match && calib.talhaoId == talhaoId;
          if (culturaId != null) match = match && calib.culturaId == culturaId;
          // Adicionar filtro de data se necessário
          return match;
        }).toList();
      }
      
      setState(() {});
    } catch (e) {
      Logger.error('Erro ao carregar atividades: $e');
    }
  }
  
  Future<void> _showFilterDialog() async {
    // Valores temporários para o diálogo
    int? tempPlotId = _selectedPlotId;
    int? tempCropId = _selectedCropId;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filtrar Histórico'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Talhão
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Talhão'),
                    value: tempPlotId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos os talhões'),
                      ),
                      ..._plots.map((plot) => DropdownMenuItem<int?>(
                        value: plot.id,
                        child: Text(plot.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempPlotId = value;
                      });
                    },
                  ),
                  
                  // Cultura
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Cultura'),
                    value: tempCropId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas as culturas'),
                      ),
                      ..._crops.map((crop) => DropdownMenuItem<int?>(
                        value: crop.id,
                        child: Text(crop.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempCropId = value;
                      });
                    },
                  ),
                  
                  // Data início
                  ListTile(
                    title: const Text('Data Inicial'),
                    subtitle: tempStartDate != null
                        ? Text(DateFormat('dd/MM/yyyy').format(tempStartDate!))
                        : const Text('Selecionar data inicial'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: tempStartDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setDialogState(() {
                          tempStartDate = date;
                        });
                      }
                    },
                  ),
                  
                  // Data fim
                  ListTile(
                    title: const Text('Data Final'),
                    subtitle: tempEndDate != null
                        ? Text(DateFormat('dd/MM/yyyy').format(tempEndDate!))
                        : const Text('Selecionar data final'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: tempEndDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setDialogState(() {
                          tempEndDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  // Limpar todos os filtros
                  setDialogState(() {
                    tempPlotId = null;
                    tempCropId = null;
                    tempStartDate = null;
                    tempEndDate = null;
                  });
                },
                child: const Text('Limpar Filtros'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
    
    if (result == true) {
      setState(() {
        _selectedPlotId = tempPlotId;
        _selectedCropId = tempCropId;
        _startDate = tempStartDate;
        _endDate = tempEndDate;
        _isFilterActive = tempPlotId != null || 
                          tempCropId != null || 
                          tempStartDate != null || 
                          tempEndDate != null;
      });
      
      await _loadActivities();
    }
  }
  
  String _getPlotName(int id) {
    final plot = _plots.firstWhere((p) => p.id == id, orElse: () => null);
    return plot != null ? plot.name : 'Talhão $id';
  }
  
  String _getCropName(int id) {
    final crop = _crops.firstWhere((c) => c.id == id, orElse: () => null);
    return crop != null ? crop.name : 'Cultura $id';
  }
  
  DateTime? _parseDateTime(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Atividades'),
        actions: [
          Stack(
            // alignment: Alignment.center, // alignment não é suportado em Marker no flutter_map 5.0.0
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              if (_isFilterActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cálculos de Sementes'),
            Tab(text: 'Calibragens de Plantadeira'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSeedCalculationList(),
                _buildCalibrationList(),
              ],
            ),
    );
  }
  
  Widget _buildSeedCalculationList() {
    if (_seedCalculations.isEmpty) {
      return const Center(
        child: Text('Nenhum cálculo de sementes encontrado'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _seedCalculations.length,
      itemBuilder: (context, index) {
        final calculation = _seedCalculations[index];
        final dataCalculo = _parseDateTime(calculation.dataCalculo);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.seedsPerHectare,
                arguments: calculation,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Cálculo #${calculation.id ?? ""}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        dataCalculo != null 
                            ? DateFormat('dd/MM/yyyy').format(dataCalculo) 
                            : 'Data não disponível',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (calculation.talhaoId > 0)
                    Text('Talhão: ${_getPlotName(calculation.talhaoId)}'),
                  if (calculation.culturaId > 0)
                    Text('Cultura: ${_getCropName(calculation.culturaId)}'),
                  const SizedBox(height: 8),
                  Text(
                    'População: ${NumberFormat('#,###').format(calculation.populacao.round())} pl/ha',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Sementes/metro: ${calculation.resultadoSementeMetro.toStringAsFixed(1)}',
                  ),
                  Text(
                    'Kg/ha: ${calculation.resultadoKgHectare.toStringAsFixed(1)}',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCalibrationList() {
    if (_calibrations.isEmpty) {
      return const Center(
        child: Text('Nenhuma calibragem de plantadeira encontrada'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _calibrations.length,
      itemBuilder: (context, index) {
        final calibration = _calibrations[index];
        final dataRegulagem = _parseDateTime(calibration.dataRegulagem);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.planterCalibrationNew,
                arguments: calibration,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          calibration.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        dataRegulagem != null 
                            ? DateFormat('dd/MM/yyyy').format(dataRegulagem) 
                            : 'Data não disponível',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        calibration.tipo == 'semente' ? Icons.grass : Icons.science,
                        size: 16,
                        color: calibration.tipo == 'semente' ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        calibration.tipo == 'semente' ? 'Sementes' : 'Adubo',
                        style: TextStyle(
                          color: calibration.tipo == 'semente' ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (calibration.talhaoId != null)
                    Text('Talhão: ${_getPlotName(calibration.talhaoId!)}'),
                  Text('Cultura: ${_getCropName(calibration.culturaId)}'),
                  const SizedBox(height: 8),
                  Text(
                    'População: ${NumberFormat('#,###').format(calibration.populacao.round())} pl/ha',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (calibration.tipo == 'semente')
                    Text(
                      'Sementes/metro: ${calibration.seedsPerMeter.toStringAsFixed(1)}',
                    ),
                  if (calibration.resultadoKgHa != null)
                    Text(
                      'Kg/ha: ${calibration.resultadoKgHa!.toStringAsFixed(1)}',
                    ),
                  if (calibration.tipo == 'adubo' && calibration.resultadoKgMetro != null)
                    Text(
                      'Kg/metro: ${calibration.resultadoKgMetro!.toStringAsFixed(3)}',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

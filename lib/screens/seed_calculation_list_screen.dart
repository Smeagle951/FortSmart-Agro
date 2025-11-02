import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/seed_calculation.dart';
import '../repositories/seed_calculation_repository.dart';
import '../repositories/crop_repository.dart';
import '../repositories/plot_repository.dart';
import '../repositories/variety_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/custom_dialog.dart';
import '../utils/logger.dart';
import 'seed_calculation_screen.dart';

class SeedCalculationListScreen extends StatefulWidget {
  const SeedCalculationListScreen({Key? key}) : super(key: key);

  @override
  _SeedCalculationListScreenState createState() => _SeedCalculationListScreenState();
}

class _SeedCalculationListScreenState extends State<SeedCalculationListScreen> {
  final _repository = SeedCalculationRepository();
  final _cropRepository = CropRepository();
  final _plotRepository = PlotRepository();
  final _varietyRepository = VarietyRepository();
  
  List<SeedCalculation> _calculations = [];
  bool _isLoading = true;
  
  // Filtros
  int? _filterTalhaoId;
  int? _filterCulturaId;
  int? _filterVariedadeId;
  String? _filterTipoCalculo;
  DateTime? _filterDataInicio;
  DateTime? _filterDataFim;
  
  // Mapeamento de IDs para nomes
  Map<int, String> _cropNames = {};
  Map<int, String> _plotNames = {};
  Map<int, String> _varietyNames = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Carregar todos os cálculos
      final calculations = await _repository.getAll();
      
      // Carregar nomes de culturas, talhões e variedades
      await _loadReferenceData();
      
      setState(() {
        _calculations = calculations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Logger.error('Erro ao carregar cálculos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }
  
  Future<void> _loadReferenceData() async {
    try {
      // Carregar culturas
      final crops = await _cropRepository.getAll();
      final plotsData = await _plotRepository.getAll();
      
      // Mapear IDs para nomes
      _cropNames = {for (var crop in crops) crop.id : crop.name};
      _plotNames = {for (var plot in plotsData) int.parse(plot.id!) : plot.name};
      
      // Carregar variedades somente se tivermos culturas
      if (crops.isNotEmpty) {
        final varieties = await _varietyRepository.getAll();
        _varietyNames = {for (var variety in varieties) variety.id! : variety.name};
      }
    } catch (e) {
      Logger.error('Erro ao carregar dados de referência: $e');
    }
  }
  
  Future<void> _applyFilters() async {
    try {
      setState(() => _isLoading = true);
      
      String? dataInicio;
      String? dataFim;
      
      if (_filterDataInicio != null) {
        dataInicio = _filterDataInicio!.toIso8601String();
      }
      
      if (_filterDataFim != null) {
        // Ajustar para o final do dia
        final endOfDay = DateTime(_filterDataFim!.year, _filterDataFim!.month, 
                               _filterDataFim!.day, 23, 59, 59);
        dataFim = endOfDay.toIso8601String();
      }
      
      final filteredCalculations = await _repository.search(
        talhaoId: _filterTalhaoId,
        culturaId: _filterCulturaId,
        variedadeId: _filterVariedadeId,
        tipoCalculo: _filterTipoCalculo,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      
      setState(() {
        _calculations = filteredCalculations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Logger.error('Erro ao aplicar filtros: $e');
    }
  }
  
  Future<void> _showFilterDialog() async {
    // Valores temporários para o diálogo
    int? tempTalhaoId = _filterTalhaoId;
    int? tempCulturaId = _filterCulturaId;
    int? tempVariedadeId = _filterVariedadeId;
    String? tempTipoCalculo = _filterTipoCalculo;
    DateTime? tempDataInicio = _filterDataInicio;
    DateTime? tempDataFim = _filterDataFim;
    
    // Obter listas para os dropdowns
    final plots = await _plotRepository.getAll();
    final crops = await _cropRepository.getAll();
    List<dynamic> varieties = [];
    
    if (tempCulturaId != null) {
      varieties = await _varietyRepository.getByCulturaId(tempCulturaId);
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filtrar Cálculos de Sementes'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Talhão
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Talhão'),
                    value: tempTalhaoId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos os talhões'),
                      ),
                      ...plots.map((plot) => DropdownMenuItem<int?>(
                        value: int.tryParse(plot.id ?? ''),
                        child: Text(plot.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempTalhaoId = value;
                      });
                    },
                  ),
                  
                  // Cultura
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Cultura'),
                    value: tempCulturaId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas as culturas'),
                      ),
                      ...crops.map((crop) => DropdownMenuItem<int?>(
                        value: crop.id,
                        child: Text(crop.name),
                      )),
                    ],
                    onChanged: (value) async {
                      setDialogState(() {
                        tempCulturaId = value;
                        tempVariedadeId = null; // Resetar variedade quando cultura mudar
                      });
                      
                      if (value != null) {
                        // Carregar variedades da cultura selecionada
                        final newVarieties = await _varietyRepository.getByCulturaId(value);
                        setDialogState(() {
                          varieties = newVarieties;
                        });
                      } else {
                        setDialogState(() {
                          varieties = [];
                        });
                      }
                    },
                  ),
                  
                  // Variedade (somente se uma cultura estiver selecionada)
                  if (tempCulturaId != null && varieties.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(labelText: 'Variedade'),
                      value: tempVariedadeId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas as variedades'),
                        ),
                        ...varieties.map((variety) => DropdownMenuItem<int?>(
                          value: variety.id,
                          child: Text(variety.name),
                        )),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempVariedadeId = value;
                        });
                      },
                    ),
                  
                  // Tipo de cálculo
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(labelText: 'Tipo de Cálculo'),
                    value: tempTipoCalculo,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos os tipos'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'populacao',
                        child: Text('Por População'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'peso',
                        child: Text('Por Peso'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempTipoCalculo = value;
                      });
                    },
                  ),
                  
                  // Data início
                  ListTile(
                    title: const Text('Data Inicial'),
                    subtitle: tempDataInicio != null
                        ? Text(DateFormat('dd/MM/yyyy').format(tempDataInicio!))
                        : const Text('Selecionar data inicial'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context, // onTap não é suportado em Polygon no flutter_map 5.0.0
                        initialDate: tempDataInicio ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setDialogState(() {
                          tempDataInicio = date;
                        });
                      }
                    },
                  ),
                  
                  // Data fim
                  ListTile(
                    title: const Text('Data Final'),
                    subtitle: tempDataFim != null
                        ? Text(DateFormat('dd/MM/yyyy').format(tempDataFim!))
                        : const Text('Selecionar data final'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context, // onTap não é suportado em Polygon no flutter_map 5.0.0
                        initialDate: tempDataFim ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setDialogState(() {
                          tempDataFim = date;
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
                    tempTalhaoId = null;
                    tempCulturaId = null;
                    tempVariedadeId = null;
                    tempTipoCalculo = null;
                    tempDataInicio = null;
                    tempDataFim = null;
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
        _filterTalhaoId = tempTalhaoId;
        _filterCulturaId = tempCulturaId;
        _filterVariedadeId = tempVariedadeId;
        _filterTipoCalculo = tempTipoCalculo;
        _filterDataInicio = tempDataInicio;
        _filterDataFim = tempDataFim;
      });
      
      await _applyFilters();
    }
  }
  
  Future<void> _confirmDelete(SeedCalculation calculation) async {
    final result = await CustomDialog.show(
      context: context,
      title: 'Confirmar exclusão',
      message: 'Deseja realmente excluir este cálculo? Esta ação não pode ser desfeita.',
      primaryButtonText: 'Excluir',
      secondaryButtonText: 'Cancelar',
      isDestructiveAction: true,
    );
    
    if (result == true) {
      try {
        await _repository.delete(calculation.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cálculo excluído com sucesso')),
        );
        _loadData();
      } catch (e) {
        Logger.error('Erro ao excluir cálculo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir cálculo: $e')),
        );
      }
    }
  }
  
  Future<void> _navigateToCalculationScreen({SeedCalculation? calculation}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeedCalculationScreen(seedCalculation: calculation),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }
  
  String _getCropName(int id) {
    return _cropNames[id] ?? 'Cultura $id';
  }
  
  String _getPlotName(int id) {
    return _plotNames[id] ?? 'Talhão $id';
  }
  
  String _getVarietyName(int id) {
    return _varietyNames[id] ?? 'Variedade $id';
  }
  
  String _formatTipoCalculo(String tipo) {
    return tipo == 'populacao' ? 'Por População' : 'Por Peso';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculos de Sementes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calculations.isEmpty
              ? EmptyState(
                  icon: Icons.calculate,
                  title: 'Nenhum cálculo encontrado',
                  message: 'Adicione um novo cálculo de sementes',
                  actionText: 'Adicionar Cálculo',
                  onAction: () => _navigateToCalculationScreen(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _calculations.length,
                  itemBuilder: (context, index) {
                    final calculation = _calculations[index];
                    
                    // Tentar converter a data do cálculo
                    DateTime? dataCalculo;
                    try {
                      dataCalculo = DateTime.parse(calculation.dataCalculo);
                    } catch (e) {
                      dataCalculo = null;
                    }
                    
                    // Determinar se existem fotos
                    final hasFotos = calculation.fotos != null && calculation.fotos!.isNotEmpty;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    calculation.nome,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _navigateToCalculationScreen(calculation: calculation);
                                    } else if (value == 'delete') {
                                      _confirmDelete(calculation);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Text('Editar'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Excluir'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Data e Tipo
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 4),
                                Text(dataCalculo != null
                                    ? DateFormat('dd/MM/yyyy').format(dataCalculo)
                                    : 'Data não disponível'),
                                const SizedBox(width: 16),
                                const Icon(Icons.category, size: 16),
                                const SizedBox(width: 4),
                                Text(_formatTipoCalculo(calculation.tipoCalculo)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Talhão e Cultura
                            if (calculation.talhaoId > 0) ...[
                              Text('Talhão: ${_getPlotName(calculation.talhaoId)}'),
                              const SizedBox(height: 4),
                            ],
                            Text('Cultura: ${_getCropName(calculation.culturaId)}'),
                            if (calculation.variedadeId > 0) ...[
                              const SizedBox(height: 4),
                              Text('Variedade: ${_getVarietyName(calculation.variedadeId)}'),
                            ],
                            const SizedBox(height: 8),
                            
                            // Detalhes técnicos
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'População: ${NumberFormat('#,###').format(calculation.populacao.round())} pl/ha',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            
                            // Resultados calculados
                            Text('Sementes/metro: ${calculation.resultadoSementesMetro.toStringAsFixed(1)}'),
                            Text('Kg/ha: ${calculation.resultadoKgHa.toStringAsFixed(1)}'),
                            
                            // Prévia de fotos se houver
                            if (hasFotos) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.photo_library, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${calculation.fotos!.split(',').length} foto(s)'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: calculation.fotos!.split(',').take(3).map((photoPath) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(photoPath),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                            
                            // Observações (se houver)
                            if (calculation.observacoes != null &&
                                calculation.observacoes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Observações:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(calculation.observacoes!),
                            ],
                            
                            // Botão para visualizar detalhes completos
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () => _navigateToCalculationScreen(calculation: calculation),
                                child: const Text('Ver detalhes completos'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCalculationScreen(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

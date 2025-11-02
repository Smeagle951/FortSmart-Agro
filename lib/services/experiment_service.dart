import 'dart:convert';
import '../models/experiment.dart';
import '../database/app_database.dart';

/// Serviço para gerenciamento de experimentos
class ExperimentService {
  static ExperimentService? _instance;
  static ExperimentService get instance => _instance ??= ExperimentService._();
  
  ExperimentService._();
  
  bool _initialized = false;
  AppDatabase? _database;

  /// Inicializa o serviço
  Future<void> initialize() async {
    if (_initialized) return;
    
    _database = AppDatabase();
    await _database!.initialize();
    _initialized = true;
  }

  /// Cria um novo experimento
  Future<Experiment> createExperiment(Experiment experiment) async {
    if (!_initialized) await initialize();
    
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final experimentWithId = experiment.copyWith(id: id);
      
      await _database!.insertExperiment(experimentWithId.toMap());
      return experimentWithId;
    } catch (e) {
      throw Exception('Erro ao criar experimento: $e');
    }
  }

  /// Atualiza um experimento existente
  Future<void> updateExperiment(Experiment experiment) async {
    if (!_initialized) await initialize();
    
    try {
      await _database!.updateExperiment(experiment.id!, experiment.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar experimento: $e');
    }
  }

  /// Exclui um experimento
  Future<void> deleteExperiment(String id) async {
    if (!_initialized) await initialize();
    
    try {
      await _database!.deleteExperiment(id);
    } catch (e) {
      throw Exception('Erro ao excluir experimento: $e');
    }
  }

  /// Busca experimento por ID
  Future<Experiment?> getExperimentById(String id) async {
    if (!_initialized) await initialize();
    
    try {
      final result = await _database!.getExperimentById(id);
      return result != null ? Experiment.fromMap(result) : null;
    } catch (e) {
      throw Exception('Erro ao buscar experimento: $e');
    }
  }

  /// Busca todos os experimentos
  Future<List<Experiment>> getAllExperiments() async {
    if (!_initialized) await initialize();
    
    try {
      final results = await _database!.getAllExperiments();
      return results.map((map) => Experiment.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar experimentos: $e');
    }
  }

  /// Busca experimentos por ID do talhão
  Future<List<Experiment>> getExperimentsByPlotId(String plotId) async {
    if (!_initialized) await initialize();
    
    try {
      final results = await _database!.getExperimentsByPlotId(plotId);
      return results.map((map) => Experiment.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar experimentos por talhão: $e');
    }
  }

  /// Busca experimentos por status
  Future<List<Experiment>> getExperimentsByStatus(String status) async {
    if (!_initialized) await initialize();
    
    try {
      final results = await _database!.getExperimentsByStatus(status);
      return results.map((map) => Experiment.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar experimentos por status: $e');
    }
  }

  /// Busca experimentos por cultura
  Future<List<Experiment>> getExperimentsByCropType(String cropType) async {
    if (!_initialized) await initialize();
    
    try {
      final results = await _database!.getExperimentsByCropType(cropType);
      return results.map((map) => Experiment.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar experimentos por cultura: $e');
    }
  }

  /// Busca experimentos por período
  Future<List<Experiment>> getExperimentsByDateRange(DateTime startDate, DateTime endDate) async {
    if (!_initialized) await initialize();
    
    try {
      final results = await _database!.getExperimentsByDateRange(startDate, endDate);
      return results.map((map) => Experiment.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar experimentos por período: $e');
    }
  }

  /// Busca experimentos com filtros
  Future<List<Experiment>> searchExperiments({
    String? plotId,
    String? status,
    String? cropType,
    DateTime? startDate,
    DateTime? endDate,
    String? searchText,
  }) async {
    if (!_initialized) await initialize();
    
    try {
      final results = await _database!.searchExperiments(
        plotId: plotId,
        status: status,
        cropType: cropType,
        startDate: startDate,
        endDate: endDate,
        searchText: searchText,
      );
      return results.map((map) => Experiment.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar experimentos: $e');
    }
  }

  /// Obtém estatísticas dos experimentos
  Future<Map<String, dynamic>> getExperimentStats() async {
    if (!_initialized) await initialize();
    
    try {
      final allExperiments = await getAllExperiments();
      
      final stats = <String, dynamic>{
        'total': allExperiments.length,
        'active': allExperiments.where((e) => e.status == 'active').length,
        'completed': allExperiments.where((e) => e.status == 'completed').length,
        'canceled': allExperiments.where((e) => e.status == 'canceled').length,
        'cropTypes': allExperiments.map((e) => e.cropType).toSet().length,
        'plots': allExperiments.map((e) => e.plotId).toSet().length,
      };
      
      return stats;
    } catch (e) {
      throw Exception('Erro ao obter estatísticas: $e');
    }
  }

  /// Obtém estatísticas por talhão
  Future<Map<String, dynamic>> getTalhaoExperimentStats(String plotId) async {
    if (!_initialized) await initialize();
    
    try {
      final experiments = await getExperimentsByPlotId(plotId);
      
      final stats = <String, dynamic>{
        'total': experiments.length,
        'active': experiments.where((e) => e.status == 'active').length,
        'completed': experiments.where((e) => e.status == 'completed').length,
        'canceled': experiments.where((e) => e.status == 'canceled').length,
        'cropTypes': experiments.map((e) => e.cropType).toSet().length,
        'averageDae': experiments.isNotEmpty 
            ? experiments.map((e) => e.dae).reduce((a, b) => a + b) / experiments.length
            : 0,
      };
      
      return stats;
    } catch (e) {
      throw Exception('Erro ao obter estatísticas do talhão: $e');
    }
  }

  /// Exporta experimentos para JSON
  Future<String> exportExperimentsToJson() async {
    if (!_initialized) await initialize();
    
    try {
      final experiments = await getAllExperiments();
      final jsonData = experiments.map((e) => e.toMap()).toList();
      return jsonEncode(jsonData);
    } catch (e) {
      throw Exception('Erro ao exportar experimentos: $e');
    }
  }

  /// Importa experimentos de JSON
  Future<List<Experiment>> importExperimentsFromJson(String jsonData) async {
    if (!_initialized) await initialize();
    
    try {
      final List<dynamic> data = jsonDecode(jsonData);
      final experiments = data.map((map) => Experiment.fromMap(map)).toList();
      
      for (final experiment in experiments) {
        await createExperiment(experiment);
      }
      
      return experiments;
    } catch (e) {
      throw Exception('Erro ao importar experimentos: $e');
    }
  }
}

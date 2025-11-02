import 'package:intl/intl.dart';
import '../database/daos/soil_analysis_dao.dart';
import '../database/models/soil_analysis.dart';

class SoilAnalysisRepository {
  final SoilAnalysisDao _dao = SoilAnalysisDao();

  // Adicionar uma nova análise de solo
  Future<int> addSoilAnalysis({
    required int monitoringId,
    String? plotId, // ID do talhão associado à análise
    double? ph,
    double? organicMatter,
    double? phosphorus,
    double? potassium,
    double? calcium,
    double? magnesium,
    double? sulfur,
    double? aluminum,
    double? cationExchangeCapacity,
    double? baseSaturation,
  }) async {
    final now = DateTime.now();
    final timestamp = now.toIso8601String();

    final analysis = SoilAnalysis(
      monitoringId: monitoringId,
      plotId: plotId, // Adicionar o ID do talhão
      ph: ph,
      organicMatter: organicMatter,
      phosphorus: phosphorus,
      potassium: potassium,
      calcium: calcium,
      magnesium: magnesium,
      sulfur: sulfur,
      aluminum: aluminum,
      cationExchangeCapacity: cationExchangeCapacity,
      baseSaturation: baseSaturation,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    return await _dao.insert(analysis);
  }

  // Atualizar uma análise de solo existente
  Future<int> updateSoilAnalysis({
    required int id,
    String? plotId,
    double? ph,
    double? organicMatter,
    double? phosphorus,
    double? potassium,
    double? calcium,
    double? magnesium,
    double? sulfur,
    double? aluminum,
    double? cationExchangeCapacity,
    double? baseSaturation,
  }) async {
    final analysis = await _dao.getById(id);
    
    if (analysis == null) {
      throw Exception('Análise de solo não encontrada');
    }

    final updatedAnalysis = analysis.copyWith(
      plotId: plotId,
      ph: ph,
      organicMatter: organicMatter,
      phosphorus: phosphorus,
      potassium: potassium,
      calcium: calcium,
      magnesium: magnesium,
      sulfur: sulfur,
      aluminum: aluminum,
      cationExchangeCapacity: cationExchangeCapacity,
      baseSaturation: baseSaturation,
      updatedAt: DateTime.now().toIso8601String(),
      syncStatus: 0, // Marca para sincronização
    );

    return await _dao.update(updatedAnalysis);
  }

  // Excluir uma análise de solo
  Future<bool> deleteSoilAnalysis(int id) async {
    final result = await _dao.delete(id);
    return result > 0;
  }

  // Obter uma análise de solo pelo ID
  Future<SoilAnalysis?> getSoilAnalysisById(int? id) async {
    if (id == null) return null;
    return await _dao.getById(id);
  }

  // Obter todas as análises de solo para um monitoramento
  Future<List<SoilAnalysis>> getAnalysesByMonitoringId(int monitoringId) async {
    return await _dao.getByMonitoringId(monitoringId);
  }

  // Obter todas as análises de solo
  Future<List<SoilAnalysis>> getAllSoilAnalyses() async {
    return await _dao.getAll();
  }

  // Obter análises de solo por período
  Future<List<SoilAnalysis>> getAnalysesByDateRange(DateTime startDate, DateTime endDate) async {
    final start = DateFormat('yyyy-MM-dd').format(startDate);
    final end = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
    
    return await _dao.getByDateRange(start, end);
  }

  // Atualizar status de sincronização
  Future<bool> updateSyncStatus(int id, int syncStatus, {int? remoteId}) async {
    final result = await _dao.updateSyncStatus(id, syncStatus, remoteId: remoteId);
    return result > 0;
  }

  // Obter análises não sincronizadas
  Future<List<SoilAnalysis>> getUnsyncedAnalyses() async {
    return await _dao.getPendingSync();
  }

  // Calcular a média de pH para um conjunto de análises
  double calculateAveragePh(List<SoilAnalysis> analyses) {
    if (analyses.isEmpty) return 0;
    
    double sum = 0;
    int count = 0;
    
    for (var analysis in analyses) {
      if (analysis.ph != null) {
        sum += analysis.ph!;
        count++;
      }
    }
    
    return count > 0 ? sum / count : 0;
  }

  // Interpretar o valor de pH do solo
  String interpretPhValue(double? ph) {
    if (ph == null) return 'Não disponível';
    
    if (ph < 5.0) return 'Muito ácido';
    if (ph < 5.5) return 'Ácido';
    if (ph < 6.5) return 'Levemente ácido';
    if (ph < 7.5) return 'Neutro';
    if (ph < 8.0) return 'Levemente alcalino';
    return 'Alcalino';
  }

  // Interpretar o valor de matéria orgânica
  String interpretOrganicMatter(double? om) {
    if (om == null) return 'Não disponível';
    
    if (om < 1.5) return 'Muito baixo';
    if (om < 3.0) return 'Baixo';
    if (om < 5.0) return 'Médio';
    if (om < 8.0) return 'Alto';
    return 'Muito alto';
  }
}

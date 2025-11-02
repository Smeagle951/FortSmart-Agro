import '../models/ai_diagnosis_result.dart';
import '../models/ai_organism_data.dart';
import '../repositories/ai_organism_repository.dart';
import '../../../utils/logger.dart';
import 'ai_diagnosis_service_integrated.dart';

/// Serviço principal de diagnóstico de IA
/// 
/// ✅ ATUALIZADO: Agora usa JSONs ricos + Feedback offline
/// 🔄 ADAPTADOR: Mantém compatibilidade com código existente
/// 🎓 APRENDIZADO: Confiança ajustada por feedback dos usuários
class AIDiagnosisService {
  // Usar versão integrada internamente
  final AIDiagnosisServiceIntegrated _integrated = AIDiagnosisServiceIntegrated();
  final AIOrganismRepository _organismRepository = AIOrganismRepository();

  /// Diagnóstico por sintomas COM APRENDIZADO
  /// NOVO: Confiança ajustada baseada em feedback histórico (offline)
  Future<List<AIDiagnosisResult>> diagnoseBySymptoms({
    required List<String> symptoms,
    required String cropName,
    double confidenceThreshold = 0.3,
  }) async {
    try {
      Logger.info('🔍 [AIDiagnosisService] Diagnóstico por sintomas (versão integrada)');
      
      // Delegar para versão integrada
      return await _integrated.diagnoseBySymptoms(
        symptoms: symptoms,
        cropName: cropName,
        confidenceThreshold: confidenceThreshold,
        farmId: 'default_farm', // TODO: Obter do Provider
      );
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico por sintomas: $e');
      return [];
    }
  }

  /// Diagnóstico por imagem (preparado para ML futuro)
  Future<List<AIDiagnosisResult>> diagnoseByImage({
    required String imagePath,
    required String cropName,
    double confidenceThreshold = 0.5,
  }) async {
    try {
      Logger.info('🖼️ [AIDiagnosisService] Diagnóstico por imagem');
      
      // Delegar para versão integrada
      return await _integrated.diagnoseByImage(
        imagePath: imagePath,
        cropName: cropName,
        confidenceThreshold: confidenceThreshold,
        farmId: 'default_farm', // TODO: Obter do Provider
      );

    } catch (e) {
      Logger.error('❌ Erro no diagnóstico por imagem: $e');
      return [];
    }
  }

  /// Busca organismos por nome ou sintoma
  Future<List<AIOrganismData>> searchOrganisms(String query) async {
    try {
      Logger.info('🔍 Buscando organismos: $query');
      
      // Delegar para versão integrada
      return await _integrated.searchOrganisms(query);

    } catch (e) {
      Logger.error('❌ Erro na busca de organismos: $e');
      return [];
    }
  }

  /// Obtém estatísticas de diagnóstico
  /// NOVO: Inclui dados de aprendizado
  Future<Map<String, dynamic>> getDiagnosisStats() async {
    try {
      // Delegar para versão integrada
      return await _integrated.getDiagnosisStats();

    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }
}

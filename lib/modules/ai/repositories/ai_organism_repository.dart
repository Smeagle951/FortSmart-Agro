import '../models/ai_organism_data.dart';
import '../../../utils/logger.dart';
import 'ai_organism_repository_integrated.dart';

/// Repositório para dados de organismos da IA
/// 
/// ✅ ATUALIZADO: Agora usa JSONs ricos + Feedback offline
/// 🔄 ADAPTADOR: Mantém compatibilidade com código existente
/// 📂 FONTE: assets/data/organismos_*.json (13 culturas, 3.000+ organismos)
/// 🎓 APRENDIZADO: Enriquecido com feedback dos usuários (offline)
class AIOrganismRepository {
  // Usar versão integrada internamente
  final AIOrganismRepositoryIntegrated _integrated = AIOrganismRepositoryIntegrated();

  /// Inicializa o repositório com dados DOS JSONs
  /// NOVO: Carrega de JSONs + enriquece com feedback
  Future<void> initialize() async {
    try {
      Logger.info('🔍 [AIOrganismRepository] Iniciando (versão integrada)...');
      await _integrated.initialize();
      Logger.info('✅ [AIOrganismRepository] Inicializado com sucesso');
    } catch (e) {
      Logger.error('❌ [AIOrganismRepository] Erro ao inicializar: $e');
    }
  }

  /// Obtém todos os organismos (dos JSONs enriquecidos)
  Future<List<AIOrganismData>> getAllOrganisms() async {
    return await _integrated.getAllOrganisms();
  }

  /// Obtém organismos por cultura
  Future<List<AIOrganismData>> getOrganismsByCrop(String cropName) async {
    return await _integrated.getOrganismsByCrop(cropName);
  }

  /// Obtém organismos por tipo
  Future<List<AIOrganismData>> getOrganismsByType(String type) async {
    return await _integrated.getOrganismsByType(type);
  }

  /// Busca organismos por nome ou sintoma
  Future<List<AIOrganismData>> searchOrganisms(String query) async {
    return await _integrated.searchOrganisms(query);
  }

  /// Obtém organismo por ID
  Future<AIOrganismData?> getOrganismById(int id) async {
    return await _integrated.getOrganismById(id);
  }

  /// Obtém estatísticas do repositório
  /// NOVO: Inclui dados de enriquecimento com feedback
  Future<Map<String, dynamic>> getStats() async {
    return await _integrated.getStats();
  }

  /// NOVO: Adiciona novo organismo (para extensibilidade futura)
  Future<bool> addOrganism(AIOrganismData organism) async {
    Logger.warning('⚠️ addOrganism() não suportado na versão integrada');
    Logger.warning('   Para adicionar organismos, edite os arquivos JSON');
        return false;
      }
      
  /// NOVO: Atualiza organismo existente
  Future<bool> updateOrganism(AIOrganismData organism) async {
    Logger.warning('⚠️ updateOrganism() não suportado na versão integrada');
    Logger.warning('   Para atualizar organismos, edite os arquivos JSON');
        return false;
      }
      
  /// NOVO: Remove organismo
  Future<bool> removeOrganism(int id) async {
    Logger.warning('⚠️ removeOrganism() não suportado na versão integrada');
    Logger.warning('   Para remover organismos, edite os arquivos JSON');
        return false;
      }
      
  /// NOVO: Recarrega IA com novos feedbacks
  /// Chamar após usuário dar feedback para atualizar IA
  Future<void> reloadAndRelearn() async {
    Logger.info('🔄 Recarregando IA com novos feedbacks...');
    await _integrated.reloadAndRelearn();
  }
}

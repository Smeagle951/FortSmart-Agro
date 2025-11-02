import '../models/planting_cv_model.dart';
import '../database/repositories/planting_cv_repository.dart';
import '../utils/logger.dart';

/// Serviço para persistir dados de CV% no histórico
/// Garante que os cálculos de CV% sejam salvos e recuperados corretamente
class PlantingCVPersistenceService {
  static const String _tag = 'PlantingCVPersistenceService';
  
  final PlantingCVRepository _cvRepository = PlantingCVRepository();

  /// Salva um cálculo de CV% no histórico
  Future<bool> salvarCvNoHistorico(PlantingCVModel cvModel) async {
    try {
      Logger.info('$_tag: Salvando CV% no histórico - Talhão: ${cvModel.talhaoNome}');
      
      // Garantir que a tabela existe
      await _cvRepository.createTableIfNotExists();
      
      // Salvar o registro
      await _cvRepository.insertCvRecord(cvModel);
      
      Logger.info('$_tag: CV% salvo com sucesso - ID: ${cvModel.id}');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao salvar CV%: $e');
      return false;
    }
  }

  /// Recupera o histórico de CV% para um talhão
  Future<List<PlantingCVModel>> obterHistoricoCv(String talhaoId) async {
    try {
      Logger.info('$_tag: Recuperando histórico de CV% para talhão: $talhaoId');
      
      final historico = await _cvRepository.getCvRecordsByTalhao(talhaoId);
      
      Logger.info('$_tag: ${historico.length} registros de CV% encontrados');
      return historico;
    } catch (e) {
      Logger.error('$_tag: Erro ao recuperar histórico de CV%: $e');
      return [];
    }
  }

  /// Obtém o último cálculo de CV% para um talhão
  Future<PlantingCVModel?> obterUltimoCv(String talhaoId) async {
    try {
      final historico = await obterHistoricoCv(talhaoId);
      
      if (historico.isEmpty) {
        Logger.info('$_tag: Nenhum registro de CV% encontrado para talhão: $talhaoId');
        return null;
      }
      
      // Ordenar por data de criação (mais recente primeiro)
      historico.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      final ultimoCv = historico.first;
      Logger.info('$_tag: Último CV% encontrado - Data: ${ultimoCv.createdAt}, CV%: ${ultimoCv.coeficienteVariacao}%');
      
      return ultimoCv;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter último CV%: $e');
      return null;
    }
  }

  /// Atualiza um registro de CV% existente
  Future<bool> atualizarCv(PlantingCVModel cvModel) async {
    try {
      Logger.info('$_tag: Atualizando CV% - ID: ${cvModel.id}');
      
      await _cvRepository.updateCvRecord(cvModel);
      
      Logger.info('$_tag: CV% atualizado com sucesso');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao atualizar CV%: $e');
      return false;
    }
  }

  /// Remove um registro de CV% do histórico
  Future<bool> removerCv(String cvId) async {
    try {
      Logger.info('$_tag: Removendo CV% - ID: $cvId');
      
      await _cvRepository.deleteCvRecord(cvId);
      
      Logger.info('$_tag: CV% removido com sucesso');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao remover CV%: $e');
      return false;
    }
  }

  /// Obtém estatísticas de CV% para um talhão
  Future<Map<String, dynamic>> obterEstatisticasCv(String talhaoId) async {
    try {
      final historico = await obterHistoricoCv(talhaoId);
      
      if (historico.isEmpty) {
        return {
          'totalRegistros': 0,
          'cvMedio': 0.0,
          'melhorCv': 0.0,
          'piorCv': 0.0,
          'classificacaoMedia': 'N/A',
          'tendencia': 'N/A',
        };
      }
      
      // Calcular estatísticas
      final cvs = historico.map((e) => e.coeficienteVariacao).toList();
      final cvMedio = cvs.reduce((a, b) => a + b) / cvs.length;
      final melhorCv = cvs.reduce((a, b) => a < b ? a : b);
      final piorCv = cvs.reduce((a, b) => a > b ? a : b);
      
      // Classificação média
      final classificacaoMedia = cvMedio.classificacao;
      
      // Calcular tendência (comparar últimos 3 registros)
      String tendencia = 'N/A';
      if (historico.length >= 3) {
        final ultimos3 = historico.take(3).map((e) => e.coeficienteVariacao).toList();
        final primeiro = ultimos3.last;
        final ultimo = ultimos3.first;
        
        if (ultimo < primeiro) {
          tendencia = 'Melhorando';
        } else if (ultimo > primeiro) {
          tendencia = 'Piorando';
        } else {
          tendencia = 'Estável';
        }
      }
      
      return {
        'totalRegistros': historico.length,
        'cvMedio': cvMedio,
        'melhorCv': melhorCv,
        'piorCv': piorCv,
        'classificacaoMedia': classificacaoMedia.toString().split('.').last,
        'tendencia': tendencia,
        'ultimoRegistro': historico.first.createdAt.toIso8601String(),
      };
    } catch (e) {
      Logger.error('$_tag: Erro ao calcular estatísticas de CV%: $e');
      return {
        'totalRegistros': 0,
        'cvMedio': 0.0,
        'melhorCv': 0.0,
        'piorCv': 0.0,
        'classificacaoMedia': 'N/A',
        'tendencia': 'N/A',
        'erro': e.toString(),
      };
    }
  }

  /// Verifica se existe CV% salvo para um talhão
  Future<bool> temCvSalvo(String talhaoId) async {
    try {
      final historico = await obterHistoricoCv(talhaoId);
      return historico.isNotEmpty;
    } catch (e) {
      Logger.error('$_tag: Erro ao verificar se tem CV% salvo: $e');
      return false;
    }
  }
}

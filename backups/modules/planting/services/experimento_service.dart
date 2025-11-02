import 'package:logger/logger.dart';
import '../models/experimento_model.dart';
import '../repositories/experimento_repository.dart';
import 'modules_integration_service.dart';

class ExperimentoService {
  final ExperimentoRepository _repository = ExperimentoRepository();
  final ModulesIntegrationService _integrationService = ModulesIntegrationService();
  final Logger _logger = Logger();

  // Método para criar um novo experimento
  Future<void> create(ExperimentoModel experimento) async {
    try {
      _logger.i('Criando novo experimento: ${experimento.nome}');
      await _repository.insert(experimento);
      _logger.i('Experimento criado com sucesso');
    } catch (e) {
      _logger.e('Erro ao criar experimento: $e');
      throw Exception('Falha ao criar experimento: $e');
    }
  }

  // Método para atualizar um experimento existente
  Future<void> update(ExperimentoModel experimento) async {
    try {
      _logger.i('Atualizando experimento ID: ${experimento.id}');
      await _repository.update(experimento);
      _logger.i('Experimento atualizado com sucesso');
    } catch (e) {
      _logger.e('Erro ao atualizar experimento: $e');
      throw Exception('Falha ao atualizar experimento: $e');
    }
  }

  // Método simplificado para salvar (criar ou atualizar)
  Future<void> saveExperimento(ExperimentoModel experimento) async {
    if (experimento.id != null) {
      await update(experimento);
    } else {
      await create(experimento);
    }
  }

  // Obter todos os experimentos
  Future<List<ExperimentoModel>> getAllExperimentos() async {
    try {
      _logger.i('Buscando todos os experimentos');
      return await _repository.getAll();
    } catch (e) {
      _logger.e('Erro ao buscar experimentos: $e');
      throw Exception('Falha ao buscar experimentos: $e');
    }
  }

  // Obter experimentos filtrados
  Future<List<ExperimentoModel>> getExperimentosByFilters({
    String? talhaoId, 
    String? culturaId, 
    String? variedadeId,
    String? nome, 
    int? ano,
    bool forceRefresh = false,
  }) async {
    try {
      _logger.i('Buscando experimentos com filtros: talhão=$talhaoId, cultura=$culturaId, variedade=$variedadeId, nome=$nome, ano=$ano');
      
      // Convertendo IDs para int para compatibilidade com o repositório
      final talhaoIdInt = talhaoId != null ? int.tryParse(talhaoId) : null;
      final culturaIdInt = culturaId != null ? int.tryParse(culturaId) : null;
      
      final results = await _repository.getByFilters(
        talhaoId: talhaoIdInt,
        culturaId: culturaIdInt,
        nome: nome,
        ano: ano,
      );
      
      _logger.i('Encontrados ${results.length} experimentos');
      return results;
    } catch (e) {
      _logger.e('Erro ao filtrar experimentos: $e');
      throw Exception('Falha ao filtrar experimentos: $e');
    }
  }

  // Obter experimento por ID
  Future<ExperimentoModel?> getExperimentoById(String id) async {
    try {
      _logger.i('Buscando experimento com ID: $id');
      final idInt = int.tryParse(id);
      if (idInt == null) {
        _logger.e('ID inválido: $id');
        return null;
      }
      
      return await _repository.getById(idInt);
    } catch (e) {
      _logger.e('Erro ao buscar experimento por ID: $e');
      throw Exception('Falha ao buscar experimento: $e');
    }
  }

  // Deletar um experimento
  Future<void> deleteExperimento(String id) async {
    try {
      _logger.i('Deletando experimento com ID: $id');
      final idInt = int.tryParse(id);
      if (idInt == null) {
        _logger.e('ID inválido para exclusão: $id');
        throw Exception('ID inválido para exclusão');
      }
      
      await _repository.delete(idInt);
      _logger.i('Experimento deletado com sucesso');
    } catch (e) {
      _logger.e('Erro ao deletar experimento: $e');
      throw Exception('Falha ao deletar experimento: $e');
    }
  }
  
  // Métodos auxiliares para integração com outros módulos
  
  // Buscar nome do talhão a partir do ID
  Future<String> getTalhaoName(String talhaoId) async {
    try {
      final talhao = await _integrationService.getTalhaoById(talhaoId);
      return talhao?.nome ?? 'Talhão não encontrado';
    } catch (e) {
      _logger.e('Erro ao buscar nome do talhão: $e');
      return 'Erro ao buscar talhão';
    }
  }
  
  // Buscar nome da cultura a partir do ID
  Future<String> getCultureName(String culturaId) async {
    try {
      final cultura = await _integrationService.getCulturaPorId(culturaId);
      return cultura?.name ?? 'Cultura não encontrada';
    } catch (e) {
      _logger.e('Erro ao buscar nome da cultura: $e');
      return 'Erro ao buscar cultura';
    }
  }
  
  // Buscar nome da variedade a partir do ID
  Future<String> getVarietyName(String variedadeId) async {
    try {
      final variedade = await _integrationService.getVariedadePorId(variedadeId);
      return variedade?.name ?? 'Variedade não encontrada';
    } catch (e) {
      _logger.e('Erro ao buscar nome da variedade: $e');
      return 'Erro ao buscar variedade';
    }
  }
}

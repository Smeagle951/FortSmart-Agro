import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/models/estande_plantas_model.dart';
import '../database/repositories/estande_plantas_repository.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar dados de estande de plantas
/// Integra com o submódulo existente "Novo Estande de Plantas"
class EstandeService {
  static final EstandeService _instance = EstandeService._internal();
  factory EstandeService() => _instance;
  EstandeService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final EstandePlantasRepository _estandeRepository = EstandePlantasRepository();

  /// Obtém o último estande válido de um talhão
  Future<EstandePlantasModel?> getLastStandByTalhao(String talhaoId) async {
    try {
      Logger.info('🔍 Buscando último estande para talhão: $talhaoId');
      
      final estandes = await _estandeRepository.buscarPorTalhao(talhaoId);
      
      if (estandes.isNotEmpty) {
        // Ordena por data de avaliação (mais recente primeiro)
        estandes.sort((a, b) => (b.dataAvaliacao ?? DateTime.now()).compareTo(a.dataAvaliacao ?? DateTime.now()));
        final ultimoEstande = estandes.first;
        
        Logger.info('✅ Último estande encontrado: DAE ${ultimoEstande.diasAposEmergencia} (${ultimoEstande.plantasPorHectare?.toStringAsFixed(0)} plantas/ha)');
        return ultimoEstande;
      }

      Logger.warning('⚠️ Nenhum estande encontrado para talhão: $talhaoId');
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar último estande: $e');
      return null;
    }
  }

  /// Verifica se existe estande recente (últimos 10 dias)
  Future<bool> hasRecentStand(String talhaoId, {int daysThreshold = 10}) async {
    try {
      final lastStand = await getLastStandByTalhao(talhaoId);
      if (lastStand == null) return false;

      final dataReferencia = lastStand.dataAvaliacao ?? lastStand.createdAt ?? DateTime.now();
      final daysDifference = DateTime.now().difference(dataReferencia).inDays;
      final hasRecent = daysDifference <= daysThreshold;
      
      Logger.info('📅 Estande de ${daysDifference} dias atrás - ${hasRecent ? 'Recente' : 'Antigo'}');
      return hasRecent;
    } catch (e) {
      Logger.error('❌ Erro ao verificar estande recente: $e');
      return false;
    }
  }

  /// Obtém todos os estandes de um talhão
  Future<List<EstandePlantasModel>> getStandsByTalhao(String talhaoId) async {
    try {
      Logger.info('🔍 Buscando todos os estandes para talhão: $talhaoId');
      
      final estandes = await _estandeRepository.buscarPorTalhao(talhaoId);
      
      // Ordena por data de avaliação (mais recente primeiro)
      estandes.sort((a, b) => (b.dataAvaliacao ?? DateTime.now()).compareTo(a.dataAvaliacao ?? DateTime.now()));
      
      Logger.info('✅ ${estandes.length} estandes encontrados');
      return estandes;
    } catch (e) {
      Logger.error('❌ Erro ao buscar estandes: $e');
      return [];
    }
  }

  /// Salva um novo estande usando o repositório existente
  Future<String?> saveStand(EstandePlantasModel estande) async {
    try {
      Logger.info('💾 Salvando estande para talhão: ${estande.talhaoId}');
      
      final id = await _estandeRepository.salvar(estande);
      Logger.info('✅ Estande salvo com ID: $id');
      return id;
    } catch (e) {
      Logger.error('❌ Erro ao salvar estande: $e');
      return null;
    }
  }

  /// Atualiza um estande existente
  Future<bool> updateStand(EstandePlantasModel estande) async {
    try {
      Logger.info('🔄 Atualizando estande: ${estande.id}');
      
      final result = await _estandeRepository.salvar(estande);
      final success = result.isNotEmpty;
      Logger.info(success ? '✅ Estande atualizado' : '⚠️ Estande não encontrado');
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar estande: $e');
      return false;
    }
  }

  /// Remove um estande
  Future<bool> deleteStand(String estandeId) async {
    try {
      Logger.info('🗑️ Removendo estande: $estandeId');
      
      final result = await _estandeRepository.excluir(estandeId);
      final success = result > 0;
      Logger.info(success ? '✅ Estande removido' : '⚠️ Estande não encontrado');
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao remover estande: $e');
      return false;
    }
  }

  /// Obtém estatísticas de estande para um talhão
  Future<Map<String, dynamic>> getStandStatistics(String talhaoId) async {
    try {
      Logger.info('📊 Calculando estatísticas de estande para talhão: $talhaoId');
      
      final estandes = await getStandsByTalhao(talhaoId);
      
      if (estandes.isEmpty) {
        return {
          'totalStands': 0,
          'averagePopulation': 0.0,
          'averageEfficiency': 0.0,
          'lastStandDate': null,
          'standEvolution': [],
        };
      }

      final totalStands = estandes.length;
      final averagePopulation = estandes.map((e) => e.plantasPorHectare ?? 0.0).reduce((a, b) => a + b) / totalStands;
      final averageEfficiency = estandes.map((e) => e.eficiencia ?? 0.0).reduce((a, b) => a + b) / totalStands;
      final lastStandDate = estandes.first.dataAvaliacao ?? estandes.first.createdAt;

      final standEvolution = estandes.map((e) => {
        'date': (e.dataAvaliacao ?? e.createdAt)?.toIso8601String(),
        'population': e.plantasPorHectare,
        'efficiency': e.eficiencia,
        'stage': calculateEstadioFenologico(e.culturaId ?? 'soja', e.diasAposEmergencia ?? 0),
        'dae': e.diasAposEmergencia,
        'plantasPorMetro': e.plantasPorMetro,
      }).toList();

      final statistics = {
        'totalStands': totalStands,
        'averagePopulation': averagePopulation,
        'averageEfficiency': averageEfficiency,
        'lastStandDate': lastStandDate?.toIso8601String(),
        'standEvolution': standEvolution,
      };

      Logger.info('✅ Estatísticas calculadas: $totalStands estandes');
      return statistics;
    } catch (e) {
      Logger.error('❌ Erro ao calcular estatísticas: $e');
      return {};
    }
  }

  /// Calcula estádio fenológico baseado na cultura e DAE
  String calculateEstadioFenologico(String cultura, int diasAposEmergencia) {
    // Mapeamento básico de estádios por cultura
    final estagios = _getEstagiosPorCultura(cultura);
    
    for (final estagio in estagios) {
      if (diasAposEmergencia >= estagio['daeMin'] && diasAposEmergencia <= estagio['daeMax']) {
        return estagio['nome'];
      }
    }
    
    // Fallback para estádio mais próximo
    if (diasAposEmergencia < 10) return 'V1-V3 (Plântula)';
    if (diasAposEmergencia < 20) return 'V4-V6 (Desenvolvimento inicial)';
    if (diasAposEmergencia < 40) return 'V7-V9 (Desenvolvimento vegetativo)';
    if (diasAposEmergencia < 60) return 'R1-R3 (Reproductivo inicial)';
    return 'R4-R8 (Reproductivo avançado)';
  }

  /// Obtém dados do estande para o card de ocorrência
  Future<Map<String, dynamic>> getEstandeDataForOccurrence(String talhaoId) async {
    try {
      final lastStand = await getLastStandByTalhao(talhaoId);
      
      if (lastStand == null) {
        return {
          'hasStand': false,
          'estadioFenologico': null,
          'diasAposEmergencia': null,
          'populacao': null,
          'eficiencia': null,
          'dataAvaliacao': null,
        };
      }

      // Calcula estádio fenológico baseado no DAE
      final estadioFenologico = calculateEstadioFenologico(
        lastStand.culturaId ?? 'soja', // Fallback para soja
        lastStand.diasAposEmergencia ?? 0,
      );

      return {
        'hasStand': true,
        'estadioFenologico': estadioFenologico,
        'diasAposEmergencia': lastStand.diasAposEmergencia,
        'populacao': lastStand.plantasPorHectare?.round(),
        'eficiencia': lastStand.eficiencia,
        'dataAvaliacao': lastStand.dataAvaliacao,
        'plantasPorMetro': lastStand.plantasPorMetro,
        'espacamento': lastStand.espacamento,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter dados do estande: $e');
      return {'hasStand': false};
    }
  }

  /// Obtém opções de estágios fenológicos para seleção
  List<String> getEstagiosFenologicosOptions(String cultura) {
    switch (cultura.toLowerCase()) {
      case 'soja':
        return [
          'VE - Emergência',
          'VC - Cotilédone',
          'V1-V2 - Primeiro par de folhas',
          'V3-V4 - Terceiro par de folhas',
          'V5-Vn - Folhas trifolioladas',
          'R1 - Início do florescimento',
          'R2 - Florescimento pleno',
          'R3 - Início da formação de vagem',
          'R4 - Formação de vagem',
          'R5 - Início do enchimento de grão',
          'R6 - Enchimento de grão',
          'R7 - Início da maturação',
          'R8 - Maturação fisiológica',
        ];
      case 'milho':
        return [
          'VE - Emergência',
          'V1-V2 - Primeira folha',
          'V3-V4 - Terceira folha',
          'V5-V6 - Quinta folha',
          'V7-Vn - Folhas adicionais',
          'VT - Pendoamento',
          'R1 - Pendoamento',
          'R2 - Blossom shed',
          'R3 - Milk stage',
          'R4 - Dough stage',
          'R5 - Dent stage',
          'R6 - Maturidade fisiológica',
        ];
      case 'trigo':
        return [
          'Emergência',
          'Afilhamento',
          'Alongamento',
          'Emborrachamento',
          'Florescimento',
          'Enchimento de grão',
          'Maturação',
        ];
      default:
        return [
          'Inicial',
          'Vegetativo',
          'Reprodutivo',
          'Maturação',
        ];
    }
  }

  /// Obtém opções de tipos de manejo anterior
  List<Map<String, dynamic>> getTiposManejoAnterior() {
    return [
      {
        'id': 'quimico',
        'nome': 'Químico',
        'descricao': 'Aplicação de defensivos químicos',
        'icone': Icons.science,
        'cor': Colors.red,
      },
      {
        'id': 'biologico',
        'nome': 'Biológico',
        'descricao': 'Controle biológico ou produtos biológicos',
        'icone': Icons.pets,
        'cor': Colors.green,
      },
      {
        'id': 'cultural',
        'nome': 'Cultural',
        'descricao': 'Manejo cultural (rotação, adubação, etc.)',
        'icone': Icons.agriculture,
        'cor': Colors.brown,
      },
      {
        'id': 'mecanico',
        'nome': 'Mecânico',
        'descricao': 'Controle mecânico (capina, etc.)',
        'icone': Icons.build,
        'cor': Colors.blue,
      },
    ];
  }

  /// Obtém opções de impacto econômico previsto
  List<Map<String, dynamic>> getImpactoEconomicoOptions() {
    return [
      {
        'id': 'baixo',
        'nome': 'Baixo',
        'descricao': 'Impacto < 5% na produtividade',
        'cor': Colors.green,
        'valorMin': 0,
        'valorMax': 5,
      },
      {
        'id': 'medio',
        'nome': 'Médio',
        'descricao': 'Impacto 5-15% na produtividade',
        'cor': Colors.orange,
        'valorMin': 5,
        'valorMax': 15,
      },
      {
        'id': 'alto',
        'nome': 'Alto',
        'descricao': 'Impacto > 15% na produtividade',
        'cor': Colors.red,
        'valorMin': 15,
        'valorMax': 50,
      },
    ];
  }

  /// Obtém estágios por cultura
  List<Map<String, dynamic>> _getEstagiosPorCultura(String cultura) {
    switch (cultura.toLowerCase()) {
      case 'soja':
        return [
          {'nome': 'V1-V3 (Plântula)', 'daeMin': 0, 'daeMax': 10},
          {'nome': 'V4-V6 (Desenvolvimento inicial)', 'daeMin': 11, 'daeMax': 20},
          {'nome': 'V7-V9 (Desenvolvimento vegetativo)', 'daeMin': 21, 'daeMax': 40},
          {'nome': 'R1-R3 (Reproductivo inicial)', 'daeMin': 41, 'daeMax': 60},
          {'nome': 'R4-R8 (Reproductivo avançado)', 'daeMin': 61, 'daeMax': 120},
        ];
      case 'milho':
        return [
          {'nome': 'V1-V3 (Plântula)', 'daeMin': 0, 'daeMax': 15},
          {'nome': 'V4-V6 (Desenvolvimento inicial)', 'daeMin': 16, 'daeMax': 30},
          {'nome': 'V7-V9 (Desenvolvimento vegetativo)', 'daeMin': 31, 'daeMax': 50},
          {'nome': 'R1-R3 (Reproductivo inicial)', 'daeMin': 51, 'daeMax': 80},
          {'nome': 'R4-R6 (Reproductivo avançado)', 'daeMin': 81, 'daeMax': 120},
        ];
      default:
        return [
          {'nome': 'Plântula', 'daeMin': 0, 'daeMax': 10},
          {'nome': 'Desenvolvimento inicial', 'daeMin': 11, 'daeMax': 30},
          {'nome': 'Desenvolvimento vegetativo', 'daeMin': 31, 'daeMax': 60},
          {'nome': 'Reproductivo', 'daeMin': 61, 'daeMax': 120},
        ];
    }
  }
}

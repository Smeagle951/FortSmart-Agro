import '../database/repositories/estande_plantas_repository.dart';
import '../database/models/estande_plantas_model.dart';
import '../database/app_database.dart';
import '../screens/plantio/submods/phenological_evolution/providers/phenological_provider.dart';
import '../screens/plantio/submods/phenological_evolution/database/daos/phenological_record_dao.dart';
import '../screens/plantio/submods/phenological_evolution/models/phenological_record_model.dart';
import '../utils/logger.dart';

/// Serviço de integração de dados para o monitoramento
/// Integra dados dos submódulos Estande de Plantas e Evolução Fenológica
class MonitoringDataIntegrationService {
  final EstandePlantasRepository _estandeRepository = EstandePlantasRepository();
  late final PhenologicalRecordDAO _phenologicalDao;
  
  static const String _tag = 'MonitoringDataIntegrationService';

  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      final database = await AppDatabase().database;
      _phenologicalDao = PhenologicalRecordDAO(database);
    } catch (e) {
      Logger.error('$_tag: Erro ao inicializar: $e');
    }
  }

  /// Obtém dados de estande de plantas para um talhão e cultura
  Future<Map<String, dynamic>?> getEstandeData(String talhaoId, String culturaId) async {
    try {
      Logger.info('$_tag: Obtendo dados de estande para talhão $talhaoId e cultura $culturaId');
      
      // Buscar dados mais recentes de estande
      final estandeData = await _estandeRepository.getLatestByTalhaoAndCultura(
        talhaoId, 
        culturaId,
      );
      
      if (estandeData != null) {
        final diasAposEmergencia = estandeData.diasAposEmergencia ?? 0;
        final plantasPorHectare = estandeData.plantasPorHectare ?? 0.0;
        final eficiencia = estandeData.eficiencia ?? 0.0;
        
        // Calcular CV% se houver dados de população ideal
        double? cvPercentage;
        if (estandeData.populacaoIdeal != null && estandeData.populacaoIdeal! > 0) {
          final diferenca = (plantasPorHectare - estandeData.populacaoIdeal!).abs();
          cvPercentage = (diferenca / estandeData.populacaoIdeal!) * 100;
        }
        
        return {
          'plantasPorHectare': plantasPorHectare,
          'eficiencia': eficiencia,
          'diasAposEmergencia': diasAposEmergencia,
          'cvPercentage': cvPercentage,
          'populacaoIdeal': estandeData.populacaoIdeal,
          'dataAvaliacao': estandeData.dataAvaliacao?.toIso8601String(),
          'metrosLinearesMedidos': estandeData.metrosLinearesMedidos,
          'plantasContadas': estandeData.plantasContadas,
          'espacamento': estandeData.espacamento,
          'plantasPorMetro': estandeData.plantasPorMetro,
        };
      }
      
      Logger.info('$_tag: Nenhum dado de estande encontrado');
      return null;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao obter dados de estande: $e');
      return null;
    }
  }

  /// Obtém dados fenológicos para um talhão e cultura
  Future<Map<String, dynamic>?> getPhenologicalData(String talhaoId, String culturaId) async {
    try {
      Logger.info('$_tag: Obtendo dados fenológicos para talhão $talhaoId e cultura $culturaId');
      
      // Inicializar se necessário
      await initialize();
      
      // Buscar último registro fenológico
      final record = await _phenologicalDao.buscarUltimoRegistro(
        talhaoId, 
        culturaId,
      );
      
      if (record != null) {
        return {
          'estagioAtual': record.estagioFenologico,
          'dae': record.diasAposEmergencia,
          'altura': record.alturaCm,
          'diametro': record.diametroColmoMm,
          'numeroFolhas': record.numeroFolhas,
          'dataRegistro': record.dataRegistro.toIso8601String(),
          'observacoes': record.observacoes,
          'descricaoEstagio': record.descricaoEstagio,
          'estandePlantas': record.estandePlantas,
          'percentualSanidade': record.percentualSanidade,
          'presencaPragas': record.presencaPragas,
          'presencaDoencas': record.presencaDoencas,
        };
      }
      
      Logger.info('$_tag: Nenhum dado fenológico encontrado');
      return null;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao obter dados fenológicos: $e');
      return null;
    }
  }

  /// Determina estado fenológico baseado em DAE e cultura
  String determinePhenologicalStage(int diasAposEmergencia, String culturaId) {
    // Estados fenológicos básicos por cultura (baseado no sistema existente)
    final estadosPorCultura = {
      'soja': {
        'V1': [0, 10],
        'V2': [11, 15],
        'V3': [16, 20],
        'V4': [21, 25],
        'V5': [26, 30],
        'R1': [31, 35],
        'R2': [36, 45],
        'R3': [46, 55],
        'R4': [56, 65],
        'R5': [66, 75],
        'R6': [76, 85],
        'R7': [86, 95],
        'R8': [96, 105],
      },
      'milho': {
        'V1': [0, 7],
        'V2': [8, 12],
        'V3': [13, 17],
        'V4': [18, 22],
        'V5': [23, 27],
        'V6': [28, 32],
        'V7': [33, 37],
        'V8': [38, 42],
        'R1': [43, 50],
        'R2': [51, 58],
        'R3': [59, 66],
        'R4': [67, 74],
        'R5': [75, 82],
        'R6': [83, 90],
      },
      'algodao': {
        'V1': [0, 8],
        'V2': [9, 15],
        'V3': [16, 22],
        'V4': [23, 30],
        'V5': [31, 40],
        'R1': [41, 50],
        'R2': [51, 60],
        'R3': [61, 70],
        'R4': [71, 80],
        'R5': [81, 90],
      },
      'feijao': {
        'V1': [0, 8],
        'V2': [9, 15],
        'V3': [16, 22],
        'V4': [23, 30],
        'R1': [31, 40],
        'R2': [41, 50],
        'R3': [51, 60],
        'R4': [61, 70],
        'R5': [71, 80],
        'R6': [81, 90],
      },
      'sorgo': {
        'V1': [0, 10],
        'V2': [11, 18],
        'V3': [19, 25],
        'V4': [26, 32],
        'V5': [33, 40],
        'R1': [41, 50],
        'R2': [51, 60],
        'R3': [61, 70],
        'R4': [71, 80],
        'R5': [81, 90],
      },
      'girassol': {
        'V1': [0, 8],
        'V2': [9, 15],
        'V3': [16, 22],
        'V4': [23, 30],
        'R1': [31, 40],
        'R2': [41, 50],
        'R3': [51, 60],
        'R4': [61, 70],
        'R5': [71, 80],
        'R6': [81, 90],
      },
      'aveia': {
        'V1': [0, 10],
        'V2': [11, 18],
        'V3': [19, 25],
        'V4': [26, 32],
        'V5': [33, 40],
        'R1': [41, 50],
        'R2': [51, 60],
        'R3': [61, 70],
        'R4': [71, 80],
        'R5': [81, 90],
      },
      'trigo': {
        'V1': [0, 10],
        'V2': [11, 18],
        'V3': [19, 25],
        'V4': [26, 32],
        'V5': [33, 40],
        'R1': [41, 50],
        'R2': [51, 60],
        'R3': [61, 70],
        'R4': [71, 80],
        'R5': [81, 90],
      },
      'gergelim': {
        'V1': [0, 8],
        'V2': [9, 15],
        'V3': [16, 22],
        'V4': [23, 30],
        'R1': [31, 40],
        'R2': [41, 50],
        'R3': [51, 60],
        'R4': [61, 70],
        'R5': [71, 80],
      },
      'cana-de-acucar': {
        'V1': [0, 15],
        'V2': [16, 30],
        'V3': [31, 45],
        'V4': [46, 60],
        'V5': [61, 90],
        'V6': [91, 120],
        'V7': [121, 150],
        'V8': [151, 180],
        'R1': [181, 210],
        'R2': [211, 240],
        'R3': [241, 270],
      },
      'tomate': {
        'V1': [0, 10],
        'V2': [11, 20],
        'V3': [21, 30],
        'V4': [31, 40],
        'V5': [41, 50],
        'R1': [51, 60],
        'R2': [61, 70],
        'R3': [71, 80],
        'R4': [81, 90],
        'R5': [91, 100],
      },
      'arroz': {
        'V1': [0, 10],
        'V2': [11, 20],
        'V3': [21, 30],
        'V4': [31, 40],
        'V5': [41, 50],
        'R1': [51, 60],
        'R2': [61, 70],
        'R3': [71, 80],
        'R4': [81, 90],
        'R5': [91, 100],
        'R6': [101, 110],
      },
    };
    
    final estados = estadosPorCultura[culturaId.toLowerCase()] ?? estadosPorCultura['soja']!;
    
    for (final entry in estados.entries) {
      final range = entry.value;
      if (diasAposEmergencia >= range[0] && diasAposEmergencia <= range[1]) {
        return entry.key;
      }
    }
    
    return 'V1'; // Estado padrão
  }

  /// Calcula classificação do CV%
  String calculateCvClassification(double cvPercentage) {
    if (cvPercentage <= 15.0) {
      return 'EXCELENTE';
    } else if (cvPercentage <= 25.0) {
      return 'BOM';
    } else if (cvPercentage <= 35.0) {
      return 'REGULAR';
    } else {
      return 'RUIM';
    }
  }

  /// Obtém cor baseada na classificação do CV%
  String getCvColor(String classification) {
    switch (classification.toUpperCase()) {
      case 'EXCELENTE':
        return '#4CAF50'; // Verde
      case 'BOM':
        return '#8BC34A'; // Verde claro
      case 'REGULAR':
        return '#FF9800'; // Laranja
      case 'RUIM':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }
}

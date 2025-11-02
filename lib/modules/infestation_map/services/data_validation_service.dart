import '../../../models/monitoring.dart';
import '../../../models/monitoring_point.dart';
import '../../../models/organism_catalog.dart';
import '../../../utils/logger.dart';

/// Serviço para validação de dados reais
/// Garante que apenas dados reais coletados no campo sejam utilizados
class DataValidationService {
  
  /// Valida se um monitoramento contém dados reais
  Future<bool> validateMonitoringData(Monitoring monitoring) async {
    try {
      Logger.info('🔍 Validando dados reais do monitoramento: ${monitoring.id}');
      
      // 1. Verificar se tem pontos
      if (monitoring.points.isEmpty) {
        Logger.warning('⚠️ Monitoramento sem pontos: ${monitoring.id}');
        return false;
      }
      
      // 2. Verificar se tem coordenadas GPS válidas
      final validPoints = monitoring.points.where((point) {
        return point.latitude != 0.0 && 
               point.longitude != 0.0 &&
               point.latitude.abs() <= 90.0 &&
               point.longitude.abs() <= 180.0;
      }).toList();
      
      if (validPoints.isEmpty) {
        Logger.warning('⚠️ Monitoramento sem coordenadas GPS válidas: ${monitoring.id}');
        return false;
      }
      
      // 3. Verificar se tem ocorrências reais
      final pointsWithOccurrences = validPoints.where((point) {
        return point.occurrences.isNotEmpty &&
               point.occurrences.any((occ) => occ.infestationIndex > 0.0);
      }).toList();
      
      if (pointsWithOccurrences.isEmpty) {
        Logger.warning('⚠️ Monitoramento sem ocorrências reais: ${monitoring.id}');
        return false;
      }
      
      // 4. Verificar precisão GPS
      final pointsWithGoodAccuracy = validPoints.where((point) {
        return point.accuracy == null || point.accuracy! <= 10.0; // 10 metros ou melhor
      }).toList();
      
      if (pointsWithGoodAccuracy.length < validPoints.length * 0.5) {
        Logger.warning('⚠️ Monitoramento com precisão GPS baixa: ${monitoring.id}');
        // Não rejeitar, mas avisar
      }
      
      // 5. Verificar se não são dados de teste
      if (_isTestData(monitoring)) {
        Logger.warning('⚠️ Dados de teste detectados: ${monitoring.id}');
        return false;
      }
      
      Logger.info('✅ Monitoramento validado com sucesso: ${monitoring.id}');
      Logger.info('   📊 ${validPoints.length} pontos válidos');
      Logger.info('   🐛 ${pointsWithOccurrences.length} pontos com ocorrências');
      Logger.info('   📍 ${pointsWithGoodAccuracy.length} pontos com boa precisão GPS');
      
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao validar dados do monitoramento: $e');
      return false;
    }
  }
  
  /// Valida se um ponto de monitoramento é real
  bool validateMonitoringPoint(MonitoringPoint point) {
    try {
      // 1. Coordenadas válidas
      if (point.latitude == 0.0 || point.longitude == 0.0) {
        return false;
      }
      
      if (point.latitude.abs() > 90.0 || point.longitude.abs() > 180.0) {
        return false;
      }
      
      // 2. Tem ocorrências
      if (point.occurrences.isEmpty) {
        return false;
      }
      
      // 3. Pelo menos uma ocorrência tem infestação > 0
      final hasRealInfestation = point.occurrences.any((occ) => occ.infestationIndex > 0.0);
      if (!hasRealInfestation) {
        return false;
      }
      
      // 4. Não é dado de teste
      if (_isTestPoint(point)) {
        return false;
      }
      
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao validar ponto: $e');
      return false;
    }
  }
  
  /// Valida se um organismo do catálogo é real
  bool validateOrganismCatalog(OrganismCatalog organism) {
    try {
      // 1. Tem nome
      if (organism.name.isEmpty) {
        return false;
      }
      
      // 2. Tem limites válidos
      if (organism.lowLimit < 0 || organism.mediumLimit < 0 || organism.highLimit < 0) {
        return false;
      }
      
      if (organism.lowLimit >= organism.mediumLimit || 
          organism.mediumLimit >= organism.highLimit) {
        return false;
      }
      
      // 3. Não é dado de teste
      if (_isTestOrganism(organism)) {
        return false;
      }
      
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao validar organismo: $e');
      return false;
    }
  }
  
  /// Filtra monitoramentos para manter apenas dados reais
  Future<List<Monitoring>> filterRealMonitorings(List<Monitoring> monitorings) async {
    try {
      Logger.info('🔍 Filtrando ${monitorings.length} monitoramentos para dados reais...');
      
      final realMonitorings = <Monitoring>[];
      
      for (final monitoring in monitorings) {
        if (await validateMonitoringData(monitoring)) {
          realMonitorings.add(monitoring);
        }
      }
      
      Logger.info('✅ ${realMonitorings.length} monitoramentos reais validados de ${monitorings.length}');
      return realMonitorings;
      
    } catch (e) {
      Logger.error('❌ Erro ao filtrar monitoramentos: $e');
      return monitorings; // Retornar todos em caso de erro
    }
  }
  
  /// Filtra pontos para manter apenas dados reais
  List<MonitoringPoint> filterRealPoints(List<MonitoringPoint> points) {
    try {
      Logger.info('🔍 Filtrando ${points.length} pontos para dados reais...');
      
      final realPoints = points.where((point) => validateMonitoringPoint(point)).toList();
      
      Logger.info('✅ ${realPoints.length} pontos reais validados de ${points.length}');
      return realPoints;
      
    } catch (e) {
      Logger.error('❌ Erro ao filtrar pontos: $e');
      return points; // Retornar todos em caso de erro
    }
  }
  
  /// Filtra organismos para manter apenas dados reais
  List<OrganismCatalog> filterRealOrganisms(List<OrganismCatalog> organisms) {
    try {
      Logger.info('🔍 Filtrando ${organisms.length} organismos para dados reais...');
      
      final realOrganisms = organisms.where((organism) => validateOrganismCatalog(organism)).toList();
      
      Logger.info('✅ ${realOrganisms.length} organismos reais validados de ${organisms.length}');
      return realOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao filtrar organismos: $e');
      return organisms; // Retornar todos em caso de erro
    }
  }
  
  // ===== MÉTODOS PRIVADOS =====
  
  /// Detecta se são dados de teste
  bool _isTestData(Monitoring monitoring) {
    // Verificar padrões comuns de dados de teste
    final testPatterns = [
      'test',
      'exemplo',
      'sample',
      'demo',
      'mock',
      'fake',
      'dummy',
    ];
    
    final monitoringId = monitoring.id.toLowerCase();
    final observations = monitoring.observations?.toLowerCase() ?? '';
    
    return testPatterns.any((pattern) => 
      monitoringId.contains(pattern) || observations.contains(pattern));
  }
  
  /// Detecta se é um ponto de teste
  bool _isTestPoint(MonitoringPoint point) {
    // Verificar se as coordenadas são muito redondas (indicativo de dados fake)
    final lat = point.latitude.abs();
    final lon = point.longitude.abs();
    
    // Coordenadas muito redondas podem indicar dados de teste
    if (lat % 1.0 == 0.0 && lon % 1.0 == 0.0) {
      return true;
    }
    
    // Verificar se as coordenadas são muito precisas (muitas casas decimais iguais)
    final latStr = lat.toString();
    final lonStr = lon.toString();
    
    if (latStr.contains('.000000') || lonStr.contains('.000000')) {
      return true;
    }
    
    return false;
  }
  
  /// Detecta se é um organismo de teste
  bool _isTestOrganism(OrganismCatalog organism) {
    final testPatterns = [
      'test',
      'exemplo',
      'sample',
      'demo',
      'mock',
      'fake',
      'dummy',
    ];
    
    final name = organism.name.toLowerCase();
    final scientificName = organism.scientificName.toLowerCase();
    
    return testPatterns.any((pattern) => 
      name.contains(pattern) || scientificName.contains(pattern));
  }
  
  /// Obtém estatísticas de validação
  Map<String, dynamic> getValidationStats() {
    return {
      'service': 'DataValidationService',
      'version': '1.0.0',
      'description': 'Validação de dados reais para Mapa de Infestação',
      'features': [
        'Validação de coordenadas GPS',
        'Validação de ocorrências reais',
        'Detecção de dados de teste',
        'Validação de precisão GPS',
        'Filtragem automática de dados fake',
      ],
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}

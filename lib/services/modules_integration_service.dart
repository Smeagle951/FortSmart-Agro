import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../models/organism_catalog.dart';
import '../repositories/organism_catalog_repository.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Serviço de integração entre módulos Monitoramento, Catálogo de Organismos e Mapa de Infestação
/// Resolve o problema de conectividade entre os módulos para cálculo automático de níveis de intensidade
class ModulesIntegrationService {
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogRepository _catalogRepository = OrganismCatalogRepository();
  
  static const String _tableName = 'modules_integration_cache';

  /// Inicializa o serviço e cria tabelas necessárias
  Future<void> initialize() async {
    try {
      final db = await _database.database;
      
      // Tabela de cache para integração entre módulos
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          organismo_id TEXT NOT NULL,
          organismo_nome TEXT NOT NULL,
          organismo_tipo TEXT NOT NULL,
          quantidade_detectada REAL NOT NULL,
          unidade_medida TEXT NOT NULL,
          nivel_intensidade TEXT NOT NULL,
          cor_mapa TEXT NOT NULL,
          data_monitoramento TEXT NOT NULL,
          monitoring_id TEXT NOT NULL,
          monitoring_point_id TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // Índices para performance
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_integration_talhao_organismo 
        ON $_tableName(talhao_id, organismo_id)
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_integration_data 
        ON $_tableName(data_monitoramento)
      ''');

      Logger.info('✅ ModulesIntegrationService inicializado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar ModulesIntegrationService: $e');
      rethrow;
    }
  }

  /// Processa dados de monitoramento e integra com catálogo de organismos
  /// Este é o método principal que resolve o problema de conectividade
  Future<Map<String, dynamic>> processMonitoringData(Monitoring monitoring) async {
    try {
      Logger.info('🔄 Processando dados de monitoramento: ${monitoring.id}');
      
      final results = <String, dynamic>{
        'monitoring_id': monitoring.id,
        'talhao_id': monitoring.plotId.toString(),
        'talhao_nome': monitoring.plotName,
        'cultura': monitoring.cropName,
        'data': monitoring.date.toIso8601String(),
        'organismos_processados': <Map<String, dynamic>>[],
        'total_pontos': monitoring.points.length,
        'alertas_gerados': <Map<String, dynamic>>[],
      };

      // Processar cada ponto de monitoramento
      for (final point in monitoring.points) {
        await _processMonitoringPoint(point, monitoring, results);
      }

      // Salvar cache de integração
      await _saveIntegrationCache(results);

      Logger.info('✅ Processamento concluído: ${results['organismos_processados'].length} organismos processados');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro ao processar dados de monitoramento: $e');
      rethrow;
    }
  }

  /// Processa um ponto de monitoramento específico
  Future<void> _processMonitoringPoint(
    MonitoringPoint point, 
    Monitoring monitoring, 
    Map<String, dynamic> results
  ) async {
    try {
      // Processar cada ocorrência no ponto
      for (final occurrence in point.occurrences) {
        await _processOccurrence(occurrence, point, monitoring, results);
      }
    } catch (e) {
      Logger.error('❌ Erro ao processar ponto ${point.id}: $e');
    }
  }

  /// Processa uma ocorrência específica e integra com catálogo
  Future<void> _processOccurrence(
    Occurrence occurrence,
    MonitoringPoint point,
    Monitoring monitoring,
    Map<String, dynamic> results
  ) async {
    try {
      // 1. Buscar organismo no catálogo
      final organismData = await _findOrganismInCatalog(occurrence.name, monitoring.cropName);
      
      if (organismData == null) {
        Logger.warning('⚠️ Organismo não encontrado no catálogo: ${occurrence.name}');
        return;
      }

      // 2. Calcular nível de intensidade baseado no catálogo
      final intensityLevel = _calculateIntensityLevel(
        occurrence.infestationIndex,
        organismData,
        occurrence.type
      );

      // 3. Determinar cor do mapa baseada no nível
      final mapColor = _getMapColorForLevel(intensityLevel);

      // 4. Criar dados integrados
      final integratedData = {
        'organismo_id': organismData['id'],
        'organismo_nome': occurrence.name,
        'organismo_tipo': occurrence.type.toString().split('.').last,
        'nome_cientifico': organismData['nome_cientifico'],
        'quantidade_detectada': occurrence.infestationIndex,
        'unidade_medida': organismData['unidade'] ?? 'indivíduos/ponto',
        'nivel_intensidade': intensityLevel,
        'cor_mapa': mapColor,
        'limiar_baixo': organismData['limiar_baixo'],
        'limiar_medio': organismData['limiar_medio'],
        'limiar_alto': organismData['limiar_alto'],
        'limiar_critico': organismData['limiar_critico'],
        'latitude': point.latitude,
        'longitude': point.longitude,
        'secoes_afetadas': occurrence.affectedSections.map((s) => s.toString().split('.').last).toList(),
        'observacoes': occurrence.notes,
        'data_monitoramento': monitoring.date.toIso8601String(),
        'monitoring_id': monitoring.id,
        'monitoring_point_id': point.id,
        'cultura': monitoring.cropName,
        'talhao_id': monitoring.plotId.toString(),
        'talhao_nome': monitoring.plotName,
      };

      // 5. Adicionar aos resultados
      (results['organismos_processados'] as List).add(integratedData);

      // 6. Verificar se deve gerar alerta
      if (_shouldGenerateAlert(intensityLevel, occurrence.infestationIndex)) {
        final alertData = {
          'tipo': 'infestacao',
          'nivel': intensityLevel,
          'organismo': occurrence.name,
          'talhao': monitoring.plotName,
          'quantidade': occurrence.infestationIndex,
          'unidade': organismData['unidade'] ?? 'indivíduos/ponto',
          'cor': mapColor,
          'latitude': point.latitude,
          'longitude': point.longitude,
          'data': monitoring.date.toIso8601String(),
          'descricao': 'Nível $intensityLevel detectado para ${occurrence.name} (${occurrence.infestationIndex.toStringAsFixed(1)} ${organismData['unidade'] ?? 'indivíduos/ponto'})',
        };
        
        (results['alertas_gerados'] as List).add(alertData);
      }

      Logger.info('✅ Organismo processado: ${occurrence.name} - Nível: $intensityLevel - Cor: $mapColor');
      
    } catch (e) {
      Logger.error('❌ Erro ao processar ocorrência ${occurrence.name}: $e');
    }
  }

  /// Busca organismo no catálogo por nome e cultura
  Future<Map<String, dynamic>?> _findOrganismInCatalog(String organismName, String cropName) async {
    try {
      // Primeiro, tentar buscar no banco de dados
      final db = await _database.database;
      final results = await db.query(
        'organism_catalog',
        where: 'name LIKE ? AND crop_name = ?',
        whereArgs: ['%$organismName%', cropName],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return results.first;
      }

      // Se não encontrou no banco, buscar nos arquivos JSON
      return await _findOrganismInJsonFiles(organismName, cropName);
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar organismo no catálogo: $e');
      return null;
    }
  }

  /// Busca organismo nos arquivos JSON por cultura
  Future<Map<String, dynamic>?> _findOrganismInJsonFiles(String organismName, String cropName) async {
    try {
      // Mapear nome da cultura para arquivo JSON
      final cropFileMap = {
        'Soja': 'organismos_soja.json',
        'Milho': 'organismos_milho.json',
        'Algodão': 'organismos_algodao.json',
        'Feijão': 'organismos_feijao.json',
        'Trigo': 'organismos_trigo.json',
        'Girassol': 'organismos_girassol.json',
        'Sorgo': 'organismos_sorgo.json',
        'Gergelim': 'organismos_gergelim.json',
      };

      final fileName = cropFileMap[cropName];
      if (fileName == null) {
        Logger.warning('⚠️ Arquivo JSON não encontrado para cultura: $cropName');
        return null;
      }

      // Carregar e buscar no arquivo JSON
      final jsonData = await _loadJsonFile('lib/data/$fileName');
      if (jsonData == null) return null;

      // Buscar organismo no JSON
      final organisms = jsonData['organismos'] as List?;
      if (organisms == null) return null;

      for (final organism in organisms) {
        if (organism['nome']?.toString().toLowerCase().contains(organismName.toLowerCase()) == true) {
          // Converter formato JSON para formato do banco
          return {
            'id': organism['id'],
            'nome': organism['nome'],
            'nome_cientifico': organism['nome_cientifico'],
            'tipo': organism['categoria']?.toLowerCase(),
            'cultura_id': organism['cultura_id'],
            'cultura_nome': cropName,
            'unidade': _extractUnitFromJson(organism),
            'limiar_baixo': _extractThresholdFromJson(organism, 'baixo'),
            'limiar_medio': _extractThresholdFromJson(organism, 'medio'),
            'limiar_alto': _extractThresholdFromJson(organism, 'alto'),
            'limiar_critico': _extractThresholdFromJson(organism, 'critico'),
            'descricao': organism['dano_economico'],
            'ativo': organism['ativo'] ?? true,
          };
        }
      }

      return null;
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar organismo nos arquivos JSON: $e');
      return null;
    }
  }

  /// Carrega arquivo JSON
  Future<Map<String, dynamic>?> _loadJsonFile(String filePath) async {
    try {
      // Implementação simplificada - em produção, usar rootBundle
      // Por enquanto, retornar null para forçar uso do banco
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao carregar arquivo JSON: $e');
      return null;
    }
  }

  /// Extrai unidade de medida do JSON
  String _extractUnitFromJson(Map<String, dynamic> organism) {
    // Lógica para extrair unidade baseada nos dados do JSON
    final nivelAcao = organism['nivel_acao']?.toString() ?? '';
    
    if (nivelAcao.contains('%')) return 'porcentagem';
    if (nivelAcao.contains('m²')) return 'indivíduos/m²';
    if (nivelAcao.contains('metro')) return 'indivíduos/metro';
    if (nivelAcao.contains('planta')) return 'indivíduos/planta';
    if (nivelAcao.contains('folha')) return 'indivíduos/folha';
    
    return 'indivíduos/ponto';
  }

  /// Extrai limiar do JSON
  double _extractThresholdFromJson(Map<String, dynamic> organism, String level) {
    final nivelAcao = organism['nivel_acao']?.toString() ?? '';
    
    // Extrair números do nível de ação
    final numbers = RegExp(r'\d+').allMatches(nivelAcao).map((m) => int.parse(m.group(0)!)).toList();
    
    if (numbers.isEmpty) {
      // Valores padrão baseados no nível
      switch (level) {
        case 'baixo': return 5.0;
        case 'medio': return 15.0;
        case 'alto': return 30.0;
        case 'critico': return 50.0;
        default: return 25.0;
      }
    }
    
    // Usar o primeiro número encontrado como base
    final baseValue = numbers.first.toDouble();
    
    switch (level) {
      case 'baixo': return baseValue * 0.3;
      case 'medio': return baseValue * 0.6;
      case 'alto': return baseValue * 0.8;
      case 'critico': return baseValue;
      default: return baseValue * 0.5;
    }
  }

  /// Calcula nível de intensidade baseado no catálogo
  String _calculateIntensityLevel(double infestationIndex, Map<String, dynamic> organismData, OccurrenceType type) {
    final lowThreshold = (organismData['limiar_baixo'] as num?)?.toDouble() ?? 5.0;
    final mediumThreshold = (organismData['limiar_medio'] as num?)?.toDouble() ?? 15.0;
    final highThreshold = (organismData['limiar_alto'] as num?)?.toDouble() ?? 30.0;
    final criticalThreshold = (organismData['limiar_critico'] as num?)?.toDouble() ?? 50.0;

    // Aplicar multiplicadores por tipo de organismo
    double adjustedIndex = infestationIndex;
    switch (type) {
      case OccurrenceType.pest:
        adjustedIndex *= 1.0; // Pragas: multiplicador padrão
        break;
      case OccurrenceType.disease:
        adjustedIndex *= 1.2; // Doenças: mais críticas
        break;
      case OccurrenceType.weed:
        adjustedIndex *= 0.8; // Plantas daninhas: menos críticas
        break;
      case OccurrenceType.deficiency:
        adjustedIndex *= 1.1; // Deficiências: moderadamente críticas
        break;
      case OccurrenceType.other:
        adjustedIndex *= 1.0; // Outros: multiplicador padrão
        break;
    }

    // Determinar nível baseado nos limiares
    if (adjustedIndex <= lowThreshold) {
      return 'BAIXO';
    } else if (adjustedIndex <= mediumThreshold) {
      return 'MODERADO';
    } else if (adjustedIndex <= highThreshold) {
      return 'ALTO';
    } else if (adjustedIndex <= criticalThreshold) {
      return 'ALTO';
    } else {
      return 'CRITICO';
    }
  }

  /// Determina cor do mapa baseada no nível de intensidade
  String _getMapColorForLevel(String level) {
    switch (level) {
      case 'BAIXO':
        return '#4CAF50'; // Verde
      case 'MODERADO':
        return '#FFC107'; // Amarelo
      case 'ALTO':
        return '#FF9800'; // Laranja
      case 'CRITICO':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Verifica se deve gerar alerta
  bool _shouldGenerateAlert(String level, double infestationIndex) {
    return level == 'ALTO' || level == 'CRITICO' || infestationIndex > 25.0;
  }

  /// Salva cache de integração
  Future<void> _saveIntegrationCache(Map<String, dynamic> results) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().toIso8601String();
      
      for (final organism in results['organismos_processados'] as List) {
        await db.insert(
          _tableName,
          {
            'id': '${organism['monitoring_id']}_${organism['monitoring_point_id']}_${organism['organismo_id']}',
            'talhao_id': organism['talhao_id'],
            'organismo_id': organism['organismo_id'],
            'organismo_nome': organism['organismo_nome'],
            'organismo_tipo': organism['organismo_tipo'],
            'quantidade_detectada': organism['quantidade_detectada'],
            'unidade_medida': organism['unidade_medida'],
            'nivel_intensidade': organism['nivel_intensidade'],
            'cor_mapa': organism['cor_mapa'],
            'data_monitoramento': organism['data_monitoramento'],
            'monitoring_id': organism['monitoring_id'],
            'monitoring_point_id': organism['monitoring_point_id'],
            'latitude': organism['latitude'],
            'longitude': organism['longitude'],
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      Logger.info('✅ Cache de integração salvo com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao salvar cache de integração: $e');
    }
  }

  /// Obtém dados integrados para o mapa de infestação
  Future<List<Map<String, dynamic>>> getInfestationMapData({
    String? talhaoId,
    String? organismoId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final db = await _database.database;
      
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND organismo_id = ?';
        whereArgs.add(organismoId);
      }
      
      if (fromDate != null) {
        whereClause += ' AND data_monitoramento >= ?';
        whereArgs.add(fromDate.toIso8601String());
      }
      
      if (toDate != null) {
        whereClause += ' AND data_monitoramento <= ?';
        whereArgs.add(toDate.toIso8601String());
      }
      
      final results = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data_monitoramento DESC',
      );
      
      Logger.info('✅ Dados do mapa de infestação obtidos: ${results.length} registros');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter dados do mapa de infestação: $e');
      return [];
    }
  }

  /// Obtém estatísticas de infestação por talhão
  Future<Map<String, dynamic>> getInfestationStatistics(String talhaoId) async {
    try {
      final db = await _database.database;
      
      final results = await db.rawQuery('''
        SELECT 
          organismo_nome,
          organismo_tipo,
          nivel_intensidade,
          COUNT(*) as total_ocorrencias,
          AVG(quantidade_detectada) as media_quantidade,
          MAX(data_monitoramento) as ultima_ocorrencia,
          cor_mapa
        FROM $_tableName 
        WHERE talhao_id = ?
        GROUP BY organismo_id, nivel_intensidade
        ORDER BY total_ocorrencias DESC
      ''', [talhaoId]);
      
      final statistics = {
        'talhao_id': talhaoId,
        'total_organismos': results.length,
        'organismos_por_nivel': <String, int>{},
        'organismos_por_tipo': <String, int>{},
        'detalhes': results,
      };
      
      // Calcular estatísticas agregadas
      for (final result in results) {
        final nivel = result['nivel_intensidade'] as String;
        final tipo = result['organismo_tipo'] as String;
        
        (statistics['organismos_por_nivel'] as Map<String, dynamic>)[nivel] = 
            ((statistics['organismos_por_nivel'] as Map<String, dynamic>)[nivel] ?? 0) + 1;
        (statistics['organismos_por_tipo'] as Map<String, dynamic>)[tipo] = 
            ((statistics['organismos_por_tipo'] as Map<String, dynamic>)[tipo] ?? 0) + 1;
      }
      
      Logger.info('✅ Estatísticas de infestação obtidas para talhão: $talhaoId');
      return statistics;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de infestação: $e');
      return {'talhao_id': talhaoId, 'erro': e.toString()};
    }
  }

  /// Limpa cache antigo
  Future<void> cleanOldCache({int daysOld = 30}) async {
    try {
      final db = await _database.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final deleted = await db.delete(
        _tableName,
        where: 'created_at < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      Logger.info('✅ Cache antigo limpo: $deleted registros removidos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar cache antigo: $e');
    }
  }
}

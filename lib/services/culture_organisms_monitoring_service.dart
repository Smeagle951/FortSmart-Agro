import '../database/app_database.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';
import 'cultura_service.dart';

/// Serviço para buscar organismos EXCLUSIVAMENTE do módulo culturas da fazenda
/// NÃO utiliza o catálogo de organismos (que é exclusivo do módulo mapa de infestação)
/// Busca apenas da tabela 'organismos' do módulo culturas
class CultureOrganismsMonitoringService {
  static const String _tag = 'CultureOrganismsMonitoringService';
  final AppDatabase _database = AppDatabase();
  final CulturaService _culturaService = CulturaService();

  /// Obtém o nome real da cultura pelo ID
  Future<String> getCultureNameById(String culturaId) async {
    try {
      final cultura = await _culturaService.loadCulturaById(culturaId);
      if (cultura != null) {
        Logger.info('$_tag: Nome da cultura encontrado: ${cultura.name}');
        return cultura.name;
      }
      
      Logger.warning('$_tag: Cultura não encontrada para ID: $culturaId');
      return 'Cultura $culturaId';
    } catch (e) {
      Logger.error('$_tag: Erro ao obter nome da cultura: $e');
      return 'Cultura $culturaId';
    }
  }

  /// Busca organismos por cultura e tipo específico
  /// Usado no monitoramento para carregar opções de infestação
  Future<List<OrganismInfo>> getOrganismsByCultureAndType({
    required String culturaId,
    String? culturaNome, // Opcional - será obtido automaticamente se não fornecido
    required OccurrenceType tipo,
  }) async {
    try {
      // Obter nome real da cultura se não fornecido
      final nomeReal = culturaNome ?? await getCultureNameById(culturaId);
      Logger.info('$_tag: Buscando organismos para $nomeReal ($culturaId) - Tipo: ${tipo.name}');
      
      final db = await _database.database;
      
      // Buscar APENAS na tabela de organismos do módulo culturas da fazenda
      // O catálogo de organismos é exclusivo do módulo mapa de infestação
      Logger.info('$_tag: Buscando organismos do módulo culturas da fazenda');
      
      final organismosResult = await db.query(
        'organismos',
        where: 'tipo = ?',
        whereArgs: [tipo.name.toUpperCase()],
        orderBy: 'nomeComum ASC',
      );

      if (organismosResult.isNotEmpty) {
        final organisms = organismosResult.map((org) => OrganismInfo(
          id: org['id'].toString(),
          nome: (org['nomeComum'] ?? 'Organismo ${org['id']}').toString(),
          nomeCientifico: org['nomeCientifico']?.toString(),
          tipo: tipo,
          culturaId: culturaId,
          culturaNome: nomeReal,
          descricao: org['sintomaDescricao']?.toString(),
          categoria: org['categoria']?.toString(),
        )).toList();
        
        Logger.info('$_tag: Encontrados ${organisms.length} organismos do módulo culturas para $nomeReal');
        return organisms;
      }

      // Se não encontrou organismos
      Logger.warning('$_tag: Nenhum organismo encontrado no módulo culturas para $nomeReal ($culturaId) - Tipo: ${tipo.name}');
      return [];

    } catch (e) {
      Logger.error('$_tag: Erro ao buscar organismos: $e');
      return [];
    }
  }

  /// Busca organismos por cultura (todos os tipos) - APENAS do módulo culturas
  Future<List<OrganismInfo>> getAllOrganismsByCulture({
    required String culturaId,
    String? culturaNome, // Opcional - será obtido automaticamente
  }) async {
    try {
      final allOrganisms = <OrganismInfo>[];
      
      // Buscar para cada tipo do módulo culturas da fazenda
      for (final tipo in [OccurrenceType.pest, OccurrenceType.disease, OccurrenceType.weed]) {
        final organisms = await getOrganismsByCultureAndType(
          culturaId: culturaId,
          culturaNome: culturaNome,
          tipo: tipo,
        );
        allOrganisms.addAll(organisms);
      }
      
      final nomeReal = culturaNome ?? await getCultureNameById(culturaId);
      Logger.info('$_tag: Encontrados ${allOrganisms.length} organismos do módulo culturas para $nomeReal');
      return allOrganisms;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar todos os organismos: $e');
      return [];
    }
  }

  /// Busca organismos por tipo (todas as culturas) - APENAS do módulo culturas
  Future<List<OrganismInfo>> getOrganismsByType(OccurrenceType tipo) async {
    try {
      final db = await _database.database;
      
      // Buscar APENAS na tabela de organismos do módulo culturas
      final result = await db.query(
        'organismos',
        where: 'tipo = ?',
        whereArgs: [tipo.name.toUpperCase()],
        orderBy: 'nomeComum ASC',
      );

      return result.map((org) => OrganismInfo(
        id: org['id'].toString(),
        nome: (org['nomeComum'] ?? 'Organismo ${org['id']}').toString(),
        nomeCientifico: org['nomeCientifico']?.toString(),
        tipo: tipo,
        culturaId: '0', // Não há cultura específica nesta busca
        culturaNome: 'Módulo Culturas',
        descricao: org['sintomaDescricao']?.toString(),
        categoria: org['categoria']?.toString(),
      )).toList();

    } catch (e) {
      Logger.error('$_tag: Erro ao buscar organismos por tipo: $e');
      return [];
    }
  }

  /// Busca organismos por nome (busca inteligente) - APENAS do módulo culturas
  Future<List<OrganismInfo>> searchOrganisms({
    required String query,
    String? culturaId,
    OccurrenceType? tipo,
  }) async {
    try {
      final db = await _database.database;
      
      // Buscar APENAS na tabela de organismos do módulo culturas
      String whereClause = 'nomeComum LIKE ? OR nomeCientifico LIKE ?';
      List<dynamic> whereArgs = ['%$query%', '%$query%'];
      
      if (tipo != null) {
        whereClause += ' AND tipo = ?';
        whereArgs.add(tipo.name.toUpperCase());
      }
      
      final result = await db.query(
        'organismos',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'nomeComum ASC',
      );

      final culturaNome = culturaId != null ? await getCultureNameById(culturaId) : 'Módulo Culturas';
      
      return result.map((org) => OrganismInfo(
        id: org['id'].toString(),
        nome: (org['nomeComum'] ?? 'Organismo ${org['id']}').toString(),
        nomeCientifico: org['nomeCientifico']?.toString(),
        tipo: _parseOccurrenceType(org['tipo']),
        culturaId: culturaId ?? '0',
        culturaNome: culturaNome,
        descricao: org['sintomaDescricao']?.toString(),
        categoria: org['categoria']?.toString(),
      )).toList();

    } catch (e) {
      Logger.error('$_tag: Erro na busca inteligente: $e');
      return [];
    }
  }

  /// Converte string para OccurrenceType
  OccurrenceType _parseOccurrenceType(dynamic type) {
    if (type == null) return OccurrenceType.pest;
    
    final typeStr = type.toString().toLowerCase();
    switch (typeStr) {
      case 'pest':
      case 'praga':
        return OccurrenceType.pest;
      case 'disease':
      case 'doenca':
        return OccurrenceType.disease;
      case 'weed':
      case 'daninha':
        return OccurrenceType.weed;
      default:
        return OccurrenceType.pest;
    }
  }
}

/// Modelo de informação de organismo para o monitoramento
class OrganismInfo {
  final String id;
  final String nome;
  final String? nomeCientifico;
  final OccurrenceType tipo;
  final String culturaId;
  final String culturaNome;
  final String? descricao;
  final String? categoria;

  OrganismInfo({
    required this.id,
    required this.nome,
    this.nomeCientifico,
    required this.tipo,
    required this.culturaId,
    required this.culturaNome,
    this.descricao,
    this.categoria,
  });

  /// Obtém o ícone baseado no tipo
  String get icon {
    switch (tipo) {
      case OccurrenceType.pest:
        return '🐛';
      case OccurrenceType.disease:
        return '🦠';
      case OccurrenceType.weed:
        return '🌿';
      case OccurrenceType.deficiency:
        return '🌱';
      case OccurrenceType.other:
        return '❓';
    }
  }

  /// Obtém a cor baseada no tipo
  String get color {
    switch (tipo) {
      case OccurrenceType.pest:
        return '#27AE60'; // Verde
      case OccurrenceType.disease:
        return '#F2C94C'; // Amarelo
      case OccurrenceType.weed:
        return '#2D9CDB'; // Azul
      case OccurrenceType.deficiency:
        return '#9B59B6'; // Roxo
      case OccurrenceType.other:
        return '#95A5A6'; // Cinza
    }
  }

  /// Obtém o nome completo (comum + científico se disponível)
  String get fullName {
    if (nomeCientifico != null && nomeCientifico!.isNotEmpty) {
      return '$nome ($nomeCientifico)';
    }
    return nome;
  }

  @override
  String toString() => 'OrganismInfo(id: $id, nome: $nome, tipo: ${tipo.name}, cultura: $culturaNome)';
}

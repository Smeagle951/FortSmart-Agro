import '../database/app_database.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';
import 'package:sqflite/sqflite.dart';

/// Modelo de organismo do catálogo
class OrganismCatalogItem {
  final int id;
  final String nome;
  final String? nomeCientifico;
  final OccurrenceType tipo;
  final String culturaId;
  final String culturaNome;
  final String unidade;
  final int baseDenominador;
  final double limiarBaixo;
  final double limiarMedio;
  final double limiarAlto;
  final double limiarCritico;
  final String? descricao;
  final String? imagemUrl;
  final bool ativo;
  final String version;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrganismCatalogItem({
    required this.id,
    required this.nome,
    this.nomeCientifico,
    required this.tipo,
    required this.culturaId,
    required this.culturaNome,
    required this.unidade,
    required this.baseDenominador,
    required this.limiarBaixo,
    required this.limiarMedio,
    required this.limiarAlto,
    required this.limiarCritico,
    this.descricao,
    this.imagemUrl,
    required this.ativo,
    required this.version,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrganismCatalogItem.fromMap(Map<String, dynamic> map) {
    return OrganismCatalogItem(
      id: map['id'],
      nome: map['nome'],
      nomeCientifico: map['nome_cientifico'],
      tipo: _parseOccurrenceType(map['tipo']),
      culturaId: map['cultura_id'],
      culturaNome: map['cultura_nome'],
      unidade: map['unidade'],
      baseDenominador: map['base_denominador'] ?? 1,
      limiarBaixo: map['limiar_baixo']?.toDouble() ?? 0.0,
      limiarMedio: map['limiar_medio']?.toDouble() ?? 0.0,
      limiarAlto: map['limiar_alto']?.toDouble() ?? 0.0,
      limiarCritico: map['limiar_critico']?.toDouble() ?? 0.0,
      descricao: map['descricao'],
      imagemUrl: map['imagem_url'],
      ativo: map['ativo'] == 1,
      version: map['version'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'nome_cientifico': nomeCientifico,
      'tipo': tipo.toString().split('.').last,
      'cultura_id': culturaId,
      'cultura_nome': culturaNome,
      'unidade': unidade,
      'base_denominador': baseDenominador,
      'limiar_baixo': limiarBaixo,
      'limiar_medio': limiarMedio,
      'limiar_alto': limiarAlto,
      'limiar_critico': limiarCritico,
      'descricao': descricao,
      'imagem_url': imagemUrl,
      'ativo': ativo ? 1 : 0,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Determina o nível de alerta baseado na quantidade
  String getAlertLevel(double quantidade) {
    if (quantidade <= limiarBaixo) return 'baixo';
    if (quantidade <= limiarMedio) return 'medio';
    if (quantidade <= limiarAlto) return 'alto';
    if (quantidade <= limiarCritico) return 'alto';
    return 'critico';
  }

  /// Normaliza um valor bruto baseado na unidade
  double normalizeValue(double valorBruto, int plantasAvaliadas) {
    switch (unidade) {
      case "individuos/10_plantas":
        final plantas = plantasAvaliadas > 0 ? plantasAvaliadas : 10;
        return (valorBruto / plantas) * baseDenominador;
        
      case "individuos/planta":
        final plantas = plantasAvaliadas > 0 ? plantasAvaliadas : 1;
        return valorBruto / plantas;
        
      case "percent_folha":
      case "percent_plantas":
        return valorBruto.clamp(0.0, 100.0);
        
      case "armadilha_24h":
      case "individuos/m2":
        return valorBruto;
        
      default:
        return valorBruto;
    }
  }
}

/// Converte string para OccurrenceType
OccurrenceType _parseOccurrenceType(String? type) {
  switch (type?.toLowerCase()) {
    case 'pest':
      return OccurrenceType.pest;
    case 'disease':
      return OccurrenceType.disease;
    case 'weed':
      return OccurrenceType.weed;
    case 'deficiency':
      return OccurrenceType.deficiency;
    case 'other':
      return OccurrenceType.other;
    default:
      return OccurrenceType.pest;
  }
}

/// Serviço de Catálogo de Organismos
/// Gerencia o catálogo de pragas, doenças e plantas daninhas
/// Fonte de verdade para unidades, limiares e versões
class OrganismCatalogService {
  static const String _tag = 'OrganismCatalogService';
  final AppDatabase _database = AppDatabase();
  
  // Cache offline
  List<Map<String, dynamic>>? _cachedOrganisms;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidity = Duration(hours: 24);

  /// Verifica se o cache é válido
  bool _isCacheValid() {
    if (_cachedOrganisms == null || _lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidity;
  }

  /// Atualiza o cache
  Future<void> _updateCache() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'organism_catalog',
        where: 'ativo = 1',
        orderBy: 'nome ASC',
      );
      
      _cachedOrganisms = result;
      _lastCacheUpdate = DateTime.now();
      Logger.info('$_tag: Cache atualizado com ${result.length} organismos');
    } catch (e) {
      Logger.error('$_tag: Erro ao atualizar cache: $e');
    }
  }

  /// Limpa o cache
  void clearCache() {
    _cachedOrganisms = null;
    _lastCacheUpdate = null;
    Logger.info('$_tag: Cache limpo');
  }

  /// Obtém todos os organismos ativos (com cache)
  Future<List<Map<String, dynamic>>> getAllOrganisms() async {
    try {
      // Verificar cache primeiro
      if (_isCacheValid() && _cachedOrganisms != null) {
        Logger.info('$_tag: Retornando ${_cachedOrganisms!.length} organismos do cache');
        return _cachedOrganisms!;
      }
      
      // Atualizar cache se necessário
      await _updateCache();
      
      return _cachedOrganisms ?? [];
    } catch (e) {
      Logger.error('$_tag: Erro ao obter organismos: $e');
      return [];
    }
  }

  /// Obtém organismos por cultura
  Future<List<Map<String, dynamic>>> getOrganismsByCrop(String culturaId) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'organism_catalog',
        where: 'cultura_id = ? AND ativo = 1',
        whereArgs: [culturaId],
        orderBy: 'tipo ASC, nome ASC',
      );
      
      return result;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter organismos por cultura: $e');
      return [];
    }
  }

  /// Obtém organismos por tipo
  Future<List<Map<String, dynamic>>> getOrganismsByType(String tipo) async {
    try {
      final db = await _database.database;
      
      final result = await db.query(
        'organism_catalog',
        where: 'tipo = ? AND ativo = 1',
        whereArgs: [tipo],
        orderBy: 'nome ASC',
      );
      
      return result;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter organismos por tipo: $e');
      return [];
    }
  }

  /// Obtém organismos por cultura e tipo
  Future<List<Map<String, dynamic>>> getOrganismsByCropAndType(String culturaId, String tipo) async {
    try {
      final db = await _database.database;
      
      final result = await db.query(
        'organism_catalog',
        where: 'cultura_id = ? AND tipo = ? AND ativo = 1',
        whereArgs: [culturaId, tipo],
        orderBy: 'nome ASC',
      );
      
      return result;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter organismos por cultura e tipo: $e');
      return [];
    }
  }

  /// Busca organismos por nome
  Future<List<Map<String, dynamic>>> searchOrganisms(String query) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'organism_catalog',
        where: 'ativo = 1 AND (nome LIKE ? OR nome_cientifico LIKE ?)',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'nome ASC',
      );
      
      return result;
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar organismos: $e');
      return [];
    }
  }

  /// Obtém um organismo específico por ID
  Future<Map<String, dynamic>?> getOrganismById(int id) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'organism_catalog',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter organismo por ID: $e');
      return null;
    }
  }

  /// Obtém a versão atual do catálogo
  Future<String> getCurrentVersion() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery('''
        SELECT version FROM catalog_organisms 
        ORDER BY updated_at DESC 
        LIMIT 1
      ''');
      
      return result.isNotEmpty ? (result.first['version']?.toString() ?? '1.0.0') : '1.0.0';
    } catch (e) {
      Logger.error('$_tag: Erro ao obter versão do catálogo: $e');
      return '1.0.0';
    }
  }

  /// Adiciona um novo organismo ao catálogo
  Future<bool> addOrganism(Map<String, dynamic> organism) async {
    try {
      final db = await _database.database;
      await db.insert(
        'organism_catalog',
        organism,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('$_tag: Organismo adicionado: ${organism['nome']}');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao adicionar organismo: $e');
      return false;
    }
  }

  /// Atualiza um organismo existente
  Future<bool> updateOrganism(Map<String, dynamic> organism) async {
    try {
      final db = await _database.database;
      final updatedMap = Map<String, dynamic>.from(organism);
      updatedMap['updated_at'] = DateTime.now().toIso8601String();
      
      await db.update(
        'organism_catalog',
        updatedMap,
        where: 'id = ?',
        whereArgs: [organism['id']],
      );
      
      Logger.info('$_tag: Organismo atualizado: ${organism['nome']}');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao atualizar organismo: $e');
      return false;
    }
  }

  /// Remove um organismo (desativa)
  Future<bool> deactivateOrganism(int id) async {
    try {
      final db = await _database.database;
      await db.update(
        'organism_catalog',
        {
          'ativo': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('$_tag: Organismo desativado: $id');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao desativar organismo: $e');
      return false;
    }
  }

  /// Obtém estatísticas do catálogo
  Future<Map<String, dynamic>> getCatalogStats() async {
    try {
      final db = await _database.database;
      
      // Total de organismos
      final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM organism_catalog WHERE ativo = 1');
      final total = totalResult.first['total'] ?? 0;
      
      // Por tipo
      final pestResult = await db.rawQuery('SELECT COUNT(*) as count FROM organism_catalog WHERE tipo = "pest" AND ativo = 1');
      final diseaseResult = await db.rawQuery('SELECT COUNT(*) as count FROM organism_catalog WHERE tipo = "disease" AND ativo = 1');
      final weedResult = await db.rawQuery('SELECT COUNT(*) as count FROM organism_catalog WHERE tipo = "weed" AND ativo = 1');
      
      // Por cultura
      final cropResult = await db.rawQuery('''
        SELECT cultura_id, COUNT(*) as count 
        FROM organism_catalog 
        WHERE ativo = 1 
        GROUP BY cultura_id
      ''');
      
      return {
        'total': total,
        'by_type': {
          'pest': pestResult.first['count'] ?? 0,
          'disease': diseaseResult.first['count'] ?? 0,
          'weed': weedResult.first['count'] ?? 0,
        },
        'by_crop': Map.fromEntries(
          cropResult.map((row) => MapEntry(row['cultura_id'], row['count']))
        ),
        'version': await getCurrentVersion(),
      };
    } catch (e) {
      Logger.error('$_tag: Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Valida se um organismo existe e está ativo
  Future<bool> validateOrganism(int organismId) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'organism_catalog',
        columns: ['id'],
        where: 'id = ? AND ativo = 1',
        whereArgs: [organismId],
      );
      
      return result.isNotEmpty;
    } catch (e) {
      Logger.error('$_tag: Erro ao validar organismo: $e');
      return false;
    }
  }

  /// Obtém sugestões de organismos baseado em texto
  Future<List<String>> getOrganismSuggestions(String query, {String? culturaId, OccurrenceType? tipo}) async {
    try {
      final organisms = await searchOrganisms(query);
      
      if (culturaId != null) {
        organisms.removeWhere((org) => org['cultura_id'] != culturaId);
      }
      
      if (tipo != null) {
        organisms.removeWhere((org) => org['tipo'] != tipo);
      }
      
      return organisms.map((org) => org['nome']?.toString() ?? '').toList();
    } catch (e) {
      Logger.error('$_tag: Erro ao obter sugestões: $e');
      return [];
    }
  }

  /// Converte string para OccurrenceType
  static OccurrenceType _parseOccurrenceType(String? type) {
    switch (type?.toLowerCase()) {
      case 'pest':
        return OccurrenceType.pest;
      case 'disease':
        return OccurrenceType.disease;
      case 'weed':
        return OccurrenceType.weed;
      case 'deficiency':
        return OccurrenceType.deficiency;
      case 'other':
        return OccurrenceType.other;
      default:
        return OccurrenceType.pest;
    }
  }

  /// Inicializa o catálogo com dados padrão se estiver vazio
  Future<void> initializeDefaultCatalog() async {
    try {
      final db = await _database.database;
      
      // Verificar se já existem dados
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM organism_catalog');
      if (count.first['count'] == 0) {
        Logger.info('$_tag: Inicializando catálogo com dados reais...');
        
        // Dados reais para diferentes culturas
        final defaultOrganisms = [
          // SOJA - Pragas
          {
            'nome': 'Lagarta-da-soja',
            'nome_cientifico': 'Anticarsia gemmatalis',
            'tipo': 'pest',
            'cultura_id': 'soja',
            'cultura_nome': 'Soja',
            'unidade': 'individuos/10_plantas',
            'base_denominador': 10,
            'limiar_baixo': 2,
            'limiar_medio': 5,
            'limiar_alto': 10,
            'limiar_critico': 20,
            'descricao': 'Lagarta que ataca as folhas da soja',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'nome': 'Bicudo-do-algodoeiro',
            'nome_cientifico': 'Anthonomus grandis',
            'tipo': 'pest',
            'cultura_id': 'algodao',
            'cultura_nome': 'Algodão',
            'unidade': 'individuos/10_plantas',
            'base_denominador': 10,
            'limiar_baixo': 1,
            'limiar_medio': 3,
            'limiar_alto': 5,
            'limiar_critico': 10,
            'descricao': 'Praga principal do algodoeiro',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'nome': 'Lagarta-do-cartucho',
            'nome_cientifico': 'Spodoptera frugiperda',
            'tipo': 'pest',
            'cultura_id': 'milho',
            'cultura_nome': 'Milho',
            'unidade': 'individuos/10_plantas',
            'base_denominador': 10,
            'limiar_baixo': 2,
            'limiar_medio': 5,
            'limiar_alto': 10,
            'limiar_critico': 20,
            'descricao': 'Lagarta que ataca o cartucho do milho',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          
          // SOJA - Doenças
          {
            'nome': 'Ferrugem Asiática',
            'nome_cientifico': 'Phakopsora pachyrhizi',
            'tipo': 'disease',
            'cultura_id': 'soja',
            'cultura_nome': 'Soja',
            'unidade': 'percent_folha',
            'base_denominador': 1,
            'limiar_baixo': 5,
            'limiar_medio': 15,
            'limiar_alto': 30,
            'limiar_critico': 50,
            'descricao': 'Doença fúngica que afeta as folhas da soja',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'nome': 'Mancha-alvo',
            'nome_cientifico': 'Corynespora cassiicola',
            'tipo': 'disease',
            'cultura_id': 'soja',
            'cultura_nome': 'Soja',
            'unidade': 'percent_folha',
            'base_denominador': 1,
            'limiar_baixo': 10,
            'limiar_medio': 25,
            'limiar_alto': 40,
            'limiar_critico': 60,
            'descricao': 'Doença fúngica que causa manchas nas folhas',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          
          // SOJA - Plantas Daninhas
          {
            'nome': 'Buva',
            'nome_cientifico': 'Conyza bonariensis',
            'tipo': 'weed',
            'cultura_id': 'soja',
            'cultura_nome': 'Soja',
            'unidade': 'plantas/m2',
            'base_denominador': 1,
            'limiar_baixo': 2,
            'limiar_medio': 5,
            'limiar_alto': 10,
            'limiar_critico': 20,
            'descricao': 'Planta daninha resistente a herbicidas',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'nome': 'Capim-amargoso',
            'nome_cientifico': 'Digitaria insularis',
            'tipo': 'weed',
            'cultura_id': 'soja',
            'cultura_nome': 'Soja',
            'unidade': 'plantas/m2',
            'base_denominador': 1,
            'limiar_baixo': 1,
            'limiar_medio': 3,
            'limiar_alto': 5,
            'limiar_critico': 10,
            'descricao': 'Planta daninha perene e resistente',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          
          // MILHO - Pragas
          {
            'nome': 'Percevejo-barriga-verde',
            'nome_cientifico': 'Dichelops melacanthus',
            'tipo': 'pest',
            'cultura_id': 'milho',
            'cultura_nome': 'Milho',
            'unidade': 'individuos/10_plantas',
            'base_denominador': 10,
            'limiar_baixo': 1,
            'limiar_medio': 2,
            'limiar_alto': 4,
            'limiar_critico': 8,
            'descricao': 'Percevejo que ataca o milho',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
          
          // ALGODÃO - Doenças
          {
            'nome': 'Ramulose',
            'nome_cientifico': 'Colletotrichum gossypii',
            'tipo': 'disease',
            'cultura_id': 'algodao',
            'cultura_nome': 'Algodão',
            'unidade': 'percent_folha',
            'base_denominador': 1,
            'limiar_baixo': 5,
            'limiar_medio': 15,
            'limiar_alto': 30,
            'limiar_critico': 50,
            'descricao': 'Doença fúngica do algodoeiro',
            'ativo': 1,
            'version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];
        
        final batch = db.batch();
        for (final organism in defaultOrganisms) {
          batch.insert('organism_catalog', organism);
        }
        await batch.commit();
        
        Logger.info('$_tag: ✅ Catálogo inicializado com ${defaultOrganisms.length} organismos reais');
      }
    } catch (e) {
      Logger.error('$_tag: Erro ao inicializar catálogo: $e');
    }
  }
}

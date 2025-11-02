import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhoes/talhao_safra_model.dart';
import '../utils/logger.dart';

/// Serviço limpo e moderno para persistência de talhões
class NovaTalhaoService {
  static final NovaTalhaoService _instance = NovaTalhaoService._internal();
  factory NovaTalhaoService() => _instance;
  NovaTalhaoService._internal();

  Database? _database;
  static const String _databaseName = 'nova_talhoes.db';
  static const int _databaseVersion = 1;

  // ===== INICIALIZAÇÃO =====

  /// Inicializa o banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa o banco de dados
  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      Logger.error('❌ Erro ao inicializar banco de dados: $e');
      rethrow;
    }
  }

  /// Cria as tabelas do banco
  Future<void> _onCreate(Database db, int version) async {
    try {
      // Tabela de talhões
      await db.execute('''
        CREATE TABLE talhao_safra (
          id TEXT PRIMARY KEY,
          nome TEXT NOT NULL,
          cultura_id TEXT,
          pontos TEXT NOT NULL,
          area REAL NOT NULL,
          perimetro REAL NOT NULL,
          data_criacao TEXT NOT NULL,
          data_atualizacao TEXT,
          ativo INTEGER NOT NULL DEFAULT 1,
          observacoes TEXT,
          cor_cultura TEXT,
          safra_id TEXT,
          fazenda_id TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // Tabela de culturas
      await db.execute('''
        CREATE TABLE culturas (
          id TEXT PRIMARY KEY,
          nome TEXT NOT NULL,
          descricao TEXT,
          cor TEXT NOT NULL,
          icone TEXT,
          ativo INTEGER NOT NULL DEFAULT 1,
          data_criacao TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // Índices para performance
      await db.execute('CREATE INDEX idx_talhao_safra_cultura ON talhao_safra(cultura_id)');
      await db.execute('CREATE INDEX idx_talhao_safra_ativo ON talhao_safra(ativo)');
      await db.execute('CREATE INDEX idx_talhao_safra_data ON talhao_safra(data_criacao)');
      await db.execute('CREATE INDEX idx_culturas_ativo ON culturas(ativo)');

      Logger.info('✅ Banco de dados criado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao criar tabelas: $e');
      rethrow;
    }
  }

  /// Atualiza o banco de dados
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migrações futuras aqui
    Logger.info('🔄 Atualizando banco de dados de $oldVersion para $newVersion');
  }

  // ===== OPERAÇÕES DE TALHÕES =====

  /// Salva um talhão
  Future<String> salvarTalhao(TalhaoSafraModel talhao) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final talhaoMap = {
        'id': talhao.id,
        'nome': talhao.nome,
        'cultura_id': '1', // talhao.culturaId,
        'pontos': _pontosToJson(talhao.pontos),
        'area': talhao.area,
        'perimetro': 0, // talhao.perimetro,
        'data_criacao': talhao.dataCriacao.toIso8601String(),
        'data_atualizacao': talhao.dataAtualizacao?.toIso8601String(),
        'ativo': 1, // talhao.ativo ? 1 : 0,
        'observacoes': null, // talhao.observacoes,
        'cor_cultura': talhao.corCultura.value.toRadixString(16),
        'safra_id': '2024/2025', // talhao.safraId,
        'fazenda_id': '1', // talhao.fazendaId,
        'created_at': now,
        'updated_at': now,
      };

      await db.insert(
        'talhao_safra',
        talhaoMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      Logger.info('✅ Talhão salvo: ${talhao.nome}');
      return talhao.id;
    } catch (e) {
      Logger.error('❌ Erro ao salvar talhão: $e');
      rethrow;
    }
  }

  /// Carrega todos os talhões
  Future<List<TalhaoSafraModel>> carregarTalhoes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'talhao_safra',
        where: 'ativo = ?',
        whereArgs: [1],
        orderBy: 'data_criacao DESC',
      );

      List<TalhaoSafraModel> talhoes = maps.map((map) => _mapToTalhao(map)).toList();
      
      Logger.info('✅ Talhões carregados: ${talhoes.length}');
      return talhoes;
    } catch (e) {
      Logger.error('❌ Erro ao carregar talhões: $e');
      rethrow;
    }
  }

  /// Carrega talhão por ID
  Future<TalhaoSafraModel?> carregarTalhaoPorId(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'talhao_safra',
        where: 'id = ? AND ativo = ?',
        whereArgs: [id, 1],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      
      return _mapToTalhao(maps.first);
    } catch (e) {
      Logger.error('❌ Erro ao carregar talhão por ID: $e');
      rethrow;
    }
  }

  /// Atualiza um talhão
  Future<bool> atualizarTalhao(TalhaoSafraModel talhao) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final talhaoMap = {
        'nome': talhao.nome,
        'cultura_id': '1', // talhao.culturaId,
        'pontos': _pontosToJson(talhao.pontos),
        'area': talhao.area,
        'perimetro': 0, // talhao.perimetro,
        'data_atualizacao': now,
        'observacoes': null, // talhao.observacoes,
        'cor_cultura': talhao.corCultura.value.toRadixString(16),
        'safra_id': '2024/2025', // talhao.safraId,
        'fazenda_id': '1', // talhao.fazendaId,
        'updated_at': now,
      };

      int count = await db.update(
        'talhao_safra',
        talhaoMap,
        where: 'id = ?',
        whereArgs: [talhao.id],
      );

      bool success = count > 0;
      if (success) {
        Logger.info('✅ Talhão atualizado: ${talhao.nome}');
      } else {
        Logger.warning('⚠️ Talhão não encontrado para atualização: ${talhao.id}');
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar talhão: $e');
      rethrow;
    }
  }

  /// Exclui um talhão (soft delete)
  Future<bool> excluirTalhao(String id) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      int count = await db.update(
        'talhao_safra',
        {
          'ativo': 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      bool success = count > 0;
      if (success) {
        Logger.info('✅ Talhão excluído: $id');
      } else {
        Logger.warning('⚠️ Talhão não encontrado para exclusão: $id');
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao excluir talhão: $e');
      rethrow;
    }
  }

  /// Exclui permanentemente um talhão
  Future<bool> excluirTalhaoPermanente(String id) async {
    try {
      final db = await database;

      int count = await db.delete(
        'talhao_safra',
        where: 'id = ?',
        whereArgs: [id],
      );

      bool success = count > 0;
      if (success) {
        Logger.info('✅ Talhão excluído permanentemente: $id');
      } else {
        Logger.warning('⚠️ Talhão não encontrado para exclusão permanente: $id');
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao excluir talhão permanentemente: $e');
      rethrow;
    }
  }

  // ===== OPERAÇÕES DE CULTURAS =====

  /// Salva uma cultura
  Future<String> salvarCultura(dynamic cultura) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final culturaMap = {
        'id': cultura.id,
        'nome': cultura.name,
        'descricao': cultura.description,
        'cor': cultura.color.value.toRadixString(16),
        'icone': cultura.iconPath,
        'ativo': cultura.ativo ? 1 : 0,
        'data_criacao': cultura.dataCriacao.toIso8601String(),
        'created_at': now,
        'updated_at': now,
      };

      await db.insert(
        'culturas',
        culturaMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      Logger.info('✅ Cultura salva: ${cultura.name}');
      return cultura.id;
    } catch (e) {
      Logger.error('❌ Erro ao salvar cultura: $e');
      rethrow;
    }
  }

  /// Carrega todas as culturas
  Future<List<dynamic>> carregarCulturas() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'culturas',
        where: 'ativo = ?',
        whereArgs: [1],
        orderBy: 'nome ASC',
      );

      List<dynamic> culturas = maps.map((map) => _mapToCultura(map)).toList();
      
      Logger.info('✅ Culturas carregadas: ${culturas.length}');
      return culturas;
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas: $e');
      rethrow;
    }
  }

  // ===== CONVERSÕES =====

  /// Converte pontos para JSON
  String _pontosToJson(List<LatLng> pontos) {
    try {
      List<Map<String, double>> pontosJson = pontos.map((ponto) => {
        'latitude': ponto.latitude,
        'longitude': ponto.longitude,
      }).toList();
      
      return jsonEncode(pontosJson);
    } catch (e) {
      Logger.error('❌ Erro ao converter pontos para JSON: $e');
      return '[]';
    }
  }

  /// Converte JSON para pontos
  List<LatLng> _jsonToPontos(String json) {
    try {
      List<dynamic> pontosJson = jsonDecode(json);
      return pontosJson.map((ponto) => LatLng(
        ponto['latitude'] as double,
        ponto['longitude'] as double,
      )).toList();
    } catch (e) {
      Logger.error('❌ Erro ao converter JSON para pontos: $e');
      return [];
    }
  }

  /// Converte Map para TalhaoSafraModel
  TalhaoSafraModel _mapToTalhao(Map<String, dynamic> map) {
    return TalhaoSafraModel(
      id: map['id'] as String,
      name: map['nome'] as String,
      idFazenda: '1', // map['fazenda_id'] as String? ?? '1',
      poligonos: [], // Lista vazia temporariamente
      area: map['area'] as double,
      dataCriacao: DateTime.parse(map['data_criacao'] as String),
      dataAtualizacao: map['data_atualizacao'] != null 
        ? DateTime.parse(map['data_atualizacao'] as String)
        : null,
    );
  }

  /// Converte Map para CulturaModel
  dynamic _mapToCultura(Map<String, dynamic> map) {
    return {
      'id': map['id'] as String,
      'name': map['nome'] as String,
      'description': map['descricao'] as String? ?? '',
      'color': 0xFF4CAF50, // Colors.green, // Color(int.parse(map['cor'] as String, radix: 16)),
      'iconPath': map['icone'] as String?,
      'ativo': (map['ativo'] as int) == 1,
      'dataCriacao': DateTime.parse(map['data_criacao'] as String),
    };
  }

  // ===== UTILITÁRIOS =====

  /// Limpa todos os dados (apenas para desenvolvimento)
  Future<void> limparTodosDados() async {
    try {
      final db = await database;
      await db.delete('talhao_safra');
      await db.delete('culturas');
      Logger.info('🗑️ Todos os dados foram limpos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados: $e');
      rethrow;
    }
  }

  /// Fecha o banco de dados
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      Logger.info('🔒 Banco de dados fechado');
    }
  }
}

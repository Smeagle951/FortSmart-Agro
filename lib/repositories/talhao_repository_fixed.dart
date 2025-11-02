import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 'package:uuid/uuid.dart';
import '../models/talhao_model.dart';
import '../utils/mapbox_compatibility_adapter.dart' as mapbox;

/// Repositório para gerenciar os talhões no banco de dados local
class TalhaoRepository extends ChangeNotifier {
  static const String _tableName = 'talhoes';
  // Banco e versão são gerenciados pelo AppDatabase unificado
  
  Database? _database;
  List<TalhaoModel> _talhoes = [];
  bool _isLoading = false;
  
  /// Lista de talhões carregados
  List<TalhaoModel> get talhoes => _talhoes;
  
  /// Indica se está carregando dados
  bool get isLoading => _isLoading;
  
  /// Define o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Inicializa o banco de dados
  Future<Database> _initDatabase() async {
    if (_database != null) return _database!;
    // Usa o banco unificado do AppDatabase
    final db = await AppDatabase.instance.database;
    // Garante que a tabela exista no banco unificado
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        cultura TEXT NOT NULL,
        area REAL NOT NULL,
        poligonos TEXT NOT NULL,
        observacoes TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        criado_por TEXT NOT NULL,
        sincronizado INTEGER NOT NULL
      )
    ''');
    _database = db;
    return db;
  }
  
  /// Carrega todos os talhões do banco de dados
  Future<List<TalhaoModel>> loadTalhoes() async {
    _setLoading(true);
    
    try {
      final db = await _initDatabase();
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      
      _talhoes = List.generate(maps.length, (i) {
        return TalhaoModel.fromMap(maps[i]);
      });
      
      notifyListeners();
      return _talhoes;
    } catch (e) {
      debugPrint('Erro ao carregar talhões: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Obtém todos os talhões (alias para loadTalhoes para compatibilidade)
  Future<List<TalhaoModel>> getTalhoes() async {
    return await loadTalhoes();
  }
  
  /// Obtém todos os talhões (alias para loadTalhoes para compatibilidade)
  Future<List<TalhaoModel>> getAll() async {
    return await loadTalhoes();
  }
  
  /// Busca um talhão pelo ID
  Future<TalhaoModel?> getTalhaoById(String id) async {
    try {
      final db = await _initDatabase();
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return TalhaoModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Erro ao buscar talhão por ID: $e');
      return null;
    }
  }
  
  /// Adiciona um novo talhão ao banco de dados
  Future<void> addTalhao(TalhaoModel talhao) async {
    _setLoading(true);
    
    try {
      final db = await _initDatabase();
      
      await db.insert(
        _tableName,
        {
          'id': talhao.id,
          'nome': talhao.name,
          'cultura': talhao.cropId ?? '',
          'area': talhao.area,
          'poligonos': jsonEncode(talhao.poligonos.map((poligono) => 
            poligono.map((ponto) => {
              'latitude': ponto.latitude,
              'longitude': ponto.longitude,
            }).toList()
          ).toList()),
          'observacoes': talhao.observacoes,
          'criado_em': talhao.dataCriacao.toIso8601String(),
          'atualizado_em': talhao.dataAtualizacao.toIso8601String(),
          'criado_por': talhao.metadados != null && talhao.metadados!['criadoPor'] != null ? talhao.metadados!['criadoPor'] : '',
          'sincronizado': talhao.sincronizado ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      await loadTalhoes();
    } catch (e) {
      debugPrint('Erro ao adicionar talhão: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Atualiza um talhão existente
  Future<void> updateTalhao(TalhaoModel talhao) async {
    _setLoading(true);
    
    try {
      final db = await _initDatabase();
      
      await db.update(
        _tableName,
        {
          'nome': talhao.name,
          'cultura': talhao.cropId ?? '',
          'area': talhao.area,
          'poligonos': jsonEncode(talhao.poligonos.map((poligono) => 
            poligono.map((ponto) => {
              'latitude': ponto.latitude,
              'longitude': ponto.longitude,
            }).toList()
          ).toList()),
          'observacoes': talhao.observacoes,
          'atualizado_em': talhao.dataAtualizacao.toIso8601String(),
          'criado_por': talhao.metadados != null && talhao.metadados!['criadoPor'] != null ? talhao.metadados!['criadoPor'] : '',
          'sincronizado': 0, // Marca como não sincronizado
        },
        where: 'id = ?',
        whereArgs: [talhao.id],
      );
      
      await loadTalhoes();
    } catch (e) {
      debugPrint('Erro ao atualizar talhão: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Exclui um talhão pelo ID
  Future<void> deleteTalhao(String id) async {
    final db = await _initDatabase();
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    await loadTalhoes();
  }
  
  /// Duplica um talhão existente
  Future<String> duplicateTalhao(String id) async {
    final talhao = await getTalhaoById(id);
    if (talhao == null) {
      throw Exception('Talhão não encontrado');
    }
    
    final novoId = const Uuid().v4();
    final novoTalhao = TalhaoModel(
      id: novoId,
      name: '${talhao.name} (Cópia)',
      poligonos: talhao.poligonos,
      area: talhao.area,
      fazendaId: talhao.fazendaId,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      sincronizado: false,
      observacoes: talhao.observacoes,
      metadados: talhao.metadados,
      safras: talhao.safras,
      cropId: talhao.cropId,
      safraId: talhao.safraId,
      crop: talhao.crop,

      // criadoPor já está em metadados se necessário
    );
    
    await addTalhao(novoTalhao);
    return novoId;
  }
  
  /// Decodifica os polígonos do formato JSON
  List<List<mapbox.MapboxLatLng>> _decodePoligonos(String poligonosJson) {
    final List<dynamic> poligonosData = jsonDecode(poligonosJson);
    
    return poligonosData.map<List<mapbox.MapboxLatLng>>((poligono) {
      return (poligono as List<dynamic>).map<mapbox.MapboxLatLng>((ponto) {
        return mapbox.MapboxLatLng(
          ponto['latitude'] as double,
          ponto['longitude'] as double,
        );
      }).toList();
    }).toList();
  }
  
  /// Calcula a área total de todos os talhões
  Future<double> calcularAreaTotal() async {
    final talhoes = await loadTalhoes();
    return talhoes.fold<double>(0.0, (double total, talhao) => total + talhao.area);
  }
  
  /// Obtém talhões por fazenda
  Future<List<TalhaoModel>> getTalhoesByFarmId(String farmId) async {
    final talhoes = await loadTalhoes();
    // Implemente a lógica de filtro por fazenda quando o modelo de talhão tiver esse campo
    return talhoes;
  }
  
  /// Lista talhões por safra
  Future<List<TalhaoModel>> listarPorSafra(String safraId) async {
    final talhoes = await loadTalhoes();
    // Implemente a lógica de filtro por safra quando o modelo de talhão tiver esse campo
    return talhoes;
  }
  
  /// Calcula a área total por safra
  Future<double> calcularAreaTotalPorSafra(String safraId) async {
    final talhoes = await listarPorSafra(safraId);
    return talhoes.fold<double>(0.0, (double total, talhao) => total + talhao.area);
  }
  
  /// Sincroniza todos os talhões com o servidor
  Future<void> syncTalhoes() async {
    // Implementar sincronização quando o backend estiver disponível
    await Future.delayed(const Duration(seconds: 2));
    
    // Simula sincronização bem-sucedida
    final db = await _initDatabase();
    await db.update(
      _tableName,
      {'sincronizado': 1},
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
    
    await loadTalhoes();
  }
  
  /// Importa talhões de um arquivo GeoJSON
  Future<int> importFromGeoJson(File file) async {
    // Implementação futura
    return 0;
  }
  
  /// Importa talhões de um arquivo KML
  Future<int> importFromKml(File file) async {
    // Implementação futura
    return 0;
  }
  
  /// Exporta talhões para um arquivo GeoJSON
  Future<File> exportToGeoJson() async {
    // Implementação futura
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/talhoes_export.geojson');
  }
}

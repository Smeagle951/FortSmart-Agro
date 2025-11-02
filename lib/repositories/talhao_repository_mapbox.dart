import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/models/talhao_model.dart';
import 'package:fortsmart_agro/models/poligono_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

/// Repositório para gerenciar os talhões no banco de dados local
class TalhaoRepository extends ChangeNotifier {
  // DB unificado via AppDatabase
  static const String _tableName = 'talhoes';
  // Versão e nome gerenciados pelo AppDatabase
  
  Database? _database;
  List<TalhaoModel> _talhoes = [];
  bool _isLoading = false;
  
  /// Lista de talhões carregados
  List<TalhaoModel> get talhoes => _talhoes;
  
  /// Indica se está carregando dados
  bool get isLoading => _isLoading;
  
  get crop => null;
  
  /// Inicializa o banco de dados
  Future<Database> _initDatabase() async {
    if (_database != null) return _database!;
    final db = await AppDatabase.instance.database;
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
        final poligonos = _decodePoligonos(maps[i]['poligonos']);
        return TalhaoModel(
          id: maps[i]['id'],
          name: maps[i]['nome'],
          crop: maps[i]['cultura'],
          area: maps[i]['area'],
          poligonos: poligonos,
          observacoes: maps[i]['observacoes'],
          dataAtualizacao: DateTime.parse(maps[i]['criado_em']),
          dataCriacao: DateTime.parse(maps[i]['atualizado_em']),
          criadoPor: maps[i]['criado_por'],
          sincronizado: maps[i]['sincronizado'] == 1,
          points: poligonos.isNotEmpty ? [] : [], // Adicionando points obrigatório
          syncStatus: maps[i]['sincronizado'] == 1 ? 1 : 0, // Adicionando syncStatus obrigatório
          safras: [], // Adicionando safras obrigatório
        );
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
          'cultura': talhao.crop,
          'area': talhao.area,
          'poligonos': jsonEncode(talhao.poligonos.map((poligono) => 
            poligono.map((ponto) => {
              'latitude': ponto.latitude,
              'longitude': ponto.longitude,
            }).toList()
          ).toList()),
          'observacoes': talhao.observacoes,
          'criado_em': talhao.dataAtualizacao.toIso8601String(),
          'atualizado_em': talhao.dataAtualizacao.toIso8601String(),
          'criado_por': talhao.criadoPor,
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
          'cultura': talhao.crop,
          'area': talhao.area,
          'poligonos': jsonEncode(talhao.poligonos.map((poligono) => 
            poligono.map((ponto) => {
              'latitude': ponto.latitude,
              'longitude': ponto.longitude,
            }).toList()
          ).toList()),
          'observacoes': talhao.observacoes,
          'atualizado_em': DateTime.now().toIso8601String(),
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
    _setLoading(true);
    
    try {
      final db = await _initDatabase();
      
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      await loadTalhoes();
    } catch (e) {
      debugPrint('Erro ao excluir talhão: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Obtém um talhão pelo ID
  Future<TalhaoModel?> getTalhaoById(String id) async {
    try {
      final db = await _initDatabase();
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      
      final poligonos = _decodePoligonos(maps[0]['poligonos']);
      return TalhaoModel(
        id: maps[0]['id'],
        name: maps[0]['nome'],
        crop: maps[0]['cultura'],
        area: maps[0]['area'],
        poligonos: poligonos,
        observacoes: maps[0]['observacoes'],
        dataCriacao: DateTime.parse(maps[0]['criado_em']),
        dataAtualizacao: DateTime.parse(maps[0]['atualizado_em']),
        criadoPor: maps[0]['criado_por'],
        sincronizado: maps[0]['sincronizado'] == 1,
        safras: [], 
        points: poligonos.isNotEmpty ? [] : [], 
        syncStatus: maps[0]['sincronizado'] == 1 ? 1 : 0, 
      );
    } catch (e) {
      debugPrint('Erro ao obter talhão por ID: $e');
      return null;
    }
  }
  
  /// Sincroniza todos os talhões com o servidor
  Future<void> syncAll() async {
    _setLoading(true);
    
    try {
      final db = await _initDatabase();
      
      // Obter talhões não sincronizados
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'sincronizado = ?',
        whereArgs: [0],
      );
      
      // Simular sincronização com servidor
      for (final map in maps) {
        // Em um caso real, enviaria os dados para o servidor
        // e atualizaria o status de sincronização
        
        await db.update(
          _tableName,
          {
            'sincronizado': 1,
            'atualizado_em': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      }
      
      await loadTalhoes();
    } catch (e) {
      debugPrint('Erro ao sincronizar talhões: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Importa talhões de um arquivo GeoJSON
  Future<List<TalhaoModel>> importFromGeoJson(String filePath, String cultura) async {
    _setLoading(true);
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $filePath');
      }
      
      final content = await file.readAsString();
      final Map<String, dynamic> geoJson = jsonDecode(content);
      
      if (geoJson['type'] != 'FeatureCollection') {
        throw Exception('Formato GeoJSON inválido');
      }
      
      final features = geoJson['features'] as List;
      final List<TalhaoModel> talhoesImportados = [];
      
      for (final feature in features) {
        if (feature['geometry']['type'] == 'Polygon') {
          final coordinates = feature['geometry']['coordinates'][0] as List;
          final pontos = coordinates.map<LatLng>((coord) {
            return LatLng(coord[1], coord[0]); // [longitude, latitude] -> LatLng(latitude, longitude)
          }).toList();
          
          // Criar talhão com os pontos importados
          final talhao = TalhaoModel(
            id: const Uuid().v4(),
            name: feature['properties']?['name'] ?? 'Talhão Importado',
            poligonos: [PoligonoModel.criar(pontos: pontos, talhaoId: const Uuid().v4())],
            area: 0.0, // A área será calculada posteriormente
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
            sincronizado: false,
            observacoes: 'Importado de GeoJSON',
            safras: [],
            points: pontos,
            syncStatus: 0,
            crop: crop,
          );
          
          await addTalhao(talhao);
          talhoesImportados.add(talhao);
        }
      }
      
      return talhoesImportados;
    } catch (e) {
      debugPrint('Erro ao importar GeoJSON: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Exporta talhões para um arquivo GeoJSON
  Future<String?> exportToGeoJson(List<TalhaoModel> talhoes) async {
    try {
      final features = talhoes.map((talhao) {
        final List<dynamic> featuresPolygons = [];
        
        for (final poligono in talhao.poligonos) {
          final coordinates = poligono.map((ponto) => 
            [ponto.longitude, ponto.latitude]
          ).toList();
          
          // Fechar o polígono (primeiro ponto = último ponto)
          if (poligono.isNotEmpty && 
              (poligono.first.latitude != poligono.last.latitude || 
               poligono.first.longitude != poligono.last.longitude)) {
            coordinates.add([poligono.first.longitude, poligono.first.latitude]);
          }
          
          featuresPolygons.add({
            'type': 'Feature',
            'properties': {
              'id': talhao.id,
              'nome': talhao.nome,
              'cultura': talhao.cultura,
              'area': talhao.area,
              'observacoes': talhao.observacoes,
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [coordinates],
            },
          });
        }
        
        return featuresPolygons;
      }).expand((element) => element).toList();
      
      final geoJson = {
        'type': 'FeatureCollection',
        'features': features,
      };
      
      // Salvar arquivo
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final fileName = 'talhoes_${DateTime.now().millisecondsSinceEpoch}.geojson';
      final filePath = '${documentsDirectory.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(jsonEncode(geoJson));
      
      return filePath;
    } catch (e) {
      debugPrint('Erro ao exportar para GeoJSON: $e');
      return null;
    }
  }
  
  /// Importa talhões de um arquivo KML
  Future<List<TalhaoModel>> importFromKml(String filePath, String cultura) async {
    _setLoading(true);
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $filePath');
      }
      
      final content = await file.readAsString();
      
      // Processamento simples de KML (em produção, usar uma biblioteca XML adequada)
      final RegExp coordsPattern = RegExp(r'<coordinates>(.*?)</coordinates>', multiLine: true, dotAll: true);
      final RegExp namePattern = RegExp(r'<name>(.*?)</name>', multiLine: true);
      
      final matches = coordsPattern.allMatches(content);
      final nameMatches = namePattern.allMatches(content);
      
      final List<TalhaoModel> talhoesImportados = [];
      int nameIndex = 0;
      
      for (final match in matches) {
        if (match.groupCount > 0) {
          final String coordsString = match.group(1)!.trim();
          final List<String> coordsArray = coordsString.split(' ');
          
          final List<LatLng> pontos = [];
          
          for (final coordPair in coordsArray) {
            if (coordPair.trim().isEmpty) continue;
            
            final List<String> parts = coordPair.trim().split(',');
            if (parts.length >= 2) {
              final double lng = double.tryParse(parts[0]) ?? 0;
              final double lat = double.tryParse(parts[1]) ?? 0;
              pontos.add(LatLng(lat, lng));
            }
          }
          
          if (pontos.length >= 3) {
            String nome = 'Talhão Importado';
            if (nameIndex < nameMatches.length && nameMatches.elementAt(nameIndex).groupCount > 0) {
              nome = nameMatches.elementAt(nameIndex).group(1) ?? nome;
              nameIndex++;
            }
            
            final talhao = TalhaoModel(
              id: const Uuid().v4(),
              name: nome,
              poligonos: [PoligonoModel.criar(pontos: pontos, talhaoId: const Uuid().v4())],
              area: 0.0, // A área será calculada posteriormente
              dataCriacao: DateTime.now(),
              dataAtualizacao: DateTime.now(),
              sincronizado: false,
              observacoes: 'Importado de KML',
              safras: [],
              points: pontos,
              syncStatus: 0,
              crop: null, // Não há cultura definida no KML
            );
            
            await addTalhao(talhao);
            talhoesImportados.add(talhao);
          }
        }
      }
      
      return talhoesImportados;
    } catch (e) {
      debugPrint('Erro ao importar KML: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Decodifica a string JSON de polígonos para uma lista de LatLng
  List<List<LatLng>> _decodePoligonos(String poligonosJson) {
    try {
      final List<dynamic> poligonosList = jsonDecode(poligonosJson);
      
      return poligonosList.map<List<LatLng>>((poligono) {
        return (poligono as List).map<LatLng>((ponto) {
          return LatLng(
            ponto['latitude'] as double, 
            ponto['longitude'] as double
          );
        }).toList();
      }).toList();
    } catch (e) {
      debugPrint('Erro ao decodificar polígonos: $e');
      return [];
    }
  }
  
  /// Altera o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/talhao_model.dart';
import '../models/poligono_model.dart';
import '../utils/latlng_adapter.dart';

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
        // Usar diretamente o método _decodePoligonos que já retorna uma lista de PoligonoModel
        final poligonosModel = _decodePoligonos(
          maps[i]['poligonos'] ?? '[]',
          talhaoId: maps[i]['id'],
        );
        
        return TalhaoModel(
          id: maps[i]['id'],
          name: maps[i]['nome'],
          poligonos: poligonosModel,
          area: maps[i]['area'],
          observacoes: maps[i]['observacoes'],
          dataCriacao: DateTime.parse(maps[i]['criado_em'] ?? DateTime.now().toIso8601String()),
          dataAtualizacao: DateTime.parse(maps[i]['atualizado_em'] ?? DateTime.now().toIso8601String()),
          sincronizado: maps[i]['sincronizado'] == 1,
          safras: [], points: [], syncStatus: null,
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
      
      // Converter os polígonos para o formato de armazenamento
      final poligonosJson = jsonEncode(talhao.poligonos.map((poligono) => 
        poligono.pontos.map((ponto) => {
          'latitude': ponto.latitude,
          'longitude': ponto.longitude,
        }).toList()
      ).toList());
      
      await db.insert(
        _tableName,
        {
          'id': talhao.id,
          'nome': talhao.name,
          'cultura': talhao.crop?.name ?? '',
          'area': talhao.area,
          'poligonos': poligonosJson,
          'observacoes': talhao.observacoes,
          'criado_em': talhao.dataCriacao.toIso8601String(),
          'atualizado_em': talhao.dataAtualizacao.toIso8601String(),
          'criado_por': talhao.criadoPor ?? '',
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
      
      // Converter os polígonos para o formato de armazenamento
      final poligonosJson = jsonEncode(talhao.poligonos.map((poligono) => 
        poligono.pontos.map((ponto) => {
          'latitude': ponto.latitude,
          'longitude': ponto.longitude,
        }).toList()
      ).toList());
      
      await db.update(
        _tableName,
        {
          'nome': talhao.name,
          'cultura': talhao.crop?.name ?? '',
          'area': talhao.area,
          'poligonos': poligonosJson,
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
      
      return TalhaoModel(
        id: maps[0]['id'],
        name: maps[0]['nome'],
        crop: maps[0]['cultura'],
        area: maps[0]['area'],
        poligonos: _decodePoligonos(
          maps[0]['poligonos'] ?? '[]',
          talhaoId: maps[0]['id'],
        ),
        observacoes: maps[0]['observacoes'],
        dataCriacao: DateTime.parse(maps[0]['criado_em'] ?? DateTime.now().toIso8601String()),
        dataAtualizacao: DateTime.parse(maps[0]['atualizado_em'] ?? DateTime.now().toIso8601String()),
        sincronizado: maps[0]['sincronizado'] == 1,
        safras: [], points: [], syncStatus: null, // Lista vazia de safras
      );
    } catch (e) {
      debugPrint('Erro ao obter talhão por ID: $e');
      return null;
    }
  }
  
  /// Decodifica a string de polígonos para uma lista de PoligonoModel
  List<PoligonoModel> _decodePoligonos(String poligonosStr, {String? talhaoId}) {
    try {
      if (poligonosStr.isEmpty) return [];
      
      final List<dynamic> poligonosJson = json.decode(poligonosStr);
      List<PoligonoModel> resultado = [];
      
      for (var poligonoJson in poligonosJson) {
        List<LatLng> pontos = [];
        
        if (poligonoJson is List) {
          for (var ponto in poligonoJson) {
            if (ponto is List && ponto.length >= 2) {
              pontos.add(LatLng(ponto[0], ponto[1]));
            }
          }
          
          if (pontos.isNotEmpty) {
            resultado.add(PoligonoModel.criar(
              pontos: pontos,
              talhaoId: talhaoId ?? 'temp_id', // Usar um ID temporário se não for fornecido
            ));
          }
        }
      }
      
      return resultado;
    } catch (e) {
      debugPrint('Erro ao decodificar polígonos: $e');
      return [];
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
          // Criar pontos usando o tipo do Google Maps primeiro
          final pontosGoogleMaps = coordinates.map<google_maps.LatLng>((coord) {
            return google_maps.LatLng(coord[1], coord[0]); // [longitude, latitude] -> LatLng(latitude, longitude)
          }).toList();
          
          // Converter para o tipo do Mapbox usando o adaptador
          final pontosMapbox = LatLngAdapter.toMapboxLatLngList(pontosGoogleMaps.cast<LatLng>());
          
          // Criar talhão com os pontos importados
          final talhao = TalhaoModel.criar(
            nome: feature['properties']?['name'] ?? 'Talhão Importado',
            pontos: LatLngAdapter.fromMapboxLatLngList(pontosMapbox),
            observacoes: 'Importado de GeoJSON',
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
          final coordinates = poligono.pontos.map((ponto) => 
            [ponto.longitude, ponto.latitude]
          ).toList();
          
          // Fechar o polígono (primeiro ponto = último ponto)
          if (poligono.pontos.isNotEmpty && 
              (poligono.pontos.first.latitude != poligono.pontos.last.latitude || 
               poligono.pontos.first.longitude != poligono.pontos.last.longitude)) {
            coordinates.add([poligono.pontos.first.longitude, poligono.pontos.first.latitude]);
          }
          
          featuresPolygons.add({
            'type': 'Feature',
            'properties': {
              'id': talhao.id,
              'nome': talhao.name,
              'cultura': talhao.crop?.name ?? '',
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
  
  // Este método foi substituído por uma nova implementação acima
  
  /// Altera o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

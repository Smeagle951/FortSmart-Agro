import 'package:sqflite/sqflite.dart';
import '../models/polygon_model.dart';


class PolygonDao {
  final Database _database;

  PolygonDao(this._database);

  /// Insere um novo polígono
  Future<int> insertPolygon(PolygonModel polygon) async {
    try {
      // Verificar se a tabela existe antes de inserir
      await _ensurePolygonTableExists();
      
      final map = polygon.toMap();
      map.remove('id'); // Remover ID para auto-incremento
      
      return await _database.insert('polygons', map);
    } catch (e) {
      print('❌ Erro ao inserir polígono: $e');
      rethrow;
    }
  }

  /// Garante que a tabela polygons existe
  Future<void> _ensurePolygonTableExists() async {
    try {
      final tables = await _database.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'polygons'],
      );
      
      if (tables.isEmpty) {
        print('🔄 Tabela polygons não encontrada. Criando...');
        await _database.execute('''
          CREATE TABLE IF NOT EXISTS polygons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            method TEXT NOT NULL,
            coordinates TEXT NOT NULL,
            area_ha REAL NOT NULL,
            perimeter_m REAL NOT NULL,
            distance_m REAL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            fazenda_id TEXT,
            cultura_id TEXT,
            safra_id TEXT
          )
        ''');
        print('✅ Tabela polygons criada com sucesso');
      }
    } catch (e) {
      print('❌ Erro ao verificar/criar tabela polygons: $e');
      rethrow;
    }
  }

  /// Atualiza um polígono existente
  Future<int> updatePolygon(PolygonModel polygon) async {
    try {
      print('🔄 PolygonDao.updatePolygon iniciado');
      print('📊 ID do polígono: ${polygon.id}');
      
      if (polygon.id == null) {
        throw Exception('ID é obrigatório para atualização');
      }
      
      final map = polygon.toMap();
      map.remove('id'); // Não atualizar o ID
      
      print('📊 Dados para atualização:');
      print('  - name: ${map['name']}');
      print('  - cultura_id: ${map['cultura_id']}');
      print('  - safra_id: ${map['safra_id']}');
      print('  - area_ha: ${map['area_ha']}');
      print('  - perimeter_m: ${map['perimeter_m']}');
      
      final result = await _database.update(
        'polygons',
        map,
        where: 'id = ?',
        whereArgs: [polygon.id],
      );
      
      print('📊 Resultado da atualização: $result');
      print('📊 Linhas afetadas: $result');
      
      return result;
    } catch (e) {
      print('❌ Erro no PolygonDao.updatePolygon: $e');
      rethrow;
    }
  }

  /// Exclui um polígono
  Future<int> deletePolygon(int id) async {
    return await _database.delete(
      'polygons',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca todos os polígonos
  Future<List<PolygonModel>> getAllPolygons() async {
    final List<Map<String, dynamic>> maps = await _database.query('polygons');
    return List.generate(maps.length, (i) => PolygonModel.fromMap(maps[i]));
  }

  /// Busca polígonos por fazenda
  Future<List<PolygonModel>> getPolygonsByFazenda(String fazendaId) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'polygons',
      where: 'fazenda_id = ?',
      whereArgs: [fazendaId],
    );
    return List.generate(maps.length, (i) => PolygonModel.fromMap(maps[i]));
  }

  /// Busca polígonos por método
  Future<List<PolygonModel>> getPolygonsByMethod(String method) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'polygons',
      where: 'method = ?',
      whereArgs: [method],
    );
    return List.generate(maps.length, (i) => PolygonModel.fromMap(maps[i]));
  }

  /// Busca um polígono por ID
  Future<PolygonModel?> getPolygonById(int id) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'polygons',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return PolygonModel.fromMap(maps.first);
    }
    return null;
  }

  /// Insere pontos de trilha
  Future<int> insertTrack(TrackModel track) async {
    try {
      // Verificar se a tabela existe antes de inserir
      await _ensureTrackTableExists();
      
      final map = track.toMap();
      map.remove('id'); // Remover ID para auto-incremento
      
      return await _database.insert('tracks', map);
    } catch (e) {
      print('❌ Erro ao inserir trilha: $e');
      rethrow;
    }
  }

  /// Garante que a tabela tracks existe
  Future<void> _ensureTrackTableExists() async {
    try {
      final tables = await _database.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'tracks'],
      );
      
      if (tables.isEmpty) {
        print('🔄 Tabela tracks não encontrada. Criando...');
        await _database.execute('''
          CREATE TABLE IF NOT EXISTS tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            polygon_id INTEGER,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            accuracy REAL,
            speed REAL,
            bearing REAL,
            ts TEXT NOT NULL,
            status TEXT,
            FOREIGN KEY(polygon_id) REFERENCES polygons(id) ON DELETE CASCADE
          )
        ''');
        print('✅ Tabela tracks criada com sucesso');
      }
    } catch (e) {
      print('❌ Erro ao verificar/criar tabela tracks: $e');
      rethrow;
    }
  }

  /// Busca trilhas de um polígono
  Future<List<TrackModel>> getTracksByPolygonId(int polygonId) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'tracks',
      where: 'polygon_id = ?',
      whereArgs: [polygonId],
      orderBy: 'ts ASC',
    );
    return List.generate(maps.length, (i) => TrackModel.fromMap(maps[i]));
  }

    /// Exclui trilhas de um polígono
  Future<int> deleteTracksByPolygonId(int polygonId) async {
    return await _database.delete(
      'tracks',
      where: 'polygon_id = ?',
      whereArgs: [polygonId],
    );
  }

  /// Busca polígonos com estatísticas
  Future<List<Map<String, dynamic>>> getPolygonsWithStats() async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'polygons',
      columns: [
        'id',
        'name',
        'method',
        'area_ha',
        'perimeter_m',
        'distance_m',
        'created_at',
        'fazenda_id',
        'cultura_id',
        'safra_id',
        'coordinates',
      ],
    );
    
    return maps.map((map) => {
      'id': map['id'],
      'name': map['name'],
      'method': map['method'],
      'areaHa': map['area_ha'],
      'perimeterM': map['perimeter_m'],
      'distanceM': map['distance_m'],
      'createdAt': map['created_at'],
      'fazendaId': map['fazenda_id'],
      'culturaId': map['cultura_id'],
      'safraId': map['safra_id'],
      'coordinates': map['coordinates'],
    }).toList();
  }
}

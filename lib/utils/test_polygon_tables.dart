import '../database/app_database.dart';
import '../database/daos/polygon_dao.dart';
import '../database/models/polygon_model.dart';

/// Utilitário para testar as tabelas de polígonos
class PolygonTablesTester {
  static Future<void> testPolygonTables() async {
    try {
      print('🧪 Iniciando teste das tabelas de polígonos...');
      
      // Inicializar banco de dados
      final appDatabase = AppDatabase.instance;
      final database = await appDatabase.database;
      
      print('✅ Banco de dados inicializado');
      
      // Verificar se as tabelas existem
      final tables = await database.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('polygons', 'tracks')");
      print('📋 Tabelas encontradas: ${tables.map((e) => e['name']).join(', ')}');
      
      // Forçar criação das tabelas se necessário
      await appDatabase.ensurePolygonTablesExist();
      
      // Testar inserção de um polígono
      final polygonDao = PolygonDao(database);
      
      final testPolygon = PolygonModel(
        id: null,
        name: 'Teste Polígono',
        method: 'manual',
        coordinates: '{"type":"Polygon","coordinates":[[[-54.43302149366,-25.43302149366],[-54.43302149366,-25.43302149366],[-54.43302149366,-25.43302149366],[-54.43302149366,-25.43302149366]]]}',
        areaHa: 1.0,
        perimeterM: 100.0,
        distanceM: 0.0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: null,
        fazendaId: 'fazenda_1',
        culturaId: '4',
        safraId: 'safra_2024',
      );
      
      print('🔄 Tentando inserir polígono de teste...');
      final polygonId = await polygonDao.insertPolygon(testPolygon);
      print('✅ Polígono inserido com ID: $polygonId');
      
      // Verificar se foi inserido
      final savedPolygon = await polygonDao.getPolygonById(polygonId);
      if (savedPolygon != null) {
        print('✅ Polígono recuperado com sucesso: ${savedPolygon.name}');
      } else {
        print('❌ Polígono não foi encontrado após inserção');
      }
      
      // Listar todos os polígonos
      final allPolygons = await polygonDao.getAllPolygons();
      print('📊 Total de polígonos no banco: ${allPolygons.length}');
      
      print('✅ Teste das tabelas de polígonos concluído com sucesso!');
      
    } catch (e) {
      print('❌ Erro no teste das tabelas de polígonos: $e');
      rethrow;
    }
  }
}

import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/daos/polygon_dao.dart';
import '../database/migrations/001_create_polygons_tables.dart';
import 'storage_service.dart';

class PolygonDatabaseService {
  static PolygonDatabaseService? _instance;
  static StorageService? _storageService;
  
  PolygonDatabaseService._();
  
  static PolygonDatabaseService get instance {
    _instance ??= PolygonDatabaseService._();
    return _instance!;
  }
  
  /// Inicializa o serviço de banco para polígonos
  Future<void> initialize() async {
    try {
      final appDatabase = AppDatabase.instance;
      final database = await appDatabase.database;
      
      // Criar DAO
      final polygonDao = PolygonDao(database);
      
      // Criar StorageService
      _storageService = StorageService(polygonDao);
      
      print('✅ Serviço de banco para polígonos inicializado');
    } catch (e) {
      print('❌ Erro ao inicializar serviço de banco para polígonos: $e');
      rethrow;
    }
  }
  
  /// Obtém o StorageService
  StorageService? get storageService => _storageService;
  
  /// Obtém o PolygonDao
  PolygonDao? get polygonDao => _storageService?.polygonDao;
  
  /// Verifica se o serviço está inicializado
  bool get isInitialized => _storageService != null;
  
  /// Executa migração de polígonos
  Future<void> runMigrations() async {
    try {
      final appDatabase = AppDatabase.instance;
      final database = await appDatabase.database;
      
      // Executar migração de polígonos
      await CreatePolygonsTables.up(database);
      
      print('✅ Migração de polígonos executada com sucesso');
    } catch (e) {
      print('❌ Erro ao executar migração de polígonos: $e');
      rethrow;
    }
  }
  
  /// Limpa dados de polígonos (para testes)
  Future<void> clearPolygonData() async {
    try {
      final appDatabase = AppDatabase.instance;
      final database = await appDatabase.database;
      
      await database.execute('DELETE FROM tracks');
      await database.execute('DELETE FROM polygons');
      
      print('✅ Dados de polígonos limpos');
    } catch (e) {
      print('❌ Erro ao limpar dados de polígonos: $e');
      rethrow;
    }
  }
}

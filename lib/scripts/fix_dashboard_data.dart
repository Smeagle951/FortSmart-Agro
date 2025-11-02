import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Script para corrigir e testar dados do dashboard
class FixDashboardData {
  static Future<void> run() async {
    try {
      Logger.info('🔄 Iniciando correção dos dados do dashboard...');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Verificar e corrigir dados da fazenda
      await _fixFarmData(db);
      
      // 2. Verificar e corrigir dados dos talhões
      await _fixTalhoesData(db);
      
      // 3. Verificar e corrigir dados dos plantios
      await _fixPlantiosData(db);
      
      // 4. Verificar e corrigir dados do estoque
      await _fixEstoqueData(db);
      
      // 5. Verificar e corrigir dados de monitoramento
      await _fixMonitoringData(db);
      
      Logger.info('✅ Correção dos dados do dashboard concluída');
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir dados do dashboard: $e');
    }
  }
  
  /// Corrige dados da fazenda
  static Future<void> _fixFarmData(Database db) async {
    try {
      Logger.info('🏠 Verificando dados da fazenda...');
      
      // Verificar se tabela farms existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='farms'"
      );
      
      if (tables.isEmpty) {
        Logger.info('📋 Criando tabela farms...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS farms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            owner TEXT,
            municipality TEXT,
            state TEXT,
            total_area REAL DEFAULT 0.0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      }
      
      // Verificar se há dados
      final farmData = await db.query('farms', limit: 1);
      
      if (farmData.isEmpty) {
        Logger.info('📝 Inserindo dados de exemplo da fazenda...');
        await db.insert('farms', {
          'name': 'Fazenda Exemplo',
          'owner': 'João Silva',
          'municipality': 'Ribeirão Preto',
          'state': 'SP',
          'total_area': 100.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        Logger.info('✅ Dados da fazenda inseridos');
      } else {
        Logger.info('✅ Dados da fazenda já existem');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir dados da fazenda: $e');
    }
  }
  
  /// Corrige dados dos talhões
  static Future<void> _fixTalhoesData(Database db) async {
    try {
      Logger.info('🌾 Verificando dados dos talhões...');
      
      // Verificar se tabela talhoes existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='talhoes'"
      );
      
      if (tables.isEmpty) {
        Logger.info('📋 Criando tabela talhoes...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS talhoes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            area REAL DEFAULT 0.0,
            status TEXT DEFAULT 'ativo',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      }
      
      // Verificar quantos talhões existem
      final talhoesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM talhoes')
      ) ?? 0;
      
      Logger.info('📊 Talhões encontrados: $talhoesCount');
      
      if (talhoesCount == 0) {
        Logger.info('📝 Inserindo talhões de exemplo...');
        
        // Inserir 2 talhões de exemplo
        await db.insert('talhoes', {
          'nome': 'Talhão A',
          'area': 25.5,
          'status': 'ativo',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        await db.insert('talhoes', {
          'nome': 'Talhão B',
          'area': 30.0,
          'status': 'ativo',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        Logger.info('✅ 2 talhões de exemplo inseridos');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir dados dos talhões: $e');
    }
  }
  
  /// Corrige dados dos plantios
  static Future<void> _fixPlantiosData(Database db) async {
    try {
      Logger.info('🌱 Verificando dados dos plantios...');
      
      // Verificar se tabela plantios existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plantios'"
      );
      
      if (tables.isEmpty) {
        Logger.info('📋 Criando tabela plantios...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS plantios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cultura TEXT NOT NULL,
            variedade TEXT,
            area REAL DEFAULT 0.0,
            status TEXT DEFAULT 'ativo',
            data_plantio TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      }
      
      // Verificar quantos plantios existem
      final plantiosCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM plantios')
      ) ?? 0;
      
      Logger.info('📊 Plantios encontrados: $plantiosCount');
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir dados dos plantios: $e');
    }
  }
  
  /// Corrige dados do estoque
  static Future<void> _fixEstoqueData(Database db) async {
    try {
      Logger.info('📦 Verificando dados do estoque...');
      
      // Verificar se tabela estoque existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='estoque'"
      );
      
      if (tables.isEmpty) {
        Logger.info('📋 Criando tabela estoque...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS estoque (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            quantidade REAL DEFAULT 0.0,
            estoque_minimo REAL DEFAULT 0.0,
            unidade TEXT DEFAULT 'kg',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      }
      
      // Verificar quantos itens existem
      final estoqueCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM estoque')
      ) ?? 0;
      
      Logger.info('📊 Itens de estoque encontrados: $estoqueCount');
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir dados do estoque: $e');
    }
  }
  
  /// Corrige dados de monitoramento
  static Future<void> _fixMonitoringData(Database db) async {
    try {
      Logger.info('🔍 Verificando dados de monitoramento...');
      
      // Verificar se tabela infestacoes_monitoramento existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='infestacoes_monitoramento'"
      );
      
      if (tables.isEmpty) {
        Logger.info('📋 Criando tabela infestacoes_monitoramento...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS infestacoes_monitoramento (
            id TEXT PRIMARY KEY,
            talhao_id INTEGER NOT NULL,
            ponto_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            tipo TEXT NOT NULL,
            subtipo TEXT NOT NULL,
            nivel TEXT NOT NULL,
            percentual INTEGER NOT NULL,
            foto_paths TEXT,
            observacao TEXT,
            data_hora TEXT NOT NULL,
            sincronizado INTEGER DEFAULT 0,
            server_id TEXT,
            last_sync_error TEXT,
            attempts_sync INTEGER DEFAULT 0
          )
        ''');
      }
      
      // Verificar quantos monitoramentos existem
      final monitoringCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM infestacoes_monitoramento')
      ) ?? 0;
      
      Logger.info('📊 Monitoramentos encontrados: $monitoringCount');
      
    } catch (e) {
      Logger.error('❌ Erro ao corrigir dados de monitoramento: $e');
    }
  }
  
  /// Testa carregamento dos dados
  static Future<void> testDataLoading() async {
    try {
      Logger.info('🧪 Testando carregamento dos dados...');
      
      final db = await AppDatabase.instance.database;
      
      // Testar fazenda
      final farmData = await db.query('farms', limit: 1);
      Logger.info('🏠 Fazenda: ${farmData.isNotEmpty ? farmData.first['name'] : 'Não encontrada'}');
      
      // Testar talhões
      final talhoesData = await db.query('talhoes');
      Logger.info('🌾 Talhões: ${talhoesData.length} encontrados');
      for (final talhao in talhoesData) {
        Logger.info('  - ${talhao['nome']}: ${talhao['area']} ha');
      }
      
      // Testar plantios
      final plantiosData = await db.query('plantios');
      Logger.info('🌱 Plantios: ${plantiosData.length} encontrados');
      
      // Testar estoque
      final estoqueData = await db.query('estoque');
      Logger.info('📦 Estoque: ${estoqueData.length} itens encontrados');
      
      // Testar monitoramentos
      final monitoringData = await db.query('infestacoes_monitoramento');
      Logger.info('🔍 Monitoramentos: ${monitoringData.length} encontrados');
      
      Logger.info('✅ Teste de carregamento concluído');
      
    } catch (e) {
      Logger.error('❌ Erro no teste de carregamento: $e');
    }
  }
}

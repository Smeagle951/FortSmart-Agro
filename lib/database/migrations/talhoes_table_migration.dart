import 'package:sqflite/sqflite.dart';

/// Migração para criar a tabela de talhões se ela não existir
class TalhoesTableMigration {
  static const String tableName = 'talhao_safra';
  static const String tablePoligono = 'talhao_poligono';
  static const String tableSafraTalhao = 'safra_talhao';
  
  /// Executa a migração para criar a tabela de talhões
  static Future<void> migrate(Database db) async {
    try {
      // Verifica se a tabela já existe
      final tableExists = await _tableExists(db, tableName);
      
      if (!tableExists) {
        await _createTalhoesTable(db);
        print('✅ Tabela de talhões criada com sucesso');
      } else {
        print('ℹ️ Tabela de talhões já existe');
      }
    } catch (e) {
      print('❌ Erro na migração da tabela de talhões: $e');
      rethrow;
    }
  }
  
  /// Verifica se uma tabela existe
  static Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Cria a tabela de talhões
  static Future<void> _createTalhoesTable(Database db) async {
    // Tabela de talhões
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        idFazenda TEXT NOT NULL,
        area REAL,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0
      )
    ''');

    // Tabela de polígonos
    await db.execute('''
      CREATE TABLE $tablePoligono (
        id TEXT PRIMARY KEY,
        idTalhao TEXT NOT NULL,
        pontos TEXT NOT NULL,
        FOREIGN KEY (idTalhao) REFERENCES $tableName (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de safras por talhão
    await db.execute('''
      CREATE TABLE $tableSafraTalhao (
        id TEXT PRIMARY KEY,
        idTalhao TEXT NOT NULL,
        idSafra TEXT NOT NULL,
        idCultura TEXT NOT NULL,
        culturaNome TEXT NOT NULL,
        culturaCor INTEGER NOT NULL,
        imagemCultura TEXT,
        area REAL NOT NULL,
        dataCadastro TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        FOREIGN KEY (idTalhao) REFERENCES $tableName (id) ON DELETE CASCADE
      )
    ''');
    
    // Criar índices para melhor performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhao_safra_fazenda ON $tableName (idFazenda)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhao_poligono_talhao ON $tablePoligono (idTalhao)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_safra_talhao_talhao ON $tableSafraTalhao (idTalhao)');
  }
  
  /// Adiciona dados de exemplo se a tabela estiver vazia
  static Future<void> addSampleData(Database db) async {
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName')
      ) ?? 0;
      
      if (count == 0) {
        await db.insert(tableName, {
          'id': 'talhao_1',
          'name': 'Talhão A',
          'idFazenda': 'fazenda_1',
          'areaTotal': 50.0,
          'dataCriacao': DateTime.now().toIso8601String(),
          'dataAtualizacao': DateTime.now().toIso8601String(),
          'sincronizado': 1,
          'observacoes': 'Talhão de exemplo',
          'criadoPor': 'sistema',
          'status': 'ativo'
        });
        
        await db.insert(tableName, {
          'id': 'talhao_2',
          'name': 'Talhão B',
          'idFazenda': 'fazenda_1',
          'areaTotal': 75.0,
          'dataCriacao': DateTime.now().toIso8601String(),
          'dataAtualizacao': DateTime.now().toIso8601String(),
          'sincronizado': 1,
          'observacoes': 'Talhão de exemplo',
          'criadoPor': 'sistema',
          'status': 'ativo'
        });
        
        print('✅ Dados de exemplo adicionados à tabela de talhões');
      }
    } catch (e) {
      print('❌ Erro ao adicionar dados de exemplo: $e');
    }
  }
} 
import 'package:sqflite/sqflite.dart';

/// Classe responsável pela migração do banco de dados para suportar integração entre módulos
class ModuleIntegrationMigration {
  /// Cria as tabelas necessárias para a integração entre módulos
  static Future<void> executeMigration(Database db) async {
    // Verificar se as tabelas já existem
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'atividades_agricolas'],
    );

    // Se a tabela principal já existe, não executa a migração
    if (tables.isNotEmpty) {
      print('Migração de integração entre módulos já foi aplicada.');
      return;
    }

    // Executar as migrações em uma transação
    await db.transaction((txn) async {
      // Verificar e criar a tabela de talhões unificada se não existir
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS talhoes_unificados (
          id TEXT PRIMARY KEY,
          nome TEXT NOT NULL,
          area REAL NOT NULL,
          poligonos TEXT NOT NULL,
          observacoes TEXT,
          criadoEm TEXT NOT NULL,
          atualizadoEm TEXT NOT NULL,
          criadoPor TEXT NOT NULL,
          sincronizado INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Tabela de safras associadas a talhões
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS safras_unificadas (
          id TEXT PRIMARY KEY,
          talhaoId TEXT NOT NULL,
          safra TEXT NOT NULL,
          culturaId TEXT NOT NULL,
          dataCriacao TEXT NOT NULL,
          dataAtualizacao TEXT NOT NULL,
          sincronizado INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (talhaoId) REFERENCES talhoes_unificados(id) ON DELETE CASCADE
        )
      ''');

      // Tabela base de atividades para rastreabilidade
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS atividades_agricolas (
          id TEXT PRIMARY KEY,
          talhaoId TEXT NOT NULL,
          safraId TEXT NOT NULL,
          culturaId TEXT NOT NULL,
          tipoAtividade TEXT NOT NULL,
          dataAtividade TEXT NOT NULL,
          detalhesId TEXT NOT NULL,
          sincronizado INTEGER NOT NULL DEFAULT 0,
          criadoEm TEXT NOT NULL,
          atualizadoEm TEXT NOT NULL,
          FOREIGN KEY (talhaoId) REFERENCES talhoes_unificados(id) ON DELETE CASCADE,
          FOREIGN KEY (safraId) REFERENCES safras_unificadas(id) ON DELETE CASCADE
        )
      ''');

      // Tabela de alertas integrada
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS alertas_integrados (
          id TEXT PRIMARY KEY,
          talhaoId TEXT NOT NULL,
          safraId TEXT NOT NULL,
          culturaId TEXT NOT NULL,
          tipo TEXT NOT NULL,
          nivel INTEGER NOT NULL,
          mensagem TEXT NOT NULL,
          dataCriacao TEXT NOT NULL,
          dataAtualizacao TEXT NOT NULL,
          resolvido INTEGER NOT NULL DEFAULT 0,
          sincronizado INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (talhaoId) REFERENCES talhoes_unificados(id) ON DELETE CASCADE,
          FOREIGN KEY (safraId) REFERENCES safras_unificadas(id) ON DELETE CASCADE
        )
      ''');
      
      // Adicionar colunas de relacionamento nas tabelas existentes se necessário
      await _adicionarColunasEmTabelasExistentes(txn);
      
      print('Migração de integração entre módulos aplicada com sucesso.');
    });
  }

  /// Adiciona colunas de relacionamento nas tabelas existentes
  static Future<void> _adicionarColunasEmTabelasExistentes(Transaction txn) async {
    // Lista de tabelas e colunas para adicionar
    final tabelasAModificar = [
      {
        'tabela': 'plantings',
        'colunas': ['safraId TEXT', 'culturaId TEXT', 'atividadeId TEXT']
      },
      {
        'tabela': 'pesticide_applications',
        'colunas': ['safraId TEXT', 'culturaId TEXT', 'atividadeId TEXT']
      },
      {
        'tabela': 'monitorings',
        'colunas': ['safraId TEXT', 'culturaId TEXT', 'atividadeId TEXT']
      },
      {
        'tabela': 'harvest_losses',
        'colunas': ['safraId TEXT', 'culturaId TEXT', 'atividadeId TEXT']
      },
      {
        'tabela': 'estande_plantas',
        'colunas': ['safraId TEXT', 'culturaId TEXT', 'atividadeId TEXT']
      },
      {
        'tabela': 'experimentos',
        'colunas': ['safraId TEXT', 'culturaId TEXT', 'atividadeId TEXT']
      }
    ];
    
    // Para cada tabela, verificar se ela existe e adicionar as colunas se necessário
    for (final item in tabelasAModificar) {
      final tabela = item['tabela'] as String;
      final colunas = item['colunas'] as List<String>;
      
      final tables = await txn.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tabela],
      );
      
      // Se a tabela existe, adicionar as colunas
      if (tables.isNotEmpty) {
        for (final coluna in colunas) {
          final nomeColuna = coluna.split(' ').first;
          
          // Verificar se a coluna já existe
          try {
            // Tenta adicionar a coluna, ignorando erro caso ela já exista
            await txn.execute('ALTER TABLE $tabela ADD COLUMN $coluna');
            print('Coluna $nomeColuna adicionada à tabela $tabela');
          } catch (e) {
            // Ignora o erro se a coluna já existir
            print('Erro ao adicionar coluna $nomeColuna à tabela $tabela: $e');
          }
        }
      } else {
        print('Tabela $tabela não encontrada, pulando modificações.');
      }
    }
  }
  
  /// Populate data from existing tables to new integrated tables
  static Future<void> migrateData(Database db) async {
    // Esta função deve ser executada após a criação das tabelas para migrar dados existentes
    await db.transaction((txn) async {
      // Migrar talhões de plots para talhoes_unificados
      await _migrarTalhoes(txn);
      
      // Migrar safras onde existirem
      await _migrarSafras(txn);
    });
  }
  
  /// Migra dados da tabela plots para talhoes_unificados
  static Future<void> _migrarTalhoes(Transaction txn) async {
    // Buscar todos os plots existentes
    final plots = await txn.query('plots');
    
    for (final plot in plots) {
      // Verificar se o talhão já existe na tabela unificada
      final talhaoExistente = await txn.query(
        'talhoes_unificados',
        where: 'id = ?',
        whereArgs: [plot['id']],
      );
      
      if (talhaoExistente.isEmpty) {
        // Converter os dados para o formato unificado
        await txn.insert(
          'talhoes_unificados',
          {
            'id': plot['id'],
            'nome': plot['name'],
            'area': plot['area'] ?? 0.0,
            'poligonos': plot['polygon_json'] ?? '[]',
            'observacoes': '',
            'criadoEm': plot['created_at'] ?? DateTime.now().toIso8601String(),
            'atualizadoEm': plot['updated_at'] ?? DateTime.now().toIso8601String(),
            'criadoPor': 'sistema',
            'sincronizado': 0
          },
        );
      }
    }
  }

  /// Migra dados de safras existentes
  static Future<void> _migrarSafras(Transaction txn) async {
    // Implementar se houver tabelas de safras existentes
    // Por enquanto, esta é apenas uma função de placeholder
  }
}

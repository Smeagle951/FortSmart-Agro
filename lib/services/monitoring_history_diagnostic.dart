import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço de diagnóstico do histórico de monitoramento
/// Verifica onde os dados estão sendo salvos
class MonitoringHistoryDiagnostic {
  final AppDatabase _database = AppDatabase();

  /// Executa diagnóstico completo do histórico
  Future<Map<String, dynamic>> executarDiagnostico() async {
    try {
      final db = await _database.database;
      
      print('\n╔═══════════════════════════════════════════════════════╗');
      print('║   🔍 DIAGNÓSTICO DO HISTÓRICO DE MONITORAMENTO        ║');
      print('╚═══════════════════════════════════════════════════════╝\n');

      // 1. Verificar tabelas que existem
      final tabelas = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      );
      
      print('📋 TABELAS EXISTENTES:');
      for (final tabela in tabelas) {
        print('   ✓ ${tabela['name']}');
      }
      print('');

      // 2. Contar registros em cada tabela relevante
      final tabelasMonitoramento = [
        'monitoring_sessions',
        'monitoring_history',
        'monitoring_occurrences',
        'monitoring_points',
        'infestation_map',
        'infestacoes_monitoramento',
      ];

      print('📊 CONTAGEM DE REGISTROS:\n');
      
      final contagens = <String, int>{};
      
      for (final tabela in tabelasMonitoramento) {
        try {
          final count = await db.rawQuery('SELECT COUNT(*) as total FROM $tabela');
          final total = count.first['total'] as int;
          contagens[tabela] = total;
          
          final status = total > 0 ? '✅' : '⚠️';
          print('   $status $tabela: $total registros');
          
          // Se tem registros, mostrar amostra
          if (total > 0) {
            final amostra = await db.query(tabela, limit: 1, orderBy: 'created_at DESC');
            if (amostra.isNotEmpty) {
              final campos = amostra.first.keys.take(5).join(', ');
              print('      Campos: $campos...');
            }
          }
        } catch (e) {
          print('   ❌ $tabela: Tabela não existe ou erro ($e)');
          contagens[tabela] = -1;
        }
      }

      print('');

      // 3. Verificar dados nas últimas 24 horas
      print('🕐 DADOS DAS ÚLTIMAS 24 HORAS:\n');
      
      final ontem = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      
      // monitoring_history
      try {
        final recent = await db.query(
          'monitoring_history',
          where: 'created_at > ?',
          whereArgs: [ontem],
        );
        print('   📚 monitoring_history: ${recent.length} registros recentes');
        
        if (recent.isNotEmpty) {
          final primeiro = recent.first;
          print('      Último: ${primeiro['plot_name']} - ${primeiro['created_at']}');
        }
      } catch (e) {
        print('   ❌ Erro ao consultar monitoring_history: $e');
      }

      // monitoring_sessions
      try {
        final sessions = await db.query(
          'monitoring_sessions',
          where: 'created_at > ?',
          whereArgs: [ontem],
        );
        print('   🎯 monitoring_sessions: ${sessions.length} sessões recentes');
        
        if (sessions.isNotEmpty) {
          final primeira = sessions.first;
          print('      Última: ${primeira['talhao_nome']} - Status: ${primeira['status']}');
        }
      } catch (e) {
        print('   ❌ Erro ao consultar monitoring_sessions: $e');
      }

      // monitoring_occurrences
      try {
        final occurrences = await db.query(
          'monitoring_occurrences',
          where: 'created_at > ?',
          whereArgs: [ontem],
        );
        print('   🐛 monitoring_occurrences: ${occurrences.length} ocorrências recentes');
        
        if (occurrences.isNotEmpty) {
          final primeira = occurrences.first;
          print('      Última: ${primeira['subtipo']} - ${primeira['percentual']}%');
        }
      } catch (e) {
        print('   ❌ Erro ao consultar monitoring_occurrences: $e');
      }

      print('');

      // 4. Verificar sessões por status
      print('📌 SESSÕES POR STATUS:\n');
      
      try {
        final statuses = ['active', 'pausado', 'finalized'];
        
        for (final status in statuses) {
          final count = await db.query(
            'monitoring_sessions',
            where: 'status = ?',
            whereArgs: [status],
          );
          
          final emoji = status == 'active' ? '🟢' : 
                        status == 'pausado' ? '🟡' : '🔵';
          print('   $emoji $status: ${count.length} sessões');
        }
      } catch (e) {
        print('   ❌ Erro ao verificar status: $e');
      }

      print('');

      // 5. Verificar compatibilidade de dados
      print('🔗 COMPATIBILIDADE DE DADOS:\n');
      
      try {
        // Verificar se há session_id em monitoring_occurrences
        final occWithSession = await db.rawQuery(
          "SELECT COUNT(*) as total FROM monitoring_occurrences WHERE session_id IS NOT NULL"
        );
        final total = occWithSession.first['total'] as int;
        print('   ✓ Ocorrências com session_id: $total');
        
        // Verificar se há organismo_id
        final occWithOrganism = await db.rawQuery(
          "SELECT COUNT(*) as total FROM monitoring_occurrences WHERE organismo_id IS NOT NULL"
        );
        final totalOrg = occWithOrganism.first['total'] as int;
        print('   ✓ Ocorrências com organismo_id: $totalOrg');
        
      } catch (e) {
        print('   ❌ Erro na verificação de compatibilidade: $e');
      }

      print('\n╔═══════════════════════════════════════════════════════╗');
      print('║              FIM DO DIAGNÓSTICO                       ║');
      print('╚═══════════════════════════════════════════════════════╝\n');

      return {
        'tabelas_existentes': tabelas.map((t) => t['name']).toList(),
        'contagens': contagens,
        'total_monitoramentos': contagens['monitoring_history'] ?? 0,
        'total_sessoes': contagens['monitoring_sessions'] ?? 0,
        'total_ocorrencias': contagens['monitoring_occurrences'] ?? 0,
        'diagnostico_completo': true,
      };

    } catch (e) {
      Logger.error('Erro ao executar diagnóstico: $e');
      return {
        'erro': e.toString(),
        'diagnostico_completo': false,
      };
    }
  }

  /// Cria as tabelas necessárias se não existirem
  Future<void> criarTabelasSeNecessario() async {
    try {
      final db = await _database.database;
      
      print('🔧 Verificando e criando tabelas necessárias...\n');

      // Criar monitoring_sessions se não existir
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monitoring_sessions (
          id TEXT PRIMARY KEY,
          fazenda_id TEXT NOT NULL,
          talhao_id TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          talhao_nome TEXT NOT NULL,
          cultura_nome TEXT NOT NULL,
          total_pontos INTEGER NOT NULL DEFAULT 0,
          total_ocorrencias INTEGER NOT NULL DEFAULT 0,
          data_inicio TEXT NOT NULL,
          data_fim TEXT,
          status TEXT NOT NULL DEFAULT 'active',
          tecnico_nome TEXT,
          observacoes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      print('✅ Tabela monitoring_sessions verificada/criada');

      // Adicionar colunas novas se necessário
      await _adicionarColunaSeNaoExiste(
        db, 
        'monitoring_occurrences', 
        'organismo_id', 
        'TEXT'
      );
      
      await _adicionarColunaSeNaoExiste(
        db, 
        'monitoring_occurrences', 
        'quantidade_bruta', 
        'INTEGER'
      );
      
      await _adicionarColunaSeNaoExiste(
        db, 
        'monitoring_occurrences', 
        'total_plantas_avaliadas', 
        'INTEGER'
      );
      
      await _adicionarColunaSeNaoExiste(
        db, 
        'monitoring_occurrences', 
        'terco_planta', 
        'TEXT'
      );

      print('✅ Colunas novas adicionadas com sucesso\n');

    } catch (e) {
      Logger.error('Erro ao criar tabelas: $e');
    }
  }

  /// Adiciona coluna se não existir
  Future<void> _adicionarColunaSeNaoExiste(
    Database db,
    String tabela,
    String coluna,
    String tipo,
  ) async {
    try {
      // Verificar se a coluna já existe
      final colunas = await db.rawQuery('PRAGMA table_info($tabela)');
      final colunaExiste = colunas.any((c) => c['name'] == coluna);
      
      if (!colunaExiste) {
        await db.execute('ALTER TABLE $tabela ADD COLUMN $coluna $tipo');
        print('   ✓ Coluna $coluna adicionada em $tabela');
      }
    } catch (e) {
      // Ignorar erro se a tabela não existir
    }
  }

  /// Limpa histórico antigo (para testes)
  Future<int> limparHistoricoAntigo({int dias = 7}) async {
    try {
      final db = await _database.database;
      final dataLimite = DateTime.now().subtract(Duration(days: dias)).toIso8601String();
      
      final deletados = await db.delete(
        'monitoring_history',
        where: 'created_at < ?',
        whereArgs: [dataLimite],
      );
      
      print('🗑️ $deletados registros antigos removidos (> $dias dias)');
      return deletados;
      
    } catch (e) {
      Logger.error('Erro ao limpar histórico: $e');
      return 0;
    }
  }
}


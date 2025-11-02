import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../models/germination_test_model.dart';
import '../../../utils/logger.dart';

/// Repositório para gerenciar testes de germinação
class GerminationTestRepository {
  final AppDatabase _appDatabase = AppDatabase();

  Future<Database> get database async => await _appDatabase.database;

  // Nomes das tabelas
  static const String tabelaTeste = 'germination_tests';
  static const String tabelaSubteste = 'germination_subtests';
  static const String tabelaRegistroDiario = 'germination_daily_records';

  /// Garante que as tabelas estão inicializadas
  Future<void> _ensureTablesExist() async {
    try {
      Logger.info('🔄 Verificando se as tabelas de germinação existem...');
      final db = await database;
      
      // Verificar se as tabelas existem
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name IN (?, ?, ?)',
        whereArgs: ['table', tabelaTeste, tabelaSubteste, tabelaRegistroDiario],
      );
      
      Logger.info('📊 Tabelas encontradas: ${tables.length}');
      for (final table in tables) {
        Logger.info('  - ${table['name']}');
      }
      
      if (tables.length < 3) {
        Logger.info('🔄 Criando tabelas de germinação...');
        await _inicializarTabelas(db);
        Logger.info('✅ Tabelas de germinação criadas com sucesso');
      } else {
        Logger.info('✅ Tabelas de germinação já existem');
      }
    } catch (e) {
      Logger.error('❌ Erro ao verificar/criar tabelas de germinação: $e');
      rethrow;
    }
  }

  /// Inicializa as tabelas no banco de dados
  Future<void> _inicializarTabelas(Database db) async {
    Logger.info('🔧 Inicializando tabelas de germinação...');
    
    // Tabela de testes de germinação
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabelaTeste (
        id TEXT PRIMARY KEY,
        lote_id TEXT NOT NULL,
        cultura TEXT NOT NULL,
        variedade TEXT NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        status TEXT NOT NULL,
        observacoes TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        usuario_id TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        percentual_final REAL,
        categoria_final TEXT,
        vigor_final REAL,
        pureza_final REAL
      )
    ''');

    // Tabela de subtestes (A, B, C)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabelaSubteste (
        id TEXT PRIMARY KEY,
        germinationTestId INTEGER NOT NULL,
        subtestCode TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        FOREIGN KEY (germinationTestId) REFERENCES $tabelaTeste (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de registros diários
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tabelaRegistroDiario (
        id TEXT PRIMARY KEY,
        subtestId INTEGER NOT NULL,
        dia INTEGER NOT NULL,
        germinadas INTEGER NOT NULL,
        nao_germinadas INTEGER NOT NULL,
        manchas INTEGER NOT NULL,
        podridao INTEGER NOT NULL,
        cotiledones_amarelados INTEGER NOT NULL,
        vigor TEXT NOT NULL,
        pureza REAL NOT NULL,
        percentual_germinacao REAL NOT NULL,
        categoria_germinacao TEXT NOT NULL,
        data_registro TEXT NOT NULL,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        usuario_id TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        FOREIGN KEY (subtestId) REFERENCES $tabelaSubteste (id) ON DELETE CASCADE
      )
    ''');
    
    Logger.info('✅ Tabelas de germinação criadas com sucesso');
  }

  /// Cria um novo teste de germinação
  Future<String> criarTesteGerminacao(GerminationTestModel teste) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      await db.insert(tabelaTeste, teste.toMap());
      
      // Criar subtestes A, B, C automaticamente
      final subtestes = ['A', 'B', 'C'];
      for (final label in subtestes) {
        final subteste = GerminationSubtestModel(
          id: '${teste.id}_$label',
          testId: teste.id,
          subtestLabel: label,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        );
        await db.insert(tabelaSubteste, subteste.toMap());
      }
      
      Logger.info('✅ Teste de germinação criado: ${teste.id}');
      return teste.id;
    } catch (e) {
      Logger.error('❌ Erro ao criar teste de germinação: $e');
      rethrow;
    }
  }

  /// Busca todos os testes de germinação
  Future<List<GerminationTestModel>> buscarTodosTestes() async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      final testes = await db.query(
        tabelaTeste,
        orderBy: 'criado_em DESC',
      );
      
      return testes.map((t) => GerminationTestModel.fromMap(t)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar testes de germinação: $e');
      return [];
    }
  }

  /// Busca um teste específico por ID
  Future<GerminationTestModel?> buscarTestePorId(String id) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      final testes = await db.query(
        tabelaTeste,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (testes.isEmpty) return null;
      return GerminationTestModel.fromMap(testes.first);
    } catch (e) {
      Logger.error('❌ Erro ao buscar teste por ID: $e');
      return null;
    }
  }

  /// Busca subtestes de um teste
  Future<List<GerminationSubtestModel>> buscarSubtestes(String testId) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      final subtestes = await db.query(
        tabelaSubteste,
        where: 'germinationTestId = ?',
        whereArgs: [testId],
        orderBy: 'subtestCode',
      );
      
      return subtestes.map((s) => GerminationSubtestModel.fromMap(s)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar subtestes: $e');
      return [];
    }
  }

  /// Adiciona registro diário
  Future<String> adicionarRegistroDiario(GerminationDailyRecordModel registro) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      await db.insert(tabelaRegistroDiario, registro.toMap());
      Logger.info('✅ Registro diário adicionado: ${registro.id}');
      return registro.id;
    } catch (e) {
      Logger.error('❌ Erro ao adicionar registro diário: $e');
      rethrow;
    }
  }

  /// Busca registros diários de um subteste
  Future<List<GerminationDailyRecordModel>> buscarRegistrosDiarios(String subtestId) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      final registros = await db.query(
        tabelaRegistroDiario,
        where: 'subtestId = ?',
        whereArgs: [subtestId],
        orderBy: 'dia ASC',
      );
      
      return registros.map((r) => GerminationDailyRecordModel.fromMap(r)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar registros diários: $e');
      return [];
    }
  }

  /// Busca todos os registros diários de um teste
  Future<List<GerminationDailyRecordModel>> buscarRegistrosPorTeste(String testId) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      final registros = await db.rawQuery('''
        SELECT r.* FROM $tabelaRegistroDiario r
        JOIN $tabelaSubteste s ON r.subtestId = s.id
        WHERE s.germinationTestId = ?
        ORDER BY s.subtestCode, r.dia ASC
      ''', [testId]);
      
      return registros.map((r) => GerminationDailyRecordModel.fromMap(r)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar registros por teste: $e');
      return [];
    }
  }

  /// Calcula resultados consolidados de um teste
  Future<GerminationTestResultModel> calcularResultados(String testId) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      // Buscar subtestes
      final subtestes = await buscarSubtestes(testId);
      final resultadosSubtestes = <GerminationSubtestResult>[];
      
      double percentualTotal = 0.0;
      double vigorTotal = 0.0;
      double purezaTotal = 0.0;
      int subtestesComDados = 0;
      
      for (final subteste in subtestes) {
        // Buscar registros do subteste
        final registros = await buscarRegistrosDiarios(subteste.id);
        
        if (registros.isNotEmpty) {
          // Pegar o último registro (mais recente)
          final ultimoRegistro = registros.last;
          
          // Calcular médias
          final vigorMedio = _calcularVigorMedio(registros);
          final purezaMedia = _calcularPurezaMedia(registros);
          
          final resultadoSubteste = GerminationSubtestResult(
            subtestLabel: subteste.subtestLabel,
            percentualFinal: ultimoRegistro.percentualGerminacao,
            categoriaFinal: ultimoRegistro.categoriaGerminacao,
            vigorMedio: vigorMedio,
            purezaMedia: purezaMedia,
            registros: registros,
          );
          
          resultadosSubtestes.add(resultadoSubteste);
          
          // Acumular para média geral
          percentualTotal += ultimoRegistro.percentualGerminacao;
          vigorTotal += vigorMedio;
          purezaTotal += purezaMedia;
          subtestesComDados++;
        }
      }
      
      // Calcular médias gerais
      final percentualMedio = subtestesComDados > 0 ? percentualTotal / subtestesComDados : 0.0;
      final vigorMedio = subtestesComDados > 0 ? vigorTotal / subtestesComDados : 0.0;
      final purezaMedia = subtestesComDados > 0 ? purezaTotal / subtestesComDados : 0.0;
      
      // Determinar categoria média
      final categoriaMedia = _determinarCategoriaMedia(percentualMedio);
      
      return GerminationTestResultModel(
        testId: testId,
        percentualMedio: percentualMedio,
        categoriaMedia: categoriaMedia,
        vigorMedio: vigorMedio,
        purezaMedia: purezaMedia,
        subtestes: resultadosSubtestes,
        calculadoEm: DateTime.now(),
      );
    } catch (e) {
      Logger.error('❌ Erro ao calcular resultados: $e');
      rethrow;
    }
  }

  /// Calcula vigor médio dos registros
  double _calcularVigorMedio(List<GerminationDailyRecordModel> registros) {
    if (registros.isEmpty) return 0.0;
    
    double vigorTotal = 0.0;
    for (final registro in registros) {
      switch (registro.vigor) {
        case 'Alto':
          vigorTotal += 1.0;
          break;
        case 'Médio':
          vigorTotal += 0.5;
          break;
        case 'Baixo':
          vigorTotal += 0.0;
          break;
      }
    }
    
    return vigorTotal / registros.length;
  }

  /// Calcula pureza média dos registros
  double _calcularPurezaMedia(List<GerminationDailyRecordModel> registros) {
    if (registros.isEmpty) return 0.0;
    
    final purezaTotal = registros.fold(0.0, (sum, r) => sum + r.pureza);
    return purezaTotal / registros.length;
  }

  /// Determina categoria média baseada no percentual
  String _determinarCategoriaMedia(double percentual) {
    if (percentual >= 90) return 'Excelente';
    if (percentual >= 80) return 'Boa';
    if (percentual >= 70) return 'Regular';
    return 'Ruim';
  }

  /// Atualiza um teste de germinação
  Future<void> atualizarTeste(GerminationTestModel teste) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      await db.update(
        tabelaTeste,
        teste.toMap(),
        where: 'id = ?',
        whereArgs: [teste.id],
      );
      Logger.info('✅ Teste de germinação atualizado: ${teste.id}');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar teste: $e');
      rethrow;
    }
  }

  /// Finaliza um teste de germinação
  Future<void> finalizarTeste(String testId, double percentualFinal, String categoriaFinal) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      await db.update(
        tabelaTeste,
        {
          'status': 'concluido',
          'data_fim': DateTime.now().toIso8601String(),
          'percentual_final': percentualFinal,
          'categoria_final': categoriaFinal,
          'atualizado_em': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [testId],
      );
      Logger.info('✅ Teste de germinação finalizado: $testId');
    } catch (e) {
      Logger.error('❌ Erro ao finalizar teste: $e');
      rethrow;
    }
  }

  /// Remove um teste de germinação
  Future<void> removerTeste(String testId) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      await db.delete(
        tabelaTeste,
        where: 'id = ?',
        whereArgs: [testId],
      );
      Logger.info('✅ Teste de germinação removido: $testId');
    } catch (e) {
      Logger.error('❌ Erro ao remover teste: $e');
      rethrow;
    }
  }

  /// Busca testes por status
  Future<List<GerminationTestModel>> buscarTestesPorStatus(String status) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      final testes = await db.query(
        tabelaTeste,
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'criado_em DESC',
      );
      
      return testes.map((t) => GerminationTestModel.fromMap(t)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar testes por status: $e');
      return [];
    }
  }

  /// Busca testes por lote
  Future<List<GerminationTestModel>> buscarTestesPorLote(String loteId) async {
    await _ensureTablesExist();
    final db = await database;
    
    try {
      final testes = await db.query(
        tabelaTeste,
        where: 'lote_id = ?',
        whereArgs: [loteId],
        orderBy: 'criado_em DESC',
      );
      
      return testes.map((t) => GerminationTestModel.fromMap(t)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar testes por lote: $e');
      return [];
    }
  }
}

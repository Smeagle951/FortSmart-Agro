/// 🗄️ Database: Gerenciador do Banco de Dados Fenológico
/// 
/// Gerenciador centralizado do banco de dados SQLite
/// para o submódulo de Evolução Fenológica.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'daos/phenological_record_dao.dart';
import 'daos/phenological_alert_dao.dart';

class PhenologicalDatabase {
  static final PhenologicalDatabase _instance = PhenologicalDatabase._internal();
  factory PhenologicalDatabase() => _instance;
  PhenologicalDatabase._internal();

  static Database? _database;
  static const String _databaseName = 'phenological.db';
  static const int _databaseVersion = 3; // Atualizado para corrigir índices snake_case

  /// Getter: Database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializar banco de dados
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Criar tabelas na primeira execução
  Future<void> _onCreate(Database db, int version) async {
    print('🗄️ Criando banco de dados fenológico...');
    
    // Criar tabela de registros fenológicos
    await db.execute(PhenologicalRecordDAO.createTableScript);
    print('✅ Tabela phenological_records criada');
    
    // Criar tabela de alertas
    await db.execute(PhenologicalAlertDAO.createTableScript);
    print('✅ Tabela phenological_alerts criada');
    
    // Criar índices para melhor performance
    await _createIndexes(db);
    
    print('✅ Banco de dados fenológico criado com sucesso!');
  }

  /// Criar índices para otimização de consultas
  Future<void> _createIndexes(Database db) async {
    // Índice para busca por talhão e cultura (registros) - CORRIGIDO: snake_case
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_records_talhao_cultura 
      ON ${PhenologicalRecordDAO.tableName}(talhao_id, cultura_id)
    ''');
    
    // Índice para busca por data (registros) - CORRIGIDO: snake_case
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_records_data 
      ON ${PhenologicalRecordDAO.tableName}(data_registro)
    ''');
    
    // Índice para busca por talhão e cultura (alertas) - CORRIGIDO: snake_case
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_alerts_talhao_cultura 
      ON ${PhenologicalAlertDAO.tableName}(talhao_id, cultura_id)
    ''');
    
    // Índice para busca por status (alertas) - já correto
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_alerts_status 
      ON ${PhenologicalAlertDAO.tableName}(status)
    ''');
    
    print('✅ Índices criados com sucesso');
  }

  /// Upgrade do banco de dados (migrações futuras)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Atualizando banco de dados de v$oldVersion para v$newVersion...');
    
    if (oldVersion < 3) {
      // Verificar se a tabela usa camelCase ou snake_case
      print('🔍 Verificando estrutura da tabela phenological_records...');
      
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(${PhenologicalRecordDAO.tableName})');
        final columnNames = tableInfo.map((col) => col['name'] as String).toList();
        
        final usaCamelCase = columnNames.contains('talhaoId');
        final usaSnakeCase = columnNames.contains('talhao_id');
        
        print('   - Usa camelCase: $usaCamelCase');
        print('   - Usa snake_case: $usaSnakeCase');
        
        if (usaCamelCase && !usaSnakeCase) {
          print('⚠️ Tabela antiga detectada com camelCase. Recriando tabela...');
          
          // Backup dos dados
          final dados = await db.query(PhenologicalRecordDAO.tableName);
          print('   - Backup: ${dados.length} registros');
          
          // Dropar tabela antiga
          await db.execute('DROP TABLE IF EXISTS ${PhenologicalRecordDAO.tableName}');
          
          // Recriar com snake_case
          await db.execute(PhenologicalRecordDAO.createTableScript);
          print('✅ Tabela recriada com snake_case');
          
          // Restaurar dados (se houver)
          if (dados.isNotEmpty) {
            print('🔄 Restaurando ${dados.length} registros...');
            for (var registro in dados) {
              // Converter de camelCase para snake_case
              final registroConvertido = {
                'id': registro['id'],
                'talhao_id': registro['talhaoId'],
                'cultura_id': registro['culturaId'],
                'data_registro': registro['dataRegistro'],
                'dias_apos_emergencia': registro['diasAposEmergencia'],
                'altura_cm': registro['alturaCm'],
                'numero_folhas': registro['numeroFolhas'],
                'numero_folhas_trifolioladas': registro['numeroFolhasTrifolioladas'],
                'diametro_colmo_mm': registro['diametroColmoMm'],
                'numero_nos': registro['numeroNos'],
                'espacamento_entre_nos_cm': registro['espacamentoEntreNosCm'],
                'numero_ramos_vegetativos': registro['numeroRamosVegetativos'],
                'numero_ramos_reprodutivos': registro['numeroRamosReprodutivos'],
                'altura_primeiro_ramo_frutifero_cm': registro['alturaPrimeiroRamoFrutiferoCm'],
                'numero_botoes_florais': registro['numeroBotoesFlor ais'] ?? registro['numeroBotoesFlor_ais'],
                'numero_macas_capulhos': registro['numeroMacasCapulhos'],
                'numero_afilhos': registro['numeroAfilhos'],
                'comprimento_panicula_cm': registro['comprimentoPaniculaCm'],
                'insercao_espiga_cm': registro['insercaoEspigaCm'],
                'comprimento_espiga_cm': registro['comprimentoEspigaCm'],
                'numero_fileiras_graos': registro['numeroFileirasGraos'],
                'vagens_planta': registro['vagensPlanta'],
                'espigas_planta': registro['espigasPlanta'],
                'comprimento_vagens_cm': registro['comprimentoVagensCm'],
                'graos_vagem': registro['graosVagem'],
                'estande_plantas': registro['estandePlantas'],
                'percentual_falhas': registro['percentualFalhas'],
                'percentual_sanidade': registro['percentualSanidade'],
                'sintomas_observados': registro['sintomasObservados'],
                'presenca_pragas': registro['presencaPragas'],
                'presenca_doencas': registro['presencaDoencas'],
                'estagio_fenologico': registro['estagioFenologico'],
                'descricao_estagio': registro['descricaoEstagio'],
                'fotos': registro['fotos'],
                'observacoes': registro['observacoes'],
                'latitude': registro['latitude'],
                'longitude': registro['longitude'],
                'responsavel': registro['responsavel'],
                'created_at': registro['createdAt'],
                'updated_at': registro['updatedAt'],
              };
              
              await db.insert(PhenologicalRecordDAO.tableName, registroConvertido);
            }
            print('✅ Registros restaurados');
          }
        }
        
        // Remover índices antigos se existirem
        print('🔧 Removendo índices antigos...');
        await db.execute('DROP INDEX IF EXISTS idx_records_talhao_cultura');
        await db.execute('DROP INDEX IF EXISTS idx_records_data');
        await db.execute('DROP INDEX IF EXISTS idx_alerts_talhao_cultura');
        await db.execute('DROP INDEX IF EXISTS idx_alerts_status');
        
        // Recriar índices com nomenclatura correta
        await _createIndexes(db);
        print('✅ Índices recriados com sucesso');
        
      } catch (e) {
        print('❌ Erro durante upgrade: $e');
        // Se falhar, apenas tenta criar índices (pode ser primeira vez)
        try {
          await _createIndexes(db);
        } catch (e2) {
          print('⚠️ Erro ao criar índices: $e2');
        }
      }
    }
    
    // Migração v1 -> v2: Adicionar novos campos de crescimento e desenvolvimento
    if (oldVersion < 2) {
      print('📊 Adicionando novos campos de crescimento e desenvolvimento...');
      
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN numero_nos INTEGER');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN espacamento_entre_nos_cm REAL');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN numero_ramos_vegetativos INTEGER');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN numero_ramos_reprodutivos INTEGER');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN altura_primeiro_ramo_frutifero_cm REAL');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN numero_botoes_florais INTEGER');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN numero_macas_capulhos INTEGER');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN numero_afilhos INTEGER');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN comprimento_panicula_cm REAL');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN insercao_espiga_cm REAL');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN comprimento_espiga_cm REAL');
      await db.execute('ALTER TABLE ${PhenologicalRecordDAO.tableName} ADD COLUMN numero_fileiras_graos INTEGER');
      
      print('✅ Novos campos adicionados com sucesso!');
    }
  }

  /// Fechar banco de dados
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('🔒 Banco de dados fenológico fechado');
  }

  /// Limpar todos os dados (usar com cuidado!)
  Future<void> limparTodosDados() async {
    final db = await database;
    
    await db.delete(PhenologicalRecordDAO.tableName);
    await db.delete(PhenologicalAlertDAO.tableName);
    
    print('🗑️ Todos os dados fenológicos foram removidos');
  }

  /// Obter estatísticas do banco
  Future<Map<String, int>> obterEstatisticas() async {
    final db = await database;
    
    // Contar registros
    final recordsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${PhenologicalRecordDAO.tableName}'
    );
    final recordsCount = Sqflite.firstIntValue(recordsResult) ?? 0;
    
    // Contar alertas ativos
    final alertsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${PhenologicalAlertDAO.tableName} WHERE status = ?',
      ['AlertStatus.ativo'],
    );
    final alertsCount = Sqflite.firstIntValue(alertsResult) ?? 0;
    
    // Contar talhões únicos
    final talhoesResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT talhaoId) as count FROM ${PhenologicalRecordDAO.tableName}'
    );
    final talhoesCount = Sqflite.firstIntValue(talhoesResult) ?? 0;
    
    return {
      'totalRegistros': recordsCount,
      'alertasAtivos': alertsCount,
      'talhoesMonitorados': talhoesCount,
    };
  }

  /// Exportar dados para backup (JSON)
  Future<Map<String, dynamic>> exportarDados() async {
    final db = await database;
    
    final records = await db.query(PhenologicalRecordDAO.tableName);
    final alerts = await db.query(PhenologicalAlertDAO.tableName);
    
    return {
      'version': _databaseVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'records': records,
      'alerts': alerts,
    };
  }

  /// Importar dados de backup (JSON)
  Future<void> importarDados(Map<String, dynamic> backup) async {
    final db = await database;
    
    try {
      await db.transaction((txn) async {
        // Limpar dados existentes
        await txn.delete(PhenologicalRecordDAO.tableName);
        await txn.delete(PhenologicalAlertDAO.tableName);
        
        // Importar registros
        final records = backup['records'] as List<dynamic>;
        for (final record in records) {
          await txn.insert(
            PhenologicalRecordDAO.tableName,
            record as Map<String, dynamic>,
          );
        }
        
        // Importar alertas
        final alerts = backup['alerts'] as List<dynamic>;
        for (final alert in alerts) {
          await txn.insert(
            PhenologicalAlertDAO.tableName,
            alert as Map<String, dynamic>,
          );
        }
      });
      
      print('✅ Dados importados com sucesso!');
    } catch (e) {
      print('❌ Erro ao importar dados: $e');
      rethrow;
    }
  }

  /// Verificar integridade do banco
  Future<bool> verificarIntegridade() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.first['integrity_check'] == 'ok';
    } catch (e) {
      print('❌ Erro ao verificar integridade: $e');
      return false;
    }
  }

  /// Otimizar banco de dados (VACUUM)
  Future<void> otimizar() async {
    final db = await database;
    await db.execute('VACUUM');
    print('✅ Banco de dados otimizado');
  }
}


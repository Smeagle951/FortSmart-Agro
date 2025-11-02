import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

// import 'migrations/create_plantio_tables.dart'; // Comentado temporariamente
import 'migrations/create_monitoring_tables_unified.dart';
import 'migrations/create_subareas_experimento_tables.dart';
import 'migrations/create_inventory_products_table.dart';
import 'migrations/add_subtest_id_to_daily_records_migration.dart';
import 'migrations/create_calibration_history_table.dart';
import 'migrations/create_planting_submodules_tables.dart';
import 'migrations/create_culturas_table.dart';
import 'migrations/create_crop_varieties_table.dart';
import 'migrations/fix_crop_varieties_foreign_key.dart';
import 'migrations/create_agricultural_products_table.dart';
import 'migrations/create_historico_plantio_table.dart';
import 'migrations/fix_monitoring_sessions_table.dart';
import 'migrations/unify_monitoring_sessions_table.dart';
import 'migrations/fix_planting_cv_table.dart';
import 'migrations/fix_talhoes_table.dart';
import 'migrations/create_plantio_table.dart';
import 'migrations/update_plantio_table_structure.dart';
import 'migrations/remove_plantio_fictional_data.dart';
import '../modules/infestation_map/repositories/infestation_repository.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;
  
  AppDatabase._internal();
  
  factory AppDatabase() => _instance;
  
  // Propriedades estáticas para compatibilidade
  static AppDatabase get instance => _instance;
  static String get databaseName => 'fortsmart_agro.db';
  
  static const int _databaseVersion = 57; // Versão com unificação da tabela monitoring_sessions
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    try {
      print('🔄 AppDatabase: Iniciando inicialização do banco...');
      
      // Obter diretório do banco
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'fortsmart_agro.db');
      
      print('🔄 AppDatabase: Inicializando banco de dados: $path, versão: $_databaseVersion');
      
      // Abrir banco
      Database db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
        onConfigure: _onConfigure,
      );
      
      print('✅ AppDatabase: Banco inicializado com sucesso');
      return db;
    } catch (e) {
      print('❌ AppDatabase: Erro ao inicializar banco: $e');
      rethrow;
    }
  }
  
  Future<void> _onConfigure(Database db) async {
    try {
      // ⚠️ TEMPORARIAMENTE DESABILITADO: FOREIGN KEYS
      // await db.execute('PRAGMA foreign_keys = ON');
      await db.execute('PRAGMA foreign_keys = OFF'); // ✅ DESABILITADO PARA DEBUG
      // Usar rawQuery para PRAGMA que retorna resultados
      await db.rawQuery('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.rawQuery('PRAGMA cache_size = 10000');
      await db.execute('PRAGMA temp_store = MEMORY');
      print('⚠️ ATENÇÃO: FOREIGN KEYS DESABILITADAS TEMPORARIAMENTE');
    } catch (e) {
      print('⚠️ Erro ao configurar banco (não crítico): $e');
      // Continuar mesmo com erro - configurações são opcionais
    }
  }
  
  Future<void> _onCreate(Database db, int version) async {
    print('🔄 AppDatabase: Criando tabelas...');
    
    // Criar tabelas principais
    await _createMainTables(db);
    
    // Criar índices
    await _createIndexes(db);
    
    print('✅ AppDatabase: Tabelas criadas com sucesso');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 AppDatabase: Atualizando banco de $oldVersion para $newVersion');
    
    // Executar migrações necessárias
    if (oldVersion < 30) {
      // Remover tabelas de germinação se existirem
      await _removeGerminationTables(db);
    }
    
    if (oldVersion < 31) {
      // Criar tabela talhoes se não existir
      await _createMainTables(db);
    }
    
    if (oldVersion < 32) {
      // Criar tabela pontos_monitoramento se não existir
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pontos_monitoramento (
          id INTEGER PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          data TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          observacoes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0
        )
      ''');
    }
    
    if (oldVersion < 33) {
      // Criar tabelas de germinação se não existirem
      await db.execute('''
        CREATE TABLE IF NOT EXISTS germination_tests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          culture TEXT NOT NULL,
          variety TEXT NOT NULL,
          seedLot TEXT NOT NULL,
          totalSeeds INTEGER NOT NULL,
          startDate TEXT NOT NULL,
          expectedEndDate TEXT,
          pureSeeds INTEGER NOT NULL,
          brokenSeeds INTEGER NOT NULL,
          stainedSeeds INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'active',
          observations TEXT,
          photos TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          hasSubtests INTEGER NOT NULL DEFAULT 0,
          subtestSeedCount INTEGER DEFAULT 100,
          subtestNames TEXT,
          position TEXT,
          finalGerminationPercentage REAL,
          purityPercentage REAL,
          diseasedPercentage REAL,
          culturalValue REAL,
          averageGerminationTime REAL,
          firstCountDay INTEGER,
          day50PercentGermination INTEGER
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS germination_subtests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          testId INTEGER NOT NULL,
          code TEXT NOT NULL,
          totalSeeds INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (testId) REFERENCES germination_tests (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS germination_daily_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          testId INTEGER NOT NULL,
          subtestId INTEGER,
          day INTEGER NOT NULL,
          recordDate TEXT NOT NULL,
          normalGerminated INTEGER NOT NULL DEFAULT 0,
          abnormalGerminated INTEGER NOT NULL DEFAULT 0,
          diseasedFungi INTEGER NOT NULL DEFAULT 0,
          diseasedBacteria INTEGER NOT NULL DEFAULT 0,
          diseasedVirus INTEGER NOT NULL DEFAULT 0,
          notGerminated INTEGER NOT NULL DEFAULT 0,
          otherSeeds INTEGER NOT NULL DEFAULT 0,
          inertMatter INTEGER NOT NULL DEFAULT 0,
          observations TEXT,
          photos TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (testId) REFERENCES germination_tests (id) ON DELETE CASCADE,
          FOREIGN KEY (subtestId) REFERENCES germination_subtests (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS germination_subtest_daily_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subtestId INTEGER NOT NULL,
          day INTEGER NOT NULL,
          recordDate TEXT NOT NULL,
          normalGerminated INTEGER NOT NULL DEFAULT 0,
          abnormalGerminated INTEGER NOT NULL DEFAULT 0,
          diseasedFungi INTEGER NOT NULL DEFAULT 0,
          diseasedBacteria INTEGER NOT NULL DEFAULT 0,
          diseasedVirus INTEGER NOT NULL DEFAULT 0,
          notGerminated INTEGER NOT NULL DEFAULT 0,
          observations TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (subtestId) REFERENCES germination_subtests (id) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 34) {
      // Adicionar colunas faltantes na tabela germination_tests
      await db.execute('ALTER TABLE germination_tests ADD COLUMN photos TEXT');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN subtestNames TEXT');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN position TEXT');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN finalGerminationPercentage REAL');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN purityPercentage REAL');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN diseasedPercentage REAL');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN culturalValue REAL');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN averageGerminationTime REAL');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN firstCountDay INTEGER');
      await db.execute('ALTER TABLE germination_tests ADD COLUMN day50PercentGermination INTEGER');
    }
    
    if (oldVersion < 35) {
      // Criar tabela calibration_history
      await createCalibrationHistoryTable(db);
    }
    
    if (oldVersion < 36) {
      // Corrigir tabela germination_daily_records - adicionar colunas faltantes
      try {
        await db.execute('ALTER TABLE germination_daily_records ADD COLUMN otherSeeds INTEGER NOT NULL DEFAULT 0');
        print('✅ Coluna otherSeeds adicionada à germination_daily_records');
      } catch (e) {
        print('ℹ️ Coluna otherSeeds já existe: $e');
      }
      
      try {
        await db.execute('ALTER TABLE germination_daily_records ADD COLUMN inertMatter INTEGER NOT NULL DEFAULT 0');
        print('✅ Coluna inertMatter adicionada à germination_daily_records');
      } catch (e) {
        print('ℹ️ Coluna inertMatter já existe: $e');
      }
      
      try {
        await db.execute('ALTER TABLE germination_daily_records ADD COLUMN photos TEXT');
        print('✅ Coluna photos adicionada à germination_daily_records');
      } catch (e) {
        print('ℹ️ Coluna photos já existe: $e');
      }
    }
    
    if (oldVersion < 37) {
      // Criar tabelas dos submódulos de plantio
      await createPlantingSubmodulesTables(db);
      print('✅ Tabelas dos submódulos de plantio criadas');
    }
    
        if (oldVersion < 38) {
          // Criar tabela de culturas e corrigir FOREIGN KEY constraints
          await createCulturasTable(db);
          print('✅ Tabela de culturas criada');
        }

        if (oldVersion < 39) {
          // Recriar tabelas com PRAGMA foreign_keys = OFF
          await db.execute('DROP TABLE IF EXISTS calibration_history');
          await db.execute('DROP TABLE IF EXISTS planting_cv');
          await db.execute('DROP TABLE IF EXISTS estande_plantas');
          await db.execute('DROP TABLE IF EXISTS phenological_records');
          await db.execute('DROP TABLE IF EXISTS phenological_alerts');
          await db.execute('DROP TABLE IF EXISTS culturas');
          
          await createCalibrationHistoryTable(db);
          await createPlantingSubmodulesTables(db);
          await createCulturasTable(db);
          print('✅ Tabelas recriadas com PRAGMA foreign_keys = OFF');
        }
        
        if (oldVersion < 40) {
          // Corrigir schemas de plantio e estande_plantas
          print('🔄 Migrando schemas para snake_case...');
          
          // Recriar tabela plantios com schema correto
          await db.execute('DROP TABLE IF EXISTS plantios');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS plantios (
              id TEXT PRIMARY KEY,
              talhao_id TEXT NOT NULL,
              cultura_id TEXT NOT NULL,
              cultura TEXT,
              variedade TEXT,
              data_plantio TEXT NOT NULL,
              data_emergencia TEXT,
              area_plantada REAL NOT NULL,
              espacamento_linhas REAL,
              espacamento_plantas REAL,
              populacao_plantas INTEGER,
              densidade_sementes REAL,
              profundidade_plantio REAL,
              sistema_plantio TEXT,
              observacoes TEXT,
              subarea_id TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              user_id TEXT,
              synchronized INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (talhao_id) REFERENCES talhoes (id) ON DELETE CASCADE
            )
          ''');
          
          // Recriar tabela estande_plantas com schema correto
          await db.execute('DROP TABLE IF EXISTS estande_plantas');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS estande_plantas (
              id TEXT PRIMARY KEY,
              talhao_id TEXT NOT NULL,
              cultura_id TEXT NOT NULL,
              data_emergencia TEXT,
              data_avaliacao TEXT,
              dias_apos_emergencia INTEGER,
              metros_lineares_medidos REAL,
              plantas_contadas INTEGER,
              espacamento REAL,
              plantas_por_metro REAL,
              plantas_por_hectare REAL,
              populacao_ideal REAL,
              eficiencia REAL,
              fotos TEXT,
              observacoes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              sync_status INTEGER DEFAULT 0,
              FOREIGN KEY (talhao_id) REFERENCES talhoes (id) ON DELETE CASCADE,
              FOREIGN KEY (cultura_id) REFERENCES culturas (id) ON DELETE RESTRICT
            )
          ''');
          
          // Criar índices
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_talhao_id ON estande_plantas (talhao_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_cultura_id ON estande_plantas (cultura_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_data_avaliacao ON estande_plantas (data_avaliacao)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_sync_status ON estande_plantas (sync_status)');
          
          print('✅ Schemas corrigidos para snake_case');
        }
        
        if (oldVersion < 41) {
          // Adicionar FOREIGN KEY para cultura_id e inserir culturas padrão
          print('🔄 Adicionando FOREIGN KEY para cultura_id e culturas padrão...');
          
          // Primeiro, criar a tabela culturas com culturas padrão
          await createCulturasTable(db);
          
          // Recriar tabela estande_plantas com FOREIGN KEY para cultura_id
          await db.execute('DROP TABLE IF EXISTS estande_plantas');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS estande_plantas (
              id TEXT PRIMARY KEY,
              talhao_id TEXT NOT NULL,
              cultura_id TEXT NOT NULL,
              data_emergencia TEXT,
              data_avaliacao TEXT,
              dias_apos_emergencia INTEGER,
              metros_lineares_medidos REAL,
              plantas_contadas INTEGER,
              espacamento REAL,
              plantas_por_metro REAL,
              plantas_por_hectare REAL,
              populacao_ideal REAL,
              eficiencia REAL,
              fotos TEXT,
              observacoes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              sync_status INTEGER DEFAULT 0,
              FOREIGN KEY (talhao_id) REFERENCES talhoes (id) ON DELETE CASCADE,
              FOREIGN KEY (cultura_id) REFERENCES culturas (id) ON DELETE RESTRICT
            )
          ''');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_talhao_id ON estande_plantas (talhao_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_cultura_id ON estande_plantas (cultura_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_data_avaliacao ON estande_plantas (data_avaliacao)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_sync_status ON estande_plantas (sync_status)');
          
          print('✅ FOREIGN KEY adicionado e culturas padrão inseridas');
        }
        
        if (oldVersion < 42) {
          // Criar tabela crop_varieties
          print('🔄 Criando tabela crop_varieties...');
          await createCropVarietiesTable(db);
          print('✅ Tabela crop_varieties criada com sucesso');
        }
        
        if (oldVersion < 43) {
          // Corrigir cor do algodão (de branco para azul claro)
          print('🔄 Corrigindo cor do algodão...');
          await db.update(
            'culturas',
            {'color_value': 'E1F5FE'}, // Azul claro em vez de branco
            where: 'id = ?',
            whereArgs: ['custom_algodao'],
          );
          print('✅ Cor do algodão corrigida para azul claro');
        }
        
        if (oldVersion < 44) {
          // REMOVER FOREIGN KEYS DE TALHÃO - CORREÇÃO CRÍTICA DE SALVAMENTO
          print('🔄 MIGRAÇÃO 44: Removendo FOREIGN KEYS de talhão que impediam salvamento...');
          
          // Backup dos dados existentes
          print('💾 Fazendo backup dos dados...');
          final plantiosBackup = await db.rawQuery('SELECT * FROM plantios');
          final estandeBackup = await db.rawQuery('SELECT * FROM estande_plantas');
          final monitoringsBackup = await db.rawQuery('SELECT * FROM monitorings');
          
          // 1. Recriar tabela plantios SEM FOREIGN KEY de talhao_id
          print('🔄 Recriando tabela plantios SEM FOREIGN KEY...');
          await db.execute('DROP TABLE IF EXISTS plantios');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS plantios (
              id TEXT PRIMARY KEY,
              talhao_id TEXT NOT NULL,
              cultura_id TEXT NOT NULL,
              cultura TEXT,
              variedade TEXT,
              data_plantio TEXT NOT NULL,
              data_emergencia TEXT,
              area_plantada REAL NOT NULL,
              espacamento_linhas REAL,
              espacamento_plantas REAL,
              populacao_plantas INTEGER,
              densidade_sementes REAL,
              profundidade_plantio REAL,
              sistema_plantio TEXT,
              observacoes TEXT,
              subarea_id TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              user_id TEXT,
              synchronized INTEGER NOT NULL DEFAULT 0
            )
          ''');
          
          // Restaurar dados de plantios
          print('📥 Restaurando dados de plantios...');
          for (final plantio in plantiosBackup) {
            try {
              await db.insert('plantios', plantio, conflictAlgorithm: ConflictAlgorithm.ignore);
            } catch (e) {
              print('⚠️ Erro ao restaurar plantio ${plantio['id']}: $e');
            }
          }
          
          // 2. Recriar tabela estande_plantas SEM FOREIGN KEY de talhao_id, MAS MANTENDO cultura_id
          print('🔄 Recriando tabela estande_plantas SEM FOREIGN KEY de talhão...');
          await db.execute('DROP TABLE IF EXISTS estande_plantas');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS estande_plantas (
              id TEXT PRIMARY KEY,
              talhao_id TEXT NOT NULL,
              cultura_id TEXT NOT NULL,
              data_emergencia TEXT,
              data_avaliacao TEXT,
              dias_apos_emergencia INTEGER,
              metros_lineares_medidos REAL,
              plantas_contadas INTEGER,
              espacamento REAL,
              plantas_por_metro REAL,
              plantas_por_hectare REAL,
              populacao_ideal REAL,
              eficiencia REAL,
              fotos TEXT,
              observacoes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              sync_status INTEGER DEFAULT 0,
              FOREIGN KEY (cultura_id) REFERENCES culturas (id) ON DELETE RESTRICT
            )
          ''');
          
          // Restaurar dados de estande_plantas
          print('📥 Restaurando dados de estande_plantas...');
          for (final estande in estandeBackup) {
            try {
              await db.insert('estande_plantas', estande, conflictAlgorithm: ConflictAlgorithm.ignore);
            } catch (e) {
              print('⚠️ Erro ao restaurar estande ${estande['id']}: $e');
            }
          }
          
          // 3. Recriar tabela monitorings SEM FOREIGN KEY de talhao_id
          print('🔄 Recriando tabela monitorings SEM FOREIGN KEY...');
          await db.execute('DROP TABLE IF EXISTS monitorings');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS monitorings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              talhao_id INTEGER NOT NULL,
              data_monitoramento TEXT NOT NULL,
              tipo_monitoramento TEXT NOT NULL,
              observacoes TEXT,
              coordenadas TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              user_id TEXT,
              synchronized INTEGER NOT NULL DEFAULT 0
            )
          ''');
          
          // Restaurar dados de monitorings
          print('📥 Restaurando dados de monitorings...');
          for (final monitoring in monitoringsBackup) {
            try {
              await db.insert('monitorings', monitoring, conflictAlgorithm: ConflictAlgorithm.ignore);
            } catch (e) {
              print('⚠️ Erro ao restaurar monitoring ${monitoring['id']}: $e');
            }
          }
          
          // Recriar índices
          await db.execute('CREATE INDEX IF NOT EXISTS idx_plantios_talhao_id ON plantios (talhao_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_plantios_cultura_id ON plantios (cultura_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_talhao_id ON estande_plantas (talhao_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_cultura_id ON estande_plantas (cultura_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_data_avaliacao ON estande_plantas (data_avaliacao)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_sync_status ON estande_plantas (sync_status)');
          
          print('✅ MIGRAÇÃO 44: FOREIGN KEYS de talhão removidas com sucesso!');
          print('📊 Plantios restaurados: ${plantiosBackup.length}');
          print('📊 Estandes restaurados: ${estandeBackup.length}');
          print('📊 Monitoramentos restaurados: ${monitoringsBackup.length}');
          print('🎉 SALVAMENTO RESTAURADO! Módulos agora funcionando normalmente.');
        }
        
        if (oldVersion < 45) {
          // MIGRAÇÃO 45: Corrigir schemas de phenological_records e criar occurrences
          print('🔄 MIGRAÇÃO 45: Corrigindo schemas e criando tabelas faltantes...');
          
          // 1. Recriar phenological_records com snake_case
          print('🔄 Recriando tabela phenological_records com snake_case...');
          try {
            // Backup dos dados
            final phenoBackup = await db.rawQuery('SELECT * FROM phenological_records');
            
            // Drop e recreate
            await db.execute('DROP TABLE IF EXISTS phenological_records');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS phenological_records (
                id TEXT PRIMARY KEY,
                talhao_id TEXT NOT NULL,
                cultura_id TEXT NOT NULL,
                data_registro TEXT NOT NULL,
                dias_apos_emergencia INTEGER NOT NULL,
                altura_cm REAL,
                numero_folhas INTEGER,
                numero_folhas_trifolioladas INTEGER,
                diametro_colmo_mm REAL,
                vagens_planta REAL,
                espigas_planta REAL,
                comprimento_vagens_cm REAL,
                graos_vagem REAL,
                estande_plantas REAL,
                percentual_falhas REAL,
                percentual_sanidade REAL,
                sintomas_observados TEXT,
                presenca_pragas INTEGER,
                presenca_doencas INTEGER,
                estagio_fenologico TEXT,
                descricao_estagio TEXT,
                fotos TEXT,
                observacoes TEXT,
                latitude REAL,
                longitude REAL,
                responsavel TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            
            // Restaurar dados (se existirem)
            for (final record in phenoBackup) {
              try {
                await db.insert('phenological_records', record, conflictAlgorithm: ConflictAlgorithm.ignore);
              } catch (e) {
                print('⚠️ Erro ao restaurar registro fenológico: $e');
              }
            }
            
            print('✅ Tabela phenological_records recriada: ${phenoBackup.length} registros');
          } catch (e) {
            print('⚠️ Erro ao recriar phenological_records: $e (tabela pode não existir ainda)');
          }
          
          // 2. Criar tabela occurrences
          print('🔄 Criando tabela occurrences...');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS occurrences (
              id TEXT PRIMARY KEY,
              monitoring_point_id TEXT NOT NULL,
              monitoring_id TEXT NOT NULL,
              organism_id TEXT NOT NULL,
              organism_name TEXT NOT NULL,
              organism_type TEXT NOT NULL,
              severity_level TEXT NOT NULL,
              infestation_percentage REAL,
              affected_area REAL,
              photo_paths TEXT,
              observations TEXT,
              latitude REAL,
              longitude REAL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              sync_status INTEGER DEFAULT 0
            )
          ''');
          
          // Índices para occurrences
          await db.execute('CREATE INDEX IF NOT EXISTS idx_occurrences_monitoring_point ON occurrences (monitoring_point_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_occurrences_monitoring ON occurrences (monitoring_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_occurrences_created_at ON occurrences (created_at)');
          
          print('✅ MIGRAÇÃO 45: Schemas corrigidos e tabelas criadas!');
        }
        
        if (oldVersion < 46) {
          // MIGRAÇÃO 46: Corrigir tabela fertilizer_calibrations
          print('🔄 MIGRAÇÃO 46: Corrigindo tabela fertilizer_calibrations...');
          
          // Verificar se a tabela existe
          final tableExists = await db.rawQuery('''
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='fertilizer_calibrations'
          ''');
          
          if (tableExists.isNotEmpty) {
            // Tabela existe, adicionar colunas faltantes
            print('🔄 Adicionando colunas faltantes à tabela fertilizer_calibrations...');
            
            try {
              await db.execute('ALTER TABLE fertilizer_calibrations ADD COLUMN collection_time REAL');
              print('✅ Coluna collection_time adicionada');
            } catch (e) {
              print('ℹ️ Coluna collection_time já existe ou erro: $e');
            }
            
            try {
              await db.execute('ALTER TABLE fertilizer_calibrations ADD COLUMN collection_type TEXT');
              print('✅ Coluna collection_type adicionada');
            } catch (e) {
              print('ℹ️ Coluna collection_type já existe ou erro: $e');
            }
          } else {
            // Tabela não existe, criar com schema completo
            print('🔄 Criando tabela fertilizer_calibrations com schema completo...');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS fertilizer_calibrations (
                id TEXT PRIMARY KEY,
                fertilizer_name TEXT NOT NULL,
                granulometry REAL NOT NULL,
                expected_width REAL,
                spacing REAL NOT NULL,
                weights TEXT NOT NULL,
                operator TEXT NOT NULL,
                machine TEXT,
                distribution_system TEXT,
                small_paddle_value REAL,
                large_paddle_value REAL,
                rpm REAL,
                speed REAL,
                density REAL,
                distance_traveled REAL,
                collection_time REAL,
                collection_type TEXT,
                desired_rate REAL,
                real_application_rate REAL,
                error_percentage REAL,
                error_status TEXT,
                coefficient_of_variation REAL,
                cv_status TEXT,
                real_width REAL,
                width_status TEXT,
                average_weight REAL,
                standard_deviation REAL,
                effective_range_indices TEXT,
                date TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            
            // Criar índices
            await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_date ON fertilizer_calibrations (date)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_operator ON fertilizer_calibrations (operator)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_machine ON fertilizer_calibrations (machine)');
            
            print('✅ Tabela fertilizer_calibrations criada com schema completo');
          }
          
          print('✅ MIGRAÇÃO 46: Tabela fertilizer_calibrations corrigida!');
        }
        
        if (oldVersion < 47) {
          // MIGRAÇÃO 47: Forçar recriação da tabela fertilizer_calibrations
          print('🔄 MIGRAÇÃO 47: Forçando recriação da tabela fertilizer_calibrations...');
          
          try {
            // Dropar tabela existente se houver
            await db.execute('DROP TABLE IF EXISTS fertilizer_calibrations');
            print('✅ Tabela antiga removida');
            
            // Recriar tabela com schema completo
            await db.execute('''
              CREATE TABLE IF NOT EXISTS fertilizer_calibrations (
                id TEXT PRIMARY KEY,
                fertilizer_name TEXT NOT NULL,
                granulometry REAL NOT NULL,
                expected_width REAL,
                spacing REAL NOT NULL,
                weights TEXT NOT NULL,
                operator TEXT NOT NULL,
                machine TEXT,
                distribution_system TEXT,
                small_paddle_value REAL,
                large_paddle_value REAL,
                rpm REAL,
                speed REAL,
                density REAL,
                distance_traveled REAL,
                collection_time REAL,
                collection_type TEXT,
                desired_rate REAL,
                real_application_rate REAL,
                error_percentage REAL,
                error_status TEXT,
                coefficient_of_variation REAL,
                cv_status TEXT,
                real_width REAL,
                width_status TEXT,
                average_weight REAL,
                standard_deviation REAL,
                effective_range_indices TEXT,
                date TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
            
            // Recriar índices
            await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_date ON fertilizer_calibrations (date)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_operator ON fertilizer_calibrations (operator)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_fertilizer_calibrations_machine ON fertilizer_calibrations (machine)');
            
            print('✅ Tabela fertilizer_calibrations recriada com sucesso!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 47: $e');
          }
          
          print('✅ MIGRAÇÃO 47: Tabela fertilizer_calibrations recriada!');
        }
        
        if (oldVersion < 48) {
          // MIGRAÇÃO 48: Corrigir chave estrangeira da tabela crop_varieties
          print('🔄 MIGRAÇÃO 48: Corrigindo chave estrangeira da tabela crop_varieties...');
          
          try {
            // Importar e executar a migração
            await fixCropVarietiesForeignKey(db);
            print('✅ MIGRAÇÃO 48: Chave estrangeira da tabela crop_varieties corrigida!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 48: $e');
          }
        }
        
        if (oldVersion < 49) {
          // MIGRAÇÃO 49: Criar tabela agricultural_products
          print('🔄 MIGRAÇÃO 49: Criando tabela agricultural_products...');
          
          try {
            // Importar e executar a migração
            await CreateAgriculturalProductsTable.createAgriculturalProductsTable(db);
            print('✅ MIGRAÇÃO 49: Tabela agricultural_products criada!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 49: $e');
          }
        }
        
        if (oldVersion < 50) {
          // MIGRAÇÃO 50: Criar tabela historico_plantio
          print('🔄 MIGRAÇÃO 50: Criando tabela historico_plantio...');
          
          try {
            // Importar e executar a migração
            await CreateHistoricoPlantioTable.createHistoricoPlantioTable(db);
            print('✅ MIGRAÇÃO 50: Tabela historico_plantio criada!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 50: $e');
          }
        }
        
        if (oldVersion < 51) {
          // MIGRAÇÃO 51: Corrigir tabela monitoring_sessions
          print('🔄 MIGRAÇÃO 51: Corrigindo tabela monitoring_sessions...');
          
          try {
            // Importar e executar a migração
            await FixMonitoringSessionsTable.fixMonitoringSessionsTable(db);
            print('✅ MIGRAÇÃO 51: Tabela monitoring_sessions corrigida!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 51: $e');
          }
        }
        
        if (oldVersion < 52) {
          // MIGRAÇÃO 52: Corrigir tabela planting_cv
          print('🔄 MIGRAÇÃO 52: Corrigindo tabela planting_cv...');
          
          try {
            // Importar e executar a migração
            await FixPlantingCVTable.fixPlantingCVTable(db);
            print('✅ MIGRAÇÃO 52: Tabela planting_cv corrigida!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 52: $e');
          }
        }
        
        if (oldVersion < 53) {
          // MIGRAÇÃO 53: Corrigir tabela talhoes
          print('🔄 MIGRAÇÃO 53: Corrigindo tabela talhoes...');
          
          try {
            // Importar e executar a migração
            await FixTalhoesTable.fixTalhoesTable(db);
            print('✅ MIGRAÇÃO 53: Tabela talhoes corrigida!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 53: $e');
          }
        }
        
        if (oldVersion < 54) {
          // MIGRAÇÃO 54: Criar tabela plantio
          print('🔄 MIGRAÇÃO 54: Criando tabela plantio...');
          
          try {
            await CreatePlantioTable.createPlantioTable(db);
            print('✅ MIGRAÇÃO 54: Tabela plantio criada!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 54: $e');
          }
        }
        
        if (oldVersion < 55) {
          // MIGRAÇÃO 55: Atualizar estrutura da tabela plantio
          print('🔄 MIGRAÇÃO 55: Atualizando estrutura da tabela plantio...');
          
          try {
            await UpdatePlantioTableStructure.updatePlantioTable(db);
            print('✅ MIGRAÇÃO 55: Estrutura da tabela plantio atualizada!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 55: $e');
          }
        }
        
        if (oldVersion < 56) {
          // MIGRAÇÃO 56: Remover dados fictícios da tabela plantio
          print('🔄 MIGRAÇÃO 56: Removendo dados fictícios (população/espaçamento)...');
          
          try {
            await RemovePlantioFictionalData.migrate(db);
            print('✅ MIGRAÇÃO 56: Dados fictícios removidos! População agora vem do Estande de Plantas!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 56: $e');
          }
        }
        
        if (oldVersion < 57) {
          // MIGRAÇÃO 57: Unificar estrutura da tabela monitoring_sessions
          print('🔄 MIGRAÇÃO 57: Unificando tabela monitoring_sessions...');
          
          try {
            await UnifyMonitoringSessionsTable.execute(db);
            print('✅ MIGRAÇÃO 57: Tabela monitoring_sessions unificada! Agora com suporte para ambos os esquemas!');
          } catch (e) {
            print('❌ Erro na MIGRAÇÃO 57: $e');
          }
        }
    
    print('✅ AppDatabase: Banco atualizado com sucesso');
  }
  
  Future<void> _onOpen(Database db) async {
    try {
      print('✅ Banco de dados aberto com sucesso');
      
      // ✅ SISTEMA DE AUTO-CORREÇÃO DE TABELAS
      print('🔧 Verificando integridade das tabelas...');
      
      await _fixMonitoringSessionsSchema(db);
      await _fixMonitoringPointsTable(db);
      await _fixMonitoringOccurrencesTable(db);
      await _fixOccurrencesTableLegacy(db);
      await _fixInfestationMapTable(db);
      await _fixCropVarietiesTable(db);
      await _fixPlantioTable(db);
      await _fixHistoricoPlantioTable(db);
      await _fixPhenologicalRecordsTable(db);
      await _fixEstandePlantasTable(db);
      await _fixTalhoesTable(db);
      
      print('✅ Verificação de integridade concluída');
      
    } catch (e) {
      print('❌ Erro em _onOpen: $e');
    }
  }
  
  /// 🔧 Criar tabela monitoring_points se não existir
  Future<void> _fixMonitoringPointsTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_points'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela monitoring_points não existe, criando...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS monitoring_points (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            numero INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            ordem INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            observacoes TEXT,
            timestamp TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES monitoring_sessions (id) ON DELETE CASCADE
          )
        ''');
        print('✅ Tabela monitoring_points criada!');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela monitoring_points: $e');
    }
  }
  
  /// 🔧 Criar tabela monitoring_occurrences se não existir
  Future<void> _fixMonitoringOccurrencesTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_occurrences'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela monitoring_occurrences não existe, criando...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS monitoring_occurrences (
            id TEXT PRIMARY KEY,
            point_id TEXT NOT NULL,
            session_id TEXT NOT NULL,
            talhao_id TEXT NOT NULL,
            organism_id TEXT,
            organism_name TEXT,
            tipo TEXT NOT NULL,
            subtipo TEXT NOT NULL,
            nivel TEXT NOT NULL,
            percentual INTEGER NOT NULL DEFAULT 0,
            quantidade INTEGER NOT NULL DEFAULT 0,
            agronomic_severity REAL DEFAULT 0,
            terco_planta TEXT,
            observacao TEXT,
            foto_paths TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            data_hora TEXT NOT NULL,
            sincronizado INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (point_id) REFERENCES monitoring_points (id) ON DELETE CASCADE,
            FOREIGN KEY (session_id) REFERENCES monitoring_sessions (id) ON DELETE CASCADE
          )
        ''');
        
        await db.execute('CREATE INDEX IF NOT EXISTS idx_occ_point ON monitoring_occurrences (point_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_occ_session ON monitoring_occurrences (session_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_occ_talhao ON monitoring_occurrences (talhao_id)');
        
        print('✅ Tabela monitoring_occurrences criada!');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela monitoring_occurrences: $e');
    }
  }
  
  /// 🔧 Criar tabela occurrences (legado) se não existir
  Future<void> _fixOccurrencesTableLegacy(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='occurrences'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela occurrences (legado) não existe, criando...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS occurrences (
            id TEXT PRIMARY KEY,
            monitoringPointId TEXT NOT NULL,
            name TEXT NOT NULL,
            severity TEXT NOT NULL,
            quantity INTEGER DEFAULT 0,
            notes TEXT,
            imagePaths TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
        
        await db.execute('CREATE INDEX IF NOT EXISTS idx_occ_legacy_point ON occurrences (monitoringPointId)');
        
        print('✅ Tabela occurrences (legado) criada!');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela occurrences: $e');
    }
  }
  
  /// 🔧 Criar tabela infestation_map se não existir
  Future<void> _fixInfestationMapTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='infestation_map'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela infestation_map não existe, criando...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS infestation_map (
            id TEXT PRIMARY KEY,
            talhao_id TEXT NOT NULL,
            ponto_id TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            tipo TEXT NOT NULL,
            subtipo TEXT NOT NULL,
            nivel TEXT NOT NULL,
            intensidade REAL NOT NULL,
            timestamp TEXT NOT NULL,
            cultura_nome TEXT,
            talhao_nome TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        
        await db.execute('CREATE INDEX IF NOT EXISTS idx_inf_talhao ON infestation_map (talhao_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_inf_ponto ON infestation_map (ponto_id)');
        
        print('✅ Tabela infestation_map criada!');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela infestation_map: $e');
    }
  }
  
  /// 🔧 Criar tabela plantio se não existir
  Future<void> _fixPlantioTable(Database db) async {
    try {
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plantio'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela plantio não existe, criando...');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS plantio (
            id TEXT PRIMARY KEY,
            talhao_id TEXT NOT NULL,
            subarea_id TEXT,
            cultura TEXT NOT NULL,
            variedade TEXT,
            data_plantio TEXT NOT NULL,
            hectares REAL NOT NULL,
            observacao TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');
        
        // Criar índices
        await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_talhao ON plantio (talhao_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_cultura ON plantio (cultura)');
        
        print('✅ Tabela plantio criada com sucesso!');
      } else {
        print('✅ Tabela plantio já existe');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela plantio: $e');
    }
  }
  
  /// 🔧 Criar tabela crop_varieties se não existir
  Future<void> _fixCropVarietiesTable(Database db) async {
    try {
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='crop_varieties'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela crop_varieties não existe, criando...');
        
        await db.execute('''
          CREATE TABLE IF NOT EXISTS crop_varieties (
            id TEXT PRIMARY KEY,
            cropId TEXT NOT NULL,
            name TEXT NOT NULL,
            company TEXT,
            cycleDays INTEGER DEFAULT 0,
            description TEXT,
            recommendedPopulation REAL,
            weightOf1000Seeds REAL,
            notes TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            isSynced INTEGER DEFAULT 0
          )
        ''');
        
        // Criar índices
        await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_varieties_crop_id ON crop_varieties (cropId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_varieties_name ON crop_varieties (name)');
        
        print('✅ Tabela crop_varieties criada com sucesso!');
      } else {
        print('✅ Tabela crop_varieties já existe');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela crop_varieties: $e');
    }
  }
  
  /// 🔧 Criar tabela talhoes se não existir
  Future<void> _fixTalhoesTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='talhoes'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela talhoes não existe, criando...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS talhoes (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            area REAL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        print('✅ Tabela talhoes criada!');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela talhoes: $e');
    }
  }
  
  /// 🔧 Criar tabela historico_plantio se não existir
  Future<void> _fixHistoricoPlantioTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='historico_plantio'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela historico_plantio não existe, criando...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS historico_plantio (
            id TEXT PRIMARY KEY,
            talhao_id TEXT NOT NULL,
            cultura TEXT NOT NULL,
            variedade TEXT,
            data_plantio TEXT NOT NULL,
            hectares REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        print('✅ Tabela historico_plantio criada!');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela historico_plantio: $e');
    }
  }
  
  /// 🔧 Criar tabela phenological_records se não existir
  Future<void> _fixPhenologicalRecordsTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='phenological_records'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela phenological_records não existe, criando...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS phenological_records (
            id TEXT PRIMARY KEY,
            talhao_id TEXT NOT NULL,
            estagio_fenologico TEXT NOT NULL,
            altura_cm REAL,
            data_registro TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        print('✅ Tabela phenological_records criada!');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela phenological_records: $e');
    }
  }
  
  /// 🔧 Criar tabela estande_plantas se não existir
  Future<void> _fixEstandePlantasTable(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='estande_plantas'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela estande_plantas não existe, criando...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS estande_plantas (
            id TEXT PRIMARY KEY,
            talhao_id TEXT NOT NULL,
            populacao_real_por_hectare REAL,
            eficiencia_percentual REAL,
            data_avaliacao TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        print('✅ Tabela estande_plantas criada!');
      }
    } catch (e) {
      print('❌ Erro ao criar tabela estande_plantas: $e');
    }
  }
  
  /// 🔧 Corrigir schema de monitoring_sessions (adicionar colunas faltantes)
  Future<void> _fixMonitoringSessionsSchema(Database db) async {
    try {
      // Verificar schema atual
      final tableInfo = await db.rawQuery('PRAGMA table_info(monitoring_sessions)');
      final colunas = tableInfo.map((col) => col['name'] as String).toList();
      
      final colunasFaltantes = <String>[];
      if (!colunas.contains('talhao_nome')) colunasFaltantes.add('talhao_nome');
      if (!colunas.contains('cultura_nome')) colunasFaltantes.add('cultura_nome');
      if (!colunas.contains('total_pontos')) colunasFaltantes.add('total_pontos');
      if (!colunas.contains('total_ocorrencias')) colunasFaltantes.add('total_ocorrencias');
      if (!colunas.contains('amostragem_padrao_plantas_por_ponto')) colunasFaltantes.add('amostragem_padrao_plantas_por_ponto');
      if (!colunas.contains('started_at')) colunasFaltantes.add('started_at');
      if (!colunas.contains('finished_at')) colunasFaltantes.add('finished_at');
      if (!colunas.contains('device_id')) colunasFaltantes.add('device_id');
      if (!colunas.contains('catalog_version')) colunasFaltantes.add('catalog_version');
      if (!colunas.contains('sync_state')) colunasFaltantes.add('sync_state');
      if (!colunas.contains('data_inicio')) colunasFaltantes.add('data_inicio');
      if (!colunas.contains('data_fim')) colunasFaltantes.add('data_fim');
      if (!colunas.contains('tecnico_nome')) colunasFaltantes.add('tecnico_nome');
      if (!colunas.contains('observacoes')) colunasFaltantes.add('observacoes');
      
      if (colunasFaltantes.isEmpty) {
        return; // Tudo OK
      }
      
      print('⚠️ Colunas faltantes detectadas: ${colunasFaltantes.join(", ")}');
      
      // Adicionar colunas faltantes
      for (final coluna in colunasFaltantes) {
        try {
          String sql = '';
          
          switch (coluna) {
            case 'talhao_nome':
            case 'cultura_nome':
            case 'tecnico_nome':
            case 'observacoes':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna TEXT DEFAULT ""';
              break;
            case 'total_pontos':
            case 'total_ocorrencias':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna INTEGER DEFAULT 0';
              break;
            case 'amostragem_padrao_plantas_por_ponto':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna INTEGER DEFAULT 10';
              break;
            case 'data_inicio':
            case 'data_fim':
            case 'started_at':
            case 'finished_at':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna TEXT';
              break;
            case 'device_id':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna TEXT DEFAULT "device_default"';
              break;
            case 'catalog_version':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna TEXT DEFAULT "1.0.0"';
              break;
            case 'sync_state':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna TEXT DEFAULT "pending"';
              break;
            case 'temperatura':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna REAL DEFAULT 0.0';
              break;
            case 'umidade':
              sql = 'ALTER TABLE monitoring_sessions ADD COLUMN $coluna REAL DEFAULT 0.0';
              break;
          }
          
          if (sql.isNotEmpty) {
            await db.execute(sql);
            print('✅ Coluna $coluna adicionada');
          }
        } catch (e) {
          print('❌ Erro ao adicionar coluna $coluna: $e');
        }
      }
      
      print('✅ Schema de monitoring_sessions corrigido!');
      
    } catch (e) {
      print('❌ Erro ao corrigir schema: $e');
    }
  }
  
  /// Remove tabelas de germinação se existirem
  Future<void> _removeGerminationTables(Database db) async {
    try {
      print('🔄 Removendo tabelas de germinação...');
      
      // Lista de tabelas de germinação para remover
      final germinationTables = [
        'germination_daily_records',
        'germination_subtest_daily_records', 
        'germination_subtests',
        'germination_tests'
      ];
      
      for (String tableName in germinationTables) {
        await db.execute('DROP TABLE IF EXISTS $tableName');
        print('✅ Tabela $tableName removida');
      }
      
      print('✅ Tabelas de germinação removidas com sucesso');
    } catch (e) {
      print('❌ Erro ao remover tabelas de germinação: $e');
    }
  }
  
  /// Cria tabelas principais
  Future<void> _createMainTables(Database db) async {
    // Tabela de talhões (DEVE SER CRIADA PRIMEIRO)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS talhoes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        idFazenda TEXT NOT NULL,
        poligonos TEXT NOT NULL,
        safras TEXT NOT NULL,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        device_id TEXT,
        deleted_at TEXT
      )
    ''');
    
    // Tabela de safras
    await db.execute('''
      CREATE TABLE IF NOT EXISTS safras (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        dataInicio TEXT NOT NULL,
        dataFim TEXT,
        status TEXT NOT NULL,
        observacoes TEXT,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT
      )
    ''');
    
    // Tabela de produtos agrícolas (culturas, variedades, defensivos, etc)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agricultural_products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        manufacturer TEXT,
        type INTEGER NOT NULL,
        activeIngredient TEXT,
        concentration TEXT,
        registrationNumber TEXT,
        safetyInterval TEXT,
        applicationInstructions TEXT,
        dosageRecommendation TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        fazendaId TEXT,
        description TEXT,
        colorValue TEXT,
        tags TEXT,
        parentId TEXT
      )
    ''');
    
    // Tabela de polígonos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS poligonos (
        id TEXT PRIMARY KEY,
        idTalhao TEXT NOT NULL,
        pontos TEXT NOT NULL,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (idTalhao) REFERENCES talhoes (id) ON DELETE CASCADE
      )
    ''');
    
    // Tabela de pontos de monitoramento
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pontos_monitoramento (
        id INTEGER PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        data TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0
      )
    ''');
    
    // Tabelas de germinação
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        culture TEXT NOT NULL,
        variety TEXT NOT NULL,
        seedLot TEXT NOT NULL,
        totalSeeds INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        expectedEndDate TEXT,
        pureSeeds INTEGER NOT NULL,
        brokenSeeds INTEGER NOT NULL,
        stainedSeeds INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        observations TEXT,
        photos TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        hasSubtests INTEGER NOT NULL DEFAULT 0,
        subtestSeedCount INTEGER DEFAULT 100,
        subtestNames TEXT,
        position TEXT,
        finalGerminationPercentage REAL,
        purityPercentage REAL,
        diseasedPercentage REAL,
        culturalValue REAL,
        averageGerminationTime REAL,
        firstCountDay INTEGER,
        day50PercentGermination INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_subtests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId INTEGER NOT NULL,
        code TEXT NOT NULL,
        totalSeeds INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (testId) REFERENCES germination_tests (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId INTEGER NOT NULL,
        subtestId INTEGER,
        day INTEGER NOT NULL,
        recordDate TEXT NOT NULL,
        normalGerminated INTEGER NOT NULL DEFAULT 0,
        abnormalGerminated INTEGER NOT NULL DEFAULT 0,
        diseasedFungi INTEGER NOT NULL DEFAULT 0,
        diseasedBacteria INTEGER NOT NULL DEFAULT 0,
        diseasedVirus INTEGER NOT NULL DEFAULT 0,
        notGerminated INTEGER NOT NULL DEFAULT 0,
        observations TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (testId) REFERENCES germination_tests (id) ON DELETE CASCADE,
        FOREIGN KEY (subtestId) REFERENCES germination_subtests (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS germination_subtest_daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subtestId INTEGER NOT NULL,
        day INTEGER NOT NULL,
        recordDate TEXT NOT NULL,
        normalGerminated INTEGER NOT NULL DEFAULT 0,
        abnormalGerminated INTEGER NOT NULL DEFAULT 0,
        diseasedFungi INTEGER NOT NULL DEFAULT 0,
        diseasedBacteria INTEGER NOT NULL DEFAULT 0,
        diseasedVirus INTEGER NOT NULL DEFAULT 0,
        notGerminated INTEGER NOT NULL DEFAULT 0,
        observations TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (subtestId) REFERENCES germination_subtests (id) ON DELETE CASCADE
      )
    ''');
    
    // Tabelas de plantio (SEM FOREIGN KEY de talhao_id para evitar erros de salvamento)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plantios (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        cultura TEXT,
        variedade TEXT,
        data_plantio TEXT NOT NULL,
        data_emergencia TEXT,
        area_plantada REAL NOT NULL,
        espacamento_linhas REAL,
        espacamento_plantas REAL,
        populacao_plantas INTEGER,
        densidade_sementes REAL,
        profundidade_plantio REAL,
        sistema_plantio TEXT,
        observacoes TEXT,
        subarea_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        user_id TEXT,
        synchronized INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // Tabela de estande de plantas (SEM FOREIGN KEY de talhao_id, MAS MANTENDO cultura_id)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estande_plantas (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        data_emergencia TEXT,
        data_avaliacao TEXT,
        dias_apos_emergencia INTEGER,
        metros_lineares_medidos REAL,
        plantas_contadas INTEGER,
        espacamento REAL,
        plantas_por_metro REAL,
        plantas_por_hectare REAL,
        populacao_ideal REAL,
        eficiencia REAL,
        fotos TEXT,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (cultura_id) REFERENCES culturas (id) ON DELETE RESTRICT
      )
    ''');
    
    // Tabelas de monitoramento (SEM FOREIGN KEY de talhao_id)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitorings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id INTEGER NOT NULL,
        data_monitoramento TEXT NOT NULL,
        tipo_monitoramento TEXT NOT NULL,
        observacoes TEXT,
        coordenadas TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        user_id TEXT,
        synchronized INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // Tabelas de inventário
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        current_stock REAL NOT NULL DEFAULT 0,
        min_stock REAL NOT NULL DEFAULT 0,
        max_stock REAL NOT NULL DEFAULT 0,
        cost_per_unit REAL,
        supplier TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        user_id TEXT,
        synchronized INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // Tabela de histórico de calibrações
    await createCalibrationHistoryTable(db);
    
    // Tabelas dos submódulos de plantio
    await createPlantingSubmodulesTables(db);
    
    // Tabela de culturas (para compatibilidade com submódulos)
    await createCulturasTable(db);
  }
  
  /// Cria índices para performance
  Future<void> _createIndexes(Database db) async {
    // Índices de talhões
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_idFazenda ON talhoes(idFazenda);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_deleted_at ON talhoes(deleted_at);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_sincronizado ON talhoes(sincronizado);');
    
    // Índices de safras
    await db.execute('CREATE INDEX IF NOT EXISTS idx_safras_status ON safras(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_safras_deleted_at ON safras(deleted_at);');
    
    // Índices de polígonos
    await db.execute('CREATE INDEX IF NOT EXISTS idx_poligonos_idTalhao ON poligonos(idTalhao);');
    
    // Índices de plantio
    await db.execute('CREATE INDEX IF NOT EXISTS idx_plantios_talhao_id ON plantios(talhao_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_plantios_cultura ON plantios(cultura);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_plantios_data_plantio ON plantios(data_plantio);');
    
    // Índices de monitoramento
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitorings_talhao_id ON monitorings(talhao_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitorings_data ON monitorings(data_monitoramento);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitorings_tipo ON monitorings(tipo_monitoramento);');
    
    // Índices de inventário
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_products_name ON inventory_products(name);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_products_category ON inventory_products(category);');
  }
  
  /// Fecha o banco de dados
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  /// Métodos de compatibilidade com código antigo
  Future<void> initDatabase() async {
    await _initDatabase();
  }
  
  Future<void> ensureDatabaseOpen() async {
    await database;
  }
  
  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, databaseName);
  }
  
  Future<String> backupDatabase() async {
    final path = await getDatabasePath();
    final backupPath = '${path}.backup';
    await File(path).copy(backupPath);
    return backupPath;
  }
  
  Future<void> resetDatabase() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;
    await _initDatabase();
  }
}

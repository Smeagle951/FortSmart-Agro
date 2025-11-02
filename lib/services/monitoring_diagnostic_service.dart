import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../repositories/monitoring_repository.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';


/// Serviço de diagnóstico para identificar problemas no módulo de monitoramento
class MonitoringDiagnosticService {
  final AppDatabase _appDatabase = AppDatabase();
  final MonitoringRepository _repository = MonitoringRepository();

  /// Executa diagnóstico completo do módulo de monitoramento
  Future<Map<String, dynamic>> executarDiagnostico() async {
    final resultado = <String, dynamic>{};
    
    try {
      Logger.info('🔍 Iniciando diagnóstico do módulo de monitoramento...');
      
      // 1. Verificar conexão com banco
      resultado['banco_conectado'] = await _verificarConexaoBanco();
      
      // 2. Verificar tabelas de monitoramento
      resultado['tabelas_existem'] = await _verificarTabelasMonitoramento();
      
      // 3. Verificar estrutura das tabelas
      resultado['estrutura_tabelas'] = await _verificarEstruturaTabelas();
      
      // 4. Verificar repositório
      resultado['repositorio_funcionando'] = await _verificarRepositorio();
      
      // 5. Testar criação de monitoramento
      resultado['teste_criacao'] = await _testarCriacaoMonitoramento();
      
      // 6. Verificar dados existentes
      resultado['dados_existentes'] = await _verificarDadosExistentes();
      
      Logger.info('✅ Diagnóstico concluído');
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      resultado['erro'] = e.toString();
    }
    
    return resultado;
  }

  /// Verifica se o banco está conectado
  Future<bool> _verificarConexaoBanco() async {
    try {
      final db = await _appDatabase.database;
      final result = await db.rawQuery('SELECT 1');
      Logger.info('✅ Banco conectado: ${result.isNotEmpty}');
      return result.isNotEmpty;
    } catch (e) {
      Logger.error('❌ Erro na conexão com banco: $e');
      return false;
    }
  }

  /// Verifica se as tabelas de monitoramento existem
  Future<bool> _verificarTabelasMonitoramento() async {
    try {
      final db = await _appDatabase.database;
      final tabelas = ['monitorings', 'monitoring_points', 'occurrences'];
      
      for (final tabela in tabelas) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tabela'"
        );
        if (result.isEmpty) {
          Logger.error('❌ Tabela $tabela não existe');
          return false;
        }
      }
      
      Logger.info('✅ Todas as tabelas de monitoramento existem');
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao verificar tabelas: $e');
      return false;
    }
  }

  /// Verifica a estrutura das tabelas
  Future<Map<String, dynamic>> _verificarEstruturaTabelas() async {
    try {
      final db = await _appDatabase.database;
      final tabelas = ['monitorings', 'monitoring_points', 'occurrences'];
      final estruturas = <String, List<String>>{};
      
      for (final tabela in tabelas) {
        final result = await db.rawQuery("PRAGMA table_info($tabela)");
        final colunas = <String>[];
        
        for (final col in result) {
          colunas.add('${col['name']} (${col['type']})');
        }
        
        estruturas[tabela] = colunas;
        Logger.info('✅ Estrutura da tabela $tabela: ${colunas.length} colunas');
      }
      
      return {
        'estruturas': estruturas,
        'todas_validas': estruturas.length == 3,
      };
    } catch (e) {
      Logger.error('❌ Erro ao verificar estrutura: $e');
      return {'erro': e.toString()};
    }
  }

  /// Verifica se o repositório está funcionando
  Future<bool> _verificarRepositorio() async {
    try {
      // Testar método simples do repositório
      final todos = await _repository.getAllMonitorings();
      Logger.info('✅ Repositório funcionando: ${todos.length} monitoramentos encontrados');
      return true;
    } catch (e) {
      Logger.error('❌ Erro no repositório: $e');
      return false;
    }
  }

  /// Testa a criação de um monitoramento
  Future<Map<String, dynamic>> _testarCriacaoMonitoramento() async {
    try {
      Logger.info('🧪 Testando criação de monitoramento...');
      
      // Criar dados de teste
      final testMonitoring = _criarMonitoramentoTeste();
      
      // Tentar salvar
      final sucesso = await _repository.saveMonitoring(testMonitoring);
      
      if (sucesso) {
        Logger.info('✅ Monitoramento de teste criado com sucesso');
        
        // Verificar se foi salvo
        final salvo = await _repository.getMonitoringById(testMonitoring.id);
        if (salvo != null) {
          Logger.info('✅ Monitoramento verificado no banco');
          
          // Limpar monitoramento de teste
          await _repository.deleteMonitoring(testMonitoring.id);
          Logger.info('✅ Monitoramento de teste removido');
          
          return {
            'sucesso': true,
            'id_criado': testMonitoring.id,
            'mensagem': 'Criação funcionando corretamente',
          };
        } else {
          return {
            'sucesso': false,
            'erro': 'Monitoramento não encontrado após salvar',
          };
        }
      } else {
        return {
          'sucesso': false,
          'erro': 'Repositório retornou false',
        };
      }
    } catch (e) {
      Logger.error('❌ Erro no teste de criação: $e');
      return {
        'sucesso': false,
        'erro': e.toString(),
      };
    }
  }

  /// Verifica dados existentes no banco
  Future<Map<String, dynamic>> _verificarDadosExistentes() async {
    try {
      final db = await _appDatabase.database;
      
      // Contar registros em cada tabela
      final monitoringsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitorings')
      ) ?? 0;
      
      final pointsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_points')
      ) ?? 0;
      
      final occurrencesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM occurrences')
      ) ?? 0;
      
      Logger.info('📊 Dados existentes:');
      Logger.info('   - Monitoramentos: $monitoringsCount');
      Logger.info('   - Pontos: $pointsCount');
      Logger.info('   - Ocorrências: $occurrencesCount');
      
      return {
        'monitorings': monitoringsCount,
        'points': pointsCount,
        'occurrences': occurrencesCount,
        'total': monitoringsCount + pointsCount + occurrencesCount,
      };
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados existentes: $e');
      return {'erro': e.toString()};
    }
  }

  /// Cria um monitoramento de teste
  Monitoring _criarMonitoramentoTeste() {
    final testPoint = MonitoringPoint(
      id: 'test-point-${DateTime.now().millisecondsSinceEpoch}',
      monitoringId: 'test-monitoring-${DateTime.now().millisecondsSinceEpoch}',
      plotId: 1,
      plotName: 'Talhão Teste',
      cropId: 1,
      cropName: 'Soja',
      latitude: -23.5505,
      longitude: -46.6333,
      occurrences: [
        Occurrence(
          id: 'test-occurrence-${DateTime.now().millisecondsSinceEpoch}',
          type: OccurrenceType.pest,
          name: 'Lagarta do Cartucho',
          infestationIndex: 25.0,
          affectedSections: [PlantSection.upper, PlantSection.middle],
          notes: 'Ocorrência de teste',
        ),
      ],
      imagePaths: [],
      audioPath: null,
      observations: 'Ponto de teste para diagnóstico',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Monitoring(
      id: 'test-monitoring-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      plotId: 1,
      plotName: 'Talhão Teste',
      cropId: 1,
      cropName: 'Soja',
      cropType: 'Grãos',
      route: [
        {'latitude': -23.5505, 'longitude': -46.6333},
        {'latitude': -23.5506, 'longitude': -46.6334},
      ],
      points: [testPoint],
      isCompleted: true,
      isSynced: false,
      severity: 25,
      observations: 'Monitoramento de teste para diagnóstico',
    );
  }

  /// Corrige problemas identificados
  Future<Map<String, dynamic>> corrigirProblemas(Map<String, dynamic> diagnostico) async {
    final correcoes = <String, dynamic>{};
    
    try {
      Logger.info('🔧 Iniciando correções...');
      
      // Se as tabelas não existem, criar
      if (diagnostico['tabelas_existem'] == false) {
        Logger.info('🔧 Criando tabelas de monitoramento...');
        await _criarTabelasMonitoramento();
        correcoes['tabelas_criadas'] = true;
      }
      
      // Se estrutura está incorreta, recriar
      final estrutura = diagnostico['estrutura_tabelas'] as Map<String, dynamic>;
      if (estrutura['todas_validas'] == false) {
        Logger.info('🔧 Recriando tabelas com estrutura correta...');
        await _recriarTabelasMonitoramento();
        correcoes['tabelas_recriadas'] = true;
      }
      
      Logger.info('✅ Correções aplicadas');
      
    } catch (e) {
      Logger.error('❌ Erro nas correções: $e');
      correcoes['erro'] = e.toString();
    }
    
    return correcoes;
  }

  /// Cria as tabelas de monitoramento
  Future<void> _criarTabelasMonitoramento() async {
    try {
      final db = await _appDatabase.database;
      
      // Tabela principal de monitoramentos
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monitorings (
          id TEXT PRIMARY KEY,
          plot_id TEXT NOT NULL,
          plotName TEXT,
          crop_id TEXT NOT NULL,
          cropName TEXT,
          cropType TEXT,
          date TEXT NOT NULL,
          route TEXT,
          isCompleted INTEGER DEFAULT 0,
          isSynced INTEGER DEFAULT 0,
          severity INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          metadata TEXT,
          technicianName TEXT,
          technicianIdentification TEXT,
          latitude REAL,
          longitude REAL,
          pests TEXT,
          diseases TEXT,
          weeds TEXT,
          images TEXT,
          observations TEXT,
          recommendations TEXT,
          sync_status INTEGER DEFAULT 0,
          remote_id INTEGER
        )
      ''');
      
      // Tabela de pontos de monitoramento
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monitoring_points (
          id TEXT PRIMARY KEY,
          monitoring_id TEXT NOT NULL,
          plot_id TEXT NOT NULL,
          plotName TEXT,
          crop_id TEXT NOT NULL,
          cropName TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          imagePaths TEXT,
          audioPath TEXT,
          observations TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          sync_status INTEGER DEFAULT 0,
          metadata TEXT
        )
      ''');
      
      // Tabela de ocorrências
      await db.execute('''
        CREATE TABLE IF NOT EXISTS occurrences (
          id TEXT PRIMARY KEY,
          monitoring_id TEXT NOT NULL,
          point_id TEXT NOT NULL,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          infestationIndex REAL NOT NULL,
          affectedSections TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0
        )
      ''');
      
      Logger.info('✅ Tabelas de monitoramento criadas');
    } catch (e) {
      Logger.error('❌ Erro ao criar tabelas: $e');
      rethrow;
    }
  }

  /// Recria as tabelas de monitoramento
  Future<void> _recriarTabelasMonitoramento() async {
    try {
      final db = await _appDatabase.database;
      
      await db.transaction((txn) async {
        // Fazer backup dos dados existentes
        final monitoringsExistentes = await txn.query('monitorings');
        final pointsExistentes = await txn.query('monitoring_points');
        final occurrencesExistentes = await txn.query('occurrences');
        
        // Remover tabelas antigas
        await txn.execute('DROP TABLE IF EXISTS monitorings');
        await txn.execute('DROP TABLE IF EXISTS monitoring_points');
        await txn.execute('DROP TABLE IF EXISTS occurrences');
        
        // Criar novas tabelas
        await _criarTabelasMonitoramento();
        
        // Restaurar dados se possível
        if (monitoringsExistentes.isNotEmpty || pointsExistentes.isNotEmpty || occurrencesExistentes.isNotEmpty) {
          Logger.warning('⚠️ Dados existentes serão perdidos na recriação');
        }
      });
      
      Logger.info('✅ Tabelas de monitoramento recriadas');
    } catch (e) {
      Logger.error('❌ Erro ao recriar tabelas: $e');
      rethrow;
    }
  }
}

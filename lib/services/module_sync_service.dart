import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/dashboard/dashboard_data.dart';
import '../utils/logger.dart';

/// Serviço para sincronização individual de cada módulo
class ModuleSyncService {
  final AppDatabase _appDatabase = AppDatabase();

  /// Sincroniza dados da fazenda
  Future<ModuleSyncResult> syncFazenda() async {
    try {
      Logger.info('🔄 Sincronizando módulo Fazenda...');
      
      final db = await _appDatabase.database;
      
      // Buscar dados da fazenda
      final farmData = await db.query('farms', limit: 1);
      
      if (farmData.isEmpty) {
        return ModuleSyncResult(
          moduleName: 'fazenda',
          status: ModuleStatus.neutral,
          message: 'Fazenda não configurada',
          dataCount: 0,
          lastSync: DateTime.now(),
        );
      }

      final farm = farmData.first;
      final totalTalhoes = await _getTalhoesCount();
      final areaTotal = await _getTotalArea();

      return ModuleSyncResult(
        moduleName: 'fazenda',
        status: ModuleStatus.active,
        message: 'Fazenda configurada',
        dataCount: 1,
        lastSync: DateTime.now(),
        details: {
          'nome': farm['name'] ?? 'Não informado',
          'proprietario': farm['owner'] ?? 'Não informado',
          'cidade': farm['municipality'] ?? 'Não informado',
          'uf': farm['state'] ?? 'N/A',
          'areaTotal': areaTotal,
          'totalTalhoes': totalTalhoes,
        },
      );
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar Fazenda: $e');
      return ModuleSyncResult(
        moduleName: 'fazenda',
        status: ModuleStatus.error,
        message: 'Erro ao carregar dados',
        dataCount: 0,
        lastSync: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Sincroniza dados de alertas
  Future<ModuleSyncResult> syncAlertas() async {
    try {
      Logger.info('🔄 Sincronizando módulo Alertas...');
      
      final db = await _appDatabase.database;
      
      // Buscar alertas ativos
      final alertsData = await db.rawQuery('''
        SELECT COUNT(*) as total,
               SUM(CASE WHEN nivel = 'CRÍTICO' THEN 1 ELSE 0 END) as criticos,
               SUM(CASE WHEN nivel = 'ALTO' THEN 1 ELSE 0 END) as altos
        FROM infestacoes_monitoramento 
        WHERE nivel IN ('ALTO', 'CRÍTICO') 
        AND percentual >= 50
      ''');
      
      final total = alertsData.first['total'] as int? ?? 0;
      final criticos = alertsData.first['criticos'] as int? ?? 0;
      final altos = alertsData.first['altos'] as int? ?? 0;

      ModuleStatus status;
      String message;
      
      if (criticos > 0) {
        status = ModuleStatus.error;
        message = '$criticos alertas críticos';
      } else if (altos > 0) {
        status = ModuleStatus.warning;
        message = '$altos alertas altos';
      } else if (total > 0) {
        status = ModuleStatus.active;
        message = '$total alertas ativos';
      } else {
        status = ModuleStatus.success;
        message = 'Nenhum alerta ativo';
      }

      return ModuleSyncResult(
        moduleName: 'alertas',
        status: status,
        message: message,
        dataCount: total,
        lastSync: DateTime.now(),
        details: {
          'total': total,
          'criticos': criticos,
          'altos': altos,
          'normais': total - criticos - altos,
        },
      );
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar Alertas: $e');
      return ModuleSyncResult(
        moduleName: 'alertas',
        status: ModuleStatus.error,
        message: 'Erro ao carregar dados',
        dataCount: 0,
        lastSync: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Sincroniza dados dos talhões
  Future<ModuleSyncResult> syncTalhoes() async {
    try {
      Logger.info('🔄 Sincronizando módulo Talhões...');
      
      final db = await _appDatabase.database;
      
      // Buscar dados dos talhões
      final talhoesData = await db.query('talhao_safra');
      final totalTalhoes = talhoesData.length;
      
      // Calcular área total e talhões ativos
      double areaTotal = 0.0;
      int talhoesAtivos = 0;
      
      for (final talhao in talhoesData) {
        final area = (talhao['area'] as num?)?.toDouble() ?? 0.0;
        areaTotal += area;
        if (area > 0) talhoesAtivos++;
      }

      ModuleStatus status;
      String message;
      
      if (totalTalhoes == 0) {
        status = ModuleStatus.neutral;
        message = 'Nenhum talhão cadastrado';
      } else if (talhoesAtivos == 0) {
        status = ModuleStatus.warning;
        message = 'Talhões sem área definida';
      } else {
        status = ModuleStatus.active;
        message = '$talhoesAtivos talhões ativos';
      }

      return ModuleSyncResult(
        moduleName: 'talhoes',
        status: status,
        message: message,
        dataCount: totalTalhoes,
        lastSync: DateTime.now(),
        details: {
          'totalTalhoes': totalTalhoes,
          'talhoesAtivos': talhoesAtivos,
          'areaTotal': areaTotal,
          'ultimaAtualizacao': talhoesData.isNotEmpty 
              ? talhoesData.map((t) => t['data_atualizacao']).toList().first
              : null,
        },
      );
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar Talhões: $e');
      return ModuleSyncResult(
        moduleName: 'talhoes',
        status: ModuleStatus.error,
        message: 'Erro ao carregar dados',
        dataCount: 0,
        lastSync: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Sincroniza dados dos plantios
  Future<ModuleSyncResult> syncPlantios() async {
    try {
      Logger.info('🔄 Sincronizando módulo Plantios...');
      
      final db = await _appDatabase.database;
      
      // Buscar plantios ativos
      final plantiosData = await db.rawQuery('''
        SELECT COUNT(*) as total,
               SUM(area_plantada) as area_total,
               COUNT(DISTINCT cultura_id) as culturas_diferentes
        FROM plantios 
        WHERE status = 'ativo' OR status = 'em_andamento'
      ''');
      
      final total = plantiosData.first['total'] as int? ?? 0;
      final areaTotal = (plantiosData.first['area_total'] as num?)?.toDouble() ?? 0.0;
      final culturasDiferentes = plantiosData.first['culturas_diferentes'] as int? ?? 0;

      ModuleStatus status;
      String message;
      
      if (total == 0) {
        status = ModuleStatus.neutral;
        message = 'Nenhum plantio ativo';
      } else {
        status = ModuleStatus.active;
        message = '$total plantios ativos';
      }

      return ModuleSyncResult(
        moduleName: 'plantios',
        status: status,
        message: message,
        dataCount: total,
        lastSync: DateTime.now(),
        details: {
          'totalPlantios': total,
          'areaTotal': areaTotal,
          'culturasDiferentes': culturasDiferentes,
        },
      );
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar Plantios: $e');
      return ModuleSyncResult(
        moduleName: 'plantios',
        status: ModuleStatus.error,
        message: 'Erro ao carregar dados',
        dataCount: 0,
        lastSync: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Sincroniza dados dos monitoramentos
  Future<ModuleSyncResult> syncMonitoramentos() async {
    try {
      Logger.info('🔄 Sincronizando módulo Monitoramentos...');
      
      final db = await _appDatabase.database;
      
      // Buscar sessões de monitoramento
      final monitoringData = await db.rawQuery('''
        SELECT COUNT(*) as total,
               SUM(CASE WHEN status = 'concluido' THEN 1 ELSE 0 END) as concluidos,
               SUM(CASE WHEN status = 'em_andamento' THEN 1 ELSE 0 END) as em_andamento,
               SUM(CASE WHEN status = 'pendente' THEN 1 ELSE 0 END) as pendentes
        FROM monitoring_sessions 
        WHERE started_at >= datetime('now', '-30 days')
      ''');
      
      final total = monitoringData.first['total'] as int? ?? 0;
      final concluidos = monitoringData.first['concluidos'] as int? ?? 0;
      final emAndamento = monitoringData.first['em_andamento'] as int? ?? 0;
      final pendentes = monitoringData.first['pendentes'] as int? ?? 0;

      ModuleStatus status;
      String message;
      
      if (total == 0) {
        status = ModuleStatus.neutral;
        message = 'Nenhum monitoramento realizado';
      } else if (pendentes > 0) {
        status = ModuleStatus.warning;
        message = '$pendentes monitoramentos pendentes';
      } else {
        status = ModuleStatus.active;
        message = '$concluidos monitoramentos concluídos';
      }

      return ModuleSyncResult(
        moduleName: 'monitoramentos',
        status: status,
        message: message,
        dataCount: total,
        lastSync: DateTime.now(),
        details: {
          'total': total,
          'concluidos': concluidos,
          'emAndamento': emAndamento,
          'pendentes': pendentes,
        },
      );
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar Monitoramentos: $e');
      return ModuleSyncResult(
        moduleName: 'monitoramentos',
        status: ModuleStatus.error,
        message: 'Erro ao carregar dados',
        dataCount: 0,
        lastSync: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Sincroniza dados do estoque
  Future<ModuleSyncResult> syncEstoque() async {
    try {
      Logger.info('🔄 Sincronizando módulo Estoque...');
      
      final db = await _appDatabase.database;
      
      // Buscar dados do estoque
      final estoqueData = await db.rawQuery('''
        SELECT COUNT(*) as total,
               SUM(CASE WHEN quantidade <= estoque_minimo THEN 1 ELSE 0 END) as baixo_estoque,
               SUM(quantidade * preco_unitario) as valor_total
        FROM estoque_items
      ''');
      
      final total = estoqueData.first['total'] as int? ?? 0;
      final baixoEstoque = estoqueData.first['baixo_estoque'] as int? ?? 0;
      final valorTotal = (estoqueData.first['valor_total'] as num?)?.toDouble() ?? 0.0;

      ModuleStatus status;
      String message;
      
      if (total == 0) {
        status = ModuleStatus.neutral;
        message = 'Nenhum item no estoque';
      } else if (baixoEstoque > 0) {
        status = ModuleStatus.warning;
        message = '$baixoEstoque itens com estoque baixo';
      } else {
        status = ModuleStatus.active;
        message = '$total itens no estoque';
      }

      return ModuleSyncResult(
        moduleName: 'estoque',
        status: status,
        message: message,
        dataCount: total,
        lastSync: DateTime.now(),
        details: {
          'totalItens': total,
          'baixoEstoque': baixoEstoque,
          'valorTotal': valorTotal,
        },
      );
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar Estoque: $e');
      return ModuleSyncResult(
        moduleName: 'estoque',
        status: ModuleStatus.error,
        message: 'Erro ao carregar dados',
        dataCount: 0,
        lastSync: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Sincroniza todos os módulos
  Future<Map<String, ModuleSyncResult>> syncAllModules() async {
    Logger.info('🔄 Iniciando sincronização de todos os módulos...');
    
    final results = <String, ModuleSyncResult>{};
    
    // Sincronizar todos os módulos em paralelo
    final futures = await Future.wait([
      syncFazenda(),
      syncAlertas(),
      syncTalhoes(),
      syncPlantios(),
      syncMonitoramentos(),
      syncEstoque(),
    ]);
    
    for (final result in futures) {
      results[result.moduleName] = result;
    }
    
    Logger.info('✅ Sincronização de todos os módulos concluída');
    return results;
  }

  /// Métodos auxiliares
  Future<int> _getTalhoesCount() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM talhao_safra');
    return result.first['count'] as int? ?? 0;
  }

  Future<double> _getTotalArea() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery('SELECT SUM(area) as total FROM talhao_safra');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

/// Resultado da sincronização de um módulo
class ModuleSyncResult {
  final String moduleName;
  final ModuleStatus status;
  final String message;
  final int dataCount;
  final DateTime lastSync;
  final Map<String, dynamic>? details;
  final String? error;

  const ModuleSyncResult({
    required this.moduleName,
    required this.status,
    required this.message,
    required this.dataCount,
    required this.lastSync,
    this.details,
    this.error,
  });
}

/// Status do módulo
enum ModuleStatus {
  active,    // Módulo ativo com dados
  warning,   // Módulo com avisos
  error,     // Módulo com erros
  neutral,   // Módulo neutro/sem dados
  success,   // Módulo funcionando perfeitamente
}

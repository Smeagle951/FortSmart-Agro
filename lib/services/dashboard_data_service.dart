import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../repositories/monitoring_repository.dart';
import '../repositories/infestacao_repository.dart';
import '../models/dashboard/dashboard_data.dart';
import '../utils/logger.dart';

/// Serviço para carregar dados específicos do dashboard
class DashboardDataService {
  final AppDatabase _appDatabase = AppDatabase();
  final MonitoringRepository _monitoringRepository = MonitoringRepository();
  late final InfestacaoRepository _infestacaoRepository;
  
  /// Inicializa o serviço
  Future<void> initialize() async {
    final db = await _appDatabase.database;
    _infestacaoRepository = InfestacaoRepository(db);
  }

  /// Carrega dados de alertas de infestação para o dashboard
  Future<Map<String, dynamic>> loadInfestationAlerts() async {
    try {
      Logger.info('🔍 Carregando alertas de infestação...');
      
      final db = await _appDatabase.database;
      
      // Buscar dados de infestação com severidade alta
      final infestationData = await db.rawQuery('''
        SELECT 
          i.id,
          i.talhao_id,
          i.tipo,
          i.nivel,
          i.percentual,
          i.latitude,
          i.longitude,
          i.data_hora,
          t.nome as talhao_nome
        FROM infestacoes_monitoramento i
        LEFT JOIN talhao_safra t ON i.talhao_id = t.id
        WHERE i.nivel IN ('ALTO', 'CRÍTICO') 
        AND i.percentual >= 50
        ORDER BY i.percentual DESC, i.data_hora DESC
        LIMIT 20
      ''');
      
      // Processar dados para alertas
      final alerts = <Map<String, dynamic>>[];
      for (final data in infestationData) {
        alerts.add({
          'id': data['id'],
          'talhao_id': data['talhao_id'],
          'talhao_nome': data['talhao_nome'] ?? 'Talhão ${data['talhao_id']}',
          'tipo': data['tipo'],
          'nivel': data['nivel'],
          'percentual': data['percentual'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'data_hora': data['data_hora'],
          'severity': _calculateSeverity(data['percentual'] as int),
        });
      }
      
      Logger.info('✅ ${alerts.length} alertas de infestação carregados');
      
      return {
        'alerts': alerts,
        'total_count': alerts.length,
        'high_severity': alerts.where((a) => a['severity'] >= 3).length,
        'critical_severity': alerts.where((a) => a['severity'] >= 4).length,
      };

    } catch (e) {
      Logger.error('❌ Erro ao carregar alertas de infestação: $e');
      return {
        'alerts': [],
        'total_count': 0,
        'high_severity': 0,
        'critical_severity': 0,
        'error': e.toString(),
      };
    }
  }

  /// Carrega dados de monitoramento para o dashboard
  Future<Map<String, dynamic>> loadMonitoringData() async {
    try {
      Logger.info('🔍 Carregando dados de monitoramento...');
      
      final db = await _appDatabase.database;
      
      // Buscar sessões de monitoramento recentes (usando nova tabela monitoring_sessions)
      final monitoringSessions = await db.rawQuery('''
        SELECT 
          s.id,
          s.talhao_id,
          s.status,
          s.data_inicio as started_at,
          s.data_fim as finished_at,
          COALESCE(s.tecnico_nome, 'Técnico') as technician_name,
          COALESCE(s.talhao_nome, 'Talhão') as talhao_nome,
          s.total_pontos as pontos_count,
          s.total_ocorrencias as ocorrencias_count
        FROM monitoring_sessions s
        WHERE s.created_at >= datetime('now', '-30 days')
        ORDER BY s.created_at DESC
        LIMIT 50
      ''');
      
      // Processar dados de monitoramento
      final monitorings = <Map<String, dynamic>>[];
      int pendentes = 0;
      int realizados = 0;
      
      for (final session in monitoringSessions) {
        final status = session['status'] as String? ?? 'active';
        final isActive = status == 'active' || status == 'pausado';
        final isFinalized = status == 'finalized';
        
        if (isActive) pendentes++;
        if (isFinalized) realizados++;
        
        monitorings.add({
          'id': session['id'],
          'talhao_id': session['talhao_id'],
          'talhao_nome': session['talhao_nome'] ?? 'Talhão ${session['talhao_id']}',
          'status': isFinalized ? 'completed' : 'pending',
          'started_at': session['started_at'],
          'finished_at': session['finished_at'],
          'technician_name': session['technician_name'],
          'pontos_count': session['pontos_count'] ?? 0,
          'ocorrencias_count': session['ocorrencias_count'] ?? 0,
          'is_active': isActive,
          'is_finalized': isFinalized,
        });
      }
      
      // Buscar último monitoramento
      final ultimoMonitoramento = monitorings.isNotEmpty ? monitorings.first : null;
      
      Logger.info('✅ ${monitorings.length} monitoramentos carregados');
      
      return {
        'monitorings': monitorings,
        'pendentes': pendentes,
        'realizados': realizados,
        'total': monitorings.length,
        'ultimo': ultimoMonitoramento,
        'has_data': monitorings.isNotEmpty,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de monitoramento: $e');
      return {
        'monitorings': [],
        'pendentes': 0,
        'realizados': 0,
        'total': 0,
        'ultimo': null,
        'has_data': false,
        'error': e.toString(),
      };
    }
  }

  /// Carrega dados para o mapa de infestação
  Future<Map<String, dynamic>> loadInfestationMapData() async {
    try {
      Logger.info('🔍 Carregando dados para mapa de infestação...');
      
      final db = await _appDatabase.database;
      
      // Buscar dados de infestação com coordenadas
      final mapData = await db.rawQuery('''
        SELECT 
          i.id,
          i.talhao_id,
          i.tipo,
          i.subtipo,
          i.nivel,
          i.percentual,
          i.latitude,
          i.longitude,
          i.data_hora,
          t.nome as talhao_nome,
          t.area as talhao_area
        FROM infestacoes_monitoramento i
        LEFT JOIN talhao_safra t ON i.talhao_id = t.id
        WHERE i.latitude IS NOT NULL 
        AND i.longitude IS NOT NULL
        AND i.percentual > 0
        ORDER BY i.data_hora DESC
      ''');
      
      // Processar dados para o mapa
      final points = <Map<String, dynamic>>[];
      final talhoes = <String, Map<String, dynamic>>{};
      
      for (final data in mapData) {
        final talhaoId = data['talhao_id'].toString();
        
        // Agrupar por talhão
        if (!talhoes.containsKey(talhaoId)) {
          talhoes[talhaoId] = {
            'id': talhaoId,
            'nome': data['talhao_nome'] ?? 'Talhão $talhaoId',
            'area': data['talhao_area'] ?? 0.0,
            'pontos': [],
            'total_infestacoes': 0,
            'severidade_media': 0.0,
            'niveis': <String>{},
          };
        }
        
        final talhao = talhoes[talhaoId]!;
        talhao['total_infestacoes']++;
        talhao['severidade_media'] = (talhao['severidade_media'] + (data['percentual'] as int)) / 2;
        talhao['niveis'].add(data['nivel'] as String);
        
        // Adicionar ponto
        points.add({
          'id': data['id'],
          'talhao_id': talhaoId,
          'tipo': data['tipo'],
          'subtipo': data['subtipo'],
          'nivel': data['nivel'],
          'percentual': data['percentual'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'data_hora': data['data_hora'],
          'severity': _calculateSeverity(data['percentual'] as int),
        });
        
        talhao['pontos'].add(points.last);
      }
      
      Logger.info('✅ ${points.length} pontos de infestação carregados para o mapa');
      
      return {
        'points': points,
        'talhoes': talhoes.values.toList(),
        'total_points': points.length,
        'talhoes_count': talhoes.length,
        'has_data': points.isNotEmpty,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados do mapa de infestação: $e');
      return {
        'points': [],
        'talhoes': [],
        'total_points': 0,
        'talhoes_count': 0,
        'has_data': false,
        'error': e.toString(),
      };
    }
  }

  /// Calcula severidade baseada no percentual
  int _calculateSeverity(int percentual) {
    if (percentual >= 90) return 5; // Crítico
    if (percentual >= 75) return 4; // Muito Alto
    if (percentual >= 50) return 3; // Alto
    if (percentual >= 25) return 2; // Moderado
    if (percentual >= 10) return 1; // Baixo
    return 0; // Muito Baixo
  }

  /// Verifica se há dados suficientes para exibir no dashboard
  Future<bool> hasDashboardData() async {
    try {
      final db = await _appDatabase.database;
      
      // Verificar se há dados de infestação
      final infestationCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM infestacoes_monitoramento')
      ) ?? 0;
      
      // Verificar se há sessões de monitoramento
      final monitoringCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_sessions')
      ) ?? 0;
      
      // CORREÇÃO: Verificar se há talhões na tabela correta
      final talhoesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM talhao_safra')
      ) ?? 0;
      
      return infestationCount > 0 || monitoringCount > 0 || talhoesCount > 0;
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados do dashboard: $e');
      return false;
    }
  }

  /// Força atualização dos dados do dashboard
  Future<Map<String, dynamic>> forceRefresh() async {
    try {
      Logger.info('🔄 Forçando atualização dos dados do dashboard...');
      
      final results = <String, dynamic>{};
      
      // Carregar todos os dados em paralelo
      final futures = await Future.wait([
        loadInfestationAlerts(),
        loadMonitoringData(),
        loadInfestationMapData(),
      ]);
      
      results['alerts'] = futures[0];
      results['monitoring'] = futures[1];
      results['map_data'] = futures[2];
      results['timestamp'] = DateTime.now().toIso8601String();
      
      Logger.info('✅ Dados do dashboard atualizados com sucesso');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro ao forçar atualização: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Carrega dados completos do dashboard e retorna DashboardData
  Future<DashboardData> loadDashboardData() async {
    try {
      Logger.info('🔄 Carregando dados completos do dashboard...');
      
      // Carregar dados em paralelo
      final futures = await Future.wait([
        loadInfestationAlerts(),
        loadMonitoringData(),
        loadInfestationMapData(),
      ]);
      
      final alertsData = futures[0];
      final monitoringData = futures[1];
      final mapData = futures[2];
      
      // Converter dados para DashboardData
      final alerts = _convertToAlerts(alertsData);
      final farmProfile = await _createFarmProfile();
      final talhoesSummary = await _createTalhoesSummary();
      final plantiosAtivos = await _createPlantiosAtivos();
      final monitoramentosSummary = _createMonitoramentosSummary(monitoringData);
      final estoqueSummary = await _createEstoqueSummary();
      final weatherData = _createWeatherData();
      final indicadoresRapidos = _createIndicadoresRapidos();
      
      final dashboardData = DashboardData(
        id: const Uuid().v4(),
        farmProfile: farmProfile,
        alerts: alerts,
        talhoesSummary: talhoesSummary,
        plantiosAtivos: plantiosAtivos,
        monitoramentosSummary: monitoramentosSummary,
        estoqueSummary: estoqueSummary,
        weatherData: weatherData,
        indicadoresRapidos: indicadoresRapidos,
        lastUpdated: DateTime.now(),
      );
      
      Logger.info('✅ DashboardData criado com sucesso');
      return dashboardData;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados do dashboard: $e');
      return DashboardData.create();
    }
  }

  /// Gera dados de teste se necessário
  Future<Map<String, dynamic>> generateTestDataIfNeeded() async {
    try {
      final hasData = await hasDashboardData();
      
      if (!hasData) {
        Logger.info('🔄 Gerando dados de teste para o dashboard...');
        
        final db = await _appDatabase.database;
        
        // Inserir dados de teste de infestação
        await db.insert('infestacoes_monitoramento', {
          'id': 'test_infestation_1',
          'talhao_id': 1,
          'ponto_id': 1,
          'latitude': -23.5505,
          'longitude': -46.6333,
          'tipo': 'Plantas Daninhas',
          'subtipo': 'Buva',
          'nivel': 'ALTO',
          'percentual': 65,
          'foto_paths': '',
          'data_hora': DateTime.now().toIso8601String(),
        });
        
        await db.insert('infestacoes_monitoramento', {
          'id': 'test_infestation_2',
          'talhao_id': 1,
          'ponto_id': 2,
          'latitude': -23.5515,
          'longitude': -46.6343,
          'tipo': 'Plantas Daninhas',
          'subtipo': 'Capim-colchão',
          'nivel': 'CRÍTICO',
          'percentual': 85,
          'foto_paths': '',
          'data_hora': DateTime.now().toIso8601String(),
        });
        
        // DADOS DE TESTE REMOVIDOS - Usar apenas dados reais
        Logger.info('✅ Banco de dados inicializado com sucesso');
        return {'test_data_created': true};
      }
      
      return {'test_data_created': false, 'has_existing_data': true};
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados de teste: $e');
      return {'test_data_created': false, 'error': e.toString()};
    }
  }

  /// Gera dados de teste de infestação mais robustos
  Future<void> generateTestInfestationData() async {
    try {
      final db = await _appDatabase.database;
      
      // Verificar se já existem dados
      final existingData = await db.rawQuery('SELECT COUNT(*) as count FROM infestacoes_monitoramento');
      final count = existingData.first['count'] as int;
      
      if (count > 0) {
        Logger.info('📊 Dados de infestação já existem: $count registros');
        return;
      }
      
      Logger.info('🔄 Gerando dados de teste de infestação...');
      
      // CORREÇÃO: Buscar talhões existentes na tabela correta
      final talhoes = await db.rawQuery('SELECT id, nome FROM talhao_safra LIMIT 5');
      
      if (talhoes.isEmpty) {
        Logger.warning('⚠️ Nenhum talhão encontrado para gerar dados de infestação');
        return;
      }
      
      // Gerar dados de infestação para cada talhão
      final infestations = <Map<String, dynamic>>[];
      final now = DateTime.now();
      
      for (int i = 0; i < talhoes.length; i++) {
        final talhao = talhoes[i];
        final talhaoId = talhao['id'] as int;
        final talhaoNome = talhao['nome'] as String;
        
        // Gerar 2-4 pontos de infestação por talhão
        final numPoints = 2 + (i % 3);
        
        for (int j = 0; j < numPoints; j++) {
          final percentual = 30 + (j * 20) + (i * 10); // 30-90%
          final nivel = percentual >= 80 ? 'CRÍTICO' : 
                       percentual >= 60 ? 'ALTO' : 
                       percentual >= 40 ? 'MÉDIO' : 'BAIXO';
          
          infestations.add({
            'id': 'inf_${talhaoId}_${j}_${now.millisecondsSinceEpoch}',
            'talhao_id': talhaoId,
            'ponto_id': j + 1,
            'latitude': -23.5 + (i * 0.01) + (j * 0.005),
            'longitude': -46.6 + (i * 0.01) + (j * 0.005),
            'tipo': _getRandomInfestationType(),
            'subtipo': _getRandomInfestationSubtype(),
            'nivel': nivel,
            'percentual': percentual,
            'data_hora': now.subtract(Duration(days: j, hours: i)).toIso8601String(),
            'observacoes': 'Dados de teste gerados automaticamente',
            'status': 'ATIVO',
          });
        }
      }
      
      // Inserir dados no banco
      for (final infestation in infestations) {
        await db.insert('infestacoes_monitoramento', infestation);
      }
      
      Logger.info('✅ ${infestations.length} registros de infestação gerados');
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados de infestação: $e');
    }
  }

  String _getRandomInfestationType() {
    final types = ['Praga', 'Doença', 'Erva Daninha', 'Deficiência'];
    return types[DateTime.now().millisecondsSinceEpoch % types.length];
  }

  String _getRandomInfestationSubtype() {
    final subtypes = ['Lagarta', 'Fungo', 'Inseto', 'Vírus', 'Bactéria'];
    return subtypes[DateTime.now().millisecondsSinceEpoch % subtypes.length];
  }

  /// Converte dados de alertas para lista de Alert
  List<Alert> _convertToAlerts(Map<String, dynamic> alertsData) {
    final alerts = <Alert>[];
    
    if (alertsData['alerts'] != null) {
      for (final alertData in alertsData['alerts'] as List) {
        alerts.add(Alert(
          id: alertData['id']?.toString() ?? const Uuid().v4(),
          titulo: 'Alerta de Infestação',
          descricao: '${alertData['tipo']} - ${alertData['nivel']} (${alertData['percentual']}%)',
          talhao: alertData['talhao_nome']?.toString() ?? 'Talhão ${alertData['talhao_id']}',
          data: DateTime.tryParse(alertData['data_hora']?.toString() ?? '') ?? DateTime.now(),
          level: _getAlertLevel(alertData['nivel']),
          type: AlertType.infestacao,
          isActive: true,
        ));
      }
    }
    
    return alerts;
  }

  /// Converte nível de string para AlertLevel
  AlertLevel _getAlertLevel(String? nivel) {
    switch (nivel?.toUpperCase()) {
      case 'CRÍTICO':
        return AlertLevel.critico;
      case 'ALTO':
        return AlertLevel.alto;
      case 'MÉDIO':
        return AlertLevel.medio;
      case 'BAIXO':
        return AlertLevel.baixo;
      default:
        return AlertLevel.baixo;
    }
  }

  /// Cria perfil da fazenda
  Future<FarmProfile> _createFarmProfile() async {
    try {
      final db = await _appDatabase.database;
      
      // Buscar dados da fazenda atual
      final farmData = await db.query(
        'farms',
        limit: 1,
        orderBy: 'created_at DESC',
      );
      
      if (farmData.isNotEmpty) {
        final farm = farmData.first;
        return FarmProfile(
          nome: farm['name'] as String? ?? 'Fazenda não configurada',
          proprietario: farm['owner'] as String? ?? 'Não informado',
          cidade: farm['municipality'] as String? ?? 'Não informado',
          uf: farm['state'] as String? ?? 'N/A',
          areaTotal: (farm['total_area'] as num?)?.toDouble() ?? 0.0,
          totalTalhoes: 0, // Será calculado separadamente
        );
      }
      
      return FarmProfile(
        nome: 'Fazenda não configurada',
        proprietario: 'Não informado',
        cidade: 'Não informado',
        uf: 'N/A',
        areaTotal: 0.0,
        totalTalhoes: 0,
      );
    } catch (e) {
      Logger.error('❌ Erro ao carregar perfil da fazenda: $e');
      return FarmProfile(
        nome: 'Fazenda não configurada',
        proprietario: 'Não informado',
        cidade: 'Não informado',
        uf: 'N/A',
        areaTotal: 0.0,
        totalTalhoes: 0,
      );
    }
  }

  /// Cria resumo dos talhões
  Future<TalhoesSummary> _createTalhoesSummary() async {
    try {
      final db = await _appDatabase.database;
      
      // CORREÇÃO: Buscar dados da tabela correta talhao_safra
      final talhoesData = await db.query('talhao_safra');
      final totalTalhoes = talhoesData.length;
      
      Logger.info('🔍 DEBUG: Buscando talhões na tabela talhao_safra - ${talhoesData.length} encontrados');
      
      // Calcular área total
      double areaTotal = 0.0;
      int talhoesAtivos = 0;
      
      for (final talhao in talhoesData) {
        final area = (talhao['area'] as num?)?.toDouble() ?? 0.0;
        areaTotal += area;
        
        // Considerar ativo se tem área > 0
        if (area > 0) talhoesAtivos++;
        
        Logger.info('🔍 DEBUG: Talhão ${talhao['nome']} - Área: ${area} ha');
      }
      
      // Buscar última atualização
      DateTime ultimaAtualizacao = DateTime.now();
      if (talhoesData.isNotEmpty) {
        final ultimoTalhao = talhoesData.reduce((a, b) {
          final dataA = DateTime.tryParse(a['data_atualizacao'] as String? ?? '') ?? DateTime(1970);
          final dataB = DateTime.tryParse(b['data_atualizacao'] as String? ?? '') ?? DateTime(1970);
          return dataA.isAfter(dataB) ? a : b;
        });
        
        ultimaAtualizacao = DateTime.tryParse(ultimoTalhao['data_atualizacao'] as String? ?? '') ?? DateTime.now();
      }
      
      Logger.info('📊 Talhões carregados: $totalTalhoes total, $talhoesAtivos ativos, ${areaTotal.toStringAsFixed(1)} ha');
      
      return TalhoesSummary(
        totalTalhoes: totalTalhoes,
        areaTotal: areaTotal,
        talhoesAtivos: talhoesAtivos,
        ultimaAtualizacao: ultimaAtualizacao,
      );
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados dos talhões: $e');
      return TalhoesSummary(
        totalTalhoes: 0,
        areaTotal: 0.0,
        talhoesAtivos: 0,
        ultimaAtualizacao: DateTime.now(),
      );
    }
  }

  /// Cria plantios ativos
  Future<PlantiosAtivos> _createPlantiosAtivos() async {
    try {
      final db = await _appDatabase.database;
      
      // Buscar todos os plantios (sem filtro de status pois a coluna não existe)
      final plantiosData = await db.query(
        'plantios',
      );
      
      final totalPlantios = plantiosData.length;
      double areaTotalPlantada = 0.0;
      
      for (final plantio in plantiosData) {
        final area = (plantio['area'] as num?)?.toDouble() ?? 0.0;
        areaTotalPlantada += area;
      }
      
      Logger.info('🌱 Plantios carregados: $totalPlantios total, ${areaTotalPlantada.toStringAsFixed(1)} ha');
      
      return PlantiosAtivos(
        plantios: [], // TODO: Implementar lista de plantios
        areaTotalPlantada: areaTotalPlantada,
        totalPlantios: totalPlantios,
      );
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados dos plantios: $e');
      return PlantiosAtivos(
        plantios: [],
        areaTotalPlantada: 0.0,
        totalPlantios: 0,
      );
    }
  }

  /// Cria resumo dos monitoramentos
  MonitoramentosSummary _createMonitoramentosSummary(Map<String, dynamic> monitoringData) {
    return MonitoramentosSummary(
      pendentes: monitoringData['pendentes'] ?? 0,
      realizados: monitoringData['realizados'] ?? 0,
      ultimoMonitoramento: monitoringData['ultimo'] != null ? DateTime.now() : null,
      ultimoTalhao: null,
    );
  }

  /// Cria resumo do estoque
  Future<EstoqueSummary> _createEstoqueSummary() async {
    try {
      final db = await _appDatabase.database;
      
      // Buscar dados do estoque
      final estoqueData = await db.query('estoque');
      final totalItens = estoqueData.length;
      
      // Contar itens com baixo estoque
      int itensBaixoEstoque = 0;
      for (final item in estoqueData) {
        final quantidade = (item['quantidade'] as num?)?.toDouble() ?? 0.0;
        final estoqueMinimo = (item['estoque_minimo'] as num?)?.toDouble() ?? 0.0;
        
        if (quantidade <= estoqueMinimo) {
          itensBaixoEstoque++;
        }
      }
      
      Logger.info('📦 Estoque carregado: $totalItens itens, $itensBaixoEstoque com baixo estoque');
      
      return EstoqueSummary(
        totalItens: totalItens,
        principaisInsumos: [], // TODO: Implementar lista de principais insumos
        itensBaixoEstoque: itensBaixoEstoque,
      );
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados do estoque: $e');
      return EstoqueSummary(
        totalItens: 0,
        principaisInsumos: [],
        itensBaixoEstoque: 0,
      );
    }
  }

  /// Cria dados do clima
  WeatherData _createWeatherData() {
    return WeatherData(
      localizacao: 'Não disponível',
      temperatura: 25.0,
      condicao: 'Ensolarado',
      umidade: 60.0,
      vento: 5.0,
      probabilidadeChuva: 0.0,
      previsao3Dias: [],
    );
  }

  /// Cria indicadores rápidos
  IndicadoresRapidos _createIndicadoresRapidos() {
    return IndicadoresRapidos(
      areaPlantada: 0.0,
      produtividadeEstimada: 0.0,
      hectaresInfestados: 0.0,
      custosAcumulados: 0.0,
    );
  }

  /// Obtém dados REAIS de plantios do histórico
  Future<Map<String, dynamic>> getPlantingsData() async {
    try {
      Logger.info('🌱 DASHBOARD: Buscando dados reais de plantios...');
      
      final db = await _appDatabase.database;
      
      // Buscar todos registros do histórico
      final historico = await db.query('historico_plantio', orderBy: 'data DESC');
      
      Logger.info('📋 DASHBOARD: ${historico.length} registros no histórico');
      
      if (historico.isEmpty) {
        Logger.info('⚠️ DASHBOARD: Nenhum registro encontrado em historico_plantio');
        return {
          'total': 0,
          'ativos': 0,
          'culturas': <String>[],
          'area_total': 0.0,
          'estagios': <String, int>{},
        };
      }
      
      // Usar um Map para agrupar por talhao_id + cultura_id (um plantio único)
      final plantiosMap = <String, Map<String, dynamic>>{};
      
      for (var registro in historico) {
        final talhaoId = registro['talhao_id'] as String? ?? '';
        final culturaId = registro['cultura_id'] as String? ?? '';
        final talhaoNome = registro['talhao_nome'] as String? ?? talhaoId;
        
        if (talhaoId.isEmpty || culturaId.isEmpty) continue;
        
        final chave = '$talhaoId|$culturaId';
        
        // Se ainda não temos este plantio, adicionar
        if (!plantiosMap.containsKey(chave)) {
          plantiosMap[chave] = {
            'talhao_id': talhaoId,
            'talhao_nome': talhaoNome,
            'cultura_id': culturaId,
            'data': registro['data'],
          };
        }
      }
      
      final plantios = plantiosMap.values.toList();
      
      Logger.info('🌱 DASHBOARD: ${plantios.length} plantios únicos identificados');
      
      // Extrair culturas únicas
      final culturasSet = <String>{};
      
      for (var plantio in plantios) {
        final culturaId = plantio['cultura_id'] as String;
        // Limpar o ID da cultura (remover "custom_" se houver)
        final culturaNome = culturaId.replaceAll('custom_', '').replaceAll('_', ' ');
        culturasSet.add(culturaNome);
      }
      
      final culturas = culturasSet.toList()..sort();
      
      Logger.info('📊 DASHBOARD: Culturas encontradas: $culturas');
      Logger.info('📊 DASHBOARD: Total de plantios: ${plantios.length}');
      
      return {
        'total': plantios.length,
        'ativos': plantios.length, // Considerar todos como ativos
        'culturas': culturas,
        'area_total': 0.0, // Área será calculada posteriormente se necessário
        'estagios': <String, int>{},
      };
      
    } catch (e, stack) {
      Logger.error('❌ DASHBOARD: Erro ao buscar plantios: $e');
      Logger.error('Stack: $stack');
      
      return {
        'total': 0,
        'ativos': 0,
        'culturas': <String>[],
        'area_total': 0.0,
        'estagios': <String, int>{},
      };
    }
  }
}
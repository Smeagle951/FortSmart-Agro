import 'dart:io'; // ✅ Para acesso a arquivos de imagem
import 'dart:convert'; // ✅ Para JSON pretty print
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart'; // ✅ Para MapTiler
import 'package:latlong2/latlong.dart'; // ✅ Para coordenadas GPS
import 'package:sqflite/sqflite.dart' as sqflite; // ✅ Para firstIntValue
import 'package:sqflite/sqflite.dart'; // ✅ Para Database type
import '../../models/monitoring.dart';
import '../../models/monitoring_point.dart';
import '../../models/occurrence.dart';
import '../../services/monitoring_infestation_integration_service.dart';
import '../../services/fortsmart_agronomic_ai.dart';
import '../../services/ia_aprendizado_continuo.dart';
import '../../services/organism_recommendations_service.dart';
import '../../database/app_database.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import '../../utils/api_config.dart'; // ✅ Para MapTiler API
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/talhao_card_widget.dart';
import '../../widgets/professional_monitoring_card.dart'; // ✅ NOVO CARD PROFISSIONAL
import '../../services/monitoring_card_data_service.dart'; // ✅ NOVO SERVIÇO
import 'monitoring_dashboard_methods.dart'; // ✅ Métodos auxiliares
import 'monitoring_dashboard_widgets_professional.dart'; // ✅ Widgets profissionais

/// Dashboard inteligente de monitoramento com integração ao mapa de infestação
class MonitoringDashboard extends StatefulWidget {
  const MonitoringDashboard({super.key});

  @override
  State<MonitoringDashboard> createState() => _MonitoringDashboardState();
}

class _MonitoringDashboardState extends State<MonitoringDashboard> {
  late Future<List<Monitoring>> _monitoringsFuture;
  String _selectedStatus = 'Todos';
  String _selectedCrop = 'Todas Culturas';
  String _selectedTalhao = 'Todos Talhões';
  
  // ✅ LISTAS DINÂMICAS DE DADOS REAIS
  List<String> _availableCrops = ['Todas Culturas'];
  List<String> _availableTalhoes = ['Todos Talhões'];
  
  // Dados de análise inteligente
  Map<String, dynamic>? _analiseInteligente;
  bool _showDetailedAnalysis = false;
  
  // Dados para heatmap de monitoramento
  List<Map<String, dynamic>> _heatmapData = [];
  bool _showHeatmap = true;
  
  // Serviços
  final MonitoringInfestationIntegrationService _integrationService = MonitoringInfestationIntegrationService();
  final OrganismRecommendationsService _recommendationsService = OrganismRecommendationsService();
  final FortSmartAgronomicAI _aiService = FortSmartAgronomicAI();
  final IAAprendizadoContinuo _learningService = IAAprendizadoContinuo();
  
  // ✅ NOVO: Serviço e dados do card limpo
  final MonitoringCardDataService _cardDataService = MonitoringCardDataService();
  List<MonitoringCardData> _cleanCards = [];
  bool _loadingCleanCards = false;

  @override
  void initState() {
    super.initState();
    _loadRealTalhoesAndCrops(); // ✅ Carregar dados reais primeiro
    _loadMonitorings();
    _loadCleanCards(); // ✅ NOVO: Carregar cards limpos
  }
  
  /// ✅ NOVO: Carrega cards limpos usando novo serviço
  Future<void> _loadCleanCards() async {
    setState(() {
      _loadingCleanCards = true;
    });
    
    try {
      Logger.info('🔄 [CLEAN_CARDS] Carregando cards limpos...');
      
      // Aplicar filtros
      String? talhaoId;
      String? culturaNome;
      
      if (_selectedTalhao != 'Todos Talhões') {
        // Converter nome do talhão para ID
        final db = await AppDatabase.instance.database;
        final talhoes = await db.query(
          'talhoes',
          columns: ['id'],
          where: 'nome = ?',
          whereArgs: [_selectedTalhao],
          limit: 1,
        );
        if (talhoes.isNotEmpty) {
          talhaoId = talhoes.first['id'].toString();
        }
      }
      
      if (_selectedCrop != 'Todas Culturas') {
        culturaNome = _selectedCrop;
      }
      
      final cards = await _cardDataService.loadMultipleCards(
        talhaoId: talhaoId,
        culturaNome: culturaNome,
        limit: 20,
      );
      
      // Aplicar filtro de status
      final filteredCards = _selectedStatus == 'Todos'
          ? cards
          : cards.where((card) {
              if (_selectedStatus == 'Ativos') return card.status == 'active';
              if (_selectedStatus == 'Concluídos') return card.status == 'finalized';
              if (_selectedStatus == 'Pausados') return card.status == 'pausado';
              return true;
            }).toList();
      
      setState(() {
        _cleanCards = filteredCards;
        _loadingCleanCards = false;
      });
      
      Logger.info('✅ [CLEAN_CARDS] ${filteredCards.length} cards limpos carregados!');
      
    } catch (e, stack) {
      Logger.error('❌ [CLEAN_CARDS] Erro ao carregar cards limpos: $e', null, stack);
      setState(() {
        _loadingCleanCards = false;
      });
    }
  }
  
  /// ✅ CARREGA TALHÕES E CULTURAS REAIS DO BANCO
  Future<void> _loadRealTalhoesAndCrops() async {
    try {
      Logger.info('🔄 Carregando talhões e culturas reais do banco...');
      
      final db = await AppDatabase.instance.database;
      
      // Conjuntos para evitar duplicados
      final talhoesSet = <String>{};
      final culturasSet = <String>{};
      
      // 1) Talhões da tabela local
      final talhoesData = await db.query(
        'talhoes',
        columns: ['id', 'nome'],
        orderBy: 'nome ASC',
      );
      for (final talhao in talhoesData) {
        final nome = talhao['nome'] as String? ?? 'Talhão ${talhao['id']}';
        talhoesSet.add(nome);
      }
      
      // 2) Talhões adicionais de outras fontes (se necessário)
      // TODO: Implementar busca em outras fontes se necessário
      
      // 3) Culturas de sessões de monitoramento
      final culturasData = await db.rawQuery('''
        SELECT DISTINCT cultura_nome 
        FROM monitoring_sessions 
        WHERE cultura_nome IS NOT NULL 
        ORDER BY cultura_nome ASC
      ''');
      for (final cultura in culturasData) {
        final nome = cultura['cultura_nome'] as String?;
        if (nome != null && nome.isNotEmpty) culturasSet.add(nome);
      }
      
      // 4) Culturas do histórico de plantio
      final plantiosCulturas = await db.rawQuery('''
        SELECT DISTINCT cultura 
        FROM historico_plantio 
        WHERE cultura IS NOT NULL 
        ORDER BY cultura ASC
      ''');
      for (final cultura in plantiosCulturas) {
        final nome = cultura['cultura'] as String?;
        if (nome != null && nome.isNotEmpty) culturasSet.add(nome);
      }
      
      // 5) Culturas adicionais de outras fontes (se necessário)
      // TODO: Implementar busca em outras fontes se necessário
      
      // Transformar em listas ordenadas com a opção "Todos"
      final talhoesList = ['Todos Talhões', ...talhoesSet.toList()..sort()];
      final cropsList = ['Todas Culturas', ...culturasSet.toList()..sort()];
      
      setState(() {
        _availableTalhoes = talhoesList;
        _availableCrops = cropsList;
      });
      
      Logger.info('✅ Dados reais carregados:');
      Logger.info('   • Talhões: ${talhoesList.length - 1}');
      Logger.info('   • Culturas: ${cropsList.length - 1}');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar talhões e culturas: $e');
      // Manter valores padrão em caso de erro
    }
  }

  void _loadMonitorings() {
    setState(() {
      _monitoringsFuture = _loadMonitoringsData();
    });
  }

  Future<List<Monitoring>> _loadMonitoringsData() async {
    try {
      Logger.info('🔍 Carregando dados reais de monitoramento...');
      
      // Carregar dados reais de monitoramento
      final monitorings = await _integrationService.getAllMonitorings();
      
      if (monitorings.isNotEmpty) {
        Logger.info('✅ ${monitorings.length} monitoramentos carregados');
        
        // Gerar análise inteligente com dados reais
        _analiseInteligente = await _gerarAnaliseInteligenteComDadosReais(monitorings);
        
        // Gerar dados para heatmap com dados reais
        _heatmapData = _gerarDadosHeatmapReais(monitorings);
        
        return monitorings;
      } else {
        Logger.warning('⚠️ Nenhum monitoramento encontrado, usando dados de exemplo');
        
        // Gerar análise inteligente
        _analiseInteligente = await _gerarAnaliseInteligente();
        
        // Gerar dados para heatmap
        _heatmapData = _gerarDadosHeatmap();
        
        // Simular dados de monitoramento
        return _gerarMonitoringsExemplo();
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar monitoramentos: $e');
      return [];
    }
  }

  /// Gera análise inteligente com dados reais de monitoramento
  Future<Map<String, dynamic>> _gerarAnaliseInteligenteComDadosReais(List<Monitoring> monitorings) async {
    try {
      await _aiService.initialize();
      await _learningService.initialize();
      
      // Processar dados reais
      final organismosDetectados = <String>[];
      final sintomasIdentificados = <String>[];
      double temperaturaMedia = 0.0;
      double umidadeMedia = 0.0;
      
      for (final monitoring in monitorings) {
        for (final point in monitoring.points) {
          for (final occurrence in point.occurrences) {
            // Adicionar organismo detectado
            final organismName = occurrence.organismName ?? occurrence.name;
            organismosDetectados.add(organismName);
            
            // Adicionar nível de infestação como "sintoma"
            final nivel = occurrence.infestationIndex > 0 
              ? '${organismName}: ${occurrence.infestationIndex.toStringAsFixed(1)}%'
              : null;
            if (nivel != null) {
              sintomasIdentificados.add(nivel);
            }
            
            // Adicionar observações como sintomas adicionais
            if (occurrence.notes != null && occurrence.notes!.isNotEmpty) {
              sintomasIdentificados.add(occurrence.notes!);
            }
          }
        }
        
        if (monitoring.weatherData != null) {
          temperaturaMedia += monitoring.weatherData!['temperatura'] ?? 0.0;
          umidadeMedia += monitoring.weatherData!['umidade'] ?? 0.0;
        }
      }
      
      if (monitorings.isNotEmpty) {
        temperaturaMedia /= monitorings.length;
        umidadeMedia /= monitorings.length;
      }
      
      return {
        'versaoIA': 'Sistema FortSmart Agro v3.0',
        'dataAnalise': DateTime.now().toIso8601String(),
        'nivelRisco': _calcularNivelRisco(organismosDetectados.length, occurrences: []), // ✅ Análise geral (sem occurrences)
        'scoreConfianca': 0.95,
        'organismosDetectados': organismosDetectados.toSet().toList(),
        'sintomasIdentificados': sintomasIdentificados.toSet().toList(),
        'condicoesFavoraveis': {
          'temperatura': temperaturaMedia,
          'umidade': umidadeMedia,
          'precipitacao': 0.0,
        },
        'recomendacoes': _gerarRecomendacoesReais(organismosDetectados),
        'alertas': _gerarAlertasReais(organismosDetectados),
        'totalMonitoramentos': monitorings.length,
        'totalPontos': monitorings.fold(0, (sum, m) => sum + m.points.length),
        'totalOcorrencias': monitorings.fold(0, (sum, m) => 
          sum + m.points.fold(0, (sum2, p) => sum2 + p.occurrences.length)),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar análise inteligente: $e');
      return _gerarAnaliseInteligente();
    }
  }

  /// Gera análise inteligente baseada nos dados de monitoramento
  Future<Map<String, dynamic>> _gerarAnaliseInteligente() async {
    try {
      await _aiService.initialize();
      await _learningService.initialize();
      
      return {
        'versaoIA': 'Sistema FortSmart Agro v3.0',
        'dataAnalise': DateTime.now().toIso8601String(),
        'nivelRisco': 'Baixo',
        'scoreConfianca': 0.0,
        'organismosDetectados': [],
        'sintomasIdentificados': [],
        'condicoesFavoraveis': {
          'temperatura': 0.0,
          'umidade': 0.0,
          'precipitacao': 0.0,
        },
        'recomendacoes': [
          'Iniciar monitoramento de campo',
          'Configurar pontos de coleta de dados',
          'Implementar sistema de alertas',
        ],
        'alertas': [
          'Sistema em configuração inicial',
          'Aguardando dados de monitoramento',
        ],
        'dadosTecnicos': {
          'totalPontos': 0,
          'areaTotalMonitorada': 0.0,
          'intensidadeMedia': 0.0,
          'coordenadasAnalisadas': [],
        },
      };
    } catch (e) {
      Logger.error('Erro ao gerar análise inteligente: $e');
      return {};
    }
  }

  /// Calcula nível de risco baseado na severidade agronômica REAL
  /// ✅ CORRIGIDO: Usa média de severidade, não contagem de organismos
  String _calcularNivelRisco(int numOrganismos, {List<dynamic>? occurrences}) {
    // Se temos ocorrências com severidade, usar severidade agronômica
    if (occurrences != null && occurrences.isNotEmpty) {
      double somaSeversidade = 0.0;
      int count = 0;
      
      for (final occ in occurrences) {
        double severity = 0.0;
        
        // Tentar múltiplas formas de acessar severidade
        if (occ is Map) {
          severity = (occ['agronomic_severity'] as num?)?.toDouble() ?? 
                    (occ['percentual'] as num?)?.toDouble() ?? 
                    (occ['severity'] as num?)?.toDouble() ?? 0.0;
        } else {
          // Se for objeto Occurrence
          try {
            severity = (occ as dynamic).infestationIndex ?? 0.0;
          } catch (e) {
            severity = 0.0;
          }
        }
        
        if (severity > 0) {
          somaSeversidade += severity;
          count++;
        }
      }
      
      if (count > 0) {
        final mediaSeversidade = somaSeversidade / count;
        
        Logger.info('📊 [RISCO] Calculando risco com severidade agronômica:');
        Logger.info('   • Soma severidade: ${somaSeversidade.toStringAsFixed(1)}');
        Logger.info('   • Total ocorrências: $count');
        Logger.info('   • Média severidade: ${mediaSeversidade.toStringAsFixed(1)}%');
        
        if (mediaSeversidade < 20) return 'Baixo';
        if (mediaSeversidade < 40) return 'Médio';
        if (mediaSeversidade < 70) return 'Alto';
        return 'Crítico';
      }
    }
    
    // Fallback: usar contagem de organismos (menos preciso)
    Logger.warning('⚠️ [RISCO] Usando fallback (contagem de organismos)');
    if (numOrganismos == 0) return 'Baixo';
    if (numOrganismos <= 2) return 'Médio';
    if (numOrganismos <= 5) return 'Alto';
    return 'Crítico';
  }

  /// 🔬 NOVA ANÁLISE: Dados reais por sessão/talhão com thresholds fenológicos
  Future<Map<String, dynamic>> _gerarAnaliseRealPorSessao({
    String? sessionIdFilter,
    String? talhaoIdFilter,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // ✅ DIAGNÓSTICO: Contar TODAS as ocorrências no banco
      final totalOccResult = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_occurrences');
      final totalOcorrencias = totalOccResult.first['total'] as int;
      Logger.info('🔍 [FILTER] Total de ocorrências no banco: $totalOcorrencias');
      
      // 1️⃣ BUSCAR OCORRÊNCIAS REAIS
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (sessionIdFilter != null && sessionIdFilter.isNotEmpty) {
        whereClause += ' AND mo.session_id = ?';
        whereArgs.add(sessionIdFilter);
        Logger.info('🔍 [FILTER] Aplicando filtro de SESSION_ID: $sessionIdFilter');
      } else if (talhaoIdFilter != null && talhaoIdFilter.isNotEmpty) {
        whereClause += ' AND mo.talhao_id = ?';
        whereArgs.add(talhaoIdFilter);
        Logger.info('🔍 [FILTER] Aplicando filtro de TALHAO_ID: $talhaoIdFilter');
      } else {
        Logger.warning('⚠️ [FILTER] NENHUM FILTRO APLICADO - Mostrando TODAS as ocorrências');
      }
      
      final occurrences = await db.rawQuery('''
        SELECT 
          mo.organism_id,
          mo.organism_name,
          mo.quantidade,
          mo.percentual,
          mo.agronomic_severity,
          mo.point_id,
          mo.session_id,
          mo.talhao_id,
          mp.latitude,
          mp.longitude
        FROM monitoring_occurrences mo
        LEFT JOIN monitoring_points mp ON mp.id = mo.point_id
        WHERE $whereClause
        ORDER BY mo.created_at DESC
        LIMIT 100
      ''', whereArgs);
      
      Logger.info('📊 Ocorrências encontradas APÓS FILTRO: ${occurrences.length} de $totalOcorrencias total');
      Logger.info('🔍 Filtros aplicados: sessionId=$sessionIdFilter, talhaoId=$talhaoIdFilter');
      
      // ✅ Se não encontrou nada COM filtro, tentar SEM filtro como fallback
      if (occurrences.isEmpty && (sessionIdFilter != null || talhaoIdFilter != null)) {
        Logger.warning('⚠️ [FALLBACK] Nenhuma ocorrência com filtro! Buscando TODAS as ocorrências...');
        final allOccurrences = await db.rawQuery('''
          SELECT 
            mo.organism_id,
            mo.organism_name,
            mo.quantidade,
            mo.percentual,
            mo.agronomic_severity,
            mo.point_id,
            mo.session_id,
            mo.talhao_id,
            mp.latitude,
            mp.longitude
          FROM monitoring_occurrences mo
          LEFT JOIN monitoring_points mp ON mp.id = mo.point_id
          ORDER BY mo.created_at DESC
          LIMIT 100
        ''');
        Logger.info('📊 [FALLBACK] Total de ocorrências encontradas: ${allOccurrences.length}');
        
        if (allOccurrences.isNotEmpty) {
          // Usar dados sem filtro
          return _processOccurrencesData(allOccurrences, sessionIdFilter, talhaoIdFilter, db);
        }
      }
      
      // Processar dados encontrados
      return _processOccurrencesData(occurrences, sessionIdFilter, talhaoIdFilter, db);
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar análise real: $e');
      return {
        'versaoIA': 'Sistema FortSmart Agro v3.1 - Erro',
        'dataAnalise': DateTime.now().toIso8601String(),
        'nivelRisco': 'Indisponível',
        'scoreConfianca': 0.0,
        'organismosDetectados': [],
        'totalPontosMonitorados': 0,
        'totalOcorrencias': 0,
      };
    }
  }
  
  /// 🔬 Processa dados de ocorrências (método auxiliar)
  Future<Map<String, dynamic>> _processOccurrencesData(
    List<Map<String, Object?>> occurrences,
    String? sessionIdFilter,
    String? talhaoIdFilter,
    Database db,
  ) async {
      // 2️⃣ CONTAR TOTAL DE PONTOS MONITORADOS
      String pointsWhereClause = '1=1';
      List<dynamic> pointsWhereArgs = [];
      
      if (sessionIdFilter != null && sessionIdFilter.isNotEmpty) {
        pointsWhereClause += ' AND session_id = ?';
        pointsWhereArgs.add(sessionIdFilter);
      } else if (talhaoIdFilter != null && talhaoIdFilter.isNotEmpty) {
        pointsWhereClause += ' AND session_id IN (SELECT id FROM monitoring_sessions WHERE talhao_id = ?)';
        pointsWhereArgs.add(talhaoIdFilter);
      }
      
      final totalPontosResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT id) as total
        FROM monitoring_points
        WHERE $pointsWhereClause
      ''', pointsWhereArgs);
      
      var totalPontosMonitorados = (totalPontosResult.first['total'] as num?)?.toInt() ?? 0;
      
      Logger.info('📍 [PONTOS] Total de pontos no banco: $totalPontosMonitorados');
      Logger.info('   Query: WHERE $pointsWhereClause');
      Logger.info('   Args: $pointsWhereArgs');
      
      // ✅ SEGURANÇA: Se totalPontos = 0, usar número de pontos ÚNICOS das ocorrências
      if (totalPontosMonitorados == 0) {
        final pontosUnicos = occurrences.map((occ) => occ['point_id']).toSet().length;
        Logger.warning('   ⚠️ Total de pontos = 0! Usando pontos únicos das ocorrências: $pontosUnicos');
        totalPontosMonitorados = pontosUnicos > 0 ? pontosUnicos : 1;
      }
      
      Logger.info('📍 [PONTOS] Total FINAL usado: $totalPontosMonitorados');
      
      // 3️⃣ AGRUPAR POR ORGANISMO E CALCULAR MÉTRICAS
      final Map<String, Map<String, dynamic>> organismosMap = {};
      
      Logger.info('🔍 [DEBUG] ===== PROCESSANDO ${occurrences.length} OCORRÊNCIAS =====');
      Logger.info('📍 [DEBUG] Total de pontos para cálculo: $totalPontosMonitorados');
      
      int ocorrenciaIndex = 0;
      for (final occ in occurrences) {
        ocorrenciaIndex++;
        final organismName = (occ['organism_name'] ?? 'Desconhecido').toString();
        
        // ✅ LOGS SUPER DETALHADOS DO QUE VEM DO BANCO
        Logger.info('🐛 [DEBUG] ===== Ocorrência #$ocorrenciaIndex/${ occurrences.length} =====');
        Logger.info('   🏷️ Organismo: $organismName');
        Logger.info('   📊 quantidade (banco): ${occ['quantidade']} (tipo: ${occ['quantidade'].runtimeType})');
        Logger.info('   📊 percentual (banco): ${occ['percentual']} (tipo: ${occ['percentual'].runtimeType})');
        Logger.info('   📊 agronomic_severity (banco): ${occ['agronomic_severity']} (tipo: ${occ['agronomic_severity'].runtimeType})');
        Logger.info('   📍 point_id: ${occ['point_id']}');
        Logger.info('   📍 session_id: ${occ['session_id']}');
        Logger.info('   📍 talhao_id: ${occ['talhao_id']}');
        
        final quantidade = (occ['quantidade'] as num?)?.toDouble() ?? (occ['percentual'] as num?)?.toDouble() ?? 0.0;
        final severity = (occ['agronomic_severity'] as num?)?.toDouble() ?? 0.0;
        
        Logger.info('   ✅ Quantidade CONVERTIDA: $quantidade');
        Logger.info('   ✅ Severidade CONVERTIDA: $severity');
        
        if (quantidade == 0.0) {
          Logger.error('   ❌ QUANTIDADE = 0! Ocorrência salva sem quantidade!');
        }
        if (severity == 0.0) {
          Logger.error('   ❌ SEVERIDADE = 0! Ocorrência salva sem severidade agronômica!');
        }
        
        if (!organismosMap.containsKey(organismName)) {
          organismosMap[organismName] = {
            'nome': organismName,
            'organism_id': occ['organism_id'],
            'pontos_com_infestacao': <String>{},
            'quantidade_total': 0.0,
            'severidade_total': 0.0,
            'quantidade_maxima': 0.0,
            'coordenadas': <Map<String, double>>[],
          };
        }
        
        final orgData = organismosMap[organismName]!;
        (orgData['pontos_com_infestacao'] as Set<String>).add(occ['point_id'].toString());
        orgData['quantidade_total'] = (orgData['quantidade_total'] as double) + quantidade;
        orgData['severidade_total'] = (orgData['severidade_total'] as double) + severity;
        
        if (quantidade > (orgData['quantidade_maxima'] as double)) {
          orgData['quantidade_maxima'] = quantidade;
        }
        
        if (occ['latitude'] != null && occ['longitude'] != null) {
          (orgData['coordenadas'] as List<Map<String, double>>).add({
            'lat': (occ['latitude'] as num).toDouble(),
            'lng': (occ['longitude'] as num).toDouble(),
          });
        }
      }
      
      // 4️⃣ CALCULAR FREQUÊNCIA, ÍNDICE E NÍVEL POR ORGANISMO
      final organismosProcessados = <Map<String, dynamic>>[];
      
      for (final entry in organismosMap.entries) {
        final orgData = entry.value;
        final pontosComInfestacao = (orgData['pontos_com_infestacao'] as Set<String>).length;
        final quantidadeTotal = orgData['quantidade_total'] as double;
        final severidadeTotal = orgData['severidade_total'] as double;
        
        // Frequência: (pontos com infestação / total de pontos) * 100
        final frequencia = totalPontosMonitorados > 0
            ? (pontosComInfestacao / totalPontosMonitorados) * 100
            : 0.0;
        
        // Quantidade média: total / pontos com infestação
        final quantidadeMedia = pontosComInfestacao > 0
            ? quantidadeTotal / pontosComInfestacao
            : 0.0;
        
        // Severidade média
        final severidadeMedia = pontosComInfestacao > 0
            ? severidadeTotal / pontosComInfestacao
            : 0.0;
        
        // Índice: (frequência * quantidade média) / 100
        final indice = (frequencia * quantidadeMedia) / 100;
        
        // 5️⃣ DETERMINAR NÍVEL usando thresholds fenológicos
        String nivel = 'BAIXO';
        
        // Usar quantidade média para classificar nível
        if (quantidadeMedia <= 2) {
          nivel = 'BAIXO';
        } else if (quantidadeMedia <= 5) {
          nivel = 'MÉDIO';
        } else if (quantidadeMedia <= 10) {
          nivel = 'ALTO';
        } else {
          nivel = 'CRÍTICO';
        }
        
        // Ajustar nível baseado na severidade agronômica também
        if (severidadeMedia >= 8) {
          nivel = 'CRÍTICO';
        } else if (severidadeMedia >= 6 && nivel == 'MÉDIO') {
          nivel = 'ALTO';
        }
        
        organismosProcessados.add({
          'nome': orgData['nome'],
          'organism_id': orgData['organism_id'],
          'pontos_com_infestacao': pontosComInfestacao,
          'total_pontos_monitorados': totalPontosMonitorados,
          'frequencia_percentual': frequencia,
          'quantidade_total': quantidadeTotal,
          'quantidade_media': quantidadeMedia,
          'quantidade_maxima': orgData['quantidade_maxima'],
          'severidade_media': severidadeMedia,
          'indice': indice,
          'nivel': nivel,
          'coordenadas': orgData['coordenadas'],
        });
      }
      
      // Ordenar por índice (maior primeiro)
      organismosProcessados.sort((a, b) => (b['indice'] as double).compareTo(a['indice'] as double));
      
      // 6️⃣ CONSOLIDADO DO TALHÃO
      final organismosNomes = organismosProcessados.map((o) => o['nome'].toString()).toList();
      final nivelRiscoGeral = _calcularNivelRiscoGeral(organismosProcessados);
      
      Logger.info('✅ Análise completa:');
      Logger.info('  - Organismos processados: ${organismosProcessados.length}');
      Logger.info('  - Nível de risco: $nivelRiscoGeral');
      Logger.info('  - Total pontos: $totalPontosMonitorados');
      Logger.info('  - Total ocorrências: ${occurrences.length}');
      
      return {
        'versaoIA': 'Sistema FortSmart Agro v3.1 - Análise Real',
        'dataAnalise': DateTime.now().toIso8601String(),
        'fonte': 'monitoring_occurrences + monitoring_points',
        'filtros': {
          'session_id': sessionIdFilter,
          'talhao_id': talhaoIdFilter,
        },
        'nivelRisco': nivelRiscoGeral,
        'scoreConfianca': 0.98, // Alta confiança (dados reais)
        'totalPontosMonitorados': totalPontosMonitorados,
        'totalOcorrencias': occurrences.length,
        'organismosDetectados': organismosNomes,
        'organismosDetalhados': organismosProcessados,
        'recomendacoes': _gerarRecomendacoesReaisDetalhadas(organismosProcessados),
        'alertas': _gerarAlertasReaisDetalhados(organismosProcessados),
      };
  }
  
  /// Calcula nível de risco geral do talhão baseado nos organismos
  String _calcularNivelRiscoGeral(List<Map<String, dynamic>> organismos) {
    if (organismos.isEmpty) return 'BAIXO';
    
    final criticos = organismos.where((o) => o['nivel'] == 'CRÍTICO').length;
    final altos = organismos.where((o) => o['nivel'] == 'ALTO').length;
    final medios = organismos.where((o) => o['nivel'] == 'MÉDIO').length;
    
    if (criticos > 0) return 'CRÍTICO';
    if (altos >= 2) return 'ALTO';
    if (altos == 1 || medios >= 3) return 'MÉDIO';
    return 'BAIXO';
  }
  
  /// Retorna a cor baseada no nível de risco
  Color _getNivelRiscoColor(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'CRÍTICO':
        return Colors.red;
      case 'ALTO':
        return Colors.orange;
      case 'MÉDIO':
        return Colors.yellow.shade700;
      case 'BAIXO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  /// Gera recomendações baseadas em organismos reais
  List<String> _gerarRecomendacoesReais(List<String> organismos) {
    final recomendacoes = <String>[];
    
    if (organismos.isEmpty) {
      recomendacoes.add('Continue o monitoramento regular');
      recomendacoes.add('Mantenha as condições atuais');
    } else {
      recomendacoes.add('Identificados ${organismos.length} organismos - ação necessária');
      recomendacoes.add('Aplicar tratamento específico para: ${organismos.join(', ')}');
      recomendacoes.add('Monitorar evolução da infestação');
    }
    
    return recomendacoes;
  }
  
  /// Gera recomendações detalhadas baseadas nos organismos processados
  List<String> _gerarRecomendacoesReaisDetalhadas(List<Map<String, dynamic>> organismos) {
    final recomendacoes = <String>[];
    
    if (organismos.isEmpty) {
      recomendacoes.add('Continue o monitoramento regular');
      recomendacoes.add('Mantenha as condições atuais');
      return recomendacoes;
    }
    
    final criticos = organismos.where((o) => o['nivel'] == 'CRÍTICO').toList();
    final altos = organismos.where((o) => o['nivel'] == 'ALTO').toList();
    
    if (criticos.isNotEmpty) {
      recomendacoes.add('🚨 AÇÃO URGENTE: ${criticos.length} organismo(s) em nível CRÍTICO');
      recomendacoes.add('Aplicar tratamento imediato para: ${criticos.map((o) => o['nome']).join(', ')}');
    }
    
    if (altos.isNotEmpty) {
      recomendacoes.add('⚠️ Atenção: ${altos.length} organismo(s) em nível ALTO');
      recomendacoes.add('Programar aplicação para: ${altos.map((o) => o['nome']).join(', ')}');
    }
    
    recomendacoes.add('Monitorar evolução em ${organismos.length} organismo(s) detectado(s)');
    recomendacoes.add('Intensificar amostragem nas áreas de maior incidência');
    
    return recomendacoes;
  }

  /// Gera alertas baseados em organismos reais
  List<String> _gerarAlertasReais(List<String> organismos) {
    final alertas = <String>[];
    
    if (organismos.isNotEmpty) {
      alertas.add('⚠️ ${organismos.length} organismos detectados');
      alertas.add('🔍 Monitoramento intensificado necessário');
      if (organismos.length > 3) {
        alertas.add('🚨 Alto risco de infestação');
      }
    }
    
    return alertas;
  }
  
  /// Gera alertas detalhados baseados nos organismos processados
  List<String> _gerarAlertasReaisDetalhados(List<Map<String, dynamic>> organismos) {
    final alertas = <String>[];
    
    if (organismos.isEmpty) return alertas;
    
    final criticos = organismos.where((o) => o['nivel'] == 'CRÍTICO').length;
    final altos = organismos.where((o) => o['nivel'] == 'ALTO').length;
    
    if (criticos > 0) {
      alertas.add('🚨 ${criticos} organismo(s) em nível CRÍTICO - Ação imediata necessária');
    }
    
    if (altos > 0) {
      alertas.add('⚠️ ${altos} organismo(s) em nível ALTO - Monitorar de perto');
    }
    
    alertas.add('📊 Total de ${organismos.length} organismo(s) detectado(s)');
    alertas.add('🔍 Análise baseada em dados reais do monitoramento');
    
    return alertas;
  }

  /// Gera dados para heatmap com dados reais
  List<Map<String, dynamic>> _gerarDadosHeatmapReais(List<Monitoring> monitorings) {
    final heatmapData = <Map<String, dynamic>>[];
    
    for (final monitoring in monitorings) {
      for (final point in monitoring.points) {
        if (point.occurrences.isNotEmpty) {
          final intensidade = point.occurrences.length / 10.0; // Normalizar
          
          // ✅ DETERMINAR COR BASEADA NA INTENSIDADE
          Color cor;
          String nivel;
          if (intensidade >= 0.7) {
            cor = Colors.red;
            nivel = 'critico';
          } else if (intensidade >= 0.4) {
            cor = Colors.orange;
            nivel = 'moderado';
          } else if (intensidade >= 0.2) {
            cor = Colors.yellow;
            nivel = 'baixo';
          } else {
            cor = Colors.green;
            nivel = 'normal';
          }
          
          heatmapData.add({
            'latitude': point.latitude,
            'longitude': point.longitude,
            'intensidade': intensidade,
            'organismo': point.occurrences.first.organismName,
            'cultura': monitoring.cropName,
            'data': point.date.toIso8601String(),
            'fonte': 'Monitoramento Real',
            'cor': cor,  // ✅ ADICIONADO
            'nivel': nivel,  // ✅ ADICIONADO
          });
        }
      }
    }
    
    return heatmapData;
  }

  /// Gera dados para heatmap de monitoramento
  List<Map<String, dynamic>> _gerarDadosHeatmap() {
    return [];
  }

  /// Gera monitoramentos de exemplo
  List<Monitoring> _gerarMonitoringsExemplo() {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Monitoramento - Sistema FortSmart Agro'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Monitoring>>(
        future: _monitoringsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          } else if (snapshot.hasError) {
            Logger.error('Erro ao carregar monitoramentos: ${snapshot.error}');
            return ErrorStateWidget(
              message: 'Erro ao carregar monitoramentos: ${snapshot.error}',
              onRetry: _loadMonitorings,
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              message: 'Nenhum monitoramento encontrado. Crie um novo monitoramento.',
              onAction: () {
                // TODO: Navegar para tela de criação de monitoramento
                Logger.info('Navegar para criação de monitoramento');
              },
              actionText: 'Criar Monitoramento',
            );
          } else {
            final allMonitorings = snapshot.data!;
            final filteredMonitorings = _filterMonitorings(allMonitorings);

            return RefreshIndicator(
              onRefresh: () async { _loadMonitorings(); },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(filteredMonitorings.length, allMonitorings.length),
                    const SizedBox(height: 16),
                    _buildFilters(allMonitorings),
                    const SizedBox(height: 16),
                    _buildStats(filteredMonitorings),
                    const SizedBox(height: 24),
                    
                    // ✅ NOVO: CARDS LIMPOS E ELEGANTES
                    _buildCleanCardsSection(),
                    const SizedBox(height: 24),
                    
        // ❌ DESABILITADO: CARD ANTIGO SISTEMA FORTSMART AGRO (substituído pelos novos cards)
        // if (_analiseInteligente != null) _buildAnaliseInteligenteCard(),
                    
                    // Heatmap de monitoramento
                    // ❌ REMOVIDO: Card "Heatmap de Monitoramento" (não está funcionando corretamente)
                    // O mapa térmico está disponível em: Relatório Agronômico → Aba "Infestação Fenológica"
                    
                    const SizedBox(height: 24),
                    // ❌ DESABILITADO: Cards antigos (mantido para referência futura)
                    // Text(
                    //   'Monitoramentos (${filteredMonitorings.length})',
                    //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    //     fontWeight: FontWeight.bold,
                    //     color: AppTheme.primaryColor,
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    // ...filteredMonitorings.map((monitoring) => _buildMonitoringCard(monitoring)).toList(),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// ✅ NOVO: Seção de cards limpos
  Widget _buildCleanCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32),
                    const Color(0xFF1B5E20),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Monitoramentos - Visualização Inteligente',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ),
            if (_loadingCleanCards)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCleanCards,
                tooltip: 'Atualizar',
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Análise completa com dados reais do banco de dados',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
        
        if (_loadingCleanCards)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_cleanCards.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum monitoramento encontrado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajuste os filtros ou crie um novo monitoramento',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  ],
                ),
              ),
          )
        else
          Column(
            children: _cleanCards.map((cardData) {
              return ProfessionalMonitoringCard(
                data: cardData,
                onTap: () => _showDetailedAnalysisFromCard(cardData),
              );
            }).toList(),
          ),
      ],
    );
  }
  
  /// ✅ NOVO: Mostra análise detalhada a partir de um card limpo
  void _showDetailedAnalysisFromCard(MonitoringCardData cardData) async {
    Logger.info('🔍 [CLEAN_CARD] Mostrando análise detalhada para sessão: ${cardData.sessionId}');
    
    // ✅ USAR NOVA TELA COM DADOS DO CARD
    await _showNewAnaliseDetalhada(cardData);
  }

  Widget _buildHeader(int filteredCount, int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Dashboard de Monitoramento',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
          onPressed: _loadMonitorings,
        ),
      ],
    );
  }

  Widget _buildFilters(List<Monitoring> allMonitorings) {
    final List<String> statuses = ['Todos', 'Ativo', 'Concluído', 'Pausado'];
    
    // ✅ USAR DADOS REAIS CARREGADOS DO BANCO
    final List<String> crops = _availableCrops;
    final List<String> talhoes = _availableTalhoes;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildDropdownFilter(
              'Status',
              statuses,
              _selectedStatus,
              (newValue) {
                setState(() {
                  _selectedStatus = newValue!;
                });
                _loadCleanCards(); // ✅ NOVO: Recarregar cards limpos
              },
            ),
            const SizedBox(height: 8),
            _buildDropdownFilter(
              'Cultura',
              crops,
              _selectedCrop,
              (newValue) {
                setState(() {
                  _selectedCrop = newValue!;
                });
                _loadCleanCards(); // ✅ NOVO: Recarregar cards limpos
              },
            ),
            const SizedBox(height: 8),
            _buildDropdownFilter(
              'Talhão',
              talhoes,
              _selectedTalhao,
              (newValue) {
                setState(() {
                  _selectedTalhao = newValue!;
                });
                _loadCleanCards(); // ✅ NOVO: Recarregar cards limpos
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(
      String label, List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// Resolve a sessão e talhão com base nos filtros selecionados
  Future<Map<String, String?>> _resolveSessionAndTalhaoFromFilters() async {
    final db = await AppDatabase.instance.database;
    final where = <String>[];
    final args = <Object?>[];
    
    if (_selectedTalhao != 'Todos Talhões') {
      where.add('talhao_nome = ?');
      args.add(_selectedTalhao);
    }
    if (_selectedCrop != 'Todas Culturas') {
      where.add('cultura_nome = ?');
      args.add(_selectedCrop);
    }
    if (_selectedStatus != 'Todos') {
      where.add('status = ?');
      args.add(_selectedStatus.toLowerCase());
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ' + where.join(' AND ');
    
    final rows = await db.rawQuery('''
      SELECT id as session_id, talhao_id
      FROM monitoring_sessions
      $whereSql
      ORDER BY started_at DESC
      LIMIT 1
    ''', args);
    
    return {
      'session_id': rows.isNotEmpty ? rows.first['session_id']?.toString() : null,
      'talhao_id': rows.isNotEmpty ? rows.first['talhao_id']?.toString() : null,
    };
  }

  List<Monitoring> _filterMonitorings(List<Monitoring> monitorings) {
    return monitorings.where((monitoring) {
      final matchesStatus = _selectedStatus == 'Todos' || monitoring.status == _selectedStatus;
      final matchesCrop = _selectedCrop == 'Todas Culturas' || monitoring.cropName == _selectedCrop;
      final matchesTalhao = _selectedTalhao == 'Todos Talhões' 
        || monitoring.plotName == _selectedTalhao 
        || ('Talhão ${monitoring.plotId}' == _selectedTalhao);
      return matchesStatus && matchesCrop && matchesTalhao;
    }).toList();
  }

  Widget _buildStats(List<Monitoring> monitorings) {
    final active = monitorings.where((m) => m.status == 'Ativo').length;
    final critical = monitorings.where((m) => m.hasCriticalOccurrences).length;
    final completed = monitorings.where((m) => m.status == 'Concluído').length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade300,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Ativos', active, Colors.blue.shade800),
            _buildStatItem('Críticos', critical, Colors.red.shade800),
            _buildStatItem('Concluídos', completed, Colors.green.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChipLike(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  double _estimativaAreaAfetada(Monitoring monitoring) {
    final totalPoints = monitoring.points.length;
    if (totalPoints == 0) return 0.0;
    final pointsWithOccurrences = monitoring.points.where((p) => p.occurrences.isNotEmpty).length;
    // estimativa simples: % de pontos com ocorrência
    return (pointsWithOccurrences / totalPoints) * 100.0;
  }

  // Exibe estatística com valor de texto (ex.: porcentagem)
  Widget _buildStatTextItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // Cor por nível de risco
  Color _getRiscoColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'baixo':
        return Colors.green;
      case 'médio':
      case 'medio':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      case 'crítico':
      case 'critico':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAnaliseInteligenteCard() {
    final analise = _analiseInteligente!;
    final confianca = (analise['scoreConfianca'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Sistema FortSmart Agro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfiancaColor(confianca),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(confianca * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Análise Inteligente de Monitoramento',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.psychology, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 4),
              Text('Sistema FortSmart Agro', style: TextStyle(fontSize: 12, color: Colors.blue[700])),
              const SizedBox(width: 16),
              Icon(Icons.analytics, size: 16, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text('Análise Térmica', style: TextStyle(fontSize: 12, color: Colors.green[700])),
            ],
          ),
          const SizedBox(height: 12),
          // ✅ BOTÃO ÚNICO: Ver Análise Detalhada
          ElevatedButton.icon(
            onPressed: () async {
              // Resolver a sessão/talhão a partir dos filtros selecionados
              final resolved = await _resolveSessionAndTalhaoFromFilters();
              
              Logger.info('🔵 [BOTÃO AZUL] ===== VER ANÁLISE DETALHADA =====');
              Logger.info('   🔍 Filtro Talhão: $_selectedTalhao');
              Logger.info('   🔍 Filtro Cultura: $_selectedCrop');
              Logger.info('   🔍 Filtro Status: $_selectedStatus');
              Logger.info('   ✅ Session ID resolvido: ${resolved['session_id']}');
              Logger.info('   ✅ Talhão ID resolvido: ${resolved['talhao_id']}');
              Logger.info('🔵 [BOTÃO AZUL] ================================');
              
              _showAnaliseDetalhada(
                sessionIdFilter: resolved['session_id'],
                talhaoIdFilter: resolved['talhao_id'],
              );
            },
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('Ver Análise Detalhada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          // ❌ REMOVIDO: Botão "Ver Mapa" (não está funcionando corretamente)
        ],
      ),
    );
  }

  Widget _buildHeatmapCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.orange[50]!, Colors.yellow[50]!, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Heatmap de Monitoramento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_heatmapData.length} pontos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Análise térmica baseada nos pontos de monitoramento',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          _buildHeatmapLegend(),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showHeatmapDetails,
            icon: const Icon(Icons.map),
            label: const Text('Ver Mapa Térmico'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Crítico', Colors.red, _heatmapData.where((d) => d['nivel'] == 'critico').length),
        _buildLegendItem('Moderado', Colors.orange, _heatmapData.where((d) => d['nivel'] == 'moderado').length),
        _buildLegendItem('Baixo', Colors.yellow, _heatmapData.where((d) => d['nivel'] == 'baixo').length),
        _buildLegendItem('Normal', Colors.green, _heatmapData.where((d) => d['intensidade'] < 0.2).length),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
        ),
        Text(
          '$count',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // ❌ DESABILITADO: Método de card antigo (mantido para referência futura)
  // Widget _buildMonitoringCard(Monitoring monitoring) {
  //   // Dados elegantes como no card de talhões
  //   final talhaoNome = (monitoring.plotName.isNotEmpty)
  //       ? monitoring.plotName
  //       : 'Talhão ${monitoring.plotId}';
  //   final areaAfetada = _estimativaAreaAfetada(monitoring);
  //   
  //   // ✅ CORRIGIDO: Passar occurrences para cálculo consistente!
  //   final allOccurrences = monitoring.points.expand((point) => point.occurrences).toList();
  //   final totalOccurrences = monitoring.points.fold<int>(0, (s, p) => s + p.occurrences.length);
  //   final nivelRisco = _calcularNivelRisco(totalOccurrences, occurrences: allOccurrences);

  //   return Card(
  //     margin: const EdgeInsets.only(bottom: 16),
  //     elevation: 4,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: InkWell(
  //       onTap: () => _showMonitoringDetails(monitoring),
  //       borderRadius: BorderRadius.circular(12),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Header
  //             Row(
  //               children: [
  //                 Icon(Icons.landscape, color: Colors.orange[700]),
  //                 const SizedBox(width: 8),
  //                 Expanded(
  //                   child: Text(
  //                     talhaoNome,
  //                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.orange[700],
  //                     ),
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: _getStatusColor(monitoring.status),
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: Text(
  //                     monitoring.status.toUpperCase(),
  //                     style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 8),

  //             // Info básica
  //             Row(
  //               children: [
  //                 Icon(Icons.agriculture, size: 16, color: Colors.grey[600]),
  //                 const SizedBox(width: 4),
  //                 Expanded(
  //                   child: Text(
  //                     '${monitoring.cropName.toUpperCase()} - Não informada',
  //                     style: TextStyle(fontSize: 14, color: Colors.grey[700]),
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //               ],
  //             ),

  //             const SizedBox(height: 8),

  //             // Estatísticas
  //             Row(
  //               children: [
  //                 _buildStatItem('Pontos', monitoring.points.length, Colors.blue),
  //                 const SizedBox(width: 16),
  //                 _buildStatTextItem('Área Afetada', '${areaAfetada.toStringAsFixed(1)}%', Colors.orange),
  //                 const SizedBox(height: 16),
  //                 _buildStatChipLike('Risco', nivelRisco, _getRiscoColor(nivelRisco)),
  //               ],
  //             ),

  //             if (monitoring.hasCriticalOccurrences)
  //               Container(
  //                 margin: const EdgeInsets.only(top: 8),
  //                 padding: const EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: Colors.red[50],
  //                   borderRadius: BorderRadius.circular(8),
  //                   border: Border.all(color: Colors.red[200]!),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.warning, color: Colors.red[700], size: 16),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       'Ocorrências críticas detectadas',
  //                       style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //             const SizedBox(height: 8),
  //             Align(
  //               alignment: Alignment.bottomRight,
  //               child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Color _getConfiancaColor(double confianca) {
    if (confianca >= 0.8) return Colors.green;
    if (confianca >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ativo':
        return Colors.blue.shade700;
      case 'Concluído':
        return Colors.green.shade700;
      case 'Pausado':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  /// 🌟 NOVA VERSÃO: Análise Detalhada com MonitoringCardData
  Future<void> _showNewAnaliseDetalhada(MonitoringCardData cardData) async {
    // Buscar imagens da sessão
    final db = await AppDatabase.instance.database;
    
    // ✅ DEBUG: Verificar se há ocorrências com fotos
    Logger.info('🔍 [IMAGES] Buscando imagens para sessão: ${cardData.sessionId}');
    final totalOcorrencias = sqflite.Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences WHERE session_id = ?', [cardData.sessionId])
    ) ?? 0;
    Logger.info('   Total de ocorrências: $totalOcorrencias');
    
    final imagensResult = await db.rawQuery('''
      SELECT foto_paths, organism_name, point_id
      FROM monitoring_occurrences 
      WHERE session_id = ? AND foto_paths IS NOT NULL AND foto_paths != '' AND foto_paths != '[]'
    ''', [cardData.sessionId]);
    
    Logger.info('   Ocorrências com foto_paths não vazio: ${imagensResult.length}');
    
    final List<String> imagensPaths = [];
    for (var i = 0; i < imagensResult.length; i++) {
      final row = imagensResult[i];
      final paths = row['foto_paths']?.toString();
      Logger.info('   Ocorrência $i (${row['organism_name']}): foto_paths="$paths"');
      
      if (paths != null && paths.isNotEmpty && paths != '[]') {
        try {
          final List<dynamic> pathsList = jsonDecode(paths);
          Logger.info('      → Decodificou ${pathsList.length} path(s)');
          for (var path in pathsList) {
            if (path != null && path.toString().isNotEmpty) {
              imagensPaths.add(path.toString());
              Logger.info('         ✓ Adicionado: $path');
            }
          }
        } catch (e) {
          Logger.warning('      ✗ Erro ao decodificar: $e');
        }
      }
    }
    
    Logger.info('📸 [NEW_ANALYSIS] TOTAL: ${imagensPaths.length} imagens encontradas para sessão ${cardData.sessionId}');
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                children: [
                    Icon(Icons.analytics, color: const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Sistema FortSmart Agro - Análise Profissional',
                        style: TextStyle(
                          fontSize: 16,
                        fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              ),
              
              const Divider(),

              // Conteúdo
                  Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                children: [
                    // 1. Sistema FortSmart
                    _buildNewAnaliseSection('Sistema FortSmart Agro', [
                      _buildInfoRow('Análise Inteligente', 'FortSmart v3.0 + PhenologicalInfestationService'),
                      _buildInfoRow('Confiança nos Dados', '${(cardData.confiancaDados * 100).toStringAsFixed(1)}%'),
                      _buildInfoRow('Data', cardData.dataInicio),
                      _buildInfoRow('Módulo', 'Análise Agronômica Avançada c/ JSONs'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // 2. Resumo do Monitoramento
                    _buildNewAnaliseSection('Resumo do Monitoramento', [
                      _buildInfoRow('Talhão', cardData.talhaoNome),
                      _buildInfoRow('Cultura', cardData.culturaNome),
                      _buildInfoRow('Total de Pontos GPS', '${cardData.totalPontos}'),
                      _buildInfoRow('Total de Ocorrências', '${cardData.totalOcorrencias}'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // 3. Galeria de Fotos
                    _buildNewImagensSection(imagensPaths),
                    
                    const SizedBox(height: 20),
                    
                    // 4. Análise Detalhada com Nível de Risco
                    _buildNewAnaliseSection('Análise Detalhada', [
                      // Nível de Risco Destacado
                Container(
                        padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                          color: _getRiskColor(cardData.nivelRisco).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getRiskColor(cardData.nivelRisco),
                            width: 2,
                          ),
                  ),
                  child: Row(
                    children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: _getRiskColor(cardData.nivelRisco),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nível de Risco',
                                    style: TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                      Text(
                                    cardData.nivelRisco,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: _getRiskColor(cardData.nivelRisco),
                                    ),
                      ),
                    ],
                  ),
                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('📊 Fonte de Dados', 'MonitoringCardDataService (Nova Fonte Única)'),
                      const Divider(height: 16),
                      _buildInfoRow('Total de Pragas', '${cardData.totalPragas} indivíduos'),
                      _buildInfoRow('Quantidade Média', cardData.quantidadeMedia.toStringAsFixed(2)),
                      _buildInfoRow('Severidade Média', '${cardData.severidadeMedia.toStringAsFixed(1)}%'),
                      const Divider(height: 16),
                      _buildInfoRow('Temperatura', '${cardData.temperatura.toStringAsFixed(1)}°C'),
                      _buildInfoRow('Umidade', '${cardData.umidade.toStringAsFixed(1)}%'),
                      const Divider(height: 16),
                      _buildInfoRow('Estágio Fenológico', cardData.estagioFenologico),
                      if (cardData.populacao != null)
                        _buildInfoRow('População', '${cardData.populacao!.toStringAsFixed(0)} plantas/ha'),
                      if (cardData.dae != null)
                        _buildInfoRow('DAE', '${cardData.dae} dias'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // 5. Organismos Detectados
                    _buildNewOrganismosSection(cardData.organismosDetectados),
                    
                    const SizedBox(height: 20),
                    
                    // 6. Recomendações
                    _buildNewRecomendacoesSection(cardData.recomendacoes),
                    
                    // 7. Alertas
                    if (cardData.alertas.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildNewAlertasSection(cardData.alertas),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✨ VERSÃO ANTIGA (DESABILITADA) - Mantida para referência
  void _showAnaliseDetalhada({String? sessionIdFilter, String? talhaoIdFilter}) async {
    if (_analiseInteligente == null) return;
    
    // ✅ CARREGAR ANÁLISE REAL POR SESSÃO/TALHÃO
    final analiseRealFiltrada = await _gerarAnaliseRealPorSessao(
      sessionIdFilter: sessionIdFilter,
      talhaoIdFilter: talhaoIdFilter,
    );
    
    Logger.info('📊 Análise Real Filtrada:');
    Logger.info('  - Nível de Risco: ${analiseRealFiltrada['nivelRisco']}');
    Logger.info('  - Total Pontos: ${analiseRealFiltrada['totalPontosMonitorados']}');
    Logger.info('  - Total Ocorrências: ${analiseRealFiltrada['totalOcorrencias']}');
    Logger.info('  - Organismos: ${(analiseRealFiltrada['organismosDetectados'] as List?)?.length ?? 0}');
    
    // ✅ IMPLEMENTADO: Carregar imagens e dados reais (com filtro opcional)
    final imagens = await _carregarImagensInfestacao(
      sessionIdFilter: sessionIdFilter,
      talhaoIdFilter: talhaoIdFilter,
    );
    final dadosCompletos = await _carregarDadosCompletos(
      sessionIdFilter: sessionIdFilter,
      talhaoIdFilter: talhaoIdFilter,
    );

    // ✅ Resumo calculado por filtro (sem reutilizar _analiseInteligente genérico)
    final db = await AppDatabase.instance.database;
    int totalMonitoramentos = 0;
    int totalPontos = 0;
    int totalOcorrencias = 0;
    
    if (sessionIdFilter != null && sessionIdFilter.isNotEmpty) {
      totalMonitoramentos = 1;
      totalPontos = sqflite.Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM monitoring_points WHERE session_id = ?', [sessionIdFilter])) ?? 0;
      totalOcorrencias = sqflite.Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM monitoring_occurrences WHERE session_id = ?', [sessionIdFilter])) ?? 0;
    } else if (talhaoIdFilter != null && talhaoIdFilter.isNotEmpty) {
      totalMonitoramentos = sqflite.Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(DISTINCT id) FROM monitoring_sessions WHERE talhao_id = ?', [talhaoIdFilter])) ?? 0;
      totalPontos = sqflite.Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM monitoring_points WHERE session_id IN (SELECT id FROM monitoring_sessions WHERE talhao_id = ?)', [talhaoIdFilter])) ?? 0;
      totalOcorrencias = sqflite.Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM monitoring_occurrences WHERE talhao_id = ?', [talhaoIdFilter])) ?? 0;
    } else {
      totalMonitoramentos = sqflite.Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM monitoring_sessions')) ?? 0;
      totalPontos = sqflite.Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM monitoring_points')) ?? 0;
      totalOcorrencias = sqflite.Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences')) ?? 0;
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sistema FortSmart Agro - Análise Profissional',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Conteúdo da análise APRIMORADO
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 1. Sistema FortSmart Agro
                    _buildAnaliseSection('Sistema FortSmart Agro', [
                      _buildInfoRow('Análise Inteligente', 'Sistema FortSmart Agro v3.0'),
                      _buildInfoRow('Confiança', '${(((_analiseInteligente!['scoreConfianca'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%'),
                      _buildInfoRow('Data', _formatDate(_analiseInteligente!['dataAnalise'] as String)),
                      _buildInfoRow('Módulo', 'Análise Agronômica Avançada'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // 2. Resumo do Monitoramento
                    _buildAnaliseSection('Resumo do Monitoramento', [
                      _buildInfoRow('Total de Monitoramentos', '$totalMonitoramentos'),
                      _buildInfoRow('Total de Pontos GPS', '$totalPontos'),
                      _buildInfoRow('Total de Ocorrências', '$totalOcorrencias'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // 3. 🖼️ IMAGENS DAS INFESTAÇÕES (SEMPRE VISÍVEL)
                    _buildImagensInfestacaoSection(imagens),
                    const SizedBox(height: 20),
                    
                    // 4. ✅ ANÁLISE DETALHADA (DADOS REAIS - EXPANDIDA)
                    _buildAnaliseSection('Análise Detalhada', [
                      // Nível de Risco (destaque)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getNivelRiscoColor(analiseRealFiltrada['nivelRisco']?.toString() ?? 'BAIXO').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getNivelRiscoColor(analiseRealFiltrada['nivelRisco']?.toString() ?? 'BAIXO'),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: _getNivelRiscoColor(analiseRealFiltrada['nivelRisco']?.toString() ?? 'BAIXO'),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nível de Risco',
                                    style: TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  Text(
                                    analiseRealFiltrada['nivelRisco']?.toString() ?? 'BAIXO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: _getNivelRiscoColor(analiseRealFiltrada['nivelRisco']?.toString() ?? 'BAIXO'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Fonte de Dados
                      _buildInfoRow('📊 Fonte de Dados', analiseRealFiltrada['fonte']?.toString() ?? 'N/A'),
                      const Divider(height: 16),
                      
                      // Total de Pontos
                      _buildInfoRow('📍 Total de Pontos', '${analiseRealFiltrada['totalPontosMonitorados'] ?? 0} pontos monitorados'),
                      
                      // Total de Ocorrências
                      _buildInfoRow('🐛 Total de Ocorrências', '${analiseRealFiltrada['totalOcorrencias'] ?? 0} registros'),
                      const Divider(height: 16),
                      
                      // Organismos Detectados (LISTA DE NOMES)
                      const SizedBox(height: 8),
                      const Text(
                        '🦠 Organismos Detectados:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      if ((analiseRealFiltrada['organismosDetectados'] as List?)?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final org in (analiseRealFiltrada['organismosDetectados'] as List))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.orange[300]!),
                                  ),
                                  child: Text(
                                    org.toString(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        const Text(
                          'Nenhum organismo detectado',
                          style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                        ),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // 4.1. 🐛 LISTA COMPLETA DE ORGANISMOS COM MÉTRICAS
                    if ((analiseRealFiltrada['organismosDetalhados'] as List?)?.isNotEmpty == true) ...[
                      _buildOrganismosDetalhadosSection(List<Map<String, dynamic>>.from(analiseRealFiltrada['organismosDetalhados'] as List)),
                      const SizedBox(height: 20),
                    ],
                    
                    // 5. 📊 NÍVEIS DE INFESTAÇÃO
                    // ✅ REMOVIDO: Card "Mapa de Infestação do Talhão" 
                    // O mapa está agora disponível em: Relatório Agronômico → Aba "Infestação Fenológica"
                    // Use o botão "Ver Mapa" para acessar o mapa completo
                    
                    const SizedBox(height: 20),
                    
                    // 6. 🌱 DADOS AGRONÔMICOS COMPLETOS (FENOLOGIA, ESTANDE, CV%, POPULAÇÃO)
                    if (dadosCompletos.isNotEmpty) ...[
                      _buildDadosAgronomicosCompletosSection(dadosCompletos),
                      const SizedBox(height: 20),
                    ],
                    // 6.1 📘 RESUMO DE PLANTIO (FENOLOGIA + ESTANDE)
                    if (dadosCompletos.isNotEmpty) ...[
                      _buildResumoPlantioSection(dadosCompletos),
                      const SizedBox(height: 20),
                    ],
                    
                    // 7. 🌤️ CONDIÇÕES AMBIENTAIS (TEMPERATURA, UMIDADE, CLIMA)
                    if (dadosCompletos['clima'] != null) ...[
                      _buildCondicoesAmbientaisCompletasSection(dadosCompletos['clima'] as Map<String, dynamic>),
                      const SizedBox(height: 20),
                    ] else if (_analiseInteligente!['condicoesFavoraveis'] != null) ...[
                      _buildCondicoesAmbientaisCompletasSection(_analiseInteligente!['condicoesFavoraveis'] as Map<String, dynamic>),
                      const SizedBox(height: 20),
                    ],
                    
                    // 8. 🧪 MANEJOS RECENTES
                    if ((dadosCompletos['manejos'] as List<dynamic>?)?.isNotEmpty == true) ...[
                      _buildManejosRecentesSection(List<Map<String, dynamic>>.from(dadosCompletos['manejos'] as List)),
                      const SizedBox(height: 20),
                    ],
                    
                    // 9. Recomendações (DADOS REAIS)
                    _buildAnaliseSection('Recomendações Agronômicas', [
                      for (final rec in (analiseRealFiltrada['recomendacoes'] as List<dynamic>?) ?? [])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(child: Text(rec.toString())),
                            ],
                          ),
                        ),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // 9.1. Alertas (DADOS REAIS)
                    if ((analiseRealFiltrada['alertas'] as List?)?.isNotEmpty == true)
                      _buildAnaliseSection('Alertas do Sistema', [
                        for (final alert in (analiseRealFiltrada['alertas'] as List<dynamic>))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(child: Text(alert.toString())),
                              ],
                            ),
                          ),
                      ]),
                    
                    const SizedBox(height: 20),
                    
                    // 10. 📄 DADOS JSON COMPLETOS DA IA FORTSMART (Expandível)
                    _buildDadosJSONExpandivelCompleto(dadosCompletos, _analiseInteligente!),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnaliseSection(String title, List<Widget> content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Divider(),
          ...content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showHeatmapDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.thermostat, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Heatmap de Monitoramento - Detalhado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Conteúdo do heatmap
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeatmapSection('Pontos de Monitoramento', _heatmapData),
                    const SizedBox(height: 20),
                    _buildHeatmapSection('Análise Térmica', _gerarAnaliseTermica()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapSection(String title, List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const Divider(),
          ...data.map((item) => _buildHeatmapItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildHeatmapItem(Map<String, dynamic> item) {
    // ✅ CORREÇÃO: Cor padrão se for null
    final cor = item['cor'] as Color? ?? Colors.grey;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: cor, // ✅ CORRIGIDO
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['organismo']} - ${(((item['intensidade'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item['cultura'] ?? 'N/A'} • ${item['fonte'] ?? 'N/A'}',  // ✅ NULL SAFETY
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${item['latitude'] ?? 0.0}, ${item['longitude'] ?? 0.0}',  // ✅ NULL SAFETY
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item['temperatura'] ?? 0.0}°C',  // ✅ NULL SAFETY
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item['nivel'] ?? 'N/A',  // ✅ NULL SAFETY
                style: TextStyle(
                  fontSize: 10,
                  color: cor, // ✅ CORRIGIDO - usa a variável já com null safety
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _gerarAnaliseTermica() {
    return [
      {
        'organismo': 'Temperatura Média',
        'intensidade': _heatmapData.fold<double>(0.0, (sum, d) => sum + ((d['temperatura'] as num?)?.toDouble() ?? 0.0)) / _heatmapData.length,
        'cor': Colors.blue,
        'temperatura': _heatmapData.fold<double>(0.0, (sum, d) => sum + ((d['temperatura'] as num?)?.toDouble() ?? 0.0)) / _heatmapData.length,
      },
      {
        'organismo': 'Intensidade Média',
        'intensidade': _heatmapData.fold<double>(0.0, (sum, d) => sum + ((d['intensidade'] as num?)?.toDouble() ?? 0.0)) / _heatmapData.length,
        'cor': Colors.orange,
        'temperatura': 0.0,
      },
    ];
  }

  void _showMonitoringDetails(Monitoring monitoring) async {
    // ✅ CORRIGIDO: Buscar session_id REAL do banco
    try {
      final db = await AppDatabase.instance.database;
      
      Logger.info('🟢 [CARD TALHÃO] ===== CLICOU NO CARD DO TALHÃO =====');
      Logger.info('   📋 Talhão Nome: ${monitoring.plotName}');
      Logger.info('   📋 Talhão ID: ${monitoring.plotId}');
      Logger.info('   📋 Cultura: ${monitoring.cropName}');
      Logger.info('   📋 Monitoring.id (modelo): ${monitoring.id}');
      Logger.info('   📋 Total pontos no modelo: ${monitoring.points.length}');
      Logger.info('   📋 Total ocorrências no modelo: ${monitoring.points.fold(0, (s, p) => s + p.occurrences.length)}');
      
      // ✅ BUSCAR SESSÃO ESPECÍFICA (TALHÃO + CULTURA) - IGUAL AO BOTÃO AZUL
      final sessionData = await db.rawQuery('''
        SELECT id, started_at, cultura_nome, status, talhao_id FROM monitoring_sessions 
        WHERE talhao_id = ? 
          AND cultura_nome = ?
        ORDER BY started_at DESC
        LIMIT 1
      ''', [monitoring.plotId.toString(), monitoring.cropName]);
      
      Logger.info('   🔍 Sessão específica (Talhão + Cultura):');
      if (sessionData.isNotEmpty) {
        final sess = sessionData.first;
        Logger.info('      ✅ ID: ${sess['id']}');
        Logger.info('      ✅ Cultura: ${sess['cultura_nome']}');
        Logger.info('      ✅ Status: ${sess['status']}');
        Logger.info('      ✅ Data: ${sess['started_at']}');
      } else {
        Logger.warning('      ❌ NENHUMA SESSÃO ENCONTRADA para Talhão=${monitoring.plotId} + Cultura=${monitoring.cropName}');
        
        // Tentar buscar sem filtro de cultura
        final fallbackData = await db.rawQuery('''
          SELECT id FROM monitoring_sessions 
          WHERE talhao_id = ? 
          ORDER BY started_at DESC
          LIMIT 1
        ''', [monitoring.plotId.toString()]);
        
        if (fallbackData.isNotEmpty) {
          Logger.warning('      ⚠️ FALLBACK: Usando última sessão do talhão (ignorando cultura)');
          sessionData.addAll(fallbackData);
        }
      }
      
      final sessionId = sessionData.isNotEmpty 
          ? sessionData.first['id']?.toString() 
          : null;
      
      Logger.info('   ✅ Session ID selecionado (mais recente): $sessionId');
      Logger.info('🟢 [CARD TALHÃO] =====================================');
      
      // ✅ Usar session_id REAL do banco
    _showAnaliseDetalhada(
        sessionIdFilter: sessionId,
        talhaoIdFilter: monitoring.plotId.toString(),
      );
    } catch (e) {
      Logger.error('❌ Erro ao buscar session_id: $e');
      // Fallback: usar apenas talhaoId
      _showAnaliseDetalhada(
        sessionIdFilter: null,
      talhaoIdFilter: monitoring.plotId.toString(),
    );
    }
  }

  /// Converte dados de monitoramento para formato do card de talhão
  List<TalhaoCardData> _convertMonitoringsToTalhaoCards(List<Monitoring> monitorings) {
    return monitorings.map((monitoring) {
      // Calcular área afetada baseada nas ocorrências
      final totalOccurrences = monitoring.points.fold<int>(0, (sum, point) => sum + point.occurrences.length);
      final areaAfetada = totalOccurrences > 0 ? (totalOccurrences / monitoring.points.length) * 10 : 0.0;
      
      // ✅ CORRIGIDO: Coletar todas as occurrences para cálculo de risco
      final allOccurrences = monitoring.points.expand((point) => point.occurrences).toList();
      
      // Determinar nível de risco usando severidade agronômica
      final nivelRisco = _calcularNivelRisco(totalOccurrences, occurrences: allOccurrences);
      
      // Determinar se é crítico
      final isCritico = monitoring.hasCriticalOccurrences;
      
      return TalhaoCardData(
        talhaoNome: 'Talhão ${monitoring.plotId}',
        cultura: monitoring.cropName,
        variedade: 'Não informada',
        pontos: monitoring.points.length,
        areaAfetada: areaAfetada,
        nivelRisco: nivelRisco,
        prescricoes: 0, // TODO: Implementar contagem de prescrições
        dataAtualizacao: monitoring.date,
        status: monitoring.status,
        isCritico: isCritico,
        talhaoId: monitoring.plotId.toString(),
        culturaId: monitoring.cropId.toString(),
      );
    }).toList();
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
  
  /// 🔍 PREVIEW DE IMAGEM EM TELA CHEIA
  void _mostrarPreviewImagem(Map<String, dynamic> imagem) {
    final path = imagem['path'] as String;
    final organismo = imagem['organismo'] as String? ?? 'Desconhecido';
    final data = imagem['data'] as String? ?? '';
    final nivel = imagem['nivel'] as String? ?? 'baixo';
    final percentual = (imagem['percentual'] as num?)?.toDouble() ?? 0.0;
    final lat = (imagem['latitude'] as num?)?.toDouble();
    final lng = (imagem['longitude'] as num?)?.toDouble();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Imagem em tela cheia com zoom
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Card de informações sobreposto
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      organismo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nível: ${nivel.toUpperCase()} • ${percentual.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (data.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Data: ${_formatDate(data)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (lat != null && lng != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Botão fechar
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📸 CARREGAR IMAGENS DAS INFESTAÇÕES DO BANCO DE DADOS
  Future<List<Map<String, dynamic>>> _carregarImagensInfestacao({
    String? sessionIdFilter,
    String? talhaoIdFilter,
  }) async {
    try {
      Logger.info('📸 Carregando imagens das infestações...');
      
      final db = await AppDatabase.instance.database;
      
      // ✅ DIAGNÓSTICO COMPLETO: Verificar estrutura da tabela
      final tableInfo = await db.rawQuery("PRAGMA table_info(monitoring_occurrences)");
      Logger.info('📋 Colunas da tabela monitoring_occurrences:');
      for (final col in tableInfo) {
        Logger.info('   - ${col['name']}: ${col['type']}');
      }
      
      // ✅ DIAGNÓSTICO: Buscar TODAS ocorrências primeiro
      final allOccs = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_occurrences');
      final totalOccs = allOccs.first['total'] as int? ?? 0;
      Logger.info('📊 Total de ocorrências no banco: $totalOccs');
      
      // ✅ BUSCAR IMAGENS DE TODAS AS FONTES POSSÍVEIS
      String whereClause = '';
      List<Object?> whereArgs = [];
      if (sessionIdFilter != null && sessionIdFilter.isNotEmpty) {
        whereClause = 'WHERE mo.session_id = ?';
        whereArgs = [sessionIdFilter];
      } else if (talhaoIdFilter != null && talhaoIdFilter.isNotEmpty) {
        whereClause = 'WHERE mo.talhao_id = ?';
        whereArgs = [talhaoIdFilter];
      }

      final occurrences = await db.rawQuery('''
        SELECT 
          mo.id,
          mo.subtipo as organismo,
          mo.foto_paths,
          mo.data_hora,
          mo.latitude,
          mo.longitude,
          mo.nivel,
          mo.percentual
        FROM monitoring_occurrences mo
        LEFT JOIN monitoring_sessions ms ON ms.id = mo.session_id
        $whereClause
        ORDER BY mo.data_hora DESC
        LIMIT 100
      ''', whereArgs);
      
      Logger.info('📸 Total de ocorrências encontradas: ${occurrences.length}');
      
      final imagens = <Map<String, dynamic>>[];
      
      for (final occ in occurrences) {
        try {
          // ✅ Apenas foto_paths existe na tabela monitoring_occurrences
          final String? fotoPaths = occ['foto_paths'] as String?;
          
          Logger.info('🔍 Ocorrência ${occ['id']}: foto_paths = $fotoPaths');
          
          if (fotoPaths != null && fotoPaths.isNotEmpty && fotoPaths != '[]') {
            List<String> paths = [];
            
            // Tentar parse como JSON primeiro
            try {
              final decoded = json.decode(fotoPaths);
              if (decoded is List) {
                paths = decoded.map((e) => e.toString()).toList();
              }
            } catch (e) {
              // Se falhar, tentar parse manual
              paths = fotoPaths
                  .replaceAll('[', '')
                  .replaceAll(']', '')
                  .replaceAll('"', '')
                  .replaceAll("'", '')
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
            
            Logger.info('   Paths extraídos: ${paths.length} itens');
            
            for (final path in paths) {
              if (path.isNotEmpty) {
                final fileExists = File(path).existsSync();
                Logger.info('   📁 Verificando: $path - Existe? $fileExists');
                
                if (fileExists) {
                  imagens.add({
                    'path': path,
                    'organismo': occ['organismo'] ?? 'Desconhecido',
                    'data': occ['data_hora'] ?? '',
                    'nivel': occ['nivel'] ?? 'baixo',
                    'percentual': (occ['percentual'] as num?)?.toDouble() ?? 0.0,
                    'latitude': (occ['latitude'] as num?)?.toDouble() ?? 0.0,
                    'longitude': (occ['longitude'] as num?)?.toDouble() ?? 0.0,
                  });
                  Logger.info('   ✅ Imagem adicionada: ${occ['organismo']}');
                }
              }
            }
          }
        } catch (e) {
          Logger.error('❌ Erro ao processar fotos da ocorrência ${occ['id']}: $e');
        }
      }
      
      Logger.info('✅ RESULTADO FINAL: ${imagens.length} imagens válidas carregadas de ${occurrences.length} ocorrências');
      
      if (imagens.isEmpty) {
        Logger.warning('⚠️ NENHUMA IMAGEM ENCONTRADA! Verifique se as fotos estão sendo salvas corretamente.');
        // ❌ REMOVIDO: Busca de image_paths em monitoring_sessions (coluna não existe)
        // ✅ Imagens são buscadas APENAS de monitoring_occurrences.foto_paths
      }
      
      return imagens;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar imagens: $e');
      Logger.error('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// 📊 CARREGAR DADOS COMPLETOS (FENOLOGIA, CV%, ESTANDE, MANEJOS, ETC)
  Future<Map<String, dynamic>> _carregarDadosCompletos({
    String? sessionIdFilter,
    String? talhaoIdFilter,
  }) async {
    try {
      Logger.info('📊 Carregando dados completos...');
      
      final db = await AppDatabase.instance.database;
      
      // Buscar dados fenológicos recentes
      final phenoData = await db.rawQuery('''
        SELECT estagio_fenologico, altura_cm, data_registro
        FROM phenological_records
        ORDER BY data_registro DESC
        LIMIT 1
      ''');
      
      // Buscar dados de estande
      final standeData = await db.rawQuery('''
        SELECT populacao_real_por_hectare, eficiencia_percentual, data_avaliacao
        FROM estande_plantas
        ORDER BY data_avaliacao DESC
        LIMIT 1
      ''');
      
      // Buscar dados de CV%
      final cvData = await db.rawQuery('''
        SELECT coeficiente_variacao, classificacao_texto, data_avaliacao
        FROM plantios_cv
        ORDER BY data_avaliacao DESC
        LIMIT 1
      ''');
      
      // ✅ BUSCAR TEMPERATURA E UMIDADE REAIS DO MONITORAMENTO (com filtro opcional)
      // Primeiro, garantir que as colunas existem na tabela monitoring_sessions
      try {
        await db.execute('ALTER TABLE monitoring_sessions ADD COLUMN temperatura REAL');
        Logger.info('✅ Coluna temperatura adicionada a monitoring_sessions');
      } catch (e) {
        // Coluna já existe, continuar
      }
      try {
        await db.execute('ALTER TABLE monitoring_sessions ADD COLUMN umidade REAL');
        Logger.info('✅ Coluna umidade adicionada a monitoring_sessions');
      } catch (e) {
        // Coluna já existe, continuar
      }
      
      String whereClauseClima = '1=1';
      List<dynamic> whereArgsClima = [];
      if (sessionIdFilter != null && sessionIdFilter.isNotEmpty) {
        whereClauseClima += ' AND id = ?';
        whereArgsClima.add(sessionIdFilter);
      } else if (talhaoIdFilter != null && talhaoIdFilter.isNotEmpty) {
        whereClauseClima += ' AND talhao_id = ?';
        whereArgsClima.add(talhaoIdFilter);
      }
      
      // ✅ BUSCAR TEMPERATURA/UMIDADE DAS OCORRÊNCIAS (NÃO DA SESSÃO!)
      Logger.info('🌡️ [CLIMA] Buscando dados climáticos DAS OCORRÊNCIAS...');
      Logger.info('   Filtros: sessionId=$sessionIdFilter, talhaoId=$talhaoIdFilter');
      
      // Buscar diretamente de monitoring_sessions.temperatura (salvo pelo DirectOccurrenceService)
      var climaData = await db.rawQuery('''
        SELECT temperatura, umidade, started_at as data_inicio
        FROM monitoring_sessions
        WHERE $whereClauseClima
        AND temperatura IS NOT NULL 
        AND umidade IS NOT NULL
        AND temperatura > 0
        AND umidade > 0
        ORDER BY started_at DESC
        LIMIT 1
      ''', whereArgsClima);
      
      Logger.info('🌡️ [CLIMA] Resultado: ${climaData.length} registros');
      
      if (climaData.isEmpty) {
        Logger.warning('   ⚠️ Nenhum dado climático em monitoring_sessions');
        Logger.info('   🔍 Tentando buscar SEM filtro (última sessão)...');
        
          climaData = await db.rawQuery('''
          SELECT temperatura, umidade, started_at as data_inicio
          FROM monitoring_sessions
          WHERE temperatura IS NOT NULL 
          AND umidade IS NOT NULL
          AND temperatura > 0
          AND umidade > 0
          ORDER BY started_at DESC
            LIMIT 1
          ''');
        
          if (climaData.isNotEmpty) {
          Logger.warning('   ⚠️ Usando última sessão com clima (SEM filtro)');
        }
      }
      
      if (climaData.isNotEmpty) {
        Logger.info('   ✅ Temperatura: ${climaData.first['temperatura']}°C');
        Logger.info('   ✅ Umidade: ${climaData.first['umidade']}%');
      } else {
        Logger.error('   ❌ NENHUM dado climático encontrado em monitoring_sessions!');
      }
      
      final dadosCompletos = <String, dynamic>{};
      
      // ✅ BUSCAR CULTURA DA SESSÃO DE MONITORAMENTO (PRIORIDADE)
      String? culturaNome;
      if (sessionIdFilter != null && sessionIdFilter.isNotEmpty) {
        final sessaoData = await db.rawQuery('''
          SELECT cultura_nome FROM monitoring_sessions WHERE id = ? LIMIT 1
        ''', [sessionIdFilter]);
        if (sessaoData.isNotEmpty) {
          culturaNome = sessaoData.first['cultura_nome'] as String?;
          Logger.info('🌾 Cultura da sessão: $culturaNome');
        }
      } else if (talhaoIdFilter != null && talhaoIdFilter.isNotEmpty) {
        // Buscar cultura do último monitoramento do talhão
        final sessaoData = await db.rawQuery('''
          SELECT cultura_nome FROM monitoring_sessions 
          WHERE talhao_id = ? 
          ORDER BY started_at DESC 
          LIMIT 1
        ''', [talhaoIdFilter]);
        if (sessaoData.isNotEmpty) {
          culturaNome = sessaoData.first['cultura_nome'] as String?;
          Logger.info('🌾 Cultura do talhão (último monitoramento): $culturaNome');
        }
      }
      
      // ✅ ADICIONAR CULTURA AOS DADOS COMPLETOS
      if (culturaNome != null && culturaNome.isNotEmpty) {
        dadosCompletos['cultura'] = culturaNome;
        Logger.info('✅ Cultura adicionada aos dados completos: $culturaNome');
      } else {
        Logger.warning('⚠️ Cultura não encontrada, usando fallback');
      }
      
      if (phenoData.isNotEmpty) {
        dadosCompletos['fenologia'] = {
          'estagio': phenoData.first['estagio_fenologico'] ?? 'N/A',
          'altura': (phenoData.first['altura_cm'] as num?)?.toDouble() ?? 0.0,
          'data': phenoData.first['data_registro'] ?? '',
        };
      }
      
      if (standeData.isNotEmpty) {
        dadosCompletos['estande'] = {
          'populacao': (standeData.first['populacao_real_por_hectare'] as num?)?.toDouble() ?? 0.0,
          'eficiencia': (standeData.first['eficiencia_percentual'] as num?)?.toDouble() ?? 0.0,
          'data': standeData.first['data_avaliacao'] ?? '',
        };
      }
      
      if (cvData.isNotEmpty) {
        dadosCompletos['cv'] = {
          'valor': (cvData.first['coeficiente_variacao'] as num?)?.toDouble() ?? 0.0,
          'classificacao': cvData.first['classificacao_texto'] ?? 'N/A',
          'data': cvData.first['data_avaliacao'] ?? '',
        };
      }
      
      // ✅ ADICIONAR DADOS CLIMÁTICOS REAIS
      if (climaData.isNotEmpty) {
        final temp = (climaData.first['temperatura'] as num?)?.toDouble();
        final umid = (climaData.first['umidade'] as num?)?.toDouble();
        
        Logger.info('🌡️ [CLIMA] Processando dados:');
        Logger.info('   temp = $temp');
        Logger.info('   umid = $umid');
        
        if (temp != null && umid != null && temp > 0 && umid > 0) {
          dadosCompletos['clima'] = {
            'temperatura': temp,
            'umidade': umid,
            'data': climaData.first['data_inicio'] ?? '',
            'descricao': _gerarDescricaoClimatica(temp, umid),
          };
          Logger.info('✅ [CLIMA] Dados climáticos REAIS carregados: Temp=${temp}°C, Umid=${umid}%');
        } else {
          Logger.error('❌ [CLIMA] Dados climáticos inválidos ou zerados!');
        }
      } else {
        Logger.error('❌ [CLIMA] Nenhum dado climático disponível - usando placeholder');
        // NÃO adicionar dados fictícios - deixar vazio
      }

      // ✅ ADICIONAR ÚLTIMOS MANEJOS (Prescrições/Aplicações)
      final manejos = <Map<String, dynamic>>[];

      // 1) Prescrições (tabela moderna)
      try {
        final rows = await db.rawQuery('''
          SELECT data AS data, tipo_aplicacao AS tipo, produtos AS detalhes, status
          FROM prescricoes
          ${talhaoIdFilter != null && talhaoIdFilter.isNotEmpty ? 'WHERE talhao_id = ?' : ''}
          ORDER BY data DESC
          LIMIT 5
        ''', talhaoIdFilter != null && talhaoIdFilter.isNotEmpty ? [talhaoIdFilter] : []);
        for (final r in rows) {
          manejos.add({
            'fonte': 'prescricoes',
            'data': r['data'],
            'tipo': r['tipo'],
            'status': r['status'],
            'detalhes': r['detalhes'],
          });
        }
      } catch (_) {}

      // 2) Prescriptions (tabela legado/alternativa)
      try {
        final rows = await db.rawQuery('''
          SELECT prescriptionDate AS data, prescriptionType AS tipo, status, notes AS detalhes
          FROM prescriptions
          ${talhaoIdFilter != null && talhaoIdFilter.isNotEmpty ? 'WHERE plotId = ?' : ''}
          ORDER BY prescriptionDate DESC
          LIMIT 5
        ''', talhaoIdFilter != null && talhaoIdFilter.isNotEmpty ? [talhaoIdFilter] : []);
        for (final r in rows) {
          manejos.add({
            'fonte': 'prescriptions',
            'data': r['data'],
            'tipo': r['tipo'],
            'status': r['status'],
            'detalhes': r['detalhes'],
          });
        }
      } catch (_) {}

      // 3) Aplicações de defensivos (quando já executado)
      try {
        final rows = await db.rawQuery('''
          SELECT application_date AS data, product_name AS produto, application_method AS metodo, dose AS dose, dose_unit AS unidade
          FROM pesticide_applications
          ${talhaoIdFilter != null && talhaoIdFilter.isNotEmpty ? 'WHERE plot_id = ?' : ''}
          ORDER BY application_date DESC
          LIMIT 5
        ''', talhaoIdFilter != null && talhaoIdFilter.isNotEmpty ? [talhaoIdFilter] : []);
        for (final r in rows) {
          final dose = (r['dose']?.toString() ?? '');
          final unidade = (r['unidade']?.toString() ?? '');
          manejos.add({
            'fonte': 'aplicacoes',
            'data': r['data'],
            'tipo': 'Aplicação',
            'status': 'Executado',
            'detalhes': '${r['produto'] ?? ''} • ${r['metodo'] ?? ''}${dose.isNotEmpty ? ' • $dose $unidade' : ''}',
          });
        }
      } catch (_) {}

      if (manejos.isNotEmpty) {
        dadosCompletos['manejos'] = manejos;
      }
      
      Logger.info('✅ Dados completos carregados: ${dadosCompletos.keys.join(", ")}');
      return dadosCompletos;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados completos: $e');
      return {};
    }
  }
  
  /// Gera descrição climática baseada em temperatura e umidade
  String _gerarDescricaoClimatica(double temp, double umid) {
    if (temp > 30 && umid > 70) {
      return 'Condições muito favoráveis para desenvolvimento de infestações';
    } else if (temp > 25 && umid > 60) {
      return 'Condições favoráveis para desenvolvimento de infestações';
    } else if (temp < 15 || umid < 40) {
      return 'Condições pouco favoráveis para desenvolvimento de infestações';
    } else {
      return 'Condições moderadas para desenvolvimento de infestações';
    }
  }

  /// 🧱 WIDGET: RESUMO DE PLANTIO (Fenologia + Estande)
  Widget _buildResumoPlantioSection(Map<String, dynamic> dados) {
    final fen = dados['fenologia'] as Map<String, dynamic>?;
    final est = dados['estande'] as Map<String, dynamic>?;
    if (fen == null && est == null) return const SizedBox.shrink();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📘 Resumo de Plantio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (fen != null) ...[
              _buildInfoRow('Estágio Fenológico', fen['estagio']?.toString() ?? 'N/A'),
              _buildInfoRow('Altura Média', fen['altura'] != null ? '${(fen['altura'] as num).toStringAsFixed(1)} cm' : 'N/A'),
              if (fen['data'] != null) _buildInfoRow('Data', _formatDate(fen['data'].toString())),
              const SizedBox(height: 8),
            ],
            if (est != null) ...[
              _buildInfoRow('População', est['populacao'] != null ? '${(est['populacao'] as num).toStringAsFixed(0)} plantas/ha' : 'N/A'),
              _buildInfoRow('Eficiência de Emergência', est['eficiencia'] != null ? '${(est['eficiencia'] as num).toStringAsFixed(1)}%' : 'N/A'),
              if (est['data'] != null) _buildInfoRow('Avaliado em', _formatDate(est['data'].toString())),
            ],
          ],
        ),
      ),
    );
  }

  /// 🐛 WIDGET: LISTA COMPLETA DE ORGANISMOS COM MÉTRICAS
  Widget _buildOrganismosDetalhadosSection(List<Map<String, dynamic>> organismos) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🐛 Organismos Detectados - Análise Detalhada', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            for (final org in organismos) ...[
              _buildOrganismoCard(org),
              if (org != organismos.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Card individual de organismo com métricas
  Widget _buildOrganismoCard(Map<String, dynamic> org) {
    final nivel = org['nivel']?.toString() ?? 'BAIXO';
    final corNivel = _getCorPorNivel(nivel);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: corNivel.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: corNivel, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: Nome + Nível
          Row(
            children: [
              Expanded(
                child: Text(
                  org['nome']?.toString() ?? 'Organismo',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: corNivel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  nivel,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Métricas em Grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetricaChip('Pontos', '${org['pontos_com_infestacao']}/${org['total_pontos_monitorados']}', Icons.location_on, Colors.blue),
              _buildMetricaChip('Frequência', '${(org['frequencia_percentual'] as num?)?.toStringAsFixed(1) ?? '0'}%', Icons.show_chart, Colors.purple),
              _buildMetricaChip('Qtd Média', '${(org['quantidade_media'] as num?)?.toStringAsFixed(2) ?? '0'}', Icons.analytics, Colors.orange),
              _buildMetricaChip('Índice', '${(org['indice'] as num?)?.toStringAsFixed(2) ?? '0'}', Icons.speed, Colors.teal),
              _buildMetricaChip('Severidade', '${(org['severidade_media'] as num?)?.toStringAsFixed(1) ?? '0'}', Icons.warning_amber, Colors.red),
              _buildMetricaChip('Máx', '${(org['quantidade_maxima'] as num?)?.toStringAsFixed(1) ?? '0'}', Icons.trending_up, Colors.deepOrange),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Chip de métrica individual
  Widget _buildMetricaChip(String label, String valor, IconData icon, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cor),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        Text(valor, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
      ],
    );
  }
  
  /// Retorna cor baseada no nível
  Color _getCorPorNivel(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'CRÍTICO':
        return Colors.red;
      case 'ALTO':
        return Colors.orange;
      case 'MÉDIO':
        return Colors.yellow[700]!;
      case 'BAIXO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 🧪 WIDGET: MANEJOS RECENTES (Prescrições/Aplicações)
  Widget _buildManejosRecentesSection(List<Map<String, dynamic>> manejos) {
    if (manejos.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧪 Últimos Manejos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final m in manejos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m['tipo'] ?? 'Manejo'} • ${m['status'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          if (m['data'] != null) Text(_formatDate(m['data'].toString()), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          if (m['detalhes'] != null) Text(m['detalhes'].toString(), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 🖼️ WIDGET: GALERIA DE IMAGENS DAS INFESTAÇÕES (SEMPRE VISÍVEL)
  Widget _buildImagensInfestacaoSection(List<Map<String, dynamic>> imagens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📸 Galeria de Fotos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: imagens.isNotEmpty ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${imagens.length} fotos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // ✅ GALERIA ou MENSAGEM
        imagens.isEmpty 
          ? Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.grey.shade400, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma foto registrada',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capture fotos durante o monitoramento',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : SizedBox(
              height: 120,
              child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imagens.length,
            itemBuilder: (context, index) {
              final img = imagens[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _mostrarPreviewImagem(img),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(img['path'] as String),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                ),
                              ),
                              child: Text(
                                img['organismo'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🗺️ MAPA DE INFESTAÇÃO INTERATIVO DO TALHÃO
  /// ✅ REMOVIDO: Mapa agora está disponível na aba "Infestação" do Relatório Agronômico
  Widget _buildNiveisInfestacaoCompletosSection(List<dynamic> sintomas) {
    // ✅ Retorna widget vazio - mapa removido da análise detalhada
    // O mapa está agora em: Relatório Agronômico → Aba "Infestação Fenológica"
    return const SizedBox.shrink();
  }

  /// 🗺️ MAPA INTERATIVO COM HEATMAP
  Widget _buildMapaInterativo() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _carregarDadosHeatmapReais(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Erro ao carregar mapa',
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        final heatmapData = snapshot.data ?? [];
        
        // ✅ SEMPRE MOSTRAR O MAPA (mesmo sem pontos)
        return _buildMapaComHeatmap(heatmapData);
      },
    );
  }

  /// 🗺️ MAPA REAL COM MAPTILER E POLÍGONO DO TALHÃO
  Widget _buildMapaComHeatmap(List<Map<String, dynamic>> heatmapData) {
    return FutureBuilder<List<LatLng>?>(
      future: _carregarPoligonoTalhao(),
      builder: (context, poligonoSnapshot) {
        // ✅ USAR APENAS DADOS REAIS (sem exemplos)
        LatLng? center;
        double zoom = 15.0;
        
        if (poligonoSnapshot.hasData && 
            poligonoSnapshot.data != null && 
            poligonoSnapshot.data!.isNotEmpty) {
          // ✅ Centro baseado no POLÍGONO REAL do talhão
          final pontos = poligonoSnapshot.data!;
          double sumLat = 0, sumLng = 0;
          for (final ponto in pontos) {
            sumLat += ponto.latitude;
            sumLng += ponto.longitude;
          }
          center = LatLng(sumLat / pontos.length, sumLng / pontos.length);
          zoom = 16.0;
          
          Logger.info('🗺️ Centro do mapa: $center (POLÍGONO com ${pontos.length} vértices)');
        } else if (heatmapData.isNotEmpty) {
          // ✅ Centro baseado nos PONTOS DE MONITORAMENTO REAIS
          double sumLat = 0, sumLng = 0;
          for (final ponto in heatmapData) {
            sumLat += (ponto['latitude'] as num?)?.toDouble() ?? 0.0;
            sumLng += (ponto['longitude'] as num?)?.toDouble() ?? 0.0;
          }
          center = LatLng(sumLat / heatmapData.length, sumLng / heatmapData.length);
          zoom = 17.0;
          
          Logger.info('🗺️ Centro do mapa: $center (${heatmapData.length} PONTOS REAIS)');
        }
        
        // ❌ Se não houver dados reais, mostrar mensagem
        if (center == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gps_off, color: Colors.orange, size: 48),
                SizedBox(height: 8),
                Text(
                  'Nenhum dado georreferenciado encontrado',
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Realize monitoramentos com GPS para visualizar o mapa',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              // 1️⃣ CAMADA BASE - MAPTILER SATÉLITE
              TileLayer(
                urlTemplate: APIConfig.getMapTilerUrl('satellite'),
                userAgentPackageName: 'com.fortsmart.agro',
                fallbackUrl: APIConfig.getFallbackUrl(),
              ),
              
              // 2️⃣ CAMADA DE POLÍGONO DO TALHÃO (SEMPRE VISÍVEL)
              if (poligonoSnapshot.hasData && 
                  poligonoSnapshot.data != null && 
                  poligonoSnapshot.data!.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: poligonoSnapshot.data!,
                      color: Colors.green.withOpacity(0.15),
                      borderColor: Colors.green,
                      borderStrokeWidth: 3.0,
                      isFilled: true,
                    ),
                  ],
                ),
              
              // 3️⃣ CAMADA TÉRMICA (HEATMAP) - Círculos de calor
              CircleLayer(
                circles: heatmapData.map((ponto) {
                  final lat = (ponto['latitude'] as num?)?.toDouble() ?? 0.0;
                  final lng = (ponto['longitude'] as num?)?.toDouble() ?? 0.0;
                  final cor = ponto['cor'] as Color? ?? Colors.grey;
                  final intensidade = (ponto['intensidade'] as num?)?.toDouble() ?? 0.0;
                  
                  // ✅ TAMANHO FIXO EM METROS (25-35m, não muda com zoom)
                  final raioMetros = 25.0 + (intensidade * 10.0); // Reduzido para melhor visualização
                  
                  return CircleMarker(
                    point: LatLng(lat, lng),
                    color: cor.withOpacity(0.2),
                    borderColor: cor.withOpacity(0.4),
                    borderStrokeWidth: 1.0,
                    radius: raioMetros,
                    useRadiusInMeter: true, // Tamanho fixo no mundo real
                  );
                }).toList(),
              ),
          
          // 4️⃣ CAMADA DE MARCADORES - PONTOS DE MONITORAMENTO
          MarkerLayer(
            markers: heatmapData.map((ponto) {
              final lat = (ponto['latitude'] as num?)?.toDouble() ?? 0.0;
              final lng = (ponto['longitude'] as num?)?.toDouble() ?? 0.0;
              final cor = ponto['cor'] as Color? ?? Colors.grey;
              final intensidade = (ponto['intensidade'] as num?)?.toDouble() ?? 0.0;
              
              // ✅ TAMANHO FIXO EM PÍXEIS (24-28px, não muda com zoom)
              final tamanho = 24.0 + (intensidade * 4.0); // Reduzido para não atrapalhar
              final fontSize = 14.0; // Fonte fixa
              
              return Marker(
                point: LatLng(lat, lng),
                width: tamanho,
                height: tamanho,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => _mostrarDetalhesPonto(ponto),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: cor.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getEmojiOrganismo(ponto['organismo'] as String?),
                        style: TextStyle(
                          fontSize: fontSize, // Fonte fixa
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          // 5️⃣ LEGENDA NO MAPA
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.satellite_alt, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'MapTiler',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thermostat, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${heatmapData.length} pontos térmicos',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (poligonoSnapshot.hasData && 
                        poligonoSnapshot.data != null && 
                        poligonoSnapshot.data!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Área do Talhão',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  /// 🗺️ CARREGAR POLÍGONO DO TALHÃO
  Future<List<LatLng>?> _carregarPoligonoTalhao() async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Buscar primeiro talhão com polígono
      final talhoes = await db.rawQuery('''
        SELECT t.id, t.nome, p.pontos
        FROM talhoes t
        LEFT JOIN poligonos p ON p.talhao_id = t.id
        WHERE p.pontos IS NOT NULL
        LIMIT 1
      ''');
      
      if (talhoes.isNotEmpty) {
        final pontosJson = talhoes.first['pontos'] as String?;
        if (pontosJson != null && pontosJson.isNotEmpty) {
          final List<dynamic> pontosList = jsonDecode(pontosJson);
          return pontosList.map((p) => LatLng(
            (p['latitude'] as num).toDouble(),
            (p['longitude'] as num).toDouble(),
          )).toList();
        }
      }
      
      Logger.info('⚠️ Nenhum polígono encontrado para o talhão');
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao carregar polígono do talhão: $e');
      return null;
    }
  }

  // ⚠️ Método _buildPontoHeatmap removido - agora usamos MarkerLayer diretamente

  /// 📊 LEGENDA DO MAPA
  Widget _buildLegendaMapa() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'Legenda:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendaItem('🟢 Baixo', Colors.green),
              _buildLegendaItem('🟡 Médio', Colors.yellow),
              _buildLegendaItem('🟠 Alto', Colors.orange),
              _buildLegendaItem('🔴 Crítico', Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<String>>(
            future: _carregarOrganismosMonitorados(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Text(
                  'Organismos: ${snapshot.data!.join(' | ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                );
              }
              return const Text(
                'Nenhum organismo detectado',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 📅 HISTÓRICO TEMPORAL
  Widget _buildHistoricoTemporal() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _carregarHistoricoTemporal(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final historico = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Text(
                  '📆 Histórico: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                ...historico.map((h) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${h['data']} ${h['emoji']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                )).toList(),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// 🗺️ CARREGAR DADOS REAIS DO HEATMAP
  Future<List<Map<String, dynamic>>> _carregarDadosHeatmapReais() async {
    try {
      final db = await AppDatabase.instance.database;
      
      Logger.info('🗺️ Buscando pontos de monitoramento para o heatmap...');
      
      // Buscar pontos de monitoramento com ocorrências
      final pontos = await db.rawQuery('''
        SELECT 
          mp.latitude,
          mp.longitude,
          mo.tipo,
          mo.subtipo,
          mo.agronomic_severity,
          mo.percentual,
          mp.timestamp
        FROM monitoring_points mp
        JOIN monitoring_occurrences mo ON mo.point_id = mp.id
        WHERE mp.latitude IS NOT NULL 
          AND mp.longitude IS NOT NULL
          AND mo.subtipo IS NOT NULL
        ORDER BY mp.timestamp DESC
        LIMIT 20
      ''');
      
      Logger.info('📊 ${pontos.length} pontos encontrados no banco');
      
      final heatmapData = <Map<String, dynamic>>[];
      
      for (final ponto in pontos) {
        final intensidade = (ponto['agronomic_severity'] as num?)?.toDouble() ?? 
                           ((ponto['percentual'] as num?)?.toDouble() ?? 5.0);
        final intensidadeNormalizada = (intensidade / 10.0).clamp(0.1, 1.0);
        
        Color cor;
        String nivel;
        if (intensidade >= 7.0) {
          cor = Colors.red;
          nivel = 'crítico';
        } else if (intensidade >= 5.0) {
          cor = Colors.orange;
          nivel = 'alto';
        } else if (intensidade >= 3.0) {
          cor = Colors.yellow;
          nivel = 'médio';
        } else {
          cor = Colors.green;
          nivel = 'baixo';
        }
        
        final lat = (ponto['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (ponto['longitude'] as num?)?.toDouble() ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          heatmapData.add({
            'latitude': lat,
            'longitude': lng,
            'intensidade': intensidadeNormalizada,
            'organismo': ponto['subtipo'] ?? 'N/A',
            'tipo': ponto['tipo'] ?? 'N/A',
            'cor': cor,
            'nivel': nivel,
            'timestamp': ponto['timestamp'],
          });
          
          Logger.info('📍 Ponto adicionado: $lat, $lng - ${ponto['subtipo']} ($nivel)');
        }
      }
      
      Logger.info('✅ ${heatmapData.length} pontos processados para o heatmap');
      return heatmapData;
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados do heatmap: $e');
      return [];
    }
  }

  /// 🐛 CARREGAR ORGANISMOS MONITORADOS
  Future<List<String>> _carregarOrganismosMonitorados() async {
    try {
      final db = await AppDatabase.instance.database;
      
      final organismos = await db.rawQuery('''
        SELECT DISTINCT mo.subtipo
        FROM monitoring_occurrences mo
        JOIN monitoring_points mp ON mp.id = mo.point_id
        WHERE mo.subtipo IS NOT NULL
        ORDER BY mo.subtipo
      ''');
      
      return organismos
        .map((o) => o['subtipo'] as String?)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar organismos: $e');
      return [];
    }
  }

  /// 📅 CARREGAR HISTÓRICO TEMPORAL
  Future<List<Map<String, dynamic>>> _carregarHistoricoTemporal() async {
    try {
      final db = await AppDatabase.instance.database;
      
      final historico = await db.rawQuery('''
        SELECT 
          DATE(mp.timestamp) as data,
          AVG(mo.agronomic_severity) as severidade_media
        FROM monitoring_points mp
        JOIN monitoring_occurrences mo ON mo.point_id = mp.id
        WHERE mp.timestamp >= datetime('now', '-7 days')
        GROUP BY DATE(mp.timestamp)
        ORDER BY mp.timestamp DESC
        LIMIT 3
      ''');
      
      return historico.map((h) {
        final severidade = (h['severidade_media'] as num?)?.toDouble() ?? 0.0;
        String emoji;
        if (severidade >= 7.0) {
          emoji = '🔴';
        } else if (severidade >= 5.0) {
          emoji = '🟠';
        } else if (severidade >= 3.0) {
          emoji = '🟡';
        } else {
          emoji = '🟢';
        }
        
        return {
          'data': h['data']?.toString().substring(5) ?? 'N/A', // MM-DD
          'emoji': emoji,
        };
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar histórico: $e');
      return [];
    }
  }

  /// 🐛 EMOJI DO ORGANISMO
  String _getEmojiOrganismo(String? organismo) {
    if (organismo == null) return '🐛';
    
    final org = organismo.toLowerCase();
    if (org.contains('percevejo') || org.contains('inseto')) return '🐛';
    if (org.contains('doença') || org.contains('fungo')) return '🍃';
    if (org.contains('daninha') || org.contains('buva')) return '🌿';
    if (org.contains('mosaico') || org.contains('vírus')) return '🦠';
    return '🐛';
  }

  /// 🗺️ MOSTRAR MAPA COMPLETO
  void _mostrarMapaCompleto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗺️ Mapa de Infestação Completo'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _buildMapaInterativo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// 📍 MOSTRAR DETALHES DO PONTO
  void _mostrarDetalhesPonto(Map<String, dynamic> ponto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📍 ${ponto['organismo']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${ponto['tipo']}'),
            Text('Nível: ${ponto['nivel']}'),
            Text('Intensidade: ${(ponto['intensidade'] * 100).toStringAsFixed(1)}%'),
            Text('Data: ${ponto['timestamp']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// 🎨 ITEM DA LEGENDA
  Widget _buildLegendaItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// 🌱 DADOS AGRONÔMICOS COMPLETOS
  Widget _buildDadosAgronomicosCompletosSection(Map<String, dynamic> dados) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco, color: Colors.green),
              SizedBox(width: 8),
              Text(
                '🌱 Dados Agronômicos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // FENOLOGIA
          if (dados['fenologia'] != null) ...[
            _buildDadoAgronomicoCard(
              'Estado Fenológico',
              dados['fenologia']['estagio'] ?? 'N/A',
              'Altura: ${dados['fenologia']['altura']}cm',
              Icons.grass,
              Colors.green,
            ),
            const SizedBox(height: 12),
          ],
          
          // ESTANDE
          if (dados['estande'] != null) ...[
            _buildDadoAgronomicoCard(
              'Estande de Plantas',
              '${(dados['estande']['populacao'] ?? 0).toStringAsFixed(0)} plantas/ha',
              'Eficiência: ${dados['estande']['eficiencia']}%',
              Icons.grass_outlined,
              Colors.blue,
            ),
            const SizedBox(height: 12),
          ],
          
          // CV%
          if (dados['cv'] != null) ...[
            _buildDadoAgronomicoCard(
              'Coeficiente de Variação',
              '${dados['cv']['valor']}%',
              'Classificação: ${dados['cv']['classificacao']}',
              Icons.show_chart,
              Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDadoAgronomicoCard(String titulo, String valor, String subtitulo, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🌤️ CONDIÇÕES AMBIENTAIS COMPLETAS
  Widget _buildCondicoesAmbientaisCompletasSection(Map<String, dynamic> condicoes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                '🌤️ Condições Ambientais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Temperatura: ${condicoes['temperatura'] ?? 'N/A'}°C',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Umidade: ${condicoes['umidade'] ?? 'N/A'}%',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Condições: ${condicoes['descricao'] ?? 'Favorável para desenvolvimento de infestações'}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 💊 RECOMENDAÇÕES DE APLICAÇÃO INTERPRETADAS PELA IA
  Widget _buildDadosJSONExpandivelCompleto(Map<String, dynamic> dadosCompletos, Map<String, dynamic> analise) {
    return ExpansionTile(
      leading: const Icon(Icons.medical_services, color: Colors.green),
      title: const Text(
        '💊 Recomendações de Aplicação',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('Protocolo técnico baseado na análise da IA FortSmart'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<Widget>>(
              future: _gerarRecomendacoesAplicacao(analise, dadosCompletos),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erro ao gerar recomendações: ${snapshot.error}'),
                  );
                }
                return Column(children: snapshot.data ?? []);
              },
            ),
          ],
          ),
        ),
      ],
    );
  }

  /// 🧪 GERAR RECOMENDAÇÕES PRÁTICAS DE APLICAÇÃO
  Future<List<Widget>> _gerarRecomendacoesAplicacao(Map<String, dynamic> analise, Map<String, dynamic> dadosCompletos) async {
    final widgets = <Widget>[];
    
    // 1. PRODUTOS RECOMENDADOS (AGORA BASEADOS NOS JSONS)
    final organismos = (analise['organismosDetectados'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final nivelRisco = analise['nivelRisco'] as String? ?? 'Baixo';
    final culturaNome = dadosCompletos['cultura'] as String? ?? 
                       analise['cultura'] as String? ?? 
                       'soja'; // Fallback
    
    // ✅ LOGS PARA DIAGNÓSTICO
    Logger.info('💊 [RECOMENDAÇÕES] Gerando recomendações de aplicação...');
    Logger.info('   🌾 Cultura: $culturaNome');
    Logger.info('   🐛 Organismos detectados: ${organismos.join(", ")}');
    Logger.info('   ⚠️ Nível de risco: $nivelRisco');
    Logger.info('   📊 Dados completos: ${dadosCompletos.keys.join(", ")}');
    
    if (organismos.isNotEmpty) {
      // ✅ CARREGAR DADOS DOS JSONs PARA CADA ORGANISMO
      final recomendacoesCombinadas = <String>[];
      
      for (final organismo in organismos.toSet()) {
        Logger.info('   🔍 Buscando dados de controle para: $organismo em $culturaNome');
        final dadosControle = await _recommendationsService.carregarDadosControle(culturaNome, organismo);
        
        if (dadosControle != null) {
          Logger.info('   ✅ Dados de controle encontrados para $organismo');
          recomendacoesCombinadas.add('📋 $organismo:');
          recomendacoesCombinadas.addAll(
            _recommendationsService.gerarProdutosRecomendados(dadosControle, nivelRisco)
          );
          recomendacoesCombinadas.add('');
        } else {
          Logger.warning('   ⚠️ Dados de controle NÃO encontrados para $organismo em $culturaNome');
        }
      }
      
      // Se não encontrou nos JSONs, usar método antigo como fallback
      if (recomendacoesCombinadas.isEmpty) {
        Logger.warning('   ⚠️ Nenhuma recomendação encontrada nos JSONs, usando fallback legacy');
        recomendacoesCombinadas.addAll(_gerarProdutosRecomendadosLegacy(organismos, nivelRisco));
      } else {
        Logger.info('   ✅ ${recomendacoesCombinadas.length} recomendações geradas dos JSONs');
      }
      
      widgets.add(_buildRecomendacaoCard(
        '🧪 Produtos Recomendados (Baseados nos JSONs)',
        recomendacoesCombinadas,
        Colors.blue,
      ));
      widgets.add(const SizedBox(height: 12));
    } else {
      Logger.warning('💊 [RECOMENDAÇÕES] Nenhum organismo detectado - sem recomendações');
    }
    
    // 2. DOSAGEM E APLICAÇÃO (AGORA BASEADOS NOS JSONs)
    Map<String, dynamic>? dadosControlePrimeiro;
    if (organismos.isNotEmpty) {
      dadosControlePrimeiro = await _recommendationsService.carregarDadosControle(
        culturaNome, 
        organismos.first,
      );
    }
    
    widgets.add(_buildRecomendacaoCard(
      '💧 Dosagem e Aplicação',
      _recommendationsService.gerarDosagemAplicacao(dadosControlePrimeiro, nivelRisco),
      Colors.orange,
    ));
    widgets.add(const SizedBox(height: 12));
    
    // ❌ REMOVIDO: Momento Ideal de Aplicação (dados fictícios - precisa de mais conhecimento)
    // ❌ REMOVIDO: Tecnologia de Aplicação (dados fictícios - precisa de mais conhecimento)
    // TODO: Implementar com dados reais dos JSONs e conhecimento técnico adequado
    
    // 3. MONITORAMENTO PÓS-APLICAÇÃO
    widgets.add(_buildRecomendacaoCard(
      '📊 Monitoramento Pós-Aplicação',
      _gerarMonitoramentoPos(nivelRisco),
      Colors.indigo,
    ));
    
    return widgets;
  }

  Widget _buildRecomendacaoCard(String titulo, List<String> itens, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...itens.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16, color: cor)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// Fallback: método legado para quando não encontrar nos JSONs
  List<String> _gerarProdutosRecomendadosLegacy(List<String> organismos, String nivelRisco) {
    final recomendacoes = <String>[];
    
    for (final org in organismos.toSet()) {
      final orgName = org.toString().toLowerCase();
      
      if (orgName.contains('percevejo')) {
        recomendacoes.add('Inseticida: Tiametoxam 250 g/L ou Imidacloprido 200 g/L');
        recomendacoes.add('Dose: 200-300 ml/ha conforme nível de infestação');
      } else if (orgName.contains('lagarta') || orgName.contains('torraozinho')) {
        recomendacoes.add('Inseticida: Clorantraniliprole 200 SC ou Flubendiamida 480 WG');
        recomendacoes.add('Dose: 60-100 ml/ha para lagartas de difícil controle');
      } else if (orgName.contains('mosaico') || orgName.contains('vírus')) {
        recomendacoes.add('Controle do vetor: Thiamethoxam + Lambda-cyhalothrin');
        recomendacoes.add('Dose: 150-200 ml/ha para controle de mosca-branca');
        recomendacoes.add('Eliminação de plantas infectadas para reduzir inóculo');
      } else if (orgName.contains('ferrugem') || orgName.contains('doença')) {
        recomendacoes.add('Fungicida: Triazol + Estrobilurina (ex: Tebuconazol + Azoxistrobina)');
        recomendacoes.add('Dose: 500-750 ml/ha em aplicação preventiva/curativa');
      } else if (orgName.contains('daninha') || orgName.contains('buva')) {
        recomendacoes.add('Herbicida: Glifosato + 2,4-D ou Glufosinato de Amônio');
        recomendacoes.add('Dose: 2-3 L/ha de glifosato + adjuvante');
      }
    }
    
    if (recomendacoes.isEmpty) {
      recomendacoes.add('Consultar agrônomo para recomendação específica');
    }
    
    return recomendacoes;
  }

  List<String> _gerarDosagemAplicacao(List<dynamic> organismos, String nivelRisco) {
    final dosagens = <String>[];
    
    dosagens.add('Volume de calda: 150-200 L/ha para aplicação terrestre');
    dosagens.add('Volume de calda: 10-15 L/ha para aplicação aérea');
    
    if (nivelRisco.toLowerCase() == 'crítico') {
      dosagens.add('⚠️ Nível crítico: Utilizar dose máxima recomendada');
      dosagens.add('Adicionar adjuvante: Óleo mineral 0,5% ou espalhante adesivo');
    } else if (nivelRisco.toLowerCase() == 'alto') {
      dosagens.add('Utilizar dose média-alta da recomendação');
      dosagens.add('Considerar adjuvante para melhor eficácia');
    } else {
      dosagens.add('Utilizar dose padrão recomendada');
    }
    
    dosagens.add('pH da calda: 5,5-6,5 para melhor eficácia dos defensivos');
    dosagens.add('Intervalo de segurança: Respeitar o período de carência');
    
    return dosagens;
  }

  // ❌ REMOVIDO: _gerarMomentoAplicacao - dados fictícios
  // TODO: Implementar com dados reais baseados em:
  //   - Condições climáticas reais do local
  //   - Características específicas dos produtos dos JSONs
  //   - Janelas de aplicação por fase fenológica
  //   - Normas técnicas de aplicação

  // ❌ REMOVIDO: _gerarTecnologiaAplicacao - dados fictícios
  // TODO: Implementar com dados reais baseados em:
  //   - Tipo de equipamento disponível na fazenda
  //   - Especificações técnicas dos produtos
  //   - Tamanho da área a ser tratada
  //   - Condições do terreno e cultura

  List<String> _gerarMonitoramentoPos(String nivelRisco) {
    final monitoramentos = <String>[];
    
    monitoramentos.add('Avaliar eficácia 3-5 dias após aplicação');
    monitoramentos.add('Realizar contagem de organismos vivos vs. mortos');
    
    if (nivelRisco.toLowerCase() == 'crítico' || nivelRisco.toLowerCase() == 'alto') {
      monitoramentos.add('⚠️ Reaplicação: Pode ser necessária em 7-10 dias');
      monitoramentos.add('Monitoramento intensivo: A cada 3 dias');
    } else {
      monitoramentos.add('Monitoramento de rotina: Semanalmente');
    }
    
    monitoramentos.add('Registrar dados no sistema FortSmart para histórico');
    monitoramentos.add('Avaliar necessidade de manejo integrado (MIP)');
    monitoramentos.add('Documentar resultados para tomada de decisão futura');
    
    return monitoramentos;
  }

  /// 🧠 INTERPRETADOR DE DADOS DA IA - CONVERTE JSON COMPLEXO EM TEXTO LEGÍVEL
  List<Widget> _interpretarDadosIA(Map<String, dynamic> analise, Map<String, dynamic> dadosCompletos) {
    final widgets = <Widget>[];
    
    // 1. CONFIANÇA E MODELO DA IA
    widgets.add(_buildInterpretacaoCard(
      '🎯 Confiança da Análise',
      '${((analise['scoreConfianca'] as num?)?.toDouble() ?? 0.0) * 100}%',
      'O FortSmart Agro analisou ${analise['totalOcorrencias'] ?? 0} ocorrências com ${((analise['scoreConfianca'] as num?)?.toDouble() ?? 0.0) * 100}% de confiança',
      Colors.blue,
    ));
    
    // 2. NÍVEL DE RISCO INTERPRETADO
    final nivelRisco = analise['nivelRisco'] as String? ?? 'Baixo';
    String descricaoRisco;
    Color corRisco;
    
    switch (nivelRisco.toLowerCase()) {
      case 'crítico':
        descricaoRisco = 'ATENÇÃO: Risco crítico detectado. Ação imediata recomendada para evitar perdas severas na produção.';
        corRisco = Colors.red;
        break;
      case 'alto':
        descricaoRisco = 'Risco alto detectado. Recomenda-se aplicação de controle dentro de 48h para evitar propagação.';
        corRisco = Colors.orange;
        break;
      case 'médio':
        descricaoRisco = 'Risco moderado. Monitoramento próximo recomendado. Avaliar necessidade de intervenção em 5-7 dias.';
        corRisco = Colors.yellow.shade700;
        break;
      default:
        descricaoRisco = 'Risco baixo. Manter monitoramento de rotina. Condições sob controle.';
        corRisco = Colors.green;
    }
    
    widgets.add(const SizedBox(height: 12));
    widgets.add(_buildInterpretacaoCard(
      '⚠️ Nível de Risco',
      nivelRisco,
      descricaoRisco,
      corRisco,
    ));
    
    // 3. ORGANISMOS DETECTADOS COM INTERPRETAÇÃO
    final organismos = analise['organismosDetectados'] as List<dynamic>?;
    if (organismos != null && organismos.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildInterpretacaoCard(
        '🐛 Organismos Identificados',
        '${organismos.length} espécies detectadas',
        'O FortSmart Agro identificou: ${organismos.join(", ")}. Cada organismo foi classificado com base em sintomas visuais, padrões de distribuição e condições ambientais favoráveis.',
        Colors.red.shade700,
      ));
    }
    
    // 4. DADOS FENOLÓGICOS INTERPRETADOS
    if (dadosCompletos['fenologia'] != null) {
      final fenologia = dadosCompletos['fenologia'] as Map<String, dynamic>;
      final estagio = fenologia['estagio'] ?? 'N/A';
      final altura = fenologia['altura'] ?? 0.0;
      
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildInterpretacaoCard(
        '🌱 Estado Fenológico',
        'Estágio $estagio',
        'A cultura está no estágio fenológico $estagio com altura média de ${altura}cm. Este estágio é crítico para o desenvolvimento e requer atenção especial ao controle de pragas e doenças.',
        Colors.green.shade700,
      ));
    }
    
    // 5. CONDIÇÕES AMBIENTAIS INTERPRETADAS
    final condicoes = analise['condicoesFavoraveis'] as Map<String, dynamic>?;
    if (condicoes != null) {
      final temp = condicoes['temperatura'] ?? 'N/A';
      final umidade = condicoes['umidade'] ?? 'N/A';
      
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildInterpretacaoCard(
        '🌤️ Condições Climáticas',
        'Temp: $temp°C | Umid: $umidade%',
        condicoes['descricao'] ?? 'Condições ambientais registradas. Temperatura e umidade são fatores determinantes para o desenvolvimento de infestações.',
        Colors.blue.shade600,
      ));
    }
    
    // 6. RECOMENDAÇÕES TÉCNICAS
    final recomendacoes = analise['recomendacoes'] as List<dynamic>?;
    if (recomendacoes != null && recomendacoes.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '💡 Recomendações Técnicas da IA',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recomendacoes.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      rec.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ));
    }
    
    return widgets;
  }

  Widget _buildInterpretacaoCard(String titulo, String valor, String descricao, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return json.toString();
    }
  }
  
  // =========================================================================
  // ✅ NOVOS MÉTODOS HELPER PARA A NOVA TELA DE ANÁLISE DETALHADA
  // =========================================================================
  
  /// 🎨 Seção de análise com estilo moderno
  Widget _buildNewAnaliseSection(String title, List<Widget> content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }
  
  /// 📸 Galeria de Fotos NOVA com dados reais
  Widget _buildNewImagensSection(List<String> imagensPaths) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Galeria de Fotos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: imagensPaths.isEmpty ? Colors.grey : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${imagensPaths.length} fotos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (imagensPaths.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma foto registrada',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capture fotos durante o monitoramento',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: imagensPaths.length,
              itemBuilder: (context, index) {
                final imagePath = imagensPaths[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  /// 🦠 Organismos Detectados NOVA
  Widget _buildNewOrganismosSection(List<OrganismSummary> organismos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Organismos Detectados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (organismos.isEmpty)
            const Text(
              'Nenhum organismo detectado',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...organismos.map((org) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRiskColor(org.nivelRisco).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRiskColor(org.nivelRisco).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            org.nivelRisco,
                            style: TextStyle(
                              color: _getRiskColor(org.nivelRisco),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Pontos Afetados', '${org.pontosAfetados}/${org.totalPontos}'),
                    _buildInfoRow('Frequência', '${org.frequencia.toStringAsFixed(1)}%'),
                    _buildInfoRow('Quantidade Total', org.quantidadeTotal.toStringAsFixed(0)),
                    _buildInfoRow('Quantidade Média', org.quantidadeMedia.toStringAsFixed(2)),
                    _buildInfoRow('Severidade Média', '${org.severidadeMedia.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            )).toList(),
        ],
      ),
    );
  }
  
  /// 💡 Recomendações NOVA
  Widget _buildNewRecomendacoesSection(List<String> recomendacoes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recomendações Agronômicas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recomendacoes.isEmpty)
            const Text(
              'Nenhuma recomendação disponível',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...recomendacoes.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }
  
  /// ⚠️ Alertas NOVA
  Widget _buildNewAlertasSection(List<String> alertas) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Alertas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alertas.map((alerta) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alerta,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  /// 🎨 Helper para cor de risco
  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'CRÍTICO':
        return Colors.red[700]!;
      case 'ALTO':
        return Colors.orange[700]!;
      case 'MÉDIO':
        return Colors.yellow[700]!;
      case 'BAIXO':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}


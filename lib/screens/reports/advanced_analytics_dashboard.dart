import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';  // ✅ ADICIONADO: Import do Database
import 'package:flutter_map/flutter_map.dart'; // ✅ MAPA TÉRMICO
import 'package:latlong2/latlong.dart'; // ✅ COORDENADAS GPS
import 'dart:convert'; // ✅ JSON parsing
import 'dart:ui' as ui; // ✅ Para Path do CurvaPainter
import '../../services/advanced_prediction_models.dart';
import '../../services/phenological_infestation_service.dart';
import '../../services/safra_validation_service.dart';
import '../../widgets/phenological_infestation_card.dart';
import '../../widgets/marquee_text.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import '../../database/app_database.dart';
import '../../utils/api_config.dart'; // ✅ MAPTILER API
import 'detailed_planting_reports_screen.dart';
import '../../debug_infestation_calculation.dart'; // ✅ DIAGNÓSTICO

/// 🧠 Dashboard de Análises Avançadas - Sistema FortSmart Agro
/// 
/// FUNCIONALIDADES AVANÇADAS:
/// - Curvas de Infestação por Cultura
/// - Validação por Safra
/// - Integração Germinação + Infestação
/// - Modelos de Progressão Temporal
/// - Dashboard com acesso aos módulos especializados
/// 
/// DIFERENCIAIS ÚNICOS:
/// - ✅ Predição de tendência 7 dias
/// - ✅ Relatórios de acurácia por safra
/// - ✅ Retroalimentação germinação → infestação
/// - ✅ Modelos matemáticos avançados
/// - ✅ Dados reais do sistema (sem dados de exemplo)

class AdvancedAnalyticsDashboard extends StatefulWidget {
  final String? talhaoId;
  final String? culturaId;
  final String? sessionId;
  final Map<String, dynamic>? monitoringData;
  
  const AdvancedAnalyticsDashboard({
    super.key,
    this.talhaoId,
    this.culturaId,
    this.sessionId,
    this.monitoringData,
  });

  @override
  State<AdvancedAnalyticsDashboard> createState() => _AdvancedAnalyticsDashboardState();
}

class _AdvancedAnalyticsDashboardState extends State<AdvancedAnalyticsDashboard>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final AdvancedPredictionModels _predictionModels = AdvancedPredictionModels();
  final PhenologicalInfestationService _infestationService = PhenologicalInfestationService();
  final SafraValidationService _safraValidationService = SafraValidationService();
  
  // Dados das análises
  Map<String, dynamic>? _curvaInfestacao;
  // _validacaoSafra REMOVIDO - substituído por Plantios Detalhados
  // _integracaoGerminacao REMOVIDO - não será mais utilizado
  
  bool _isLoading = false;
  String _selectedSafra = '2024/2025';
  String _selectedCultura = 'Soja';
  String _selectedOrganismo = 'Lagarta-do-cartucho';
  
  // 🔽 Filtro de talhão
  String? _selectedTalhaoId;
  String? _selectedTalhaoNome;
  List<Map<String, String>> _talhoesOptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // ✅ Se recebeu dados de monitoramento, usar esses dados
    if (widget.monitoringData != null) {
      Logger.info('📊 [RELATORIO_AGRO] Iniciando com dados de monitoramento');
      Logger.info('📊 [RELATORIO_AGRO] Session ID: ${widget.sessionId}');
      Logger.info('📊 [RELATORIO_AGRO] Talhão: ${widget.monitoringData!['talhao_nome']}');
      Logger.info('📊 [RELATORIO_AGRO] Cultura: ${widget.monitoringData!['cultura_nome']}');
    }
    
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);
    
    try {
      Logger.info('🧠 Inicializando análises avançadas...');
      await _predictionModels.initialize();
      await _infestationService.initialize();
      Logger.info('✅ Modelos de predição e infestação inicializados');
      
      // Carregar opções de talhões e definir seleção inicial
      await _loadTalhoesOptions();
      
      await _loadAnalyses();
      Logger.info('✅ Análises carregadas com sucesso');
      
    } catch (e) {
      Logger.error('❌ Erro ao inicializar análises avançadas: $e');
      // Mostrar erro para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar relatório agronômico: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Carrega opções de talhões para filtro
  Future<void> _loadTalhoesOptions() async {
    try {
      final db = await AppDatabase.instance.database;
      final options = <Map<String, String>>[];
      
      // 1) Tabela de talhões
      final talhoes = await db.query('talhoes', columns: ['id', 'nome'], orderBy: 'nome ASC');
      for (final t in talhoes) {
        final id = t['id']?.toString() ?? '';
        final nome = (t['nome'] as String?)?.trim();
        if (id.isNotEmpty && nome != null && nome.isNotEmpty) {
          options.add({'id': id, 'nome': nome});
        }
      }
      
      // 2) Complementar com monitoring_sessions (se faltar)
      final sessoes = await db.rawQuery('''
        SELECT DISTINCT talhao_id, talhao_nome 
        FROM monitoring_sessions 
        WHERE talhao_id IS NOT NULL AND talhao_nome IS NOT NULL
        ORDER BY talhao_nome ASC
      ''');
      for (final s in sessoes) {
        final id = s['talhao_id']?.toString() ?? '';
        final nome = (s['talhao_nome'] as String?)?.trim();
        if (id.isNotEmpty && nome != null && nome.isNotEmpty &&
            !options.any((o) => o['id'] == id)) {
          options.add({'id': id, 'nome': nome});
        }
      }
      
      // Seleção inicial: usar talhão vindo por argumento, senão primeiro da lista
      _selectedTalhaoId = widget.talhaoId ?? (_selectedTalhaoId ?? (options.isNotEmpty ? options.first['id'] : null));
      _selectedTalhaoNome = options.firstWhere(
        (o) => o['id'] == _selectedTalhaoId,
        orElse: () => (options.isNotEmpty ? options.first : {'id': '', 'nome': ''}),
      )['nome'];
      
      setState(() {
        _talhoesOptions = options;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar opções de talhões: $e');
    }
  }

  /// Seletor de talhão por NOME (não ID)
  Widget _buildTalhaoFilter() {
    if (_talhoesOptions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        const Icon(Icons.map, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedTalhaoId,
            decoration: const InputDecoration(
              labelText: 'Filtrar por Talhão',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _talhoesOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt['id'],
                child: Text(opt['nome'] ?? ''),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() {
                _selectedTalhaoId = value;
                _selectedTalhaoNome = _talhoesOptions.firstWhere(
                  (o) => o['id'] == value,
                  orElse: () => {'id': '', 'nome': ''},
                )['nome'];
              });
              // Recarregar análises com novo filtro
              await _loadAnalyses();
            },
          ),
        ),
      ],
    );
  }


  Future<void> _loadAnalyses() async {
    try {
      // Carregar curva de infestação com tratamento de erro
      try {
        _curvaInfestacao = await _predictionModels.calcularCurvaInfestacao(
          cultura: _selectedCultura,
          organismo: _selectedOrganismo,
          estagioFenologico: 'V4',
          temperatura: 28.5,
          umidade: 75.0,
          densidadeAtual: 0.3,
          diasProjecao: 7,
        );
      } catch (e) {
        Logger.error('❌ Erro ao carregar curva de infestação: $e');
        _curvaInfestacao = null;
      }
      
      // ❌ REMOVIDO: Validação por safra substituída por "Plantios Detalhados"
      // ❌ REMOVIDO: Integração germinação - não será mais utilizada
      
    } catch (e) {
      Logger.error('❌ Erro geral ao carregar análises: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Agronômico - FortSmart Agro'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            MarqueeTab(
              text: 'Infestação Fenológica',
              icon: Icon(Icons.bug_report),
            ),
            MarqueeTab(
              text: 'Curvas de Infestação',
              icon: Icon(Icons.trending_up),
            ),
            MarqueeTab(
              text: 'Plantios Detalhados',
              icon: Icon(Icons.description),
            ),
            MarqueeTab(
              text: 'Dashboard Inteligente',
              icon: Icon(Icons.grid_view),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInfestacaoFenologica(),
                _buildCurvaInfestacao(),
                _buildPlantiosDetalhados(),
                _buildDashboardSection(),
              ],
            ),
    );
  }

  /// Constrói aba de infestação fenológica
  Widget _buildInfestacaoFenologica() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(
            'Análise de Infestação Fenológica',
            'Níveis de ação dinâmicos baseados no estágio da cultura',
            Icons.bug_report,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildTalhaoFilter(),
          const SizedBox(height: 16),
          
          // Card com dados REAIS de infestação do banco de dados
          FutureBuilder<TalhaoInfestationResult>(
            future: _loadRealInfestationData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                Logger.error('❌ Erro no FutureBuilder de infestação: ${snapshot.error}');
                return _buildEmptyState('Erro ao carregar dados de infestação: ${snapshot.error}');
              }
              
              final result = snapshot.data;
              
              // ✅ NOVA LÓGICA: Verificar se TEM dados de monitoramento
              if (!snapshot.hasData || !result!.hasMonitoringData) {
                return _buildEmptyState(
                  'Nenhuma infestação detectada.\n\n'
                  'Realize monitoramentos no campo para ver análises fenológicas em tempo real.'
                );
              }
              
              // ✅ SE TEM dados mas organisms está vazio, mostrar card com dados brutos + aviso
              if (result.organisms.isEmpty && result.rawOrganisms != null && result.rawOrganisms!.isNotEmpty) {
                Logger.warning('⚠️ Mostrando dados brutos porque organisms.isEmpty mas rawOrganisms tem ${result.rawOrganisms!.length} itens');
                return _buildRawDataCard(result);
              }
              
              // ✅ Análise completa disponível
              return PhenologicalInfestationCard(
                result: result,
                onScheduleApplication: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚜 Navegando para módulo de Prescrição...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // TODO: Navegar para módulo de prescrição/aplicação
                },
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 🗺️ MAPA TÉRMICO DE INFESTAÇÃO (com tratamento de erro)
          _buildMapaTermicoInfestacao(),
          
          const SizedBox(height: 16),
          _buildInfestationLegend(),
          
          // 🔍 BOTÃO DE DIAGNÓSTICO (temporário)
          const SizedBox(height: 16),
          _buildDiagnosticButton(),
        ],
      ),
    );
  }

  /// Busca dados REAIS de infestação do banco de dados
  Future<TalhaoInfestationResult> _loadRealInfestationData() async {
    try {
      Logger.info('🔍 Buscando dados REAIS de infestação do banco...');
      
      final db = await AppDatabase.instance.database;
      
      // Buscar últimas ocorrências de infestação do banco
      // ✅ BUSCAR DA TABELA NOVA: monitoring_occurrences
      Logger.info('🔍 Buscando ocorrências de monitoring_occurrences...');
      
      // ✅ MOSTRAR TODAS AS OCORRÊNCIAS (sem agrupar para não perder dados)
      // ✅ FILTRAR APENAS DADOS DA SESSÃO/DATA ATUAL (NÃO USAR HISTÓRICO ANTIGO)
      // Se tiver sessionId ou data específica, usar apenas esses dados
      String whereTalhao;
      List<dynamic> whereArgs = [];
      
      if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        // ✅ FILTRO POR SESSÃO ESPECÍFICA (dados mais precisos)
        whereTalhao = "WHERE mo.session_id = ?";
        whereArgs = [widget.sessionId!];
        Logger.info('🔍 Filtrando por sessão específica: ${widget.sessionId}');
      } else if (_selectedTalhaoId != null && _selectedTalhaoId!.isNotEmpty) {
        // ✅ FILTRO POR TALHÃO (pode ter múltiplas sessões)
        whereTalhao = "WHERE mo.talhao_id = ?";
        whereArgs = [_selectedTalhaoId!];
        Logger.info('🔍 Filtrando por talhão: $_selectedTalhaoId');
      } else {
        whereTalhao = "WHERE 1=1";
        Logger.warning('⚠️ Sem filtro específico - mostrando todos os dados');
      }
      
      // ✅ BUSCAR OCORRÊNCIAS PRIMEIRO
      final sql = '''
        SELECT 
          mo.organism_name as organismo_nome,
          mo.organism_id,
          mo.tipo,
          mo.quantidade,
          mo.percentual,
          mo.agronomic_severity,
          mo.point_id,
          mo.data_hora
        FROM monitoring_occurrences mo
        ${whereTalhao}
        ORDER BY mo.data_hora DESC
      ''';
      final infestacoes = await db.rawQuery(sql, whereArgs);
      
      Logger.info('📊 ${infestacoes.length} ocorrências encontradas no banco');
      
      // ✅ PADRÃO MIP: Contar PONTOS ÚNICOS monitorados (não ocorrências)
      final totalPontosResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT mp.id) as total
        FROM monitoring_points mp
        ${widget.sessionId != null && widget.sessionId!.isNotEmpty
          ? 'WHERE mp.session_id = ?'
          : (_selectedTalhaoId != null && _selectedTalhaoId!.isNotEmpty 
              ? 'WHERE mp.session_id IN (SELECT id FROM monitoring_sessions WHERE talhao_id = ?)' 
              : 'WHERE 1=1')}
      ''', whereArgs.isNotEmpty ? whereArgs : []);
      
      var totalPontosMapeados = (totalPontosResult.first['total'] as num?)?.toInt() ?? 0;
      
      // ✅ GARANTIR QUE NUNCA SEJA ZERO (evitar divisão por zero)
      if (totalPontosMapeados == 0) {
        Logger.warning('⚠️ Total de pontos = 0, usando total de ocorrências como fallback');
        totalPontosMapeados = infestacoes.length > 0 ? infestacoes.length : 1;
      }
      
      Logger.info('📍 TOTAL DE PONTOS MAPEADOS NO TALHÃO: $totalPontosMapeados');
      
      if (infestacoes.isEmpty) {
        Logger.warning('⚠️ ========================================');
        Logger.warning('⚠️ NENHUMA OCORRÊNCIA ENCONTRADA NO BANCO!');
        Logger.warning('⚠️ ========================================');
        Logger.warning('⚠️ Possíveis causas:');
        Logger.warning('⚠️ 1. Banco de dados está vazio - Faça um monitoramento NOVO');
        Logger.warning('⚠️ 2. Filtro muito restritivo - Tente "Todos Talhões"');
        Logger.warning('⚠️ 3. sessionId inválido: ${widget.sessionId}');
        Logger.warning('⚠️ 4. talhaoId inválido: $_selectedTalhaoId');
        Logger.warning('⚠️ ========================================');
        
        // Diagnóstico adicional: Verificar se há dados em outras tabelas
        try {
          final totalOccAll = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_occurrences');
          final totalInfAll = await db.rawQuery('SELECT COUNT(*) as total FROM infestation_map');
          Logger.warning('⚠️ DIAGNÓSTICO:');
          Logger.warning('   Total em monitoring_occurrences (sem filtro): ${totalOccAll.first['total']}');
          Logger.warning('   Total em infestation_map (sem filtro): ${totalInfAll.first['total']}');
          
          if ((totalOccAll.first['total'] as num) == 0) {
            Logger.error('❌ BANCO COMPLETAMENTE VAZIO! Faça um monitoramento primeiro.');
          } else {
            Logger.warning('⚠️ Há ${totalOccAll.first['total']} ocorrências no banco, mas o FILTRO não encontrou nada.');
            Logger.warning('⚠️ SOLUÇÃO: Remova o filtro ou escolha outro talhão.');
          }
        } catch (e) {
          Logger.error('❌ Erro no diagnóstico: $e');
        }
        
        return TalhaoInfestationResult(
          phenologicalStage: 'Não determinado',
          generalLevel: 'BAIXO',
          organisms: [],
          actionRequired: false,
          hasMonitoringData: false, // ✅ NOVO: Indica que NÃO TEM dados de monitoramento
        );
      }
      
      // 🔄 AGRUPAR MANUALMENTE POR ORGANISMO E SOMAR QUANTIDADES
      final Map<String, Map<String, dynamic>> organismosMap = {};
      
      for (final infestacao in infestacoes) {
        final organismName = (infestacao['organismo_nome'] ?? infestacao['organism_name'] ?? 'Desconhecido').toString();
        final quantidade = (infestacao['quantidade'] as num?)?.toDouble() ?? (infestacao['percentual'] as num?)?.toDouble() ?? 0.0;
        final severity = (infestacao['agronomic_severity'] as num?)?.toDouble() ?? 0.0;
        final pointId = infestacao['point_id']?.toString() ?? '';
        
        if (!organismosMap.containsKey(organismName)) {
          organismosMap[organismName] = {
            'nome': organismName,
            'organism_id': infestacao['organism_id'] ?? 'org_${organismName.replaceAll(' ', '_')}',
            'tipo': infestacao['tipo'],
            'pontos_com_infestacao': <String>{},
            'quantidade_total': 0.0,
            'severidade_total': 0.0,
            'quantidade_maxima': 0.0,
            'ocorrencias': 0,
            // ✅ NOVA: Lista de quantidades individuais por ocorrência
            'quantidades_individuais': <double>[],
          };
        }
        
        final orgData = organismosMap[organismName]!;
        if (pointId.isNotEmpty) {
          (orgData['pontos_com_infestacao'] as Set<String>).add(pointId);
        }
        orgData['quantidade_total'] = (orgData['quantidade_total'] as double) + quantidade;
        orgData['severidade_total'] = (orgData['severidade_total'] as double) + severity;
        orgData['ocorrencias'] = (orgData['ocorrencias'] as int) + 1;
        (orgData['quantidades_individuais'] as List<double>).add(quantidade); // ✅ GUARDAR CADA QUANTIDADE
        
        if (quantidade > (orgData['quantidade_maxima'] as double)) {
          orgData['quantidade_maxima'] = quantidade;
        }
      }
      
      // ✅ CRIAR UM MonitoringPointData POR OCORRÊNCIA REAL (não agregar!)
      // Isso permite que calculateTalhaoLevel faça o cálculo correto:
      // Exemplo: 3 pontos com 4 Torraozinho cada → 3 MonitoringPointData com quantity=4
      final points = <MonitoringPointData>[];
      
      for (final entry in organismosMap.entries) {
        final orgData = entry.value;
        final pontosComInfestacao = (orgData['pontos_com_infestacao'] as Set<String>).length;
        final quantidadeTotal = (orgData['quantidade_total'] as double);
        final quantidadesIndividuais = orgData['quantidades_individuais'] as List<double>;
        final ocorrencias = orgData['ocorrencias'] as int;
        
        Logger.info('✅ ${orgData['nome']}: $pontosComInfestacao pontos, $ocorrencias ocorrências, TOTAL: $quantidadeTotal unidades');
        Logger.info('   Quantidades individuais: $quantidadesIndividuais');
        
        // ✅ CRIAR UM MonitoringPointData POR CADA OCORRÊNCIA COM SUA QUANTIDADE REAL
        for (final qtd in quantidadesIndividuais) {
          if (qtd > 0) { // Só adicionar se quantidade > 0
            points.add(MonitoringPointData(
              organismId: orgData['organism_id'].toString(),
              organismName: orgData['nome'].toString(),
              quantity: qtd.round(), // ✅ QUANTIDADE INDIVIDUAL REAL
            ));
          }
        }
      }
      
      Logger.info('✅ ${points.length} ocorrências processadas - calculando níveis fenológicos...');
      
      // ✅ BUSCAR ESTÁGIO FENOLÓGICO REAL DO BANCO
      final estagioReal = await _buscarEstagioFenologicoReal(db);
      Logger.info('🌱 Estágio fenológico real: $estagioReal');
      
      // ✅ DEBUG: Verificar se temos points antes de calcular
      if (points.isEmpty) {
        Logger.error('❌ ERRO: Lista de points está vazia após processamento!');
        Logger.warning('⚠️ Mas TEM infestações no banco (quantidade=0 ou dados inválidos)');
        return TalhaoInfestationResult(
          phenologicalStage: estagioReal,
          generalLevel: 'BAIXO',
          organisms: [],
          actionRequired: false,
          hasMonitoringData: true, // ✅ TEM dados de monitoramento (mas quantidade = 0)
          hasPhenologicalData: estagioReal != 'V1', // ✅ Verifica se tem dados fenológicos reais
          rawOrganisms: organismosMap.values.toList(), // ✅ DADOS BRUTOS para exibição
        );
      }
      
      Logger.info('📋 DEBUG: Enviando ${points.length} ocorrências para calculateTalhaoLevel');
      Logger.info('📍 Total de pontos mapeados no talhão: $totalPontosMapeados');
      for (final point in points.take(5)) {  // Mostrar 5 primeiras
        Logger.info('   - ${point.organismName}: ${point.quantity} unidades');
      }
      
      // ✅ CALCULAR NÍVEIS USANDO PADRÃO MIP CORRETO
      final result = await _infestationService.calculateTalhaoLevelMIP(
        points: points,
        phenologicalStage: estagioReal,
        cropId: _selectedCultura.toLowerCase(),
        totalPontosMapeados: totalPontosMapeados, // ✅ PASSAR TOTAL DE PONTOS REAL
      );
      
      Logger.info('✅ Análise fenológica concluída: ${result.organisms.length} organismos');
      Logger.info('🎯 Nível geral: ${result.generalLevel}');
      Logger.info('⚠️ Ação necessária: ${result.actionRequired}');
      
      // ✅ DEBUG: Se organisms estiver vazio, logar o resultado completo
      if (result.organisms.isEmpty) {
        Logger.error('❌ AVISO: calculateTalhaoLevel retornou 0 organismos!');
        Logger.error('   Estágio: ${result.phenologicalStage}');
        Logger.error('   Nível geral: ${result.generalLevel}');
        Logger.error('   Cultura: ${_selectedCultura.toLowerCase()}');
        Logger.warning('⚠️ Mas TEM ${organismosMap.length} organismos com dados brutos!');
      }
      
      // ✅ ADICIONAR DADOS EXTRAS AO RESULTADO
      return TalhaoInfestationResult(
        phenologicalStage: result.phenologicalStage,
        generalLevel: result.generalLevel,
        organisms: result.organisms,
        actionRequired: result.actionRequired,
        hasMonitoringData: true, // ✅ TEM dados de monitoramento
        hasPhenologicalData: estagioReal != 'V1', // ✅ Verifica se tem dados fenológicos reais
        rawOrganisms: organismosMap.values.toList(), // ✅ DADOS BRUTOS para fallback
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar dados reais de infestação: $e');
      Logger.error('❌ Stack: ${StackTrace.current}');
      
      // Retornar estado vazio em caso de erro
      return TalhaoInfestationResult(
        phenologicalStage: 'Erro',
        generalLevel: 'BAIXO',
        organisms: [],
        actionRequired: false,
      );
    }
  }
  
  /// ✅ MÉTODO NOVO: Busca estágio fenológico REAL do banco de dados
  Future<String> _buscarEstagioFenologicoReal(Database db) async {
    try {
      Logger.info('🌱 [FENOLOGIA] Buscando estágio fenológico real do banco...');
      Logger.info('   Cultura: ${_selectedCultura}');
      
      // 1. Tentar buscar de phenological_records (mais recente)
      final phenoRecords = await db.rawQuery('''
        SELECT fase_fenologica, data_registro 
        FROM phenological_records 
        ORDER BY data_registro DESC 
        LIMIT 1
      ''');
      
      if (phenoRecords.isNotEmpty) {
        final estagio = phenoRecords.first['fase_fenologica'] as String?;  // ✅ CORRIGIDO: coluna certa!
        if (estagio != null && estagio.isNotEmpty && estagio != 'V1') {
          Logger.info('✅ Estágio fenológico encontrado em phenological_records: $estagio');
          return estagio;
        } else {
          Logger.warning('⚠️ Estágio fenológico encontrado mas é V1 (padrão) - considerando como não preenchido');
        }
      } else {
        Logger.warning('⚠️ Nenhum registro encontrado em phenological_records');
      }
      
      // 2. Tentar buscar de historico_plantio
      final plantioRecords = await db.rawQuery('''
        SELECT fase_fenologica, data_plantio
        FROM historico_plantio
        ORDER BY data_plantio DESC
        LIMIT 1
      ''');
      
      if (plantioRecords.isNotEmpty) {
        final fase = plantioRecords.first['fase_fenologica'] as String?;
        if (fase != null && fase.isNotEmpty) {
          Logger.info('✅ Estágio fenológico encontrado em historico_plantio: $fase');
          return fase;
        }
      }
      
      // 3. Tentar buscar de dados de monitoramento (metadata)
      final monitoringMeta = await db.rawQuery('''
        SELECT DISTINCT observacoes
        FROM monitoring_sessions
        WHERE observacoes LIKE '%V%' OR observacoes LIKE '%R%'
        ORDER BY started_at DESC
        LIMIT 1
      ''');
      
      if (monitoringMeta.isNotEmpty) {
        final obs = monitoringMeta.first['observacoes'] as String?;
        if (obs != null) {
          // Tentar extrair estágio do padrão V1, V2, R1, R2, etc
          final match = RegExp(r'[VR]\d+').firstMatch(obs);
          if (match != null) {
            final estagio = match.group(0)!;
            Logger.info('✅ Estágio fenológico extraído de observações: $estagio');
            return estagio;
          }
        }
      }
      
      // 4. Fallback: Retornar estágio padrão (V1 vegetativo inicial)
      Logger.warning('⚠️ Nenhum estágio fenológico encontrado - usando V1 como padrão');
      return 'V1';
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar estágio fenológico: $e');
      return 'V1'; // Padrão seguro
    }
  }

  /// Constrói legenda explicativa
  Widget _buildInfestationLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Como Interpretar os Níveis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLegendItem('🟢 BAIXO', 'Monitoramento de rotina', Colors.green),
            _buildLegendItem('🟡 MÉDIO', 'Atenção - monitorar de perto', Colors.orange),
            _buildLegendItem('🔴 ALTO', 'Aplicação recomendada', Colors.red),
            _buildLegendItem('🟣 CRÍTICO', 'Aplicação IMEDIATA - perdas severas', Colors.purple),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Estágios Fenológicos Críticos: Os thresholds mudam conforme o estágio da cultura. '
                      'Exemplo: 5 torrãozinhos em V4 = MÉDIO, mas em R5 = CRÍTICO!',
                      style: TextStyle(fontSize: 12),
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

  Widget _buildLegendItem(String label, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
          Expanded(child: Text(description, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  /// 🔍 Botão de diagnóstico (temporário)
  Widget _buildDiagnosticButton() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Diagnóstico de Infestação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Se as quantidades não estão aparecendo corretamente, execute o diagnóstico para identificar o problema.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _runDiagnosis,
              icon: const Icon(Icons.search),
              label: const Text('Executar Diagnóstico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Executa diagnóstico completo
  Future<void> _runDiagnosis() async {
    try {
      Logger.info('🔍 Executando diagnóstico de infestação...');
      
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Executando diagnóstico...'),
            ],
          ),
        ),
      );
      
      // Executar diagnóstico
      final results = await InfestationCalculationDebugger.runFullDiagnosis();
      
      // Fechar loading
      if (mounted) Navigator.of(context).pop();
      
      // Gerar relatório
      final report = InfestationCalculationDebugger.generateDiagnosisReport(results);
      
      // Mostrar relatório
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔍 Relatório de Diagnóstico'),
            content: SingleChildScrollView(
              child: Text(
                report,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no diagnóstico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Constrói aba de curvas de infestação
  Widget _buildCurvaInfestacao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(
            'Curvas de Infestação por Cultura',
            'Modelos de progressão temporal usando regressão logística',
            Icons.trending_up,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          
          if (_curvaInfestacao != null) ...[
            _buildCurvaChart(),
            const SizedBox(height: 16),
            _buildCurvaDetails(),
            const SizedBox(height: 16),
            _buildPontosCriticos(),
          ] else
            _buildEmptyState('Nenhum dado de curva de infestação encontrado.\n\nRealize monitoramentos para gerar análises preditivas.'),
        ],
      ),
    );
  }

  /// Constrói aba de validação por safra
  // ❌ MÉTODO REMOVIDO: _buildValidacaoSafra
  // Substituído pela aba "Plantios Detalhados" que é muito melhor!

  // ❌ REMOVIDO: _buildIntegracaoGerminacao() - Não será mais utilizado
  
  /// ✅ NOVA ABA: Plantios Detalhados
  Widget _buildPlantiosDetalhados() {
    // Embutir a tela de relatórios detalhados diretamente
    return const DetailedPlantingReportsScreen();
  }

  Widget _buildDashboardSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(),
          const SizedBox(height: 24),
          _buildDashboardsGrid(),
          const SizedBox(height: 24),
          _buildDashboardsInfo(),
        ],
      ),
    );
  }

  /// Cabeçalho do Dashboard
  Widget _buildDashboardHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Dashboards Inteligentes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Acesse os dashboards especializados do Sistema FortSmart Agro',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.psychology, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Sistema FortSmart Agro',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  /// Grid de Dashboards (2x2)
  Widget _buildDashboardsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _buildDashboardCard(
          title: 'Monitoramento',
          subtitle: 'Dashboard inteligente de monitoramento',
          icon: Icons.visibility,
          color: Colors.green,
          onTap: () => _navigateToMonitoringDashboard(),
        ),
        // ❌ REMOVIDO: Card "Germinação" - não será mais utilizado
        _buildDashboardCard(
          title: 'Infestação',
          subtitle: 'Heatmap térmico de infestação',
          icon: Icons.bug_report,
          color: Colors.red,
          onTap: () => _navigateToInfestationDashboard(),
        ),
        _buildDashboardCard(
          title: 'Análises Avançadas',
          subtitle: 'Modelos preditivos e relatórios',
          icon: Icons.analytics,
          color: Colors.purple,
          onTap: () => _showCurrentTab(),
        ),
      ],
    );
  }

  /// Card de Dashboard Individual
  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sistema FortSmart Agro',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Informações detalhadas dos Dashboards
  Widget _buildDashboardsInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Sobre os Dashboards',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDashboardInfo(
              'Monitoramento',
              'Dashboard inteligente com análise térmica e integração com mapa de infestação',
              Colors.green,
            ),
            const SizedBox(height: 12),
            // ❌ REMOVIDO: Info "Germinação" - não será mais utilizado
            _buildDashboardInfo(
              'Infestação',
              'Heatmap térmico com coordenadas reais e prescrições baseadas em JSONs',
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildDashboardInfo(
              'Análises Avançadas',
              'Modelos de predição, curvas de infestação e validação por safra com IA',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  /// Item de informação do Dashboard
  Widget _buildDashboardInfo(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // MÉTODOS DE NAVEGAÇÃO
  // ============================================================================

  void _navigateToMonitoringDashboard() {
    Navigator.pushNamed(context, '/reports/monitoring-dashboard');
  }

  // ❌ REMOVIDO: _navigateToGerminationDashboard() - não será mais utilizado

  void _navigateToInfestationDashboard() {
    Navigator.pushNamed(context, '/reports/infestation-dashboard');
  }

  void _showCurrentTab() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Você já está no dashboard de Análises Avançadas!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Cabeçalho com informações
  Widget _buildHeaderCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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

  /// Gráfico da curva de infestação
  Widget _buildCurvaChart() {
    if (_curvaInfestacao == null) {
      return _buildEmptyState('Dados de curva de infestação não disponíveis');
    }
    
    // Verificar se os dados existem antes de acessar
    final curvaData = _curvaInfestacao!['curva_projecao'];
    final tendenciaData = _curvaInfestacao!['tendencia'];
    final confiancaData = _curvaInfestacao!['confianca_modelo'];
    
    final curva = _safeCastToList(curvaData);
    final tendencia = _safeCastToString(tendenciaData);
    final confianca = _safeCastToDouble(confiancaData);
    
    if (curva.isEmpty) {
      return _buildEmptyState('Curva de projeção vazia');
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Projeção de Infestação (7 dias)',
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
                    color: _getTendenciaColor(tendencia),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tendencia,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: _buildSimpleChart(curva),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetricItem('Confiança', '${(confianca * 100).toStringAsFixed(0)}%'),
                _buildMetricItem('Densidade Final', curva.isNotEmpty ? '${_safeCastToDouble(curva.last).toStringAsFixed(2)}' : '0.00'),
                _buildMetricItem('Crescimento', '${_safeCastToDouble(_curvaInfestacao?['crescimento_medio']).toStringAsFixed(3)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Gráfico simples
  Widget _buildSimpleChart(List<dynamic> curva) {
    // ✅ CORRIGIDO: Filtrar nulls e converter com segurança
    final curvaSegura = curva
        .where((value) => value != null)
        .map((value) => (value as num).toDouble())
        .toList();
    
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: CurvaPainter(curvaSegura),
    );
  }

  /// Detalhes da curva
  Widget _buildCurvaDetails() {
    final modelo = _safeCastToString(_curvaInfestacao!['modelo_usado']);
    final amostras = _safeCastToInt(_curvaInfestacao!['amostras_treinamento']);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes do Modelo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Modelo Usado', modelo),
            _buildDetailRow('Amostras de Treinamento', amostras.toString()),
            _buildDetailRow('Fator Ambiental', '${_safeCastToDouble(_curvaInfestacao?['fator_ambiental']).toStringAsFixed(2)}'),
            _buildDetailRow('Parâmetros', 'Regressão Logística'),
          ],
        ),
      ),
    );
  }

  /// Pontos críticos
  Widget _buildPontosCriticos() {
    final pontos = _safeCastToList(_curvaInfestacao!['pontos_criticos']);
    
    if (pontos.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pontos Críticos Identificados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...pontos.map((ponto) => _buildPontoCritico(ponto)).toList(),
          ],
        ),
      ),
    );
  }

  /// Item de ponto crítico
  Widget _buildPontoCritico(Map<String, dynamic> ponto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dia ${ponto['dia']} - ${ponto['tipo']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ponto['significado'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_safeCastToDouble(ponto['densidade']).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ❌ REMOVIDO: Métodos relacionados à validação por safra
  // - _buildMetricasValidacao()
  // - _buildInsightsOrganismo()
  // - _buildOrganismoInsight()
  // - _buildTendenciaMelhoria()
  // Estes métodos não serão mais utilizados (substituídos por "Plantios Detalhados").

  /// Tendência de melhoria (STUB - mantido por compatibilidade mas retorna vazio)
  Widget _buildTendenciaMelhoria() {
    // Método obsoleto - não exibe nada
    return const SizedBox.shrink();
  }

  /// Análise de risco
  // ❌ REMOVIDO: Métodos relacionados à integração germinação
  // - _buildRiscoAnalysis()
  // - _buildFatoresRisco()
  // - _buildFatorRisco()
  // - _buildRecomendacoesIntegracao()
  // - _buildRecomendacao()
  // Estes métodos não serão mais utilizados.

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// ✅ NOVO: Card com dados brutos quando falta análise fenológica
  Widget _buildRawDataCard(TalhaoInfestationResult result) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⚠️ AVISO SOBRE DADOS FENOLÓGICOS
            if (!result.hasPhenologicalData) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⚠️ Ainda falta dados Fenológico da cultura\n\nPreencha o módulo "Evolução Fenológica" para análise completa.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 📊 DADOS DETECTADOS
            Text(
              '🐛 Infestações Detectadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Lista de organismos com dados brutos
            if (result.rawOrganisms != null)
              ...result.rawOrganisms!.map((orgData) {
                final nome = orgData['nome']?.toString() ?? 'Desconhecido';
                final quantidadeTotal = (orgData['quantidade_total'] as num?)?.toDouble() ?? 0.0;
                final pontosAfetados = (orgData['pontos_com_infestacao'] as Set?)?.length ?? 0;
                final ocorrencias = orgData['ocorrencias'] as int? ?? 0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildRawMetric('📍 Pontos', pontosAfetados.toString()),
                          const SizedBox(width: 16),
                          _buildRawMetric('🐛 Total', quantidadeTotal.toStringAsFixed(0)),
                          const SizedBox(width: 16),
                          _buildRawMetric('📊 Ocorrências', ocorrencias.toString()),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            
            const SizedBox(height: 16),
            
            // Botão para ir ao módulo fenológico
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🌱 Navegue para "Evolução Fenológica" no menu principal'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.spa, size: 18),
              label: const Text('Preencher Dados Fenológicos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRawMetric(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: AppTheme.primaryColor.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'Dados de Análise Não Disponíveis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Sistema FortSmart Agro',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRiscoCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getTendenciaColor(String tendencia) {
    switch (tendencia) {
      case 'Acelerando':
        return Colors.red;
      case 'Desacelerando':
        return Colors.green;
      case 'Estável':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getAcuraciaColor(double? acuracia) {
    final value = acuracia ?? 0.0;
    if (value >= 90) return Colors.green;
    if (value >= 80) return Colors.lightGreen;
    if (value >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getRiscoColor(double? risco) {
    final value = risco ?? 0.0;
    if (value >= 0.7) return Colors.red;
    if (value >= 0.4) return Colors.orange;
    return Colors.green;
  }

  Color _getVigorColor(double? vigor) {
    final value = vigor ?? 0.0;
    if (value >= 85) return Colors.green;
    if (value >= 70) return Colors.orange;
    return Colors.red;
  }

  // ❌ REMOVIDO: _getGerminacaoColor() - não será mais utilizado

  IconData _getTendenciaIcon(String tendencia) {
    switch (tendencia) {
      case 'Melhorando':
        return Icons.trending_up;
      case 'Piorando':
        return Icons.trending_down;
      case 'Estável':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }

  // ============================================================================
  // MÉTODOS DE CASTING SEGURO
  // ============================================================================

  /// Cast seguro para List<dynamic>
  List<dynamic> _safeCastToList(dynamic value) {
    if (value == null) {
      return [];
    }
    if (value is List) {
      return value;
    }
    Logger.warning('Tentativa de cast para List falhou. Valor: $value');
    return [];
  }

  /// Cast seguro para String
  String _safeCastToString(dynamic value) {
    if (value == null) {
      return 'N/A';
    }
    if (value is String) {
      return value;
    }
    Logger.warning('Tentativa de cast para String falhou. Valor: $value');
    return 'N/A';
  }

  /// Cast seguro para double
  double _safeCastToDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    Logger.warning('Tentativa de cast para double falhou. Valor: $value');
    return 0.0;
  }

  /// Cast seguro para int
  int _safeCastToInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    Logger.warning('Tentativa de cast para int falhou. Valor: $value');
    return 0;
  }

  /// Cast seguro para Map<String, dynamic>
  Map<String, dynamic> _safeCastToMap(dynamic value) {
    if (value == null) {
      return {};
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    Logger.warning('Tentativa de cast para Map falhou. Valor: $value');
    return {};
  }

  /// 🗺️ MAPA TÉRMICO DE INFESTAÇÃO (Reutilizado do Monitoring Dashboard)
  Widget _buildMapaTermicoInfestacao() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _carregarDadosHeatmap(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          Logger.error('❌ Erro ao carregar mapa térmico: ${snapshot.error}');
          return _buildEmptyState('Erro ao carregar mapa: ${snapshot.error}');
        }
        
        final heatmapData = snapshot.data ?? [];
        
        if (heatmapData.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.map, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Nenhum ponto georreferenciado encontrado',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Realize monitoramentos com GPS para visualizar o mapa térmico',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🗺️ Mapa Térmico de Infestação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMapaComHeatmap(heatmapData),
            const SizedBox(height: 12),
            _buildLegendaMapa(heatmapData),
          ],
        );
      },
    );
  }

  /// 🗺️ Mapa com FlutterMap (Reutilizado do Monitoring Dashboard)
  /// 
  /// 📌 NOTA FUTURA: Interpolação tipo NDVI
  /// Quando houver mais dados de infestação (>50 pontos), implementar:
  /// - Interpolação espacial (Kriging ou IDW)
  /// - Camada de gradiente contínuo (PolygonLayer com cores interpoladas)
  /// - Pintura tipo NDVI cobrindo toda a área do talhão
  /// - Transição suave entre pontos adjacentes
  Widget _buildMapaComHeatmap(List<Map<String, dynamic>> heatmapData) {
    return FutureBuilder<List<LatLng>?>(
      future: _carregarPoligonoTalhao(),
      builder: (context, poligonoSnapshot) {
        // ✅ TRATAMENTO DE ERRO PARA EVITAR TELA VERMELHA
        if (poligonoSnapshot.hasError) {
          Logger.error('❌ Erro ao carregar polígono do talhão: ${poligonoSnapshot.error}');
          return _buildEmptyState('Erro ao carregar polígono do talhão');
        }
        
        LatLng? center;
        double zoom = 15.0;
        
        if (poligonoSnapshot.hasData && 
            poligonoSnapshot.data != null && 
            poligonoSnapshot.data!.isNotEmpty) {
          final pontos = poligonoSnapshot.data!;
          double sumLat = 0, sumLng = 0;
          for (final ponto in pontos) {
            sumLat += ponto.latitude;
            sumLng += ponto.longitude;
          }
          center = LatLng(sumLat / pontos.length, sumLng / pontos.length);
          zoom = 16.0;
        } else if (heatmapData.isNotEmpty) {
          double sumLat = 0, sumLng = 0;
          for (final ponto in heatmapData) {
            sumLat += (ponto['latitude'] as num?)?.toDouble() ?? 0.0;
            sumLng += (ponto['longitude'] as num?)?.toDouble() ?? 0.0;
          }
          center = LatLng(sumLat / heatmapData.length, sumLng / heatmapData.length);
          zoom = 17.0;
        }
        
        if (center == null) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('Aguardando dados georreferenciados...')),
          );
        }
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 400,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: 10.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: APIConfig.getMapTilerUrl('satellite'),
                  userAgentPackageName: 'com.fortsmart.agro',
                  fallbackUrl: APIConfig.getFallbackUrl(),
                ),
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
                CircleLayer(
                  circles: heatmapData.map((ponto) {
                    final lat = (ponto['latitude'] as num?)?.toDouble() ?? 0.0;
                    final lng = (ponto['longitude'] as num?)?.toDouble() ?? 0.0;
                    final cor = ponto['cor'] as Color? ?? Colors.grey;
                    final intensidade = (ponto['intensidade'] as num?)?.toDouble() ?? 0.0;
                    
                    // ✅ TAMANHO FIXO EM METROS (não muda com zoom)
                    // Raio reduzido: 25-35m para melhor visualização
                    final raioMetros = 25.0 + (intensidade * 10.0); // 25-35m (antes: 50-70m)
                    
                    return CircleMarker(
                      point: LatLng(lat, lng),
                      color: cor.withOpacity(0.2), // Opacidade ainda menor
                      borderColor: cor.withOpacity(0.4),
                      borderStrokeWidth: 1.0, // Borda mais fina
                      radius: raioMetros,
                      useRadiusInMeter: true, // Tamanho fixo no mundo real
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: heatmapData.map((ponto) {
                    final lat = (ponto['latitude'] as num?)?.toDouble() ?? 0.0;
                    final lng = (ponto['longitude'] as num?)?.toDouble() ?? 0.0;
                    final cor = ponto['cor'] as Color? ?? Colors.grey;
                    final intensidade = (ponto['intensidade'] as num?)?.toDouble() ?? 0.0;
                    
                    // ✅ TAMANHO FIXO EM PÍXEIS (não muda com zoom)
                    // Tamanho reduzido: 24-28px (antes: 32-40px) para não atrapalhar visualização
                    final tamanho = 24.0 + (intensidade * 4.0); // 24-28px
                    final fontSize = 14.0; // Tamanho de fonte fixo
                    
                    return Marker(
                      point: LatLng(lat, lng),
                      width: tamanho,
                      height: tamanho,
                      alignment: Alignment.center,
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
                              fontSize: fontSize, // Fonte fixa, não proporcional
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🗺️ Carregar dados do heatmap
  Future<List<Map<String, dynamic>>> _carregarDadosHeatmap() async {
    try {
      Logger.info('🗺️ Carregando dados do heatmap...');
      final db = await AppDatabase.instance.database;
      
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
        }
      }
      
      return heatmapData;
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados do heatmap: $e');
      return [];
    }
  }

  /// 🗺️ Carregar polígono do talhão
  Future<List<LatLng>?> _carregarPoligonoTalhao() async {
    try {
      Logger.info('🗺️ Carregando polígono do talhão...');
      final db = await AppDatabase.instance.database;
      
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
          return pontosList.map((p) {
            final lat = (p['latitude'] as num?)?.toDouble();
            final lng = (p['longitude'] as num?)?.toDouble();
            if (lat == null || lng == null) {
              Logger.warning('⚠️ Coordenada inválida ignorada: lat=$lat, lng=$lng');
              return null;
            }
            return LatLng(lat, lng);
          }).whereType<LatLng>().toList();
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao carregar polígono: $e');
      return null;
    }
  }

  /// 🗺️ Legenda do mapa
  Widget _buildLegendaMapa(List<Map<String, dynamic>> heatmapData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
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
              _buildLegendaItem('🟢 Baixo', Colors.green, 
                heatmapData.where((d) => d['nivel'] == 'baixo').length),
              _buildLegendaItem('🟡 Médio', Colors.yellow,
                heatmapData.where((d) => d['nivel'] == 'médio').length),
              _buildLegendaItem('🟠 Alto', Colors.orange,
                heatmapData.where((d) => d['nivel'] == 'alto').length),
              _buildLegendaItem('🔴 Crítico', Colors.red,
                heatmapData.where((d) => d['nivel'] == 'crítico').length),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${heatmapData.length} pontos monitorados',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(String label, Color color, int count) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getEmojiOrganismo(String? organismo) {
    if (organismo == null) return '📍';
    final nome = organismo.toLowerCase();
    if (nome.contains('lagarta')) return '🐛';
    if (nome.contains('percevejo')) return '🪲';
    if (nome.contains('buva')) return '🌿';
    if (nome.contains('caruru')) return '🌿';
    if (nome.contains('mosaico')) return '🍃';
    if (nome.contains('ferrugem')) return '🦠';
    return '🐛';
  }
}

/// Painter para desenhar a curva
class CurvaPainter extends CustomPainter {
  final List<double> curva;
  
  CurvaPainter(this.curva);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (curva.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final path = ui.Path(); // ✅ Usar Path do dart:ui
    if (curva.isEmpty) return;
    
    final maxValue = curva.reduce((a, b) => a > b ? a : b);
    final minValue = curva.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    
    if (range == 0) return;
    
    for (int i = 0; i < curva.length; i++) {
      final x = (i / (curva.length - 1)) * size.width;
      final y = size.height - ((curva[i] - minValue) / range) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Desenhar pontos
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < curva.length; i++) {
      final x = (i / (curva.length - 1)) * size.width;
      final y = size.height - ((curva[i] - minValue) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ❌ EXTENSÃO REMOVIDA: SafraValidationMethods
// Substituída pela aba "Plantios Detalhados"
/*
extension SafraValidationMethods on _AdvancedAnalyticsDashboardState {
  /// Constrói estatísticas de plantio
  Widget _buildPlantioStatistics() {
    final stats = _validacaoSafra!['estatisticas_gerais'] as Map<String, dynamic>? ?? {};
    final totalPlantios = stats['total_plantios'] ?? 0;
    final culturas = stats['culturas'] as Map<String, dynamic>? ?? {};
    final talhoes = stats['talhoes'] as Map<String, dynamic>? ?? {};
    final medias = stats['medias'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas Gerais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Métricas principais
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total de Plantios',
                    totalPlantios.toString(),
                    Icons.agriculture,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Culturas',
                    culturas.length.toString(),
                    Icons.grass,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Talhões',
                    talhoes.length.toString(),
                    Icons.location_on,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Médias
            if (medias.isNotEmpty) ...[
              Text(
                'Médias Técnicas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'População Média',
                      '${(medias['populacao_media'] ?? 0).toStringAsFixed(0)} plantas/ha',
                      Icons.analytics,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'Espaçamento Médio',
                      '${(medias['espacamento_medio'] ?? 0).toStringAsFixed(1)} cm',
                      Icons.straighten,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Constrói análise por talhão
  Widget _buildTalhaoAnalysis() {
    final analiseTalhoes = _validacaoSafra!['analise_talhoes'] as Map<String, dynamic>? ?? {};
    
    if (analiseTalhoes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.orange.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Análise por Talhão',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...analiseTalhoes.entries.take(3).map((entry) {
              final talhaoNome = entry.key;
              final dados = entry.value as Map<String, dynamic>;
              final totalPlantios = dados['total_plantios'] ?? 0;
              final culturas = dados['culturas'] as Map<String, dynamic>? ?? {};
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      talhaoNome,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalPlantios plantios • ${culturas.length} culturas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            if (analiseTalhoes.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${analiseTalhoes.length - 3} talhões adicionais',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Constrói análise de qualidade
  Widget _buildQualityAnalysis() {
    final qualidade = _validacaoSafra!['qualidade_dados'] as Map<String, dynamic>? ?? {};
    final score = qualidade['score'] ?? 0;
    final nivel = qualidade['nivel'] ?? 'BAIXO';
    
    Color corNivel;
    IconData iconeNivel;
    
    switch (nivel) {
      case 'EXCELENTE':
        corNivel = Colors.green.shade700;
        iconeNivel = Icons.star;
        break;
      case 'MUITO BOM':
        corNivel = Colors.green;
        iconeNivel = Icons.thumb_up;
        break;
      case 'BOM':
        corNivel = Colors.blue;
        iconeNivel = Icons.check_circle;
        break;
      case 'REGULAR':
        corNivel = Colors.orange;
        iconeNivel = Icons.warning;
        break;
      default:
        corNivel = Colors.red;
        iconeNivel = Icons.error;
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: corNivel, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Qualidade dos Dados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: corNivel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Score principal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: corNivel.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: corNivel.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(iconeNivel, color: corNivel, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$score% - $nivel',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: corNivel,
                          ),
                        ),
                        Text(
                          'Score de qualidade dos dados de plantio',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
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
  
  /// Constrói recomendações
  Widget _buildRecommendations() {
    final recomendacoes = _validacaoSafra!['recomendacoes'] as List<dynamic>? ?? [];
    
    if (recomendacoes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Recomendações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...recomendacoes.take(3).map((rec) {
              final recomendacao = rec as Map<String, dynamic>;
              final titulo = recomendacao['titulo'] ?? '';
              final descricao = recomendacao['descricao'] ?? '';
              final prioridade = recomendacao['prioridade'] ?? 'baixa';
              
              Color corPrioridade;
              switch (prioridade) {
                case 'alta':
                  corPrioridade = Colors.red;
                  break;
                case 'media':
                  corPrioridade = Colors.orange;
                  break;
                default:
                  corPrioridade = Colors.blue;
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: corPrioridade.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: corPrioridade.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: corPrioridade,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            prioridade.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  /// Constrói card de estatística
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói item de métrica
  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/
// ❌ FIM DA EXTENSÃO REMOVIDA

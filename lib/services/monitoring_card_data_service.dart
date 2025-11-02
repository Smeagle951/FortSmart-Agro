import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../database/app_database.dart';
import '../utils/logger.dart';
import 'phenological_infestation_service.dart'; // ✅ Usa cálculos dos JSONs + Regras
import 'organism_recommendations_service.dart'; // ✅ NOVO: Recomendações dos JSONs

/// 🌾 SERVIÇO CENTRAL: Carrega dados consolidados para o Card de Monitoramento
/// ✅ Única fonte de verdade
/// ✅ Queries otimizadas
/// ✅ Fallbacks seguros
/// ✅ USA cálculos dos JSONs dos organismos
/// ✅ PRIORIZA regras customizadas do módulo "Regras de Infestação"
/// ✅ RECOMENDAÇÕES específicas dos JSONs dos organismos
class MonitoringCardDataService {
  static const String _tag = 'CARD_DATA_SVC';
  final PhenologicalInfestationService _infestationService = PhenologicalInfestationService();
  final OrganismRecommendationsService _recommendationsService = OrganismRecommendationsService(); // ✅ NOVO

  /// Carrega dados consolidados de uma sessão de monitoramento
  Future<MonitoringCardData> loadCardData({
    required String sessionId,
    String? talhaoId,
  }) async {
    try {
      Logger.info('🔍 [$_tag] Carregando dados do card para sessão: $sessionId');
      
      final db = await AppDatabase.instance.database;
      
      // 1️⃣ BUSCAR SESSÃO
      final sessions = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      
      if (sessions.isEmpty) {
        throw Exception('Sessão não encontrada: $sessionId');
      }
      
      final session = sessions.first;
      final sessionTalhaoId = session['talhao_id']?.toString() ?? talhaoId ?? '';
      
      // 2️⃣ BUSCAR OCORRÊNCIAS (TODAS, sem filtros restritivos)
      Logger.info('🔍 [$_tag] Buscando ocorrências para sessão: $sessionId');
      
      final occurrences = await db.rawQuery('''
        SELECT 
          mo.*,
          mp.latitude,
          mp.longitude,
          mp.numero as ponto_numero
        FROM monitoring_occurrences mo
        INNER JOIN monitoring_points mp ON mp.id = mo.point_id
        WHERE mo.session_id = ?
        ORDER BY mo.data_hora DESC
      ''', [sessionId]);
      
      Logger.info('✅ [$_tag] ${occurrences.length} ocorrências encontradas (TODAS)');
      
      // 🐛 DEBUG: Mostrar primeiras 3 ocorrências com detalhes
      for (var i = 0; i < occurrences.length && i < 3; i++) {
        final occ = occurrences[i];
        final fotoPathsStr = occ['foto_paths']?.toString() ?? '';
        final fotoPathsPreview = fotoPathsStr.length > 50 ? fotoPathsStr.substring(0, 50) + '...' : fotoPathsStr;
        
        Logger.info('   🔍 Ocorrência $i:');
        Logger.info('      - organism_name: ${occ['organism_name']}');
        Logger.info('      - quantidade: ${occ['quantidade']} (tipo: ${occ['quantidade'].runtimeType})');
        Logger.info('      - agronomic_severity: ${occ['agronomic_severity']} (tipo: ${occ['agronomic_severity'].runtimeType})');
        Logger.info('      - foto_paths: $fotoPathsPreview');
      }
      
      // 3️⃣ BUSCAR PONTOS ÚNICOS
      final pointsResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT mp.id) as total
        FROM monitoring_points mp
        WHERE mp.session_id = ?
      ''', [sessionId]);
      
      var totalPontos = (pointsResult.first['total'] as num?)?.toInt() ?? 0;
      
      // ✅ FALLBACK: Usar pontos únicos das ocorrências
      if (totalPontos == 0 && occurrences.isNotEmpty) {
        totalPontos = occurrences.map((o) => o['point_id']).toSet().length;
        Logger.warning('⚠️ [$_tag] Total pontos = 0, usando fallback: $totalPontos');
      }
      
      // 4️⃣ BUSCAR ESTÁGIO FENOLÓGICO (do submódulo Evolução Fenológica)
      final estagioFenologico = await _buscarEstagioFenologico(db, sessionTalhaoId, session['cultura_nome']?.toString() ?? '');
      
      // 4.5️⃣ BUSCAR DADOS COMPLEMENTARES SIMPLIFICADOS (População + DAE)
      final dadosComplementares = await _buscarDadosComplementaresSimplificados(db, sessionTalhaoId, session['cultura_nome']?.toString() ?? '');
      
      // 5️⃣ CALCULAR MÉTRICAS CONSOLIDADAS
      final metrics = _calculateMetrics(occurrences, totalPontos);
      
      // 6️⃣ BUSCAR DADOS AMBIENTAIS (reais da sessão)
      final temperatura = (session['temperatura'] as num?)?.toDouble() ?? 0.0;
      final umidade = (session['umidade'] as num?)?.toDouble() ?? 0.0;
      
      // 7️⃣ BUSCAR IMAGENS
      final totalFotos = await _countPhotos(db, sessionId);
      
      // 8️⃣ PROCESSAR ORGANISMOS DETECTADOS (com cálculos dos JSONs + regras customizadas)
      final organismos = await _processOrganismsWithInfestationCalc(
        occurrences, 
        totalPontos,
        session['cultura_nome']?.toString() ?? 'soja',
        estagioFenologico,
      );
      
      // 8️⃣ GERAR RECOMENDAÇÕES (Gerais + dos JSONs)
      final recomendacoes = await _generateRecommendationsWithJSONs(
        organismos, 
        metrics['nivelRisco'] as String,
        session['cultura_nome']?.toString() ?? 'soja',
        estagioFenologico,
      );
      
      // 9️⃣ MONTAR OBJETO CONSOLIDADO (com dados complementares)
      final cardData = MonitoringCardData(
        sessionId: sessionId,
        talhaoId: sessionTalhaoId,
        talhaoNome: session['talhao_nome']?.toString() ?? 'Talhão $sessionTalhaoId',
        culturaNome: session['cultura_nome']?.toString() ?? 'Não informada',
        status: session['status']?.toString() ?? 'active',
        dataInicio: session['started_at']?.toString() ?? DateTime.now().toIso8601String(),
        dataFim: session['finished_at']?.toString(),
        totalPontos: totalPontos,
        totalOcorrencias: occurrences.length,
        totalPragas: metrics['totalPragas'] as int,
        severidadeMedia: metrics['severidadeMedia'] as double,
        quantidadeMedia: metrics['quantidadeMedia'] as double,
        nivelRisco: metrics['nivelRisco'] as String,
        temperatura: temperatura,
        umidade: umidade,
        totalFotos: totalFotos,
        organismosDetectados: organismos,
        recomendacoes: recomendacoes,
        alertas: _generateAlerts(organismos, metrics['nivelRisco'] as String),
        confiancaDados: _calculateConfidence(occurrences, totalPontos),
        // ✅ DADOS COMPLEMENTARES SIMPLIFICADOS
        estagioFenologico: estagioFenologico,
        populacao: dadosComplementares['populacao'] as double?,
        dae: dadosComplementares['dae'] as int?,
      );
      
      Logger.info('✅ [$_tag] Card data carregado com sucesso!');
      Logger.info('   • Talhão: ${cardData.talhaoNome}');
      Logger.info('   • Cultura: ${cardData.culturaNome}');
      Logger.info('   • Pontos: ${cardData.totalPontos}');
      Logger.info('   • Ocorrências: ${cardData.totalOcorrencias}');
      Logger.info('   • Nível de Risco: ${cardData.nivelRisco}');
      Logger.info('   • Confiança: ${(cardData.confiancaDados * 100).toStringAsFixed(0)}%');
      
      return cardData;
      
    } catch (e, stack) {
      Logger.error('❌ [$_tag] Erro ao carregar dados do card: $e', null, stack);
      rethrow;
    }
  }
  
  /// Calcula métricas consolidadas
  Map<String, dynamic> _calculateMetrics(List<Map<String, dynamic>> occurrences, int totalPontos) {
    if (occurrences.isEmpty) {
      return {
        'totalPragas': 0,
        'quantidadeMedia': 0.0,
        'severidadeMedia': 0.0,
        'nivelRisco': 'BAIXO',
      };
    }
    
    // 🐛 DEBUG: Log detalhado de CADA ocorrência
    Logger.info('🔍 [$_tag] Analisando ${occurrences.length} ocorrências:');
    for (var i = 0; i < occurrences.length; i++) {
      final occ = occurrences[i];
      final qtd = occ['quantidade'];
      final sev = occ['agronomic_severity'];
      Logger.info('   Ocorrência $i: quantidade=$qtd, severidade=$sev');
    }
    
    // Soma total de pragas
    Logger.info('🧮 [$_tag] Calculando total de pragas...');
    final totalPragas = occurrences.fold<int>(
      0,
      (sum, occ) {
        final qtd = (occ['quantidade'] as num?)?.toInt() ?? 0;
        Logger.info('   + ${occ['organism_name']}: $qtd');
        return sum + qtd;
      },
    );
    Logger.info('   🎯 Total pragas: $totalPragas');
    
    // Média de quantidade (por ponto)
    final quantidadeMedia = totalPontos > 0 ? totalPragas / totalPontos : 0.0;
    Logger.info('   📊 Quantidade média: ${quantidadeMedia.toStringAsFixed(2)} (total: $totalPragas / pontos: $totalPontos)');
    
    // Média de severidade agronômica
    Logger.info('🧮 [$_tag] Calculando severidade média...');
    final somaSeveridade = occurrences.fold<double>(
      0.0,
      (sum, occ) {
        final sev = (occ['agronomic_severity'] as num?)?.toDouble() ?? 0.0;
        Logger.info('   + ${occ['organism_name']}: ${sev.toStringAsFixed(1)}%');
        return sum + sev;
      },
    );
    final severidadeMedia = occurrences.isNotEmpty ? (somaSeveridade / occurrences.length) : 0.0;
    Logger.info('   🎯 Severidade média: ${severidadeMedia.toStringAsFixed(2)}% (soma: ${somaSeveridade.toStringAsFixed(1)} / ocorrências: ${occurrences.length})');
    
    // Determinar nível de risco baseado na severidade média
    String nivelRisco;
    if (severidadeMedia >= 70) {
      nivelRisco = 'CRÍTICO';
    } else if (severidadeMedia >= 40) {
      nivelRisco = 'ALTO';
    } else if (severidadeMedia >= 20) {
      nivelRisco = 'MÉDIO';
    } else {
      nivelRisco = 'BAIXO';
    }
    
    Logger.info('📊 [$_tag] Métricas calculadas:');
    Logger.info('   • Total pragas: $totalPragas');
    Logger.info('   • Quantidade média: ${quantidadeMedia.toStringAsFixed(2)}');
    Logger.info('   • Severidade média: ${severidadeMedia.toStringAsFixed(2)}%');
    Logger.info('   • Nível de risco: $nivelRisco');
    
    return {
      'totalPragas': totalPragas,
      'quantidadeMedia': quantidadeMedia,
      'severidadeMedia': severidadeMedia,
      'nivelRisco': nivelRisco,
    };
  }
  
  /// Busca estágio fenológico para cálculos com JSONs
  /// ✅ ORIGEM: Submódulo "Evolução Fenológica" (phenological_records)
  Future<String> _buscarEstagioFenologico(Database db, String talhaoId, String culturaNome) async {
    try {
      // Buscar estágio fenológico mais recente
      // ✅ CORRIGIDO: usar fase_fenologica (nome correto da coluna)
      final phenoRecords = await db.rawQuery('''
        SELECT fase_fenologica as estagio_fenologico, data_registro 
        FROM phenological_records 
        WHERE talhao_id = ? OR cultura_nome = ?
        ORDER BY data_registro DESC 
        LIMIT 1
      ''', [talhaoId, culturaNome]);
      
      if (phenoRecords.isNotEmpty) {
        final estagio = phenoRecords.first['estagio_fenologico']?.toString() ?? 'V6';
        Logger.info('✅ [$_tag] Estágio fenológico encontrado: $estagio (do submódulo Evolução Fenológica)');
        return estagio;
      }
      
      // Fallback: estágio padrão baseado na cultura
      Logger.warning('⚠️ [$_tag] Nenhum estágio fenológico encontrado, usando fallback: V6');
      return 'V6'; // Estágio vegetativo médio como padrão
    } catch (e) {
      Logger.error('❌ [$_tag] Erro ao buscar estágio fenológico: $e');
      return 'V6';
    }
  }
  
  /// ✅ SIMPLIFICADO: Busca apenas População e DAE
  /// ORIGEM:
  /// • População → estande_plantas
  /// • DAE → calculado a partir da data de plantio (historico_plantio)
  Future<Map<String, dynamic>> _buscarDadosComplementaresSimplificados(Database db, String talhaoId, String culturaNome) async {
    Logger.info('🔍 [$_tag] Buscando dados complementares simplificados...');
    
    final dados = <String, dynamic>{
      'populacao': null,
      'dae': null, // Dias Após Emergência
    };
    
    try {
      // 1️⃣ BUSCAR POPULAÇÃO (do submódulo Estande de Plantas)
      // ✅ CORRIGIDO: usar plantas_por_hectare (nome correto da coluna)
      final estandeRecords = await db.rawQuery('''
        SELECT plantas_por_hectare as populacao_media, created_at as data_calculo
        FROM estande_plantas
        WHERE talhao_id = ?
        ORDER BY created_at DESC
        LIMIT 1
      ''', [talhaoId]);
      
      if (estandeRecords.isNotEmpty) {
        dados['populacao'] = (estandeRecords.first['populacao_media'] as num?)?.toDouble();
        Logger.info('   ✅ População: ${dados['populacao']} plantas/m²');
      }
      
      // 2️⃣ CALCULAR DAE (Dias Após Emergência)
      // ✅ CORRIGIDO: usar coluna 'data' (nome correto na tabela)
      final plantioRecords = await db.rawQuery('''
        SELECT data, created_at
        FROM historico_plantio
        WHERE talhao_id = ?
        ORDER BY data DESC
        LIMIT 1
      ''', [talhaoId]);
      
      if (plantioRecords.isNotEmpty) {
        final record = plantioRecords.first;
        DateTime? dataPlantio;
        
        // ✅ CORRIGIDO: usar coluna 'data'
        if (record['data'] != null) {
          try {
            dataPlantio = DateTime.parse(record['data'].toString());
          } catch (e) {
            Logger.warning('   ⚠️ Erro ao parsear data: $e');
          }
        }
        
        // Calcular DAE a partir da data de plantio
        // Estimar emergência: geralmente 5-10 dias após plantio (média 7 dias)
        if (dataPlantio != null) {
          final dataEmergencia = dataPlantio.add(const Duration(days: 7));
          final hoje = DateTime.now();
          final dae = hoje.difference(dataEmergencia).inDays;
          
          if (dae >= 0) { // Só mostrar se já passou da emergência
            dados['dae'] = dae;
            Logger.info('   ✅ DAE: $dae dias (Dias Após Emergência estimada)');
          }
        }
      }
      
      if (dados['dae'] == null) {
        Logger.warning('   ⚠️ DAE não disponível (sem data de plantio/emergência)');
      }
      
      Logger.info('✅ [$_tag] Dados complementares simplificados carregados!');
      
    } catch (e) {
      Logger.error('❌ [$_tag] Erro ao buscar dados complementares: $e');
    }
    
    return dados;
  }
  
  /// ✅ NOVO: Processa organismos com cálculos dos JSONs + Regras Customizadas
  Future<List<OrganismSummary>> _processOrganismsWithInfestationCalc(
    List<Map<String, dynamic>> occurrences, 
    int totalPontos,
    String culturaNome,
    String estagioFenologico,
  ) async {
    if (occurrences.isEmpty) return [];
    
    // Inicializar serviço de infestação
    await _infestationService.initialize();
    
    final Map<String, Map<String, dynamic>> organismosMap = {};
    
    Logger.info('🧮 [$_tag] Processando ${occurrences.length} ocorrências com cálculos dos JSONs...');
    Logger.info('   📋 Cultura: $culturaNome');
    Logger.info('   🌱 Estágio fenológico: $estagioFenologico');
    
    for (final occ in occurrences) {
      final organismName = (occ['organism_name'] ?? 'Desconhecido').toString();
      final quantidade = (occ['quantidade'] as num?)?.toDouble() ?? 0.0;
      final severity = (occ['agronomic_severity'] as num?)?.toDouble() ?? 0.0;
      final pointId = occ['point_id'].toString();
      
      if (!organismosMap.containsKey(organismName)) {
        organismosMap[organismName] = {
          'nome': organismName,
          'pontos_afetados': <String>{},
          'quantidade_total': 0.0,
          'severidade_total': 0.0,
          'quantidade_maxima': 0.0,
          'ocorrencias': 0,
          'niveis_calculados': <String>[], // ✅ NOVO: armazenar níveis calculados
        };
      }
      
      final orgData = organismosMap[organismName]!;
      (orgData['pontos_afetados'] as Set<String>).add(pointId);
      orgData['quantidade_total'] = (orgData['quantidade_total'] as double) + quantidade;
      orgData['severidade_total'] = (orgData['severidade_total'] as double) + severity;
      orgData['ocorrencias'] = (orgData['ocorrencias'] as int) + 1;
      
      if (quantidade > (orgData['quantidade_maxima'] as double)) {
        orgData['quantidade_maxima'] = quantidade;
      }
      
      // ✅ NOVO: Calcular nível usando JSONs + Regras Customizadas
      try {
        final nivelCalculado = await _infestationService.calculateLevel(
          organismId: organismName,
          organismName: organismName,
          quantity: quantidade,
          phenologicalStage: estagioFenologico,
          cropId: culturaNome.toLowerCase(),
        );
        (orgData['niveis_calculados'] as List<String>).add(nivelCalculado.level);
        
        Logger.info('   ✅ $organismName: $quantidade → ${nivelCalculado.level}'); // ✅ Removido .threshold (não existe)
      } catch (e) {
        Logger.warning('   ⚠️ Erro ao calcular nível para $organismName: $e');
      }
    }
    
    // Converter para lista de OrganismSummary
    final organismos = organismosMap.entries.map((entry) {
      final orgData = entry.value;
      final pontosAfetados = (orgData['pontos_afetados'] as Set<String>).length;
      final frequencia = totalPontos > 0 ? (pontosAfetados / totalPontos) * 100 : 0.0;
      final ocorrencias = orgData['ocorrencias'] as int;
      final quantidadeMedia = ocorrencias > 0 ? (orgData['quantidade_total'] as double) / ocorrencias : 0.0;
      final severidadeMedia = ocorrencias > 0 ? (orgData['severidade_total'] as double) / ocorrencias : 0.0;
      
      return OrganismSummary(
        nome: orgData['nome'] as String,
        pontosAfetados: pontosAfetados,
        totalPontos: totalPontos,
        frequencia: frequencia,
        quantidadeTotal: orgData['quantidade_total'] as double,
        quantidadeMedia: quantidadeMedia,
        quantidadeMaxima: orgData['quantidade_maxima'] as double,
        severidadeMedia: severidadeMedia,
        totalOcorrencias: ocorrencias,
      );
    }).toList();
    
    // Ordenar por severidade (maior primeiro)
    organismos.sort((a, b) => b.severidadeMedia.compareTo(a.severidadeMedia));
    
    Logger.info('✅ [$_tag] ${organismos.length} organismos processados com cálculos dos JSONs!');
    
    return organismos;
  }
  
  /// Conta total de fotos (APENAS válidas!)
  Future<int> _countPhotos(Database db, String sessionId) async {
    try {
      final occurrences = await db.query(
        'monitoring_occurrences',
        columns: ['foto_paths'],
        where: 'session_id = ? AND foto_paths IS NOT NULL AND foto_paths != \'\' AND foto_paths != \'[]\' AND foto_paths != \'[""]\'',
        whereArgs: [sessionId],
      );
      
      int total = 0;
      for (final occ in occurrences) {
        final fotoPaths = occ['foto_paths']?.toString();
        if (fotoPaths != null && fotoPaths.isNotEmpty && fotoPaths != '[]' && fotoPaths != '[""]') {
          try {
            final List<dynamic> paths = jsonDecode(fotoPaths);
            // ✅ FILTRAR strings vazias ao contar
            final pathsValidos = paths.where((p) => p != null && p.toString().trim().isNotEmpty).toList();
            total += pathsValidos.length;
          } catch (_) {}
        }
      }
      
      Logger.info('📸 [$_tag] Total de fotos VÁLIDAS: $total');
      return total;
    } catch (e) {
      Logger.warning('⚠️ [$_tag] Erro ao contar fotos: $e');
      return 0;
    }
  }
  
  /// ✅ NOVO: Gera recomendações COMPLETAS (Gerais + dos JSONs)
  Future<List<String>> _generateRecommendationsWithJSONs(
    List<OrganismSummary> organismos, 
    String nivelRisco,
    String culturaNome,
    String estagioFenologico,
  ) async {
    final recomendacoes = <String>[];
    
    // 1️⃣ RECOMENDAÇÕES GERAIS (baseadas em nível de risco)
    if (organismos.isEmpty) {
      recomendacoes.add('✅ Continue o monitoramento regular do talhão');
      recomendacoes.add('✅ Mantenha as práticas de manejo atuais');
      return recomendacoes;
    }
    
    // Adicionar recomendações por nível de risco
    switch (nivelRisco) {
      case 'CRÍTICO':
        recomendacoes.add('🚨 AÇÃO URGENTE: Aplicar tratamento imediato');
        recomendacoes.add('⏰ Janela de ação: 24-48 horas');
        break;
      case 'ALTO':
        recomendacoes.add('⚠️ Programar aplicação nos próximos 3-5 dias');
        recomendacoes.add('📊 Monitorar evolução diária da infestação');
        break;
      case 'MÉDIO':
        recomendacoes.add('📋 Monitorar evolução nos próximos 7 dias');
        recomendacoes.add('💰 Avaliar custo-benefício de aplicação');
        break;
      default:
        recomendacoes.add('✅ Situação controlada');
        recomendacoes.add('📅 Manter monitoramento preventivo semanal');
    }
    
    // 2️⃣ RECOMENDAÇÕES ESPECÍFICAS DOS JSONs (por organismo)
    Logger.info('🧪 [$_tag] Buscando recomendações dos JSONs para ${organismos.length} organismo(s)...');
    
    for (final organismo in organismos.take(3)) { // Top 3 organismos mais críticos
      try {
        final dadosControle = await _recommendationsService.carregarDadosControle(
          culturaNome,      // ✅ Primeiro parâmetro: cultura
          organismo.nome,   // ✅ Segundo parâmetro: organismo
        );
        
        if (dadosControle != null && dadosControle.isNotEmpty) {
          Logger.info('   ✅ Recomendações encontradas para ${organismo.nome}');
          
          // Header do organismo - MAIS LEGÍVEL (sem caracteres especiais UTF-16)
          recomendacoes.add('');
          recomendacoes.add('=== ${organismo.nome.toUpperCase()} - Risco ${organismo.nivelRisco} ===');
          recomendacoes.add('');
          
          // ✅ CONTROLE QUÍMICO COM DOSES E MÉTODOS (usar campos corretos do JSON!)
          final quimico = dadosControle['manejo_quimico'] as List? ?? 
                         dadosControle['recomendacoes_controle']?['quimico'] as List?;
          if (quimico != null && quimico.isNotEmpty) {
            recomendacoes.add('💊 CONTROLE QUIMICO:');
            for (var i = 0; i < quimico.length && i < 4; i++) {
              var rec = quimico[i].toString();
              rec = _sanitizarTexto(rec);
              recomendacoes.add('   ${i + 1}. $rec');
            }
            recomendacoes.add('');
          }
          
          // ✅ DOSES DETALHADAS DOS DEFENSIVOS
          final dosesDefensivos = dadosControle['doses_defensivos'] as Map?;
          if (dosesDefensivos != null && dosesDefensivos.isNotEmpty) {
            recomendacoes.add('📋 DOSES RECOMENDADAS:');
            int count = 0;
            for (final entry in dosesDefensivos.entries.take(3)) {
              count++;
              final produto = entry.key.toString().replaceAll('_', ' ').toUpperCase();
              final info = entry.value as Map<String, dynamic>;
              final dose = info['dose']?.toString() ?? 'Consultar bula';
              recomendacoes.add('   $count. $produto: $dose');
            }
            recomendacoes.add('');
          }
          
          // ✅ CONTROLE BIOLÓGICO COM DETALHES
          final biologico = dadosControle['manejo_biologico'] as List? ?? 
                           dadosControle['recomendacoes_controle']?['biologico'] as List?;
          if (biologico != null && biologico.isNotEmpty) {
            recomendacoes.add('🦠 CONTROLE BIOLOGICO:');
            for (var i = 0; i < biologico.length && i < 3; i++) {
              recomendacoes.add('   ${i + 1}. ${_sanitizarTexto(biologico[i].toString())}');
            }
            recomendacoes.add('');
          }
          
          // ✅ PRÁTICAS CULTURAIS DETALHADAS
          final cultural = dadosControle['manejo_cultural'] as List? ??
                          dadosControle['recomendacoes_controle']?['cultural'] as List?;
          if (cultural != null && cultural.isNotEmpty) {
            recomendacoes.add('🌾 PRATICAS CULTURAIS:');
            for (var i = 0; i < cultural.length && i < 3; i++) {
              recomendacoes.add('   ${i + 1}. ${_sanitizarTexto(cultural[i].toString())}');
            }
            recomendacoes.add('');
          }
          
          // ✅ OBSERVAÇÕES DE MANEJO
          final observacoes = dadosControle['observacoes_importantes'] as List? ??
                             dadosControle['observacoes_manejo'] as List?;
          if (observacoes != null && observacoes.isNotEmpty) {
            recomendacoes.add('⚠️ OBSERVACOES IMPORTANTES:');
            for (var i = 0; i < observacoes.length && i < 3; i++) {
              recomendacoes.add('   - ${_sanitizarTexto(observacoes[i].toString())}');
            }
            recomendacoes.add('');
          }
          
          // ✅ INFORMAÇÕES TÉCNICAS (se disponível)
          final infoTecnica = dadosControle['info_tecnica'];
          if (infoTecnica != null) {
            final nomesCientificos = infoTecnica['nomes_cientificos'] as List?;
            if (nomesCientificos != null && nomesCientificos.isNotEmpty) {
              recomendacoes.add('');
              recomendacoes.add('Nome Cientifico: ${_sanitizarTexto(nomesCientificos.first.toString())}');
            }
          }
        } else {
          Logger.warning('   ⚠️ Nenhuma recomendação encontrada no JSON para ${organismo.nome}');
        }
      } catch (e) {
        Logger.warning('   ⚠️ Erro ao buscar recomendações para ${organismo.nome}: $e');
      }
    }
    
    // 3️⃣ RECOMENDAÇÃO DE FOCO
    final criticos = organismos.where((o) => o.severidadeMedia >= 70).toList();
    if (criticos.isNotEmpty) {
      recomendacoes.add('');
      recomendacoes.add('🎯 FOCO PRIORITÁRIO: ${criticos.map((o) => o.nome).join(', ')}');
    }
    
    Logger.info('✅ [$_tag] ${recomendacoes.length} recomendações geradas (gerais + JSONs)!');
    
    return recomendacoes;
  }
  
  /// Gera alertas baseados nos organismos e nível de risco
  List<String> _generateAlerts(List<OrganismSummary> organismos, String nivelRisco) {
    final alertas = <String>[];
    
    if (nivelRisco == 'CRÍTICO') {
      alertas.add('Nível crítico de infestação detectado');
    }
    
    for (final org in organismos) {
      if (org.frequencia >= 80) {
        alertas.add('${org.nome}: alta frequência (${org.frequencia.toStringAsFixed(0)}% dos pontos)');
      }
      if (org.severidadeMedia >= 70) {
        alertas.add('${org.nome}: severidade crítica (${org.severidadeMedia.toStringAsFixed(0)}%)');
      }
    }
    
    return alertas;
  }
  
  /// Calcula confiança nos dados (0.0 a 1.0)
  double _calculateConfidence(List<Map<String, dynamic>> occurrences, int totalPontos) {
    if (occurrences.isEmpty || totalPontos == 0) return 0.0;
    
    double confidence = 0.0;
    
    // Fator 1: Quantidade de dados (40%)
    final dataFactor = (occurrences.length / (totalPontos * 3)).clamp(0.0, 1.0) * 0.4;
    
    // Fator 2: Completude dos dados (30%)
    final completeOccurrences = occurrences.where((occ) =>
      occ['quantidade'] != null &&
      occ['agronomic_severity'] != null &&
      occ['organism_name'] != null
    ).length;
    final completenessFactor = (completeOccurrences / occurrences.length) * 0.3;
    
    // Fator 3: Cobertura de pontos (30%)
    final uniquePoints = occurrences.map((o) => o['point_id']).toSet().length;
    final coverageFactor = (uniquePoints / totalPontos).clamp(0.0, 1.0) * 0.3;
    
    confidence = dataFactor + completenessFactor + coverageFactor;
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// 🧹 Sanitiza texto para evitar erro UTF-16
  String _sanitizarTexto(String texto) {
    return texto
      .replaceAll('━', '-')  // Linha box-drawing
      .replaceAll('═', '=')  // Linha box-drawing dupla
      .replaceAll('│', '|')  // Linha vertical
      .replaceAll('└', '+')  // Canto
      .replaceAll('├', '+')  // Junção
      .replaceAll('─', '-')  // Linha horizontal
      .replaceAll('•', '-')  // Bullet especial
      .replaceAll('°', 'o')  // Grau
      .replaceAll('²', '2')  // Superscript
      .replaceAll('³', '3')  // Superscript
      .replaceAll('ª', 'a')  // Ordinal
      .replaceAll('º', 'o')  // Ordinal
      // Remover outros caracteres problemáticos se necessário
      .trim();
  }
  
  /// Carrega múltiplos cards (para lista de monitoramentos)
  Future<List<MonitoringCardData>> loadMultipleCards({
    String? talhaoId,
    String? culturaNome,
    int limit = 10,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Buscar sessões filtradas
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (culturaNome != null) {
        whereClause += ' AND cultura_nome = ?';
        whereArgs.add(culturaNome);
      }
      
      final sessions = await db.query(
        'monitoring_sessions',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'started_at DESC',
        limit: limit,
      );
      
      Logger.info('🔍 [$_tag] ${sessions.length} sessões encontradas para carregar cards');
      
      // Carregar dados de cada sessão
      final cards = <MonitoringCardData>[];
      for (var i = 0; i < sessions.length; i++) {
        final session = sessions[i];
        final sessionId = session['id'].toString();
        
        Logger.info('📋 [$_tag] ========== CARREGANDO CARD ${i + 1}/${sessions.length} ==========');
        Logger.info('   Session ID: $sessionId');
        Logger.info('   Talhão: ${session['talhao_nome']}');
        Logger.info('   Cultura: ${session['cultura_nome']}');
        Logger.info('   Status: ${session['status']}');
        
        try {
          final card = await loadCardData(
            sessionId: sessionId,
            talhaoId: session['talhao_id']?.toString(),
          );
          
          cards.add(card);
          Logger.info('✅ [$_tag] Card ${i + 1} ADICIONADO à lista!');
          
        } catch (e, stack) {
          Logger.error('❌ [$_tag] FALHA ao carregar card ${i + 1}: $e');
          Logger.error('   Stack trace: $stack');
          Logger.warning('⚠️ [$_tag] Pulando card da sessão $sessionId');
          continue;
        }
      }
      
      Logger.info('📦 [$_tag] ========== RESUMO ==========');
      Logger.info('   Sessões encontradas: ${sessions.length}');
      Logger.info('   Cards carregados: ${cards.length}');
      Logger.info('   Cards com erro: ${sessions.length - cards.length}');
      
      return cards;
      
    } catch (e, stack) {
      Logger.error('❌ [$_tag] Erro ao carregar múltiplos cards: $e', null, stack);
      return [];
    }
  }
}

/// 📊 MODELO: Dados consolidados do card de monitoramento
class MonitoringCardData {
  final String sessionId;
  final String talhaoId;
  final String talhaoNome;
  final String culturaNome;
  final String status;
  final String dataInicio;
  final String? dataFim;
  final int totalPontos;
  final int totalOcorrencias;
  final int totalPragas;
  final double severidadeMedia;
  final double quantidadeMedia;
  final String nivelRisco;
  final double temperatura;
  final double umidade;
  final int totalFotos;
  final List<OrganismSummary> organismosDetectados;
  final List<String> recomendacoes;
  final List<String> alertas;
  final double confiancaDados;
  
  // ✅ DADOS COMPLEMENTARES SIMPLIFICADOS
  final String estagioFenologico;          // Do submódulo Evolução Fenológica (ex: V4, V5, R1)
  final double? populacao;                  // Do submódulo Estande (plantas/m²)
  final int? dae;                          // Dias Após Emergência (calculado)

  MonitoringCardData({
    required this.sessionId,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaNome,
    required this.status,
    required this.dataInicio,
    this.dataFim,
    required this.totalPontos,
    required this.totalOcorrencias,
    required this.totalPragas,
    required this.severidadeMedia,
    required this.quantidadeMedia,
    required this.nivelRisco,
    required this.temperatura,
    required this.umidade,
    required this.totalFotos,
    required this.organismosDetectados,
    required this.recomendacoes,
    required this.alertas,
    required this.confiancaDados,
    required this.estagioFenologico,
    this.populacao,
    this.dae,
  });

  /// Retorna cor do nível de risco
  String get nivelRiscoColor {
    switch (nivelRisco) {
      case 'CRÍTICO':
        return '#D32F2F';
      case 'ALTO':
        return '#F57C00';
      case 'MÉDIO':
        return '#FBC02D';
      case 'BAIXO':
        return '#388E3C';
      default:
        return '#757575';
    }
  }
  
  /// Retorna ícone do status
  String get statusIcon {
    switch (status) {
      case 'active':
        return '🟢';
      case 'pausado':
        return '⏸️';
      case 'finalized':
        return '✅';
      default:
        return '⚪';
    }
  }
  
  /// Retorna label do status
  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Ativo';
      case 'pausado':
        return 'Pausado';
      case 'finalized':
        return 'Finalizado';
      default:
        return 'Desconhecido';
    }
  }
}

/// 🐛 MODELO: Resumo de um organismo detectado
class OrganismSummary {
  final String nome;
  final int pontosAfetados;
  final int totalPontos;
  final double frequencia;
  final double quantidadeTotal;
  final double quantidadeMedia;
  final double quantidadeMaxima;
  final double severidadeMedia;
  final int totalOcorrencias;

  OrganismSummary({
    required this.nome,
    required this.pontosAfetados,
    required this.totalPontos,
    required this.frequencia,
    required this.quantidadeTotal,
    required this.quantidadeMedia,
    required this.quantidadeMaxima,
    required this.severidadeMedia,
    required this.totalOcorrencias,
  });
  
  /// Retorna nível de risco individual do organismo
  String get nivelRisco {
    if (severidadeMedia >= 70) return 'CRÍTICO';
    if (severidadeMedia >= 40) return 'ALTO';
    if (severidadeMedia >= 20) return 'MÉDIO';
    return 'BAIXO';
  }
  
  /// Retorna cor do nível de risco
  String get nivelRiscoColor {
    switch (nivelRisco) {
      case 'CRÍTICO':
        return '#D32F2F';
      case 'ALTO':
        return '#F57C00';
      case 'MÉDIO':
        return '#FBC02D';
      case 'BAIXO':
        return '#388E3C';
      default:
        return '#757575';
    }
  }
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/app_database.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import 'dart:convert';

/// 📊 Relatório Completo do Talhão
/// 
/// Consolida TODOS os dados coletados pelo sistema:
/// - Fenologia, Estande, CV%
/// - Histórico de manejos
/// - Monitoramento e infestações
/// - Análise da IA
/// - Impacto econômico
/// - Recomendações inteligentes
class ComprehensivePlotReportScreen extends StatefulWidget {
  final String talhaoId;
  final String? talhaoNome;
  final String? sessionId;

  const ComprehensivePlotReportScreen({
    Key? key,
    required this.talhaoId,
    this.talhaoNome,
    this.sessionId,
  }) : super(key: key);

  @override
  State<ComprehensivePlotReportScreen> createState() => _ComprehensivePlotReportScreenState();
}

class _ComprehensivePlotReportScreenState extends State<ComprehensivePlotReportScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  
  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  /// Carrega todos os dados do relatório
  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    
    try {
      final db = await AppDatabase.instance.database;
      
      // 1. DADOS BÁSICOS DO TALHÃO
      final talhaoData = await _loadTalhaoBasicData(db);
      
      // 2. DADOS FENOLÓGICOS
      final phenoData = await _loadPhenologicalData(db);
      
      // 3. DADOS DE ESTANDE
      final standeData = await _loadStandeData(db);
      
      // 4. DADOS DE CV%
      final cvData = await _loadCVData(db);
      
      // 5. HISTÓRICO DE MANEJOS
      final manejoData = await _loadManagementHistory(db);
      
      // 6. MONITORAMENTO E INFESTAÇÕES
      final monitoringData = await _loadMonitoringData(db);
      
      // 7. CONDIÇÕES CLIMÁTICAS
      final climateData = await _loadClimateData(db);
      
      // 8. ANÁLISE DA IA E RECOMENDAÇÕES
      final aiData = await _loadAIAnalysis(db, monitoringData);
      
      setState(() {
        _reportData = {
          'talhao': talhaoData,
          'fenologia': phenoData,
          'estande': standeData,
          'cv': cvData,
          'manejos': manejoData,
          'monitoramento': monitoringData,
          'clima': climateData,
          'ia': aiData,
          'gerado_em': DateTime.now(),
        };
        _isLoading = false;
      });
      
      Logger.info('✅ Relatório completo carregado: ${_reportData.keys.join(", ")}');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar relatório: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar relatório: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 1. Carrega dados básicos do talhão
  Future<Map<String, dynamic>> _loadTalhaoBasicData(db) async {
    try {
      final talhoes = await db.rawQuery('''
        SELECT nome, cultura, variedade, area_hectares, data_plantio
        FROM talhoes
        WHERE id = ?
      ''', [widget.talhaoId]);
      
      if (talhoes.isNotEmpty) {
        final talhao = talhoes.first;
        final dataPlantio = talhao['data_plantio'] != null 
          ? DateTime.tryParse(talhao['data_plantio'].toString())
          : null;
        
        return {
          'nome': talhao['nome'] ?? widget.talhaoNome ?? 'Talhão ${widget.talhaoId}',
          'cultura': talhao['cultura'] ?? 'N/A',
          'variedade': talhao['variedade'] ?? 'N/A',
          'area': (talhao['area_hectares'] as num?)?.toDouble() ?? 0.0,
          'data_plantio': dataPlantio,
          'dias_apos_emergencia': dataPlantio != null 
            ? DateTime.now().difference(dataPlantio).inDays
            : null,
        };
      }
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar dados básicos: $e');
    }
    
    return {
      'nome': widget.talhaoNome ?? 'Talhão ${widget.talhaoId}',
      'cultura': 'N/A',
      'variedade': 'N/A',
      'area': 0.0,
      'data_plantio': null,
      'dias_apos_emergencia': null,
    };
  }

  /// 2. Carrega dados fenológicos
  Future<Map<String, dynamic>> _loadPhenologicalData(db) async {
    try {
      final pheno = await db.rawQuery('''
        SELECT estagio_fenologico, altura_cm, data_registro, observacoes
        FROM phenological_records
        WHERE talhao_id = ?
        ORDER BY data_registro DESC
        LIMIT 5
      ''', [widget.talhaoId]);
      
      if (pheno.isNotEmpty) {
        final atual = pheno.first;
        return {
          'estagio_atual': atual['estagio_fenologico'] ?? 'N/A',
          'altura_media': (atual['altura_cm'] as num?)?.toDouble() ?? 0.0,
          'data_avaliacao': atual['data_registro'] != null 
            ? DateTime.tryParse(atual['data_registro'].toString())
            : null,
          'observacoes': atual['observacoes'],
          'historico': pheno.map((p) => {
            'estagio': p['estagio_fenologico'],
            'altura': (p['altura_cm'] as num?)?.toDouble(),
            'data': p['data_registro'] != null 
              ? DateTime.tryParse(p['data_registro'].toString())
              : null,
          }).toList(),
        };
      }
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar fenologia: $e');
    }
    
    return {'estagio_atual': 'N/A', 'altura_media': 0.0, 'historico': []};
  }

  /// 3. Carrega dados de estande
  Future<Map<String, dynamic>> _loadStandeData(db) async {
    try {
      final estande = await db.rawQuery('''
        SELECT populacao_real_por_hectare, eficiencia_percentual, 
               falhas_por_hectare, data_avaliacao
        FROM estande_plantas
        WHERE talhao_id = ?
        ORDER BY data_avaliacao DESC
        LIMIT 1
      ''', [widget.talhaoId]);
      
      if (estande.isNotEmpty) {
        final e = estande.first;
        return {
          'populacao': (e['populacao_real_por_hectare'] as num?)?.toDouble() ?? 0.0,
          'eficiencia': (e['eficiencia_percentual'] as num?)?.toDouble() ?? 0.0,
          'falhas': (e['falhas_por_hectare'] as num?)?.toDouble() ?? 0.0,
          'data': e['data_avaliacao'] != null 
            ? DateTime.tryParse(e['data_avaliacao'].toString())
            : null,
          'status': _getStandeStatus((e['eficiencia_percentual'] as num?)?.toDouble() ?? 0.0),
        };
      }
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar estande: $e');
    }
    
    return {'populacao': 0.0, 'eficiencia': 0.0, 'falhas': 0.0, 'status': 'N/A'};
  }

  /// 4. Carrega dados de CV%
  Future<Map<String, dynamic>> _loadCVData(db) async {
    try {
      final cv = await db.rawQuery('''
        SELECT coeficiente_variacao, classificacao_texto, data_avaliacao
        FROM plantios_cv
        WHERE talhao_id = ?
        ORDER BY data_avaliacao DESC
        LIMIT 1
      ''', [widget.talhaoId]);
      
      if (cv.isNotEmpty) {
        final c = cv.first;
        return {
          'valor': (c['coeficiente_variacao'] as num?)?.toDouble() ?? 0.0,
          'classificacao': c['classificacao_texto'] ?? 'N/A',
          'data': c['data_avaliacao'] != null 
            ? DateTime.tryParse(c['data_avaliacao'].toString())
            : null,
        };
      }
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar CV%: $e');
    }
    
    return {'valor': 0.0, 'classificacao': 'N/A'};
  }

  /// 5. Carrega histórico de manejos
  Future<List<Map<String, dynamic>>> _loadManagementHistory(db) async {
    try {
      // Buscar manejos salvos nas ocorrências
      final manejos = await db.rawQuery('''
        SELECT DISTINCT tipo_manejo_anterior, data_hora_ocorrencia
        FROM monitoring_occurrences
        WHERE talhao_id = ?
        AND tipo_manejo_anterior IS NOT NULL
        ORDER BY data_hora_ocorrencia DESC
        LIMIT 10
      ''', [widget.talhaoId]);
      
      return manejos.map((m) {
        var tipos = <String>[];
        try {
          if (m['tipo_manejo_anterior'] is String) {
            final decoded = jsonDecode(m['tipo_manejo_anterior'] as String);
            if (decoded is List) {
              tipos = List<String>.from(decoded);
            }
          }
        } catch (e) {
          // Se não for JSON, usar como string simples
          tipos = [m['tipo_manejo_anterior'].toString()];
        }
        
        return {
          'tipos': tipos,
          'data': m['data_hora_ocorrencia'] != null 
            ? DateTime.tryParse(m['data_hora_ocorrencia'].toString())
            : null,
        };
      }).toList();
      
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar manejos: $e');
    }
    
    return [];
  }

  /// 6. Carrega dados de monitoramento
  Future<Map<String, dynamic>> _loadMonitoringData(db) async {
    try {
      String whereClause = 'mo.talhao_id = ?';
      List<dynamic> whereArgs = [widget.talhaoId];
      
      if (widget.sessionId != null) {
        whereClause += ' AND mo.session_id = ?';
        whereArgs.add(widget.sessionId);
      }
      
      final ocorrencias = await db.rawQuery('''
        SELECT 
          mo.organism_name,
          mo.quantidade,
          mo.agronomic_severity,
          mo.terco_planta,
          mo.estadio_fenologico,
          mo.impacto_economico_previsto,
          mo.severidade_ia,
          mo.nivel_ia,
          mo.confianca_ia,
          mo.recomendacao_ia,
          mo.perda_produtividade_ia,
          mo.data_hora_ocorrencia,
          mo.foto_paths
        FROM monitoring_occurrences mo
        WHERE $whereClause
        ORDER BY mo.data_hora_ocorrencia DESC
      ''', whereArgs);
      
      // Agrupar por organismo
      final Map<String, dynamic> organismos = {};
      double impactoTotal = 0.0;
      double perdaTotal = 0.0;
      
      for (final oc in ocorrencias) {
        final nome = oc['organism_name']?.toString() ?? 'Desconhecido';
        
        if (!organismos.containsKey(nome)) {
          organismos[nome] = {
            'nome': nome,
            'ocorrencias': 0,
            'quantidade_total': 0,
            'severidade_max': 0,
            'impacto_economico': 0.0,
            'perda_produtividade': 0.0,
            'recomendacoes': <String>[],
          };
        }
        
        organismos[nome]['ocorrencias']++;
        organismos[nome]['quantidade_total'] += (oc['quantidade'] as num?)?.toInt() ?? 0;
        organismos[nome]['severidade_max'] = (oc['agronomic_severity'] as num?)?.toInt() ?? 0;
        
        final impacto = (oc['impacto_economico_previsto'] as num?)?.toDouble() ?? 0.0;
        final perda = (oc['perda_produtividade_ia'] as num?)?.toDouble() ?? 0.0;
        
        organismos[nome]['impacto_economico'] += impacto;
        organismos[nome]['perda_produtividade'] += perda;
        
        impactoTotal += impacto;
        perdaTotal += perda;
        
        if (oc['recomendacao_ia'] != null && oc['recomendacao_ia'].toString().isNotEmpty) {
          if (!organismos[nome]['recomendacoes'].contains(oc['recomendacao_ia'])) {
            organismos[nome]['recomendacoes'].add(oc['recomendacao_ia']);
          }
        }
      }
      
      return {
        'total_ocorrencias': ocorrencias.length,
        'organismos_detectados': organismos.length,
        'organismos': organismos.values.toList(),
        'impacto_economico_total': impactoTotal,
        'perda_produtividade_total': perdaTotal,
        'ultima_avaliacao': ocorrencias.isNotEmpty && ocorrencias.first['data_hora_ocorrencia'] != null
          ? DateTime.tryParse(ocorrencias.first['data_hora_ocorrencia'].toString())
          : null,
      };
      
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar monitoramento: $e');
    }
    
    return {
      'total_ocorrencias': 0,
      'organismos_detectados': 0,
      'organismos': [],
      'impacto_economico_total': 0.0,
      'perda_produtividade_total': 0.0,
    };
  }

  /// 7. Carrega dados climáticos
  Future<Map<String, dynamic>> _loadClimateData(db) async {
    try {
      String whereClause = 'talhao_id = ?';
      List<dynamic> whereArgs = [widget.talhaoId];
      
      if (widget.sessionId != null) {
        whereClause += ' AND id = ?';
        whereArgs.add(widget.sessionId);
      }
      
      final clima = await db.rawQuery('''
        SELECT temperatura, umidade, started_at
        FROM monitoring_sessions
        WHERE $whereClause
        AND temperatura IS NOT NULL
        AND umidade IS NOT NULL
        ORDER BY started_at DESC
        LIMIT 1
      ''', whereArgs);
      
      if (clima.isNotEmpty) {
        final c = clima.first;
        final temp = (c['temperatura'] as num?)?.toDouble() ?? 0.0;
        final umid = (c['umidade'] as num?)?.toDouble() ?? 0.0;
        
        return {
          'temperatura': temp,
          'umidade': umid,
          'data': c['started_at'] != null 
            ? DateTime.tryParse(c['started_at'].toString())
            : null,
          'condicoes': _getClimateConditions(temp, umid),
        };
      }
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar clima: $e');
    }
    
    return {'temperatura': 0.0, 'umidade': 0.0, 'condicoes': 'N/A'};
  }

  /// 8. Análise da IA e recomendações
  Future<Map<String, dynamic>> _loadAIAnalysis(db, Map<String, dynamic> monitoringData) async {
    final organismos = monitoringData['organismos'] as List<dynamic>? ?? [];
    final impactoTotal = monitoringData['impacto_economico_total'] as double? ?? 0.0;
    final perdaTotal = monitoringData['perda_produtividade_total'] as double? ?? 0.0;
    
    // Gerar nível de risco geral
    String nivelRisco = 'Baixo';
    if (organismos.length >= 5 || impactoTotal > 5000) {
      nivelRisco = 'Crítico';
    } else if (organismos.length >= 3 || impactoTotal > 2000) {
      nivelRisco = 'Alto';
    } else if (organismos.length >= 1 || impactoTotal > 500) {
      nivelRisco = 'Médio';
    }
    
    // Gerar recomendações prioritárias
    final recomendacoes = <String>[];
    
    if (organismos.isNotEmpty) {
      recomendacoes.add('🚨 ${organismos.length} organismo(s) detectado(s) - ação imediata necessária');
      
      // Ordenar por impacto
      final organismosOrdenados = List<Map<String, dynamic>>.from(organismos);
      organismosOrdenados.sort((a, b) => 
        (b['impacto_economico'] as double).compareTo(a['impacto_economico'] as double));
      
      if (organismosOrdenados.isNotEmpty) {
        final maisCritico = organismosOrdenados.first;
        recomendacoes.add(
          '⚠️ Prioridade: ${maisCritico['nome']} '
          '(${maisCritico['ocorrencias']} ocorrências, '
          'R\$ ${maisCritico['impacto_economico'].toStringAsFixed(2)} de impacto)'
        );
      }
    }
    
    if (perdaTotal > 0) {
      recomendacoes.add('📉 Perda de produtividade prevista: ${perdaTotal.toStringAsFixed(1)}%');
    }
    
    if (impactoTotal > 0) {
      recomendacoes.add('💰 Impacto econômico estimado: R\$ ${impactoTotal.toStringAsFixed(2)}');
    }
    
    return {
      'nivel_risco': nivelRisco,
      'cor_risco': _getRiskColor(nivelRisco),
      'score_confianca': 0.85,
      'recomendacoes': recomendacoes,
      'acoes_prioritarias': _getActionsForRisk(nivelRisco, organismos),
    };
  }

  /// Helpers
  String _getStandeStatus(double eficiencia) {
    if (eficiencia >= 90) return 'Excelente';
    if (eficiencia >= 75) return 'Bom';
    if (eficiencia >= 60) return 'Regular';
    return 'Ruim';
  }

  String _getClimateConditions(double temp, double umid) {
    if (temp > 30 && umid > 70) return 'Muito favorável para infestações';
    if (temp > 25 && umid > 60) return 'Favorável para infestações';
    if (temp < 15 || umid < 40) return 'Desfavorável para infestações';
    return 'Condições moderadas';
  }

  Color _getRiskColor(String nivel) {
    switch (nivel) {
      case 'Crítico': return Colors.purple;
      case 'Alto': return Colors.red;
      case 'Médio': return Colors.orange;
      case 'Baixo': return Colors.green;
      default: return Colors.grey;
    }
  }

  List<String> _getActionsForRisk(String nivel, List<dynamic> organismos) {
    final acoes = <String>[];
    
    switch (nivel) {
      case 'Crítico':
        acoes.add('✅ Aplicar tratamento imediatamente');
        acoes.add('✅ Monitorar diariamente');
        acoes.add('✅ Consultar agrônomo');
        break;
      case 'Alto':
        acoes.add('✅ Programar aplicação em 24-48h');
        acoes.add('✅ Aumentar frequência de monitoramento');
        break;
      case 'Médio':
        acoes.add('✅ Monitorar evolução');
        acoes.add('✅ Preparar insumos preventivamente');
        break;
      case 'Baixo':
        acoes.add('✅ Manter monitoramento de rotina');
        break;
    }
    
    return acoes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Completo do Talhão'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _reportData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareReport,
              tooltip: 'Compartilhar',
            ),
          if (!_isLoading && _reportData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportToPDF,
              tooltip: 'Exportar PDF',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData.isEmpty
              ? _buildEmptyState()
              : _buildReportContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum dado disponível',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Realize monitoramentos para gerar o relatório',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com informações básicas
          _buildHeaderSection(),
          const SizedBox(height: 24),
          
          // Análise da IA e Nível de Risco
          _buildAISection(),
          const SizedBox(height: 24),
          
          // Dados de Plantio
          _buildPlantingDataSection(),
          const SizedBox(height: 24),
          
          // Monitoramento e Infestações
          _buildMonitoringSection(),
          const SizedBox(height: 24),
          
          // Condições Climáticas
          _buildClimateSection(),
          const SizedBox(height: 24),
          
          // Histórico de Manejos
          _buildManagementSection(),
          const SizedBox(height: 24),
          
          // Rodapé
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final talhao = _reportData['talhao'] as Map<String, dynamic>;
    final geradoEm = _reportData['gerado_em'] as DateTime;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.landscape, size: 32, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        talhao['nome'] ?? 'Talhão',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${talhao['cultura']} - ${talhao['variedade']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Área', '${talhao['area']?.toStringAsFixed(2)} ha', Icons.crop_square),
                _buildInfoItem(
                  'DAE',
                  talhao['dias_apos_emergencia'] != null 
                    ? '${talhao['dias_apos_emergencia']} dias'
                    : 'N/A',
                  Icons.calendar_today,
                ),
                _buildInfoItem(
                  'Gerado em',
                  DateFormat('dd/MM/yyyy HH:mm').format(geradoEm),
                  Icons.access_time,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAISection() {
    final ia = _reportData['ia'] as Map<String, dynamic>;
    final nivelRisco = ia['nivel_risco'] as String;
    final cor = ia['cor_risco'] as Color;
    final recomendacoes = ia['recomendacoes'] as List<String>;
    final acoes = ia['acoes_prioritarias'] as List<String>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, size: 28, color: cor),
                const SizedBox(width: 12),
                const Text(
                  'Análise Inteligente FortSmart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cor, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'NÍVEL DE RISCO: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    nivelRisco.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      color: cor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            if (recomendacoes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recomendações:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...recomendacoes.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $rec', style: const TextStyle(fontSize: 14)),
              )),
            ],
            
            if (acoes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Ações Prioritárias:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...acoes.map((acao) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(acao, style: const TextStyle(fontSize: 14, color: Colors.green)),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlantingDataSection() {
    final fenologia = _reportData['fenologia'] as Map<String, dynamic>;
    final estande = _reportData['estande'] as Map<String, dynamic>;
    final cv = _reportData['cv'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, size: 28, color: Colors.green[700]),
                const SizedBox(width: 12),
                const Text(
                  'Dados de Plantio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Fenologia
            _buildSubSection(
              'Fenologia',
              Icons.eco,
              Colors.green,
              [
                'Estádio: ${fenologia['estagio_atual']}',
                'Altura média: ${fenologia['altura_media']?.toStringAsFixed(1)} cm',
              ],
            ),
            const SizedBox(height: 12),
            
            // Estande
            _buildSubSection(
              'Estande',
              Icons.grid_on,
              Colors.blue,
              [
                'População: ${(estande['populacao'] as num?)?.toStringAsFixed(0)} pl/ha',
                'Eficiência: ${estande['eficiencia']?.toStringAsFixed(1)}% - ${estande['status']}',
                'Falhas: ${(estande['falhas'] as num?)?.toStringAsFixed(0)} pl/ha',
              ],
            ),
            const SizedBox(height: 12),
            
            // CV%
            _buildSubSection(
              'Uniformidade (CV%)',
              Icons.straighten,
              Colors.orange,
              [
                'CV: ${cv['valor']?.toStringAsFixed(1)}%',
                'Classificação: ${cv['classificacao']}',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSection(String title, IconData icon, Color color, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $item', style: const TextStyle(fontSize: 14)),
          )),
        ],
      ),
    );
  }

  Widget _buildMonitoringSection() {
    final monit = _reportData['monitoramento'] as Map<String, dynamic>;
    final organismos = monit['organismos'] as List<dynamic>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, size: 28, color: Colors.red[700]),
                const SizedBox(width: 12),
                const Text(
                  'Monitoramento e Infestações',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildStatCard(
                  'Ocorrências',
                  monit['total_ocorrencias'].toString(),
                  Icons.numbers,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Organismos',
                  monit['organismos_detectados'].toString(),
                  Icons.pest_control,
                  Colors.orange,
                ),
              ],
            ),
            
            if (organismos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Organismos Detectados:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...organismos.map((org) => _buildOrganismCard(org as Map<String, dynamic>)),
            ],
            
            if (monit['impacto_economico_total'] > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '💰 Impacto Econômico Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'R\$ ${monit['impacto_economico_total'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (monit['perda_produtividade_total'] > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📉 Perda de Produtividade:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${monit['perda_produtividade_total'].toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganismCard(Map<String, dynamic> org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  org['nome'] ?? 'Desconhecido',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ocorrências: ${org['ocorrencias']}'),
          Text('Quantidade total: ${org['quantidade_total']}'),
          Text('Severidade máxima: ${org['severidade_max']}/10'),
          if (org['impacto_economico'] > 0)
            Text(
              'Impacto: R\$ ${org['impacto_economico'].toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildClimateSection() {
    final clima = _reportData['clima'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, size: 28, color: Colors.orange[700]),
                const SizedBox(width: 12),
                const Text(
                  'Condições Climáticas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildClimateCard(
                  'Temperatura',
                  '${clima['temperatura']?.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildClimateCard(
                  'Umidade',
                  '${clima['umidade']?.toStringAsFixed(1)}%',
                  Icons.water_drop,
                  Colors.blue,
                ),
              ],
            ),
            
            if (clima['condicoes'] != 'N/A') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        clima['condicoes'] ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClimateCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    final manejos = _reportData['manejos'] as List<dynamic>;
    
    if (manejos.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.healing, size: 28, color: Colors.purple[700]),
                const SizedBox(width: 12),
                const Text(
                  'Histórico de Manejos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...manejos.take(5).map((manejo) {
              final m = manejo as Map<String, dynamic>;
              final tipos = m['tipos'] as List<dynamic>;
              final data = m['data'] as DateTime?;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 20, color: Colors.purple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipos.join(', '),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (data != null)
                            Text(
                              DateFormat('dd/MM/yyyy').format(data),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'Relatório gerado pelo Sistema FortSmart Agro',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Análise inteligente baseada em dados reais de campo',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de compartilhamento em desenvolvimento')),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de exportação PDF em desenvolvimento')),
    );
  }
}


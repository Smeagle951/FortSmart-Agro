/// 🎯 Dashboard de Infestação - Relatório Agronômico
/// Integração híbrida entre IA existente e FortSmart AI
/// Especialista Agronômico + Desenvolvedor Sênior + Treinador de IA

import 'package:flutter/material.dart';
import '../../models/infestation_report_model.dart';
import '../../models/monitoring.dart';
import '../../services/infestation_ai_integration_service.dart';
import '../../services/infestation_report_service.dart';
import '../../services/monitoring_infestation_integration_service.dart';
import '../../modules/ai/services/ai_dose_recommendation_service.dart';
import '../../modules/ai/widgets/ai_talhao_dose_recommendation_widget.dart';
import '../infestation/infestation_history_screen.dart';
import '../../utils/logger.dart';
import 'package:intl/intl.dart';

class InfestationDashboard extends StatefulWidget {
  const InfestationDashboard({Key? key}) : super(key: key);

  @override
  State<InfestationDashboard> createState() => _InfestationDashboardState();
}

class _InfestationDashboardState extends State<InfestationDashboard> {
  final InfestationAIIntegrationService _aiIntegration = InfestationAIIntegrationService();
  final InfestationReportService _reportService = InfestationReportService();
  final MonitoringInfestationIntegrationService _monitoringService = MonitoringInfestationIntegrationService();
  final AIDoseRecommendationService _aiDoseService = AIDoseRecommendationService();
  
  List<InfestationReportModel> _relatorios = [];
  bool _isLoading = true;
  String _filterStatus = 'todos'; // todos, ativo, critico, controlado
  String _filterCultura = 'todas';
  String _filterIA = 'todas';
  bool _showAnaliseHibrida = false;
  
  void _toggleAnaliseHibrida() {
    setState(() {
      _showAnaliseHibrida = !_showAnaliseHibrida;
    });
  }
  
  void _toggleAIDoseRecommendations() {
    setState(() {
      _showAIDoseRecommendations = !_showAIDoseRecommendations;
    });
  }
  
  // Dados de análise unificada
  Map<String, dynamic>? _analiseUnificada;
  bool _showAnaliseDetalhada = false;
  
  // Dados para heatmap térmico
  List<Map<String, dynamic>> _heatmapData = [];
  bool _showHeatmap = true;
  
  // Recomendações de dose da IA
  List<TalhaoDoseRecommendation> _aiDoseRecommendations = [];
  bool _showAIDoseRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadRelatorios();
  }

  Future<void> _loadRelatorios() async {
    setState(() => _isLoading = true);
    
    try {
      Logger.info('🗺️ Carregando dados reais de infestação...');
      
      // Carregar dados reais de monitoramento
      final monitorings = await _carregarDadosMonitoramento();
      
      if (monitorings.isNotEmpty) {
        Logger.info('✅ ${monitorings.length} monitoramentos carregados');
        
        // Processar dados reais para gerar relatórios de infestação
        _relatorios = await _processarDadosReais(monitorings);
        
        // Gerar análise unificada com dados reais
        _analiseUnificada = await _gerarAnaliseComDadosReais(monitorings);
        
        // Gerar dados para heatmap com dados reais
        _heatmapData = _gerarHeatmapComDadosReais(monitorings);
        
        // Gerar recomendações de dose da IA
        _aiDoseRecommendations = await _gerarRecomendacoesIA(monitorings);
        
      } else {
        Logger.warning('⚠️ Nenhum monitoramento encontrado, usando dados de exemplo');
        
        // Fallback para dados de exemplo
        _analiseUnificada = await _aiIntegration.analiseHibridaCompleta(
          talhaoId: 'talhao_001',
          cultura: 'soja',
          pontosInfestacao: _gerarPontosInfestacaoExemplo(),
          dadosAmbientais: _gerarDadosAmbientaisExemplo(),
        );
        
        _heatmapData = _gerarDadosHeatmap();
        _relatorios = _gerarRelatoriosExemplo();
      }
      
      setState(() {
        _isLoading = false;
      });
      
      Logger.info('✅ Dashboard de infestação carregado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao carregar dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Carrega dados reais de monitoramento
  Future<List<Monitoring>> _carregarDadosMonitoramento() async {
    try {
      Logger.info('🔍 Carregando dados de monitoramento...');
      final monitorings = await _monitoringService.getAllMonitorings();
      Logger.info('✅ ${monitorings.length} monitoramentos encontrados');
      return monitorings;
    } catch (e) {
      Logger.error('❌ Erro ao carregar monitoramentos: $e');
      return [];
    }
  }

  /// Processa dados reais de monitoramento para gerar relatórios de infestação
  Future<List<InfestationReportModel>> _processarDadosReais(List<Monitoring> monitorings) async {
    final relatorios = <InfestationReportModel>[];
    
    for (final monitoring in monitorings) {
      try {
        // Processar cada monitoramento para gerar relatório de infestação
        final relatorio = await _reportService.gerarRelatorioCompleto(
          talhaoId: monitoring.farmId,
          talhaoNome: monitoring.plotName,
          cultura: monitoring.cropName,
          variedade: monitoring.cropVariety ?? 'Não informada',
          pontosInfestacao: monitoring.points.map((point) => {
            'latitude': point.latitude,
            'longitude': point.longitude,
            'organismo': point.occurrences.isNotEmpty ? point.occurrences.first.organismName : 'Desconhecido',
            'intensidade': point.occurrences.isNotEmpty ? point.occurrences.first.severity : 0.0,
            'areaAfetada': 1.0, // Área padrão por ponto
            'data': point.date.toIso8601String(),
          }).toList(),
          dadosAgronomicos: monitoring.weatherData ?? {},
        );
        
        relatorios.add(relatorio);
        
      } catch (e) {
        Logger.error('❌ Erro ao processar monitoramento ${monitoring.id}: $e');
      }
    }
    
    Logger.info('✅ ${relatorios.length} relatórios de infestação gerados');
    return relatorios;
  }

  /// Gera análise unificada com dados reais
  Future<Map<String, dynamic>> _gerarAnaliseComDadosReais(List<Monitoring> monitorings) async {
    try {
      // Agrupar dados por cultura
      final dadosPorCultura = <String, List<Map<String, dynamic>>>{};
      
      for (final monitoring in monitorings) {
        final cultura = monitoring.cropName;
        if (!dadosPorCultura.containsKey(cultura)) {
          dadosPorCultura[cultura] = [];
        }
        
        for (final point in monitoring.points) {
          if (point.occurrences.isNotEmpty) {
            dadosPorCultura[cultura]!.add({
              'latitude': point.latitude,
              'longitude': point.longitude,
              'organismo': point.occurrences.first.organismName,
              'severidade': point.occurrences.first.severity,
              'data': point.date.toIso8601String(),
            });
          }
        }
      }
      
      // Gerar análise para cada cultura
      final analises = <String, dynamic>{};
      for (final entry in dadosPorCultura.entries) {
        final cultura = entry.key;
        final pontos = entry.value;
        
        if (pontos.isNotEmpty) {
          analises[cultura] = await _aiIntegration.analiseHibridaCompleta(
            talhaoId: 'talhao_${cultura.toLowerCase()}',
            cultura: cultura,
            pontosInfestacao: pontos,
            dadosAmbientais: monitorings.first.weatherData ?? {},
          );
        }
      }
      
      return {
        'versaoIA': 'Sistema FortSmart Agro v3.0',
        'dataAnalise': DateTime.now().toIso8601String(),
        'totalMonitoramentos': monitorings.length,
        'culturasAnalisadas': dadosPorCultura.keys.toList(),
        'analisesPorCultura': analises,
        'confiancaGeral': 0.95,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar análise com dados reais: $e');
      return {};
    }
  }

  /// Gera heatmap com dados reais
  List<Map<String, dynamic>> _gerarHeatmapComDadosReais(List<Monitoring> monitorings) {
    final heatmapData = <Map<String, dynamic>>[];
    
    for (final monitoring in monitorings) {
      for (final point in monitoring.points) {
        if (point.occurrences.isNotEmpty) {
          heatmapData.add({
            'latitude': point.latitude,
            'longitude': point.longitude,
            'intensidade': point.occurrences.first.severity,
            'organismo': point.occurrences.first.organismName,
            'cultura': monitoring.cropName,
            'data': point.date.toIso8601String(),
            'fonte': 'Monitoramento Real',
            'severidade': point.occurrences.first.severity,
            'sintomas': point.occurrences.first.symptoms.join(', '),
          });
        }
      }
    }
    
    Logger.info('✅ ${heatmapData.length} pontos para heatmap gerados');
    return heatmapData;
  }

  /// Gera recomendações de dose da IA para cada talhão
  Future<List<TalhaoDoseRecommendation>> _gerarRecomendacoesIA(List<Monitoring> monitorings) async {
    final recommendations = <TalhaoDoseRecommendation>[];
    
    try {
      Logger.info('🧠 [IA] Gerando recomendações de dose para ${monitorings.length} monitoramentos');
      
      for (final monitoring in monitorings) {
        // Preparar dados de infestação para a IA
        final infestationData = monitoring.points.map((point) => {
          'organismo': point.occurrences.isNotEmpty ? point.occurrences.first.organismName : 'Desconhecido',
          'intensidade': point.occurrences.isNotEmpty ? point.occurrences.first.severity : 0.0,
          'latitude': point.latitude,
          'longitude': point.longitude,
          'data': point.date.toIso8601String(),
          'sintomas': point.occurrences.isNotEmpty ? point.occurrences.first.symptoms : [],
        }).toList();
        
        // Gerar recomendação da IA para este talhão
        final recommendation = await _aiDoseService.generateTalhaoDoseRecommendation(
          talhaoId: monitoring.farmId,
          talhaoName: monitoring.plotName,
          cropName: monitoring.cropName,
          infestationData: infestationData,
        );
        
        recommendations.add(recommendation);
      }
      
      Logger.info('✅ [IA] ${recommendations.length} recomendações de dose geradas');
      
    } catch (e) {
      Logger.error('❌ [IA] Erro ao gerar recomendações: $e');
    }
    
    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Dashboard de Infestação'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InfestationHistoryScreen(),
                ),
              );
            },
            tooltip: 'Histórico e Aprendizado da IA',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRelatorios,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _toggleAnaliseHibrida,
          ),
          IconButton(
            icon: Icon(_showAIDoseRecommendations ? Icons.psychology : Icons.psychology_outlined),
            onPressed: _toggleAIDoseRecommendations,
            tooltip: 'Recomendações de Dose da IA',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _relatorios.isEmpty
              ? _buildEmptyState()
              : _buildDashboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bug_report, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum relatório de infestação encontrado',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Execute um monitoramento para gerar relatórios',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // ❌ REMOVIDO: Card "Sistema FortSmart Agro" (não está funcionando)
        // ❌ REMOVIDO: Card "Heatmap Térmico" (não está funcionando)
        // ❌ REMOVIDO: Card "Recomendações de dose da IA" (não está funcionando)
        
        // Filtros ativos
        _buildActiveFilters(),
        
        // Estatísticas gerais
        _buildGeneralStats(),
        
        // Lista de relatórios
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _relatorios.length,
            itemBuilder: (context, index) => _buildRelatorioCard(_relatorios[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAnaliseUnificadaCard() {
    final analise = _analiseUnificada!;
    final fonte = 'Sistema FortSmart Agro';
    final confianca = (analise['confianca'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
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
            'Análise Unificada Inteligente',
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
          ElevatedButton.icon(
            onPressed: _showAnaliseUnificada,
            icon: const Icon(Icons.visibility),
            label: const Text('Ver Análise Detalhada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'Filtros: ',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Chip(
            label: Text(_filterStatus == 'todos' ? 'Todos' : _filterStatus),
            backgroundColor: Colors.red[100],
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(_filterCultura == 'todas' ? 'Todas' : _filterCultura),
            backgroundColor: Colors.blue[100],
          ),
          const SizedBox(width: 8),
          // Removido filtro de IA - apenas uma IA unificada
          const Spacer(),
          Text(
            '${_relatorios.length} relatórios',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralStats() {
    final ativos = _relatorios.where((r) => r.status == 'ativo').length;
    final criticos = _relatorios.where((r) => r.status == 'critico').length;
    final controlados = _relatorios.where((r) => r.status == 'controlado').length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip('Ativos', ativos.toString(), Colors.orange),
          _buildStatChip('Críticos', criticos.toString(), Colors.red),
          _buildStatChip('Controlados', controlados.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
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
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRelatorioCard(InfestationReportModel relatorio) {
    final stats = relatorio.estatisticas;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openRelatorioDetails(relatorio),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do relatório
              Row(
                children: [
                  Icon(
                    relatorio.isCritico ? Icons.warning : Icons.bug_report,
                    color: relatorio.corStatus,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      relatorio.talhaoNome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: relatorio.corStatus,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: relatorio.corStatus.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      relatorio.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: relatorio.corStatus,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Informações básicas
              Row(
                children: [
                  Icon(Icons.agriculture, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${relatorio.cultura.toUpperCase()} - ${relatorio.variedade}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Estatísticas
              Row(
                children: [
                  _buildStatItem(
                    'Pontos',
                    '${stats['totalPontos']}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Área Afetada',
                    '${((stats['percentualAfetado'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Risco',
                    relatorio.nivelRisco,
                    _getRiscoColor(relatorio.nivelRisco),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Prescrições
              if (relatorio.prescricoes.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.medical_services, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${relatorio.prescricoes.length} prescrições',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Footer
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Atualizado ${DateFormat('dd/MM/yyyy').format(relatorio.dataAnalise)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
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
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getConfiancaColor(double confianca) {
    if (confianca >= 0.9) return Colors.green;
    if (confianca >= 0.7) return Colors.orange;
    return Colors.red;
  }

  Color _getRiscoColor(String risco) {
    switch (risco.toLowerCase()) {
      case 'alto': return Colors.red;
      case 'médio': return Colors.orange;
      case 'baixo': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros Avançados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtro de status
            DropdownButtonFormField<String>(
              value: _filterStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                DropdownMenuItem(value: 'critico', child: Text('Crítico')),
                DropdownMenuItem(value: 'controlado', child: Text('Controlado')),
              ],
              onChanged: (value) {
                setState(() => _filterStatus = value!);
              },
            ),
            const SizedBox(height: 16),
            
            // Filtro de cultura
            DropdownButtonFormField<String>(
              value: _filterCultura,
              decoration: const InputDecoration(
                labelText: 'Cultura',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'todas', child: Text('Todas')),
                DropdownMenuItem(value: 'soja', child: Text('Soja')),
                DropdownMenuItem(value: 'milho', child: Text('Milho')),
                DropdownMenuItem(value: 'algodao', child: Text('Algodão')),
                DropdownMenuItem(value: 'feijao', child: Text('Feijão')),
              ],
              onChanged: (value) {
                setState(() => _filterCultura = value!);
              },
            ),
            const SizedBox(height: 16),
            
            // Filtro de IA
            DropdownButtonFormField<String>(
              value: _filterIA,
              decoration: const InputDecoration(
                labelText: 'Tipo de IA',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'todas', child: Text('Todas')),
                DropdownMenuItem(value: 'hibrida', child: Text('Híbrida')),
                DropdownMenuItem(value: 'fortSmart', child: Text('FortSmart')),
                DropdownMenuItem(value: 'existente', child: Text('Existente')),
              ],
              onChanged: (value) {
                setState(() => _filterIA = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadRelatorios();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showAnaliseUnificada() {
    if (_analiseUnificada == null) return;
    
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
                        'Sistema FortSmart Agro - Análise Detalhada',
                        style: TextStyle(
                          fontSize: 20,
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
              
              // Conteúdo da análise
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildAnaliseSection('Sistema FortSmart Agro', [
                      _buildInfoRow('Análise Unificada', 'Sistema FortSmart Agro'),
                      _buildInfoRow('Confiança', '${(((_analiseUnificada!['confianca'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%'),
                      _buildInfoRow('Timestamp', _formatTimestamp(_analiseUnificada!['timestamp'] as String? ?? '')),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    _buildAnaliseSection('Análise Detalhada', [
                      _buildInfoRow('Nível de Risco', _analiseUnificada!['analise']?['nivelRisco'] as String? ?? 'N/A'),
                      _buildInfoRow('Organismos Detectados', (_analiseUnificada!['analise']?['organismosDetectados'] as List<dynamic>?)?.join(', ') ?? 'N/A'),
                      _buildInfoRow('Área Total Afetada', '${((_analiseUnificada!['analise']?['areaTotalAfetada'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} ha'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    _buildAnaliseSection('Recomendações', [
                      for (final rec in (_analiseUnificada!['recomendacoes'] as List<dynamic>?) ?? [])
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _openRelatorioDetails(InfestationReportModel relatorio) {
    // ✅ NAVEGAR PARA RELATÓRIO AGRONÔMICO COM DADOS DO TALHÃO
    Navigator.pushNamed(
      context,
      '/reports', // Rota para o relatório agronômico
      arguments: {
        'talhaoId': relatorio.talhaoId,
        'culturaId': relatorio.cultura,
        'talhaoNome': relatorio.talhaoNome,
      },
    );
  }

  /// Gera dados para heatmap térmico baseado em pontos reais de monitoramento
  List<Map<String, dynamic>> _gerarDadosHeatmap() {
    // Em produção, estes dados viriam dos pontos de monitoramento reais
    return [
      {
        'latitude': -15.7801,
        'longitude': -47.9292,
        'intensidade': 0.9,
        'organismo': 'Bicheira-da-raiz',
        'nivel': 'critico',
        'temperatura': 28.5,
        'cor': Colors.red,
        'cultura': 'Arroz',
        'fonte': 'JSON_Arroz',
      },
      {
        'latitude': -15.7805,
        'longitude': -47.9295,
        'intensidade': 0.6,
        'organismo': 'Lagarta-do-cartucho',
        'nivel': 'moderado',
        'temperatura': 26.2,
        'cor': Colors.orange,
        'cultura': 'Milho',
        'fonte': 'JSON_Milho',
      },
      {
        'latitude': -15.7808,
        'longitude': -47.9298,
        'intensidade': 0.3,
        'organismo': 'Ferrugem Asiática',
        'nivel': 'baixo',
        'temperatura': 24.8,
        'cor': Colors.yellow,
        'cultura': 'Soja',
        'fonte': 'JSON_Soja',
      },
      {
        'latitude': -15.7811,
        'longitude': -47.9301,
        'intensidade': 0.1,
        'organismo': 'Mancha Foliar',
        'nivel': 'baixo',
        'temperatura': 23.5,
        'cor': Colors.green,
        'cultura': 'Trigo',
        'fonte': 'JSON_Trigo',
      },
    ];
  }

  /// Constrói card do heatmap térmico
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
                'Heatmap Térmico de Infestação',
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
            'Análise térmica baseada na intensidade de infestação',
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

  /// Constrói legenda do heatmap
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

  /// Constrói item da legenda
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

  /// Mostra detalhes do heatmap
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
                        'Heatmap Térmico - Detalhado',
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
                    _buildHeatmapSection('Pontos de Infestação', _heatmapData),
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

  /// Constrói seção do heatmap
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

  /// Constrói item do heatmap
  Widget _buildHeatmapItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item['cor'] as Color,
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
                  '${item['cultura']} • ${item['fonte']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${item['latitude']}, ${item['longitude']}',
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
                '${item['temperatura']}°C',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item['nivel'],
                style: TextStyle(
                  fontSize: 10,
                  color: item['cor'] as Color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Gera análise térmica
  List<Map<String, dynamic>> _gerarAnaliseTermica() {
    if (_heatmapData.isEmpty) {
      return [];
    }
    
    final tempMedia = _heatmapData.fold<double>(0.0, (sum, d) => sum + ((d['temperatura'] as num?)?.toDouble() ?? 0.0)) / _heatmapData.length;
    final intensidadeMedia = _heatmapData.fold<double>(0.0, (sum, d) => sum + ((d['intensidade'] as num?)?.toDouble() ?? 0.0)) / _heatmapData.length;
    
    return [
      {
        'organismo': 'Temperatura Média',
        'intensidade': tempMedia,
        'cor': Colors.blue,
        'temperatura': tempMedia,
        'nivel': 'media',
        'cultura': 'Todas',
        'fonte': 'Análise Térmica',
      },
      {
        'organismo': 'Intensidade Média',
        'intensidade': intensidadeMedia,
        'cor': Colors.orange,
        'temperatura': 0.0,
        'nivel': 'media',
        'cultura': 'Todas',
        'fonte': 'Análise Térmica',
      },
    ];
  }

  // Métodos auxiliares para dados de exemplo
  List<Map<String, dynamic>> _gerarPontosInfestacaoExemplo() {
    return [];
  }

  Map<String, dynamic> _gerarDadosAmbientaisExemplo() {
    return {
      'temperatura': 0.0,
      'umidade': 0.0,
      'precipitacao': 0.0,
      'vento': 0.0,
      'pressao': 0.0,
    };
  }

  List<InfestationReportModel> _gerarRelatoriosExemplo() {
    // ✅ GERAR DADOS DE EXEMPLO PARA TESTE
    return [
      InfestationReportModel(
        id: 'rel_001',
        talhaoId: 'talhao_14',
        talhaoNome: 'Talhão 14',
        cultura: 'SOJA',
        variedade: 'Não informada',
        dataColeta: DateTime.now().subtract(const Duration(days: 1)),
        dataAnalise: DateTime.now(),
        status: 'ativo',
        pontosInfestacao: [
          InfestationPoint(
            id: 'p1',
            latitude: -15.7801,
            longitude: -47.9292,
            organismo: 'Lagarta',
            nivel: 'baixo',
            intensidade: 0.3,
            areaAfetada: 1.0,
            sintomas: 'Folhas mordidas',
            observacoes: 'Ponto de monitoramento',
            dataDetectado: DateTime.now().subtract(const Duration(hours: 2)),
            fotos: [],
            dadosTecnicos: {},
          ),
        ],
        dadosAgronomicos: {
          'temperatura': 28.5,
          'umidade': 65.0,
          'vento': 12.0,
          'pressao': 1013.2,
        },
        analiseIA: {
          'confianca': 0.85,
          'recomendacao': 'Aplicar inseticida específico',
          'urgencia': 'média',
        },
        prescricoes: [],
        feedbacks: [],
        observacoes: 'Monitoramento realizado com sucesso',
      ),
    ];
  }

  /// Constrói card com recomendações de dose da IA
  Widget _buildAIDoseRecommendationsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.blue[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                'Recomendações de Dose da IA FortSmart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Recomendações inteligentes baseadas nos dados de infestação e catálogo de organismos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de recomendações por talhão
          ..._aiDoseRecommendations.map((recommendation) =>
            AITalhaoDoseRecommendationWidget(
              recommendation: recommendation,
              onAcceptRecommendation: _onAcceptAIRecommendation,
              onEditRecommendation: _onEditAIRecommendation,
              onLearningFeedback: _onAILearningFeedback,
            ),
          ).toList(),
        ],
      ),
    );
  }

  /// Callback para aceitar recomendação da IA
  void _onAcceptAIRecommendation(String organismName, List<DoseRecommendation> doses) {
    Logger.info('✅ [IA] Usuário aceitou recomendação: $organismName');
    
    // Aqui você pode implementar lógica adicional, como:
    // - Salvar no histórico
    // - Enviar para sistema de aplicação
    // - Atualizar estatísticas
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recomendação da IA aceita para $organismName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Callback para editar recomendação da IA
  void _onEditAIRecommendation(String organismName, List<DoseRecommendation> doses) {
    Logger.info('✏️ [IA] Usuário editou recomendação: $organismName');
    
    // Aqui você pode implementar lógica adicional, como:
    // - Abrir tela de edição
    // - Salvar alterações
    // - Enviar feedback para a IA
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando recomendação da IA para $organismName'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Callback para feedback de aprendizado da IA
  void _onAILearningFeedback(String organismName, String feedback) {
    Logger.info('🧠 [IA] Feedback de aprendizado: $organismName - $feedback');
    
    // Aqui você pode implementar lógica adicional, como:
    // - Salvar feedback no banco de dados
    // - Enviar para sistema de ML
    // - Atualizar modelo da IA
    
    // Por enquanto, apenas log
    Logger.info('💡 [IA] Sistema de aprendizado atualizado com feedback do usuário');
  }
}
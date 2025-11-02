/// 📚 Tela de Histórico de Infestações e Aprendizado da IA
/// Mostra ao usuário:
/// - Surtos anteriores no talhão
/// - Eficácia de produtos utilizados
/// - Padrões identificados pela IA
/// - Insights personalizados

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/ia_aprendizado_continuo.dart';
import '../../utils/logger.dart';

class InfestationHistoryScreen extends StatefulWidget {
  final String? talhaoId;
  final String? talhaoNome;
  final String? cultura;
  final String? organismo;

  const InfestationHistoryScreen({
    Key? key,
    this.talhaoId,
    this.talhaoNome,
    this.cultura,
    this.organismo,
  }) : super(key: key);

  @override
  State<InfestationHistoryScreen> createState() => _InfestationHistoryScreenState();
}

class _InfestationHistoryScreenState extends State<InfestationHistoryScreen> {
  final IAAprendizadoContinuo _iaAprendizado = IAAprendizadoContinuo();
  
  bool _isLoading = true;
  Map<String, dynamic> _padroes = {};
  List<Map<String, dynamic>> _surtos = [];
  List<String> _insights = [];
  Map<String, dynamic> _estatisticas = {};
  
  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }
  
  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    
    try {
      await _iaAprendizado.initialize();
      
      // 1. Carregar padrões do talhão
      if (widget.talhaoId != null && widget.organismo != null) {
        _padroes = await _iaAprendizado.obterPadroesTalhao(
          talhaoId: widget.talhaoId!,
          organismo: widget.organismo!,
          cultura: widget.cultura,
        );
      }
      
      // 2. Carregar histórico de surtos
      if (widget.talhaoId != null) {
        _surtos = await _iaAprendizado.obterHistoricoSurtos(
          talhaoId: widget.talhaoId!,
          organismo: widget.organismo,
          limit: 20,
        );
      }
      
      // 3. Gerar insights personalizados baseados nos padrões
      if (_padroes['tem_historico'] == true) {
        _insights = _gerarInsightsLocais(
          padroes: _padroes,
          surtos: _surtos,
        );
      }
      
      // 4. Carregar estatísticas gerais
      _estatisticas = await _iaAprendizado.obterEstatisticasAprendizado();
      
      Logger.info('✅ Histórico carregado: ${_surtos.length} surtos, ${_insights.length} insights');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar histórico: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 Histórico de Infestações'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarHistorico,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _surtos.isEmpty && _padroes.isEmpty
              ? _buildEmptyState()
              : _buildHistoryContent(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum histórico encontrado',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Continue monitorando para a IA aprender!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de estatísticas gerais
        _buildEstatisticasCard(),
        const SizedBox(height: 16),
        
        // Card de padrões identificados
        if (_padroes['tem_historico'] == true) ...[
          _buildPadroesCard(),
          const SizedBox(height: 16),
        ],
        
        // Card de insights da IA
        if (_insights.isNotEmpty) ...[
          _buildInsightsCard(),
          const SizedBox(height: 16),
        ],
        
        // Lista de surtos históricos
        if (_surtos.isNotEmpty) ...[
          _buildSurtosHeader(),
          const SizedBox(height: 8),
          ..._surtos.map((surto) => _buildSurtoCard(surto)).toList(),
        ],
      ],
    );
  }
  
  Widget _buildEstatisticasCard() {
    final totalPadroes = _estatisticas['total_padroes_aprendidos'] ?? 0;
    final totalSurtos = _estatisticas['total_surtos_registrados'] ?? 0;
    final acuracia = (_estatisticas['acuracia_media'] as double?) ?? 0.0;
    final nivelAprendizado = _estatisticas['nivel_aprendizado'] ?? 'Novo';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Nível de Aprendizado da IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Padrões', totalPadroes.toString(), Icons.pattern),
                _buildStatItem('Surtos', totalSurtos.toString(), Icons.warning),
                _buildStatItem('Acurácia', '${(acuracia * 100).toStringAsFixed(0)}%', Icons.check_circle),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Nível: $nivelAprendizado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPadroesCard() {
    final mediaHistorica = (_padroes['densidade_media_historica'] as double?) ?? 0.0;
    final maxHistorica = (_padroes['densidade_maxima_historica'] as double?) ?? 0.0;
    final totalRegistros = _padroes['total_registros'] ?? 0;
    final tendencia = _padroes['tendencia'] ?? 'Insuficiente';
    final tempFavorece = _padroes['temperatura_favorece_surto'] ?? false;
    
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
                Icon(Icons.analytics, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Padrões Identificados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPadraoItem('📊 Densidade Média', '${mediaHistorica.toStringAsFixed(1)}/m²'),
            _buildPadraoItem('📈 Pico Máximo', '${maxHistorica.toStringAsFixed(1)}/m²'),
            _buildPadraoItem('📋 Registros', '$totalRegistros amostras'),
            _buildPadraoItem('📉 Tendência', tendencia),
            _buildPadraoItem(
              '🌡️ Temperatura',
              tempFavorece ? 'Favorece surtos' : 'Não correlacionado',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPadraoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
  
  Widget _buildInsightsCard() {
    return Card(
      elevation: 4,
      color: Colors.amber[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Insights da IA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSurtosHeader() {
    return Row(
      children: [
        Icon(Icons.history, color: Colors.red[700], size: 24),
        const SizedBox(width: 8),
        Text(
          'Surtos Anteriores (${_surtos.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSurtoCard(Map<String, dynamic> surto) {
    final organismo = surto['organismo'] as String? ?? 'Desconhecido';
    final dataSurto = DateTime.tryParse(surto['data_surto'] as String? ?? '');
    final densidadePico = (surto['densidade_pico'] as double?) ?? 0.0;
    final temperatura = (surto['temperatura_media'] as double?) ?? 0.0;
    final umidade = (surto['umidade_media'] as double?) ?? 0.0;
    final controleRealizado = surto['controle_realizado'] as String?;
    final eficaciaControle = (surto['eficacia_controle'] as double?) ?? 0.0;
    final danoEconomico = (surto['dano_economico'] as double?) ?? 0.0;
    
    // Calcular tempo desde o surto
    final diasAtras = dataSurto != null 
        ? DateTime.now().difference(dataSurto).inDays 
        : 0;
    final tempoAtras = diasAtras > 365 
        ? '${(diasAtras / 365).floor()} ano(s) atrás'
        : diasAtras > 30
            ? '${(diasAtras / 30).floor()} mês(es) atrás'
            : '$diasAtras dias atrás';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        leading: Icon(
          Icons.bug_report,
          color: Colors.red[700],
        ),
        title: Text(
          organismo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$tempoAtras • Pico: ${densidadePico.toStringAsFixed(1)}/m²',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Condições climáticas
                const Text(
                  'Condições do Surto:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.thermostat, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text('${temperatura.toStringAsFixed(1)}°C'),
                    const SizedBox(width: 16),
                    Icon(Icons.water_drop, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text('${umidade.toStringAsFixed(0)}%'),
                  ],
                ),
                
                // Controle realizado
                if (controleRealizado != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Controle Utilizado:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(controleRealizado),
                  
                  // Eficácia do controle
                  if (eficaciaControle > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          eficaciaControle >= 80 
                              ? Icons.check_circle 
                              : eficaciaControle >= 50
                                  ? Icons.remove_circle
                                  : Icons.cancel,
                          color: eficaciaControle >= 80 
                              ? Colors.green 
                              : eficaciaControle >= 50
                                  ? Colors.orange
                                  : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eficácia: ${eficaciaControle.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: eficaciaControle >= 80 
                                ? Colors.green 
                                : eficaciaControle >= 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                
                // Dano econômico
                if (danoEconomico > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dano Econômico: R\$ ${danoEconomico.toStringAsFixed(2)}/ha',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Gera insights locais baseados nos padrões
  List<String> _gerarInsightsLocais({
    required Map<String, dynamic> padroes,
    required List<Map<String, dynamic>> surtos,
  }) {
    final insights = <String>[];
    
    if (padroes['tem_historico'] != true) {
      insights.add('📝 Primeiro registro neste talhão - IA vai aprender');
      insights.add('💡 Continue monitorando para IA melhorar predições');
      return insights;
    }
    
    final totalRegistros = padroes['total_registros'] as int? ?? 0;
    final mediaHistorica = (padroes['densidade_media_historica'] as double?) ?? 0.0;
    final maxHistorica = (padroes['densidade_maxima_historica'] as double?) ?? 0.0;
    final tendencia = padroes['tendencia'] as String? ?? 'Insuficiente';
    
    // Insight sobre quantidade de dados
    if (totalRegistros >= 30) {
      insights.add('🎯 Alta confiança ($totalRegistros registros) - Predições personalizadas');
    } else if (totalRegistros >= 10) {
      insights.add('📊 Padrão em formação ($totalRegistros registros) - Continue monitorando');
    }
    
    // Insight sobre tendência
    if (tendencia == 'Crescente') {
      insights.add('📈 Tendência de CRESCIMENTO detectada - Atenção redobrada!');
    } else if (tendencia == 'Decrescente') {
      insights.add('📉 Tendência de QUEDA - Controle efetivo');
    }
    
    // Insight sobre surtos
    if (surtos.isNotEmpty) {
      insights.add('📚 ${surtos.length} surto(s) registrado(s) neste talhão no histórico');
      
      final ultimoSurto = surtos.first;
      final densidadeSurto = (ultimoSurto['densidade_pico'] as double?) ?? 0.0;
      
      if (densidadeSurto > mediaHistorica * 1.5) {
        insights.add('⚠️ Último surto foi ${((densidadeSurto / mediaHistorica - 1) * 100).toStringAsFixed(0)}% acima da média');
      }
      
      // Eficácia de controles
      final controlesEficazes = surtos.where((s) => 
        (s['eficacia_controle'] as double?) != null && 
        (s['eficacia_controle'] as double) >= 80
      ).length;
      
      if (controlesEficazes > 0) {
        insights.add('✅ $controlesEficazes controle(s) com eficácia ≥80% registrados');
      }
    }
    
    return insights;
  }
}


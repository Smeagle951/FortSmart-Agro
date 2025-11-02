import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/soil_compaction_point_model.dart';
import '../repositories/soil_compaction_point_repository.dart';
import '../services/soil_temporal_analysis_service.dart';
import '../constants/app_colors.dart';
import 'soil_map_visualization_screen.dart';

/// Tela de análises temporais e mapas de tendência
class SoilTemporalAnalysisScreen extends StatefulWidget {
  final int talhaoId;
  final String nomeTalhao;
  final List<LatLng> polygonCoordinates;

  const SoilTemporalAnalysisScreen({
    Key? key,
    required this.talhaoId,
    required this.nomeTalhao,
    required this.polygonCoordinates,
  }) : super(key: key);

  @override
  State<SoilTemporalAnalysisScreen> createState() => _SoilTemporalAnalysisScreenState();
}

class _SoilTemporalAnalysisScreenState extends State<SoilTemporalAnalysisScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late TabController _tabController;
  
  Map<int, List<SoilCompactionPointModel>> _dadosPorSafra = {};
  Map<String, dynamic>? _evolucaoPorSafra;
  Map<String, dynamic>? _mapaCalor;
  Map<String, dynamic>? _tendenciaAtual;
  bool _isLoading = true;
  int _safraSelecionada = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final repository = Provider.of<SoilCompactionPointRepository>(
        context,
        listen: false,
      );

      // Carrega dados de todas as safras
      final todosPontos = await repository.getByTalhao(widget.talhaoId);
      
      // Agrupa por safra
      _dadosPorSafra = {};
      for (var ponto in todosPontos) {
        if (ponto.safraId != null) {
          _dadosPorSafra[ponto.safraId!] ??= [];
          _dadosPorSafra[ponto.safraId!]!.add(ponto);
        }
      }

      // Gera análises
      if (_dadosPorSafra.isNotEmpty) {
        _evolucaoPorSafra = SoilTemporalAnalysisService.gerarEvolucaoPorSafra(
          dadosPorSafra: _dadosPorSafra,
        );

        // Calcula tendência entre as duas últimas safras
        final safras = _dadosPorSafra.keys.toList()..sort();
        if (safras.length >= 2) {
          _tendenciaAtual = SoilTemporalAnalysisService.calcularTendencia(
            pontosAtuais: _dadosPorSafra[safras.last]!,
            pontosAnteriores: _dadosPorSafra[safras[safras.length - 2]]!,
          );
        }

        // Gera mapa de calor para safra selecionada
        if (_dadosPorSafra.containsKey(_safraSelecionada)) {
          _mapaCalor = SoilTemporalAnalysisService.gerarMapaCalorTemporal(
            pontos: _dadosPorSafra[_safraSelecionada]!,
            safraId: _safraSelecionada,
          );
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Análises Temporais - ${widget.nomeTalhao}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Evolução'),
            Tab(icon: Icon(Icons.map), text: 'Mapa Calor'),
            Tab(icon: Icon(Icons.analytics), text: 'Tendências'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEvolucaoTab(),
                _buildMapaCalorTab(),
                _buildTendenciasTab(),
              ],
            ),
    );
  }

  Widget _buildEvolucaoTab() {
    if (_evolucaoPorSafra == null) {
      return const Center(
        child: Text('Nenhum dado de evolução disponível'),
      );
    }

    final safras = _evolucaoPorSafra!['safras'] as List;
    final graficoDados = _evolucaoPorSafra!['grafico_dados'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo geral
          _buildResumoCard(),
          const SizedBox(height: 16),
          
          // Gráfico de evolução
          _buildGraficoCard(graficoDados),
          const SizedBox(height: 16),
          
          // Tabela de safras
          _buildTabelaSafras(safras),
          const SizedBox(height: 16),
          
          // Tendencias entre safras
          if (_evolucaoPorSafra!['tendencias'] != null)
            _buildTendenciasCard(_evolucaoPorSafra!['tendencias']),
        ],
      ),
    );
  }

  Widget _buildMapaCalorTab() {
    return Column(
      children: [
        // Controles
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Safra:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _safraSelecionada,
                items: _dadosPorSafra.keys.map((safra) {
                  return DropdownMenuItem(
                    value: safra,
                    child: Text(safra.toString()),
                  );
                }).toList(),
                onChanged: (safra) {
                  if (safra != null) {
                    setState(() {
                      _safraSelecionada = safra;
                      _mapaCalor = SoilTemporalAnalysisService.gerarMapaCalorTemporal(
                        pontos: _dadosPorSafra[safra]!,
                        safraId: safra,
                      );
                    });
                  }
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _abrirMapaCompleto,
                icon: const Icon(Icons.fullscreen),
                label: const Text('Mapa Completo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Mapa
        Expanded(
          child: _mapaCalor != null ? _buildMapaCalor() : const Center(
            child: Text('Nenhum dado de mapa de calor disponível'),
          ),
        ),
      ],
    );
  }

  Widget _buildTendenciasTab() {
    if (_tendenciaAtual == null) {
      return const Center(
        child: Text('Nenhum dado de tendência disponível'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo da tendência
          _buildTendenciaCard(),
          const SizedBox(height: 16),
          
          // Gráfico de distribuição
          _buildDistribuicaoCard(),
          const SizedBox(height: 16),
          
          // Detalhes dos grupos
          if (_tendenciaAtual!['detalhes_grupos'] != null)
            _buildDetalhesGruposCard(),
        ],
      ),
    );
  }

  Widget _buildResumoCard() {
    final safras = _evolucaoPorSafra!['safras'] as List;
    final ultimaSafra = safras.isNotEmpty ? safras.last : null;
    
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Resumo da Evolução',
                  style: TextStyle(
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
                _buildStatItem(
                  'Safras',
                  '${safras.length}',
                  Icons.calendar_today,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Última Média',
                  ultimaSafra != null 
                      ? '${(ultimaSafra['media_compactacao'] as double).toStringAsFixed(2)} MPa'
                      : 'N/A',
                  Icons.analytics,
                  Colors.green,
                ),
                _buildStatItem(
                  'Áreas Críticas',
                  ultimaSafra != null 
                      ? '${ultimaSafra['areas_criticas']}'
                      : 'N/A',
                  Icons.warning,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoCard(Map<String, dynamic> graficoDados) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Evolução da Compactação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Aqui seria implementado um gráfico real com fl_chart ou similar
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Gráfico de Evolução\n(Implementar com fl_chart)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaSafras(List safras) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.table_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dados por Safra',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Safra')),
                  DataColumn(label: Text('Pontos')),
                  DataColumn(label: Text('Média (MPa)')),
                  DataColumn(label: Text('Min (MPa)')),
                  DataColumn(label: Text('Max (MPa)')),
                  DataColumn(label: Text('Classificação')),
                  DataColumn(label: Text('Áreas Críticas')),
                ],
                rows: safras.map<DataRow>((safra) {
                  return DataRow(
                    cells: [
                      DataCell(Text(safra['ano'].toString())),
                      DataCell(Text(safra['total_pontos'].toString())),
                      DataCell(Text((safra['media_compactacao'] as double).toStringAsFixed(2))),
                      DataCell(Text((safra['min_compactacao'] as double).toStringAsFixed(2))),
                      DataCell(Text((safra['max_compactacao'] as double).toStringAsFixed(2))),
                      DataCell(Text(safra['classificacao'])),
                      DataCell(Text(safra['areas_criticas'].toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTendenciasCard(List tendencias) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.compare_arrows,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tendências Entre Safras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tendencias.map<Widget>((tendencia) => _buildTendenciaItem(tendencia)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTendenciaItem(Map<String, dynamic> tendencia) {
    final cor = _getCorTendencia(tendencia['tendencia']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor),
      ),
      child: Row(
        children: [
          Icon(
            _getIconeTendencia(tendencia['tendencia']),
            color: cor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tendencia['de_safra']} → ${tendencia['para_safra']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${tendencia['tendencia']} (${(tendencia['variacao_percentual'] as double).toStringAsFixed(1)}%)',
                  style: TextStyle(color: cor),
                ),
                Text(
                  'Melhorou: ${tendencia['melhorou']} | Piorou: ${tendencia['piorou']} | Igual: ${tendencia['igual']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTendenciaCard() {
    final tendencia = _tendenciaAtual!;
    final cor = _getCorTendencia(tendencia['tendencia_geral']);
    
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconeTendencia(tendencia['tendencia_geral']),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tendência Atual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tendencia['tendencia_geral'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Variação: ${(tendencia['variacao_percentual'] as double).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              tendencia['interpretacao'],
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTendenciaStat('Melhorou', tendencia['melhorou'], Colors.green),
                _buildTendenciaStat('Piorou', tendencia['piorou'], Colors.red),
                _buildTendenciaStat('Igual', tendencia['igual'], Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistribuicaoCard() {
    final tendencia = _tendenciaAtual!;
    
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Distribuição de Tendências',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Aqui seria implementado um gráfico de pizza
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Gráfico de Distribuição\n(Implementar com fl_chart)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhesGruposCard() {
    final detalhes = _tendenciaAtual!['detalhes_grupos'] as List;
    
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.brown,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Detalhes por Localização',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: detalhes.length,
                itemBuilder: (context, index) {
                  final detalhe = detalhes[index];
                  return _buildDetalheItem(detalhe);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalheItem(Map<String, dynamic> detalhe) {
    final cor = detalhe['cor'] as String;
    final corFlutter = Color(int.parse(cor.replaceAll('#', '0xFF')));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: corFlutter.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: corFlutter),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: corFlutter,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(detalhe['latitude'] as double).toStringAsFixed(4)}, ${(detalhe['longitude'] as double).toStringAsFixed(4)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${detalhe['tendencia']} (${(detalhe['variacao_percentual'] as double).toStringAsFixed(1)}%)',
                  style: TextStyle(color: corFlutter),
                ),
                Text(
                  'Atual: ${(detalhe['media_atual'] as double).toStringAsFixed(2)} MPa | Anterior: ${(detalhe['media_anterior'] as double).toStringAsFixed(2)} MPa',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaCalor() {
    final dadosMapa = _mapaCalor!['dados_mapa'] as Map<String, dynamic>;
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: widget.polygonCoordinates.isNotEmpty
            ? _calcularCentroPoligono(widget.polygonCoordinates)
            : LatLng(-23.5505, -46.6333),
        zoom: 15,
        maxZoom: 18,
        minZoom: 10,
      ),
      children: [
        // Mapa base
        TileLayer(
          urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
          subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
        ),
        
        // Polígono do talhão
        PolygonLayer(
          polygons: [
            Polygon(
              points: widget.polygonCoordinates,
              color: Colors.blue.withOpacity(0.2),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        
        // Marcadores de tendência
        MarkerLayer(
          markers: dadosMapa.values.map<Marker>((dados) {
            final cor = dados['cor'] as String;
            final corFlutter = Color(int.parse(cor.replaceAll('#', '0xFF')));
            
            return Marker(
              point: LatLng(dados['latitude'], dados['longitude']),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: corFlutter,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getIconeTendencia(dados['tendencia']),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTendenciaStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getCorTendencia(String tendencia) {
    if (tendencia.contains('Melhora')) return Colors.green;
    if (tendencia.contains('Piora')) return Colors.red;
    return Colors.grey;
  }

  IconData _getIconeTendencia(String tendencia) {
    if (tendencia.contains('Melhora')) return Icons.trending_up;
    if (tendencia.contains('Piora')) return Icons.trending_down;
    return Icons.trending_flat;
  }

  LatLng _calcularCentroPoligono(List<LatLng> coords) {
    double sumLat = 0;
    double sumLng = 0;
    
    for (var coord in coords) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }
    
    return LatLng(sumLat / coords.length, sumLng / coords.length);
  }

  Future<void> _abrirMapaCompleto() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoilMapVisualizationScreen(
          talhaoId: widget.talhaoId,
          nomeTalhao: widget.nomeTalhao,
          polygonCoordinates: widget.polygonCoordinates,
        ),
      ),
    );
  }
}

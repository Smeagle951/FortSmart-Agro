import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/soil_compaction_point_model.dart';
import '../repositories/soil_compaction_point_repository.dart';
import '../services/soil_analysis_service.dart';
import '../services/soil_recommendation_service.dart';
import '../constants/app_colors.dart';
import 'soil_collection_screen.dart';

/// Tela de visualização dos pontos de compactação no mapa
class SoilMapVisualizationScreen extends StatefulWidget {
  final int talhaoId;
  final String nomeTalhao;
  final List<LatLng> polygonCoordinates;

  const SoilMapVisualizationScreen({
    Key? key,
    required this.talhaoId,
    required this.nomeTalhao,
    required this.polygonCoordinates,
  }) : super(key: key);

  @override
  State<SoilMapVisualizationScreen> createState() =>
      _SoilMapVisualizationScreenState();
}

class _SoilMapVisualizationScreenState
    extends State<SoilMapVisualizationScreen> {
  final MapController _mapController = MapController();
  List<SoilCompactionPointModel> _pontos = [];
  bool _isLoading = true;
  SoilCompactionPointModel? _pontoSelecionado;
  
  // Filtros
  bool _showSolto = true;
  bool _showModerado = true;
  bool _showAlto = true;
  bool _showCritico = true;
  bool _showNaoMedido = true;

  @override
  void initState() {
    super.initState();
    _carregarPontos();
  }

  Future<void> _carregarPontos() async {
    setState(() => _isLoading = true);
    
    try {
      final repository = Provider.of<SoilCompactionPointRepository>(
        context,
        listen: false,
      );
      
      final pontos = await repository.getByTalhao(widget.talhaoId);
      
      setState(() {
        _pontos = pontos;
        _isLoading = false;
      });
      
      // Centraliza mapa no primeiro ponto ou centro do polígono
      if (_pontos.isNotEmpty) {
        _mapController.move(
          LatLng(_pontos.first.latitude, _pontos.first.longitude),
          15,
        );
      } else if (widget.polygonCoordinates.isNotEmpty) {
        final centro = _calcularCentroPoligono(widget.polygonCoordinates);
        _mapController.move(centro, 15);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar pontos: $e')),
        );
      }
    }
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

  Color _getCorPorNivel(String nivel) {
    return SoilRecommendationService.getCorPorNivel(nivel);
  }

  bool _deveMostrarPonto(SoilCompactionPointModel ponto) {
    final nivel = ponto.penetrometria != null
        ? ponto.calcularNivelCompactacao()
        : 'Não Medido';
    
    switch (nivel) {
      case 'Solto':
        return _showSolto;
      case 'Moderado':
        return _showModerado;
      case 'Alto':
        return _showAlto;
      case 'Crítico':
        return _showCritico;
      case 'Não Medido':
        return _showNaoMedido;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.nomeTalhao,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarPontos,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Estatísticas
                _buildEstatisticasBar(),
                
                // Mapa
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
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
                            urlTemplate:
                                'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
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
                          
                          // Pontos de compactação
                          MarkerLayer(
                            markers: _pontos
                                .where(_deveMostrarPonto)
                                .map((ponto) => _criarMarker(ponto))
                                .toList(),
                          ),
                        ],
                      ),
                      
                      // Legenda
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _buildLegenda(),
                      ),
                    ],
                  ),
                ),
                
                // Painel de detalhes do ponto selecionado
                if (_pontoSelecionado != null) _buildPainelDetalhes(),
              ],
            ),
    );
  }

  Widget _buildEstatisticasBar() {
    if (_pontos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[200],
        child: const Center(
          child: Text('Nenhum ponto de coleta encontrado'),
        ),
      );
    }
    
    final estatisticas = SoilAnalysisService.calcularEstatisticas(_pontos);
    final classificacao = SoilAnalysisService.classificarTalhao(_pontos);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEstatItem(
                'Total de Pontos',
                '${estatisticas['totalPontos']}',
                Icons.location_on,
                Colors.blue,
              ),
              _buildEstatItem(
                'Medições',
                '${estatisticas['pontosComMedicao']}',
                Icons.assessment,
                Colors.green,
              ),
              _buildEstatItem(
                'Média',
                '${classificacao['media'].toStringAsFixed(2)} MPa',
                Icons.analytics,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getCorClassificacao(classificacao['classificacao'])
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              classificacao['classificacao'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getCorClassificacao(classificacao['classificacao']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCorClassificacao(String classificacao) {
    if (classificacao.contains('Adequado')) return Colors.green;
    if (classificacao.contains('Moderado')) return Colors.yellow[700]!;
    if (classificacao.contains('Alta')) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEstatItem(String label, String value, IconData icon, Color cor) {
    return Column(
      children: [
        Icon(icon, color: cor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Marker _criarMarker(SoilCompactionPointModel ponto) {
    final nivel = ponto.penetrometria != null
        ? ponto.calcularNivelCompactacao()
        : 'Não Medido';
    final cor = _getCorPorNivel(nivel);
    final isSelected = _pontoSelecionado?.id == ponto.id;
    
    return Marker(
      point: LatLng(ponto.latitude, ponto.longitude),
      width: isSelected ? 50 : 40,
      height: isSelected ? 50 : 40,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _pontoSelecionado = ponto;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Text(
              ponto.pointCode.replaceAll('C-', ''),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSelected ? 12 : 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegenda() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nível de Compactação',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildLegendaItem('Solto', '< 1,5 MPa', const Color(0xFF4CAF50)),
            _buildLegendaItem('Moderado', '1,5-2,0 MPa', const Color(0xFFFFEB3B)),
            _buildLegendaItem('Alto', '2,0-2,5 MPa', const Color(0xFFFF9800)),
            _buildLegendaItem('Crítico', '> 2,5 MPa', const Color(0xFFF44336)),
            _buildLegendaItem('Não Medido', '-', const Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaItem(String nivel, String faixa, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$nivel ($faixa)',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelDetalhes() {
    final ponto = _pontoSelecionado!;
    final nivel = ponto.penetrometria != null
        ? ponto.calcularNivelCompactacao()
        : 'Não Medido';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ponto ${ponto.pointCode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _pontoSelecionado = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetalheItem(
                  'Penetrometria',
                  ponto.penetrometria != null
                      ? '${ponto.penetrometria!.toStringAsFixed(2)} MPa'
                      : 'Não medido',
                ),
              ),
              Expanded(
                child: _buildDetalheItem(
                  'Nível',
                  nivel,
                  cor: _getCorPorNivel(nivel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SoilCollectionScreen(
                        ponto: ponto,
                        talhaoId: widget.talhaoId,
                        nomeTalhao: widget.nomeTalhao,
                      ),
                    ),
                  );
                  
                  if (resultado == true) {
                    _carregarPontos();
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _mostrarDetalhesCompletos(ponto);
                },
                icon: const Icon(Icons.info),
                label: const Text('Detalhes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheItem(String label, String value, {Color? cor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filtrar Pontos por Nível',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                title: const Text('Solto'),
                value: _showSolto,
                onChanged: (value) {
                  setModalState(() => _showSolto = value!);
                  setState(() => _showSolto = value!);
                },
                secondary: const CircleAvatar(backgroundColor: Color(0xFF4CAF50)),
              ),
              CheckboxListTile(
                title: const Text('Moderado'),
                value: _showModerado,
                onChanged: (value) {
                  setModalState(() => _showModerado = value!);
                  setState(() => _showModerado = value!);
                },
                secondary: const CircleAvatar(backgroundColor: Color(0xFFFFEB3B)),
              ),
              CheckboxListTile(
                title: const Text('Alto'),
                value: _showAlto,
                onChanged: (value) {
                  setModalState(() => _showAlto = value!);
                  setState(() => _showAlto = value!);
                },
                secondary: const CircleAvatar(backgroundColor: Color(0xFFFF9800)),
              ),
              CheckboxListTile(
                title: const Text('Crítico'),
                value: _showCritico,
                onChanged: (value) {
                  setModalState(() => _showCritico = value!);
                  setState(() => _showCritico = value!);
                },
                secondary: const CircleAvatar(backgroundColor: Color(0xFFF44336)),
              ),
              CheckboxListTile(
                title: const Text('Não Medido'),
                value: _showNaoMedido,
                onChanged: (value) {
                  setModalState(() => _showNaoMedido = value!);
                  setState(() => _showNaoMedido = value!);
                },
                secondary: const CircleAvatar(backgroundColor: Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalhesCompletos(SoilCompactionPointModel ponto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ponto ${ponto.pointCode}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoDialog('Penetrometria', '${ponto.penetrometria ?? "N/A"} MPa'),
              _buildInfoDialog('Umidade', '${ponto.umidade ?? "N/A"}%'),
              _buildInfoDialog('Textura', ponto.textura ?? 'N/A'),
              _buildInfoDialog('Estrutura', ponto.estrutura ?? 'N/A'),
              _buildInfoDialog('Profundidade', '${ponto.profundidadeInicio.toInt()}-${ponto.profundidadeFim.toInt()} cm'),
              _buildInfoDialog('Coordenadas', '${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}'),
              if (ponto.observacoes != null && ponto.observacoes!.isNotEmpty)
                _buildInfoDialog('Observações', ponto.observacoes!),
            ],
          ),
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

  Widget _buildInfoDialog(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}


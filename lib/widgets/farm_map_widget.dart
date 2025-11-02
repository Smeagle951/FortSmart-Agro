import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../models/cultura_model.dart';
import '../modules/monitoring/models/alert_model.dart';
import '../repositories/talhao_repository.dart';
import '../modules/monitoring/repositories/alert_repository.dart';
import '../modules/monitoring/services/data_cache_service.dart';
import '../utils/logger.dart';

class FarmMapWidget extends StatefulWidget {
  final String? farmId;
  final double height;
  final Function(TalhaoModel, bool)? onTalhaoTap;
  final BuildContext? navigatorContext;

  const FarmMapWidget({
    Key? key,
    this.farmId,
    this.height = 300,
    this.onTalhaoTap,
    this.navigatorContext,
  }) : super(key: key);

  @override
  State<FarmMapWidget> createState() => _FarmMapWidgetState();
}

class _FarmMapWidgetState extends State<FarmMapWidget> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final AlertRepository _alertRepository = AlertRepository();
  final MonitoringDataCacheService _dataCacheService = MonitoringDataCacheService();
  
  List<TalhaoModel> _talhoes = [];
  List<CulturaModel> _culturas = [];
  List<AlertModel> _alertas = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Para animação do alerta
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Configurar animação para o ícone de alerta piscar
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_animationController);
    
    _loadData();
    
    // Atualizar dados a cada 30 segundos
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Carregar talhões
      List<TalhaoModel> talhoes;
      if (widget.farmId != null) {
        talhoes = await _talhaoRepository.buscarTalhoesPorFazenda(widget.farmId!);
      } else {
        talhoes = await _dataCacheService.getTalhoes(forceRefresh: true);
      }
      
      // Carregar culturas para colorir os talhões
      final culturas = await _dataCacheService.getCulturas(forceRefresh: true);
      // O método getCulturas() já retorna uma lista de CulturaModel, não é necessário conversão
      
      // Carregar alertas para mostrar ícones de alerta
      final alertas = await _alertRepository.getAll();
      
      if (mounted) {
        setState(() {
          _talhoes = talhoes;
          _culturas = culturas;
          _alertas = alertas;
          _isLoading = false;
          
          // Centralizar o mapa no primeiro talhão se houver
          if (talhoes.isNotEmpty && talhoes.first.polygon.isNotEmpty) {
            _centralizarMapa(talhoes);
          }
        });
      }
    } catch (e) {
      Logger.error('FarmMapWidget', 'Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Erro ao carregar dados do mapa: $e';
        });
      }
    }
  }
  
  void _centralizarMapa(List<TalhaoModel> talhoes) {
    // Calcular o centro de todos os talhões
    double latSum = 0;
    double lngSum = 0;
    int pointCount = 0;
    
    for (var talhao in talhoes) {
      if (talhao.polygon.isNotEmpty) {
        for (var coord in talhao.polygon) {
          latSum += coord.latitude;
          lngSum += coord.longitude;
          pointCount++;
        }
      }
    }
    
    if (pointCount > 0) {
      final centerLat = latSum / pointCount;
      final centerLng = lngSum / pointCount;
      _mapController.move(LatLng(centerLat, centerLng), 13);
    }
  }
  
  Color _getColorByCultura(dynamic cropId) {
    if (cropId == null) return Color(int.parse('0xFF9E9E9E'));
    String cropIdStr = cropId.toString();
    final cultura = _culturas.firstWhere(
      (c) => c.id.toString() == cropIdStr,
      orElse: () => CulturaModel(
        id: '',
        nome: '',
        descricao: '',
        ciclo: '',
        tipo: '',
        cor: '0xFF9E9E9E', // Cinza em formato string
      ),
    );
    // Retornar a cor da cultura ou uma cor baseada no nome
    if (cultura.cor != '0xFF9E9E9E') {
      // Converter a string para Color
      return cultura.color; // Usa o getter color que converte para Color
    }
    // Cores padrão por tipo de cultura (usando strings hexadecimais)
    switch (cultura.nome.toLowerCase()) {
      case 'soja':
        return Color(int.parse('0xFF4CAF50')); // Verde
      case 'milho':
        return Color(int.parse('0xFFFFEB3B')); // Amarelo
      case 'algodão':
      case 'algodao':
        return Color(int.parse('0xFF1976D2')); // Azul mais escuro para melhor contraste
      case 'feijão':
      case 'feijao':
        return Color(int.parse('0xFF795548')); // Marrom
      case 'trigo':
        return Color(int.parse('0xFFFFC107')); // Âmbar
      case 'café':
      case 'cafe':
        return Color(int.parse('0xFF5D4037')); // Marrom escuro
      case 'cana':
      case 'cana-de-açúcar':
      case 'cana-de-acucar':
        return Color(int.parse('0xFF2E7D32')); // Verde escuro
      default:
        // Gerar uma cor baseada no nome da cultura
        final hash = cultura.nome.hashCode;
        return Color((hash & 0xFFFFFF) | 0xFF000000);
    }
  }
  
  IconData _getIconByCultura(String? culturaId) {
    if (culturaId == null) return Icons.grass;
    
    final cultura = _culturas.firstWhere(
      (c) => c.id == culturaId,
      orElse: () => CulturaModel(
        id: '',
        nome: '',
        descricao: '',
        ciclo: '',
        tipo: '',
        cor: '#808080',
      ),
    );
    
    // Ícones por tipo de cultura
    switch (cultura.nome.toLowerCase()) {
      case 'soja':
        return Icons.grass;
      case 'milho':
        return Icons.agriculture;
      case 'algodão':
      case 'algodao':
        return Icons.spa;
      case 'feijão':
      case 'feijao':
        return Icons.grain;
      case 'trigo':
        return Icons.grass_outlined;
      case 'café':
      case 'cafe':
        return Icons.coffee;
      case 'cana':
      case 'cana-de-açúcar':
      case 'cana-de-acucar':
        return Icons.grass;
      default:
        return Icons.grass;
    }
  }
  
  bool _talhaoTemAlerta(String talhaoId) {
    return _alertas.any((alerta) => alerta.talhaoId == talhaoId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mapa dos Talhões',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A4F3D),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF2A4F3D)),
                  onPressed: _loadData,
                  tooltip: 'Atualizar mapa',
                ),
              ],
            ),
          ),
          SizedBox(
            height: widget.height,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2A4F3D)))
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(
                                // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      )
                    : _talhoes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nenhum talhão cadastrado.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Adicione talhões para visualizá-los no mapa.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center: LatLng(-15.7801, -47.9292), // Brasília como padrão
                                zoom: 5,
                                // interactionOptions não é suportado no flutter_map 5.0.0
                                // onTap: (_, // onTap não é suportado em Polygon no flutter_map 5.0.0 __) {}, // Evitar que o mapa capture o tap quando queremos clicar em um talhão
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.fortsmart.agro',
                                ),
                                PolygonLayer(
                                  polygons: _talhoes.map((talhao) {
                                    final hasAlerta = _talhaoTemAlerta(talhao.id);
                                    final cropId = talhao.cropId;
                                    
                                    return Polygon(
                                      points: talhao.points.map((coord) => LatLng(coord.latitude, coord.longitude)).toList(),
                                      color: _getColorByCultura(cropId).withOpacity(0.5),
                                      borderColor: _getColorByCultura(cropId),
                                      borderStrokeWidth: 2,
                                      isFilled: true,
                                      label: talhao.nome,
                                      // Nota: onTap não é suportado em Polygon no flutter_map 5.0.0
                                      // Para implementar interatividade, considere usar PolygonLayer com GestureDetector
                                      /* 
                                      // Código comentado para referência futura:
                                      // Implementação anterior que usava onTap:
                                      // onTap: () {
                                      //   final context = widget.navigatorContext ?? this.context;
                                      //   if (hasAlerta) {
                                      //     final nivelSeveridade = _getAlertaSeveridade(talhao.id);
                                      //     double severidadeMedia = 0;
                                      //     switch (nivelSeveridade) {
                                      //       case SeveridadeLevel.BAIXO:
                                      //         severidadeMedia = 20;
                                      //         break;
                                      //       case SeveridadeLevel.MODERADO:
                                      //         severidadeMedia = 50;
                                      //         break;
                                      //       case SeveridadeLevel.ALTO:
                                      //         severidadeMedia = 75;
                                      //         break;
                                      //       case SeveridadeLevel.CRITICO:
                                      //         severidadeMedia = 95;
                                      //         break;
                                      //     }
                                      //     final talhaoResumo = TalhaoResumoModel(
                                      //       talhaoId: talhao.id,
                                      //       talhaoNome: talhao.nome,
                                      //       severidadeMedia: severidadeMedia,
                                      //       nivelSeveridade: nivelSeveridade,
                                      //       corSeveridade: TalhaoResumoModel.getCorPorSeveridade(severidadeMedia),
                                      //       principaisOcorrencias: _getOcorrenciasDoTalhao(talhao.id),
                                      //       ultimaAtualizacao: DateTime.now(),
                                      //     );
                                      //     Navigator.pushNamed(
                                      //       context,
                                      //       AppRoutes.listaAlertas,
                                      //       arguments: {
                                      //         'resumos': [talhaoResumo],
                                      //       },
                                      //     );
                                      //   } else if (widget.onTalhaoTap != null) {
                                      //     widget.onTalhaoTap!(talhao, hasAlerta);
                                      //   }
                                      // },
                                      */
                                    );
                                  }).toList(),
                                ),
                                // Ícones das culturas no centro dos talhões
                                MarkerLayer(
                                  markers: _talhoes.map((talhao) {
                                    // Calcular o centro do talhão
                                    double latSum = 0;
                                    double lngSum = 0;
                                    
                                    for (var coord in talhao.polygon) {
                                      latSum += coord.latitude;
                                      lngSum += coord.longitude;
                                    }
                                    
                                    final centerLat = latSum / talhao.polygon.length;
                                    final centerLng = lngSum / talhao.polygon.length;
                                    
                                    return Marker(
                                      point: LatLng(centerLat, centerLng),
                                      width: 30,
                                      height: 30,
                                      builder: (context) => Icon(
                                        _getIconByCultura(talhao.culturaId?.toString()),
                                        color: const Color(0xFFFFFFFF), // Branco em formato hexadecimal
                                        size: 20,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                // Ícones de alerta
                                MarkerLayer(
                                  markers: _talhoes.where((talhao) => _talhaoTemAlerta(talhao.id)).map((talhao) {
                                    // Calcular o centro do talhão
                                    double latSum = 0;
                                    double lngSum = 0;
                                    
                                    for (var coord in talhao.polygon) {
                                      latSum += coord.latitude;
                                      lngSum += coord.longitude;
                                    }
                                    
                                    final centerLat = latSum / talhao.polygon.length;
                                    final centerLng = lngSum / talhao.polygon.length;
                                    
                                    return Marker(
                                      point: LatLng(centerLat, centerLng),
                                      width: 40,
                                      height: 40,
                                      builder: (context) => FadeTransition(
                                        opacity: _opacityAnimation,
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          color: const Color(0xFFF44336), // Vermelho em formato hexadecimal
                                          size: 30,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
  }
}

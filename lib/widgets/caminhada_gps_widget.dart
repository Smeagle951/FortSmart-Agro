import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/geo_math.dart';

/// Widget para o modo de caminhada GPS
/// Permite criar talhões caminhando pelo perímetro com o GPS
class CaminhadaGpsWidget extends StatefulWidget {
  final MapController mapController;
  final List<LatLng> pontos;
  final Color cor;
  final Function(LatLng) onPontoAdicionado;
  final Function() onDesenhoLimpo;
  final Function(List<LatLng>) onDesenhoCompleto;
  final bool mostrarControles;
  final bool mostrarArea;
  final double distanciaMinima; // Distância mínima entre pontos em metros

  const CaminhadaGpsWidget({
    Key? key,
    required this.mapController,
    required this.pontos,
    required this.cor,
    required this.onPontoAdicionado,
    required this.onDesenhoLimpo,
    required this.onDesenhoCompleto,
    this.mostrarControles = true,
    this.mostrarArea = true,
    this.distanciaMinima = 5.0, // 5 metros por padrão
  }) : super(key: key);

  @override
  State<CaminhadaGpsWidget> createState() => _CaminhadaGpsWidgetState();
}

class _CaminhadaGpsWidgetState extends State<CaminhadaGpsWidget> {
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _rastreando = false;
  bool _poligonoFechado = false;
  LatLng? _posicaoAtual;
  final Distance _distance = const Distance();
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _pararRastreamento();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camada de polígono
        _buildPoligonoLayer(),
        
        // Camada de pontos
        _buildPontosLayer(),
        
        // Posição atual
        if (_posicaoAtual != null) _buildPosicaoAtualLayer(),
        
        // Controles de rastreamento
        if (widget.mostrarControles) _buildControles(),
        
        // Informação de área
        if (widget.mostrarArea && widget.pontos.length >= 3) _buildInfoArea(),
        
        // Status de rastreamento
        _buildStatusRastreamento(),
      ],
    );
  }
  
  /// Constrói a camada de polígono
  Widget _buildPoligonoLayer() {
    if (widget.pontos.isEmpty) return const SizedBox.shrink();
    
    return PolygonLayer(
      polygons: [
        Polygon(
          points: widget.pontos,
          color: widget.cor.withOpacity(0.3),
          borderColor: widget.cor,
          borderStrokeWidth: 2.0,
          isFilled: _poligonoFechado,
        ),
      ],
    );
  }
  
  /// Constrói a camada de pontos
  Widget _buildPontosLayer() {
    if (widget.pontos.isEmpty) return const SizedBox.shrink();
    
    return MarkerLayer(
      markers: [
        // Marcadores para cada ponto do polígono
        for (int i = 0; i < widget.pontos.length; i++)
          Marker(
            point: widget.pontos[i],
            width: 14,
            height: 14,
            child: Container(
              decoration: BoxDecoration(
                color: i == 0 ? widget.cor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.cor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: i == 0
                  ? const Icon(Icons.flag, size: 8, color: Colors.white)
                  : null,
            ),
          ),
        
        // Marcador para o primeiro ponto (destacado)
        if (widget.pontos.length >= 3)
          Marker(
            point: widget.pontos.first,
            width: 24,
            height: 24,
            child: GestureDetector(
              onTap: _fecharPoligono,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.cor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: widget.cor,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Constrói a camada de posição atual
  Widget _buildPosicaoAtualLayer() {
    if (_posicaoAtual == null) return const SizedBox.shrink();
    
    return MarkerLayer(
      markers: [
        Marker(
          point: _posicaoAtual!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Constrói os controles de rastreamento
  Widget _buildControles() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão para iniciar/parar rastreamento
          FloatingActionButton(
            heroTag: 'rastreamento_gps',
            onPressed: _rastreando ? _pararRastreamento : _iniciarRastreamento,
            backgroundColor: _rastreando ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            elevation: 4,
            tooltip: _rastreando ? 'Parar rastreamento' : 'Iniciar rastreamento',
            child: Icon(_rastreando ? Icons.stop : Icons.play_arrow),
          ),
          const SizedBox(height: 8),
          
          // Botão para limpar desenho
          if (widget.pontos.isNotEmpty)
            FloatingActionButton.small(
              heroTag: 'limpar_caminhada',
              onPressed: () {
                _pararRastreamento();
                widget.onDesenhoLimpo();
              },
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[900],
              elevation: 4,
              tooltip: 'Limpar caminhada',
              child: const Icon(Icons.delete_outline),
            ),
          const SizedBox(height: 8),
          
          // Botão para completar desenho
          if (widget.pontos.length >= 3)
            FloatingActionButton.small(
              heroTag: 'completar_caminhada',
              onPressed: _fecharPoligono,
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              elevation: 4,
              tooltip: 'Completar caminhada',
              child: const Icon(Icons.check),
            ),
        ],
      ),
    );
  }
  
  /// Constrói o widget de informação de área
  Widget _buildInfoArea() {
    final area = GeoMath.calcularArea(widget.pontos);
    final areaFormatada = GeoMath.formatarArea(area);
    final perimetro = GeoMath.calcularPerimetro(widget.pontos);
    final perimetroFormatado = _formatarPerimetro(perimetro);
    
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: widget.cor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.area_chart,
                  color: widget.cor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Área: $areaFormatada',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.straighten,
                  color: widget.cor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Perímetro: $perimetroFormatado',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Constrói o indicador de status de rastreamento
  Widget _buildStatusRastreamento() {
    if (!_rastreando) return const SizedBox.shrink();
    
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Gravando caminhada',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Inicia o rastreamento GPS
  Future<void> _iniciarRastreamento() async {
    // Verificar permissões
    final permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      final solicitacao = await Geolocator.requestPermission();
      if (solicitacao == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização negada'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    if (permissao == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissões de localização negadas permanentemente. '
              'Por favor, habilite-as nas configurações do dispositivo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Iniciar rastreamento
    setState(() {
      _rastreando = true;
    });
    
    // Configurar stream de localização
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Atualizar a cada 2 metros
      ),
    ).listen(_processarPosicao);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rastreamento GPS iniciado'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  /// Para o rastreamento GPS
  void _pararRastreamento() {
    _positionStreamSubscription?.cancel();
    
    setState(() {
      _rastreando = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rastreamento GPS parado'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
  
  /// Processa uma nova posição GPS
  void _processarPosicao(Position position) {
    final novaPosicao = LatLng(position.latitude, position.longitude);
    
    setState(() {
      _posicaoAtual = novaPosicao;
    });
    
    // Centralizar mapa na posição atual
    widget.mapController.move(novaPosicao, widget.mapController.zoom);
    
    // Verificar se deve adicionar o ponto
    if (widget.pontos.isEmpty) {
      // Primeiro ponto, adicionar sempre
      widget.onPontoAdicionado(novaPosicao);
    } else {
      // Verificar distância mínima
      final ultimoPonto = widget.pontos.last;
      final distancia = _distance.as(
        LengthUnit.Meter,
        ultimoPonto,
        novaPosicao,
      );
      
      if (distancia >= widget.distanciaMinima) {
        widget.onPontoAdicionado(novaPosicao);
        
        // Processamento dos pontos adicionados
        if (widget.pontos.length > 3) {
          // Código para processamento dos pontos, se necessário
          
          if (widget.pontos.length > 3) {
            // Implementação futura: substituir pontos
          }
        }
      }
    }
  }
  
  /// Fecha o polígono e completa a caminhada
  void _fecharPoligono() {
    if (widget.pontos.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('São necessários pelo menos 3 pontos para formar um polígono'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Parar rastreamento se estiver ativo
    if (_rastreando) {
      _pararRastreamento();
    }
    
    setState(() {
      _poligonoFechado = true;
    });
    
    // Usar os pontos originais sem filtro
    List<LatLng> pontosFiltrados = widget.pontos;
    
    // Notificar que o desenho foi completado
    widget.onDesenhoCompleto(pontosFiltrados);
  }
  
  /// Formata o perímetro para exibição
  String _formatarPerimetro(double perimetroMetros) {
    if (perimetroMetros < 1000) {
      return '${perimetroMetros.toStringAsFixed(0)} m';
    } else {
      final km = perimetroMetros / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }
}

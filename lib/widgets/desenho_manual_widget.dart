import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/geo_math.dart';
import '../utils/validador_talhao.dart';

/// Widget para o modo de desenho manual de talhões
/// Permite desenhar polígonos diretamente no mapa
class DesenhoManualWidget extends StatefulWidget {
  final MapController mapController;
  final List<LatLng> pontos;
  final Color cor;
  final Function(LatLng) onPontoAdicionado;
  final Function(int) onPontoRemovido;
  final Function() onDesenhoLimpo;
  final Function(List<LatLng>) onDesenhoCompleto;
  final bool mostrarControles;
  final bool mostrarArea;

  const DesenhoManualWidget({
    Key? key,
    required this.mapController,
    required this.pontos,
    required this.cor,
    required this.onPontoAdicionado,
    required this.onPontoRemovido,
    required this.onDesenhoLimpo,
    required this.onDesenhoCompleto,
    this.mostrarControles = true,
    this.mostrarArea = true,
  }) : super(key: key);

  @override
  State<DesenhoManualWidget> createState() => _DesenhoManualWidgetState();
}

class _DesenhoManualWidgetState extends State<DesenhoManualWidget> {
  bool _arrastando = false;
  int? _pontoSelecionado;
  bool _poligonoFechado = false;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camada de polígono
        _buildPoligonoLayer(),
        
        // Camada de pontos interativos
        _buildPontosLayer(),
        
        // Controles de desenho
        if (widget.mostrarControles) _buildControles(),
        
        // Informação de área
        if (widget.mostrarArea && widget.pontos.length >= 3) _buildInfoArea(),
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
  
  /// Constrói a camada de pontos interativos
  Widget _buildPontosLayer() {
    if (widget.pontos.isEmpty) return const SizedBox.shrink();
    
    return MarkerLayer(
      markers: [
        // Marcadores para cada ponto do polígono
        for (int i = 0; i < widget.pontos.length; i++)
          Marker(
            point: widget.pontos[i],
            width: 20,
            height: 20,
            child: GestureDetector(
              onTap: () => _selecionarPonto(i),
              onPanStart: (_) => _iniciarArrasto(i),
              onPanUpdate: (details) => _atualizarArrasto(details, i),
              onPanEnd: (_) => _finalizarArrasto(),
              child: Container(
                decoration: BoxDecoration(
                  color: _pontoSelecionado == i ? Colors.red : Colors.white,
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
                child: _pontoSelecionado == i
                    ? const Icon(Icons.close, size: 12, color: Colors.white)
                    : null,
              ),
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
  
  /// Constrói os controles de desenho
  Widget _buildControles() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão para desfazer último ponto
          if (widget.pontos.isNotEmpty)
            FloatingActionButton.small(
              heroTag: 'desfazer_ponto',
              onPressed: _removerUltimoPonto,
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[700],
              elevation: 4,
              tooltip: 'Remover último ponto',
              child: const Icon(Icons.undo),
            ),
          const SizedBox(height: 8),
          
          // Botão para limpar desenho
          if (widget.pontos.isNotEmpty)
            FloatingActionButton.small(
              heroTag: 'limpar_desenho',
              onPressed: widget.onDesenhoLimpo,
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[900],
              elevation: 4,
              tooltip: 'Limpar desenho',
              child: const Icon(Icons.delete_outline),
            ),
          const SizedBox(height: 8),
          
          // Botão para completar desenho
          if (widget.pontos.length >= 3)
            FloatingActionButton.small(
              heroTag: 'completar_desenho',
              onPressed: _fecharPoligono,
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              elevation: 4,
              tooltip: 'Completar desenho',
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
        child: Row(
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
      ),
    );
  }
  
  /// Seleciona um ponto para edição ou remoção
  void _selecionarPonto(int indice) {
    setState(() {
      if (_pontoSelecionado == indice) {
        // Se o ponto já está selecionado, remove-o
        widget.onPontoRemovido(indice);
        _pontoSelecionado = null;
      } else {
        // Seleciona o ponto
        _pontoSelecionado = indice;
      }
    });
  }
  
  /// Inicia o arrasto de um ponto
  void _iniciarArrasto(int indice) {
    setState(() {
      _arrastando = true;
      _pontoSelecionado = indice;
    });
  }
  
  /// Atualiza a posição do ponto durante o arrasto
  void _atualizarArrasto(DragUpdateDetails details, int indice) {
    if (!_arrastando || _pontoSelecionado == null || _pontoSelecionado != indice) return;
    
    // Converter o ponto de tela para coordenadas do mapa
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Obter as coordenadas do mapa
    final novoLatLng = widget.mapController.pointToLatLng(
      CustomPoint(localPosition.dx, localPosition.dy),
    );
    
    if (novoLatLng != null) {
      // Atualizar a lista de pontos
      final novosPontos = List<LatLng>.from(widget.pontos);
      novosPontos[indice] = novoLatLng;
      
      // Notificar a mudança
      widget.onPontoRemovido(indice);
      widget.onPontoAdicionado(novoLatLng);
    }
  }
  
  /// Finaliza o arrasto de um ponto
  void _finalizarArrasto() {
    setState(() {
      _arrastando = false;
    });
  }
  
  /// Remove o último ponto adicionado
  void _removerUltimoPonto() {
    if (widget.pontos.isNotEmpty) {
      widget.onPontoRemovido(widget.pontos.length - 1);
      setState(() {
        _pontoSelecionado = null;
      });
    }
  }
  
  /// Fecha o polígono e completa o desenho
  void _fecharPoligono() {
    if (widget.pontos.length < 3) return;
    
    // Verificar se o polígono é válido
    if (!ValidadorTalhao.isPoligonoValido(widget.pontos)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ValidadorTalhao.getMensagemErro(widget.pontos)),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }
    
    setState(() {
      _poligonoFechado = true;
    });
    
    // Notificar que o desenho foi completado
    widget.onDesenhoCompleto(widget.pontos);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide PolygonPainter;
import '../polygon_painter.dart';
import '../../../providers/cultura_provider.dart';
import '../../../models/cultura_model.dart';
import '../providers/desenho_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/talhao_info_card_v2.dart';
import '../../../widgets/talhao_editor_modal.dart';
import '../../../utils/glass_morphism.dart';

/// Widget de overlay para desenhar o polígono do talhão com a cor da cultura selecionada
class PolygonOverlayWidget extends StatefulWidget {
  final String? culturaId;
  final String? nomeTalhao;
  final String? nomeSafra;
  final MapController mapController;

  const PolygonOverlayWidget({
    Key? key,
    this.culturaId,
    this.nomeTalhao,
    this.nomeSafra,
    required this.mapController,
  }) : super(key: key);

  @override
  State<PolygonOverlayWidget> createState() => _PolygonOverlayWidgetState();
}

class _PolygonOverlayWidgetState extends State<PolygonOverlayWidget> {
  bool _showInfoCard = false;
  Offset _infoCardPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Consumer2<DesenhoProvider, CulturaProvider>(
      builder: (context, desenhoProvider, culturaProvider, child) {
        // Se não há pontos, não renderiza nada
        if (desenhoProvider.pontos.isEmpty) {
          return const SizedBox.shrink();
        }

        // Converte pontos de LatLng para Offset na tela
        final List<Offset> pontosNaTela = desenhoProvider.pontos.map((ponto) {
          final pixelPos = widget.mapController.latLngToScreenPoint(ponto);
          return pixelPos != null ? Offset(pixelPos.x.toDouble(), pixelPos.y.toDouble()) : Offset.zero;
        }).toList();

        // Usa cor verde padrão para todos os polígonos (sem cores por cultura)
        Color corPoligono = Colors.green;
        
        // Obtém o nome da cultura selecionada para exibir no polígono (se necessário)
        String? nomeCultura;
        if (widget.culturaId != null) {
          final cultura = culturaProvider.obterCulturaPorId(widget.culturaId!);
          if (cultura != null) {
            nomeCultura = cultura.nome;
          }
        }

        // Calcula o centro do polígono para posicionar o card de informações
        if (pontosNaTela.isNotEmpty && desenhoProvider.desenhoConcluido) {
          double sumX = 0;
          double sumY = 0;
          for (var ponto in pontosNaTela) {
            sumX += ponto.dx;
            sumY += ponto.dy;
          }
          _infoCardPosition = Offset(sumX / pontosNaTela.length, sumY / pontosNaTela.length);
        }

        return Stack(
          children: [
            // Detector de gestos para capturar toques no polígono
            GestureDetector(
              onTap: () {
                // Verifica se o desenho está concluído antes de mostrar o card
                if (desenhoProvider.desenhoConcluido) {
                  setState(() {
                    _showInfoCard = !_showInfoCard;
                  });
                }
              },
              child: CustomPaint(
                painter: PolygonPainter(
                  pontos: pontosNaTela,
                  corPoligono: corPoligono,
                  desenharVertices: true, // Sempre desenhar os vértices quando há pontos
                  desenhoConcluido: desenhoProvider.desenhoConcluido,
                  modoEdicao: true, // Sempre em modo edição quando estiver desenhando
                  nomeCultura: nomeCultura,
                  area: desenhoProvider.areaCalculada > 0 
                      ? '${desenhoProvider.areaCalculada.toStringAsFixed(2)} ha' 
                      : null,
                ),
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              ),
            ),
            
            // Card de informações do talhão
            if (_showInfoCard && desenhoProvider.desenhoConcluido)
              Positioned(
                left: _infoCardPosition.dx - 130, // Centraliza o card (largura do card é 260)
                top: _infoCardPosition.dy - 100, // Posiciona acima do centro do polígono
                child: TalhaoInfoCardV2(
                  nomeTalhao: widget.nomeTalhao ?? 'Novo Talhão',
                  nomeCultura: nomeCultura,
                  nomeSafra: widget.nomeSafra,
                  area: desenhoProvider.areaCalculada,
                  corCultura: corPoligono,
                  pontos: desenhoProvider.pontos,
                  onClose: () {
                    setState(() {
                      _showInfoCard = false;
                    });
                  },
                  onEdit: () {
                    // Abrir modal de edição do talhão
                    _abrirModalEdicao(context, desenhoProvider);
                  },
                  onViewDetails: () {
                    // Implementar ação de visualizar detalhes
                    setState(() {
                      _showInfoCard = false;
                    });
                    // Navegar para tela de detalhes
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  /// Abre modal de edição do talhão
  void _abrirModalEdicao(BuildContext context, DesenhoProvider desenhoProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: TalhaoEditorModal(
          nomeTalhao: widget.nomeTalhao ?? 'Novo Talhão',
          nomeCultura: widget.culturaId,
          nomeSafra: widget.nomeSafra,
          area: desenhoProvider.areaCalculada,
          pontos: desenhoProvider.pontos,
          onSave: (talhaoAtualizado) {
            // Atualizar dados do talhão
            setState(() {
              _showInfoCard = false;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Talhão atualizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onCancel: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

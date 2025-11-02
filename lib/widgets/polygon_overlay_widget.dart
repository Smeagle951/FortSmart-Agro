import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide PolygonPainter;
import 'polygon_painter.dart';
import '../../../providers/cultura_provider.dart';
import '../../../models/cultura_model.dart';
import '../providers/desenho_provider.dart';
import 'package:provider/provider.dart';
import '../../../utils/glass_morphism.dart';
// import 'talhao_info_card_v2.dart'; // Arquivo não encontrado

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
            nomeCultura = cultura.name;
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
            
            // Card de informações do talhão com estilo de vidro transparente
            if (_showInfoCard && desenhoProvider.desenhoConcluido)
              Positioned(
                left: _infoCardPosition.dx - 140, // Centraliza o card (largura do card é 280)
                top: _infoCardPosition.dy - 110, // Posiciona acima do centro do polígono
                child: GlassMorphism(
                  blur: 15,
                  opacity: 0.25,
                  radius: 16,
                  padding: const EdgeInsets.all(20),
                  borderColor: Colors.white.withOpacity(0.3),
                  borderWidth: 1.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título do talhão
                      Text(
                        widget.nomeTalhao ?? 'Novo Talhão',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Informações do talhão
                      _buildInfoRow(Icons.eco, 'Cultura', nomeCultura ?? 'Não definida'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.calendar_today, 'Safra', widget.nomeSafra ?? 'Não definida'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.area_chart, 'Área', '${desenhoProvider.areaCalculada.toStringAsFixed(2)} ha'),
                      
                      const SizedBox(height: 16),
                      
                      // Botões de ação
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showInfoCard = false;
                                });
                                // Implementar ação de edição do talhão
                                _showEditDialog(context, desenhoProvider);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Editar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showInfoCard = false;
                                });
                                // Implementar ação de deletar o talhão
                                _showDeleteDialog(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_forever, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Deletar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Constrói uma linha de informação elegante
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mostra o diálogo de edição do talhão
  void _showEditDialog(BuildContext context, DesenhoProvider desenhoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.green),
            SizedBox(width: 8),
            Text('Editar Talhão'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Funcionalidades de edição em desenvolvimento...'),
              const SizedBox(height: 16),
              const Text('Em breve você poderá:'),
              const SizedBox(height: 8),
              const Text('• Editar nome do talhão'),
              const Text('• Alterar cultura'),
              const Text('• Selecionar cor personalizada'),
              const Text('• Editar safra'),
              const Text('• Ajustar área'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostra o diálogo de confirmação para deletar o talhão
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Deletar Talhão'),
          ],
        ),
        content: const Text(
          'Tem certeza que deseja deletar este talhão?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar lógica de deletar talhão
              _deleteTalhao(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  /// Deleta o talhão atual
  void _deleteTalhao(BuildContext context) {
    // Implementar lógica de deletar talhão
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de deletar talhão em desenvolvimento...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

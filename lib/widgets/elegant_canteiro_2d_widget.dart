import 'package:flutter/material.dart';
import '../models/canteiro_model.dart';

/// Widget elegante 2D para visualização e interação com canteiros
/// Estrutura 7x3 (7 colunas x 3 linhas) = 21 posições
class ElegantCanteiro2DWidget extends StatefulWidget {
  final CanteiroModel? canteiro;
  final Function(String position)? onPositionTap;
  final Function(String position)? onPositionLongPress;
  final bool showGridLabels;
  final bool interactive;
  final List<String>? selectedPositions; // Posições selecionadas para subtestes

  const ElegantCanteiro2DWidget({
    super.key,
    this.canteiro,
    this.onPositionTap,
    this.onPositionLongPress,
    this.showGridLabels = true,
    this.interactive = true,
    this.selectedPositions,
  });

  @override
  State<ElegantCanteiro2DWidget> createState() => _ElegantCanteiro2DWidgetState();
}

class _ElegantCanteiro2DWidgetState extends State<ElegantCanteiro2DWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _hoverController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _hoverAnimation;
  
  String? _hoveredPosition;
  String? _selectedPosition;

  @override
  void initState() {
    super.initState();
    
    // Animação de pulso para posições vazias
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Animação de hover para posições
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildGrid(),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.grid_view,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.canteiro?.nome ?? 'Canteiro Padrão',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  '${widget.canteiro?.cultura ?? 'Cultura'} - ${widget.canteiro?.variedade ?? 'Variedade'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final occupiedPositions = _getOccupiedPositions();
    final totalPositions = 21;
    final percentage = (occupiedPositions / totalPositions * 100).round();
    
    Color statusColor;
    String statusText;
    
    if (percentage == 0) {
      statusColor = Colors.green.shade600;
      statusText = 'Livre';
    } else if (percentage < 50) {
      statusColor = Colors.orange.shade600;
      statusText = '$percentage% Ocupado';
    } else if (percentage < 100) {
      statusColor = Colors.blue.shade600;
      statusText = '$percentage% Ocupado';
    } else {
      statusColor = Colors.red.shade600;
      statusText = 'Completo';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho com letras das colunas
          if (widget.showGridLabels) _buildColumnHeader(),
          // Grid principal
          _buildMainGrid(),
        ],
      ),
    );
  }

  Widget _buildColumnHeader() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade200],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Célula vazia para alinhar com as linhas
          Container(
            width: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
              ),
            ),
          ),
          // Letras das colunas
          ...List.generate(7, (colIndex) {
            final letter = String.fromCharCode(65 + colIndex); // A, B, C, D, E, F, G
            return Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.green.shade300, width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMainGrid() {
    return Column(
      children: List.generate(3, (rowIndex) {
        final rowNumber = rowIndex + 1;
        return Row(
          children: [
            // Número da linha
            if (widget.showGridLabels)
              Container(
                width: 40,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  border: Border(
                    top: BorderSide(color: Colors.green.shade300, width: 1),
                    right: BorderSide(color: Colors.green.shade300, width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$rowNumber',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ),
            // Posições da linha
            ...List.generate(7, (colIndex) {
              final position = '${String.fromCharCode(65 + colIndex)}$rowNumber';
              return Expanded(
                child: _buildPosition(position, rowIndex, colIndex),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildPosition(String position, int rowIndex, int colIndex) {
    final isOccupied = _isPositionOccupied(position);
    final isHovered = _hoveredPosition == position;
    final isSelected = _selectedPosition == position || 
                      (widget.selectedPositions?.contains(position) ?? false);
    
    return GestureDetector(
      onTap: widget.interactive ? () => _onPositionTap(position) : null,
      onLongPress: widget.interactive ? () => _onPositionLongPress(position) : null,
      onTapDown: widget.interactive ? (_) => _onPositionHover(position) : null,
      onTapUp: widget.interactive ? (_) => _onPositionLeave() : null,
      onTapCancel: widget.interactive ? () => _onPositionLeave() : null,
      child: Container(
              height: 60,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                gradient: _getPositionGradient(position, isOccupied, isSelected),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getPositionBorderColor(position, isOccupied, isSelected),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  if (isHovered || isSelected)
                    BoxShadow(
                      color: Colors.green.shade300,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Conteúdo principal
                  Center(
                    child: _buildPositionContent(position, isOccupied),
                  ),
                  // Indicador de status
                  if (isOccupied)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  // Indicador de seleção
                  if (isSelected)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
  }

  Widget _buildPositionContent(String position, bool isOccupied) {
    if (isOccupied) {
      final positionData = _getPositionData(position);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            position,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${positionData['germinadas']}/${positionData['total']}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
          Text(
            '${positionData['percentual']}%',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  position,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Colors.green.shade600,
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda do Canteiro',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildLegendItem(
                  'Posição Livre',
                  Colors.green.shade100,
                  Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLegendItem(
                  'Posição Ocupada',
                  Colors.blue.shade100,
                  Colors.blue.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildLegendItem(
                  'Selecionada',
                  Colors.orange.shade100,
                  Colors.orange.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLegendItem(
                  'Hover',
                  Colors.purple.shade100,
                  Colors.purple.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color backgroundColor, Color textColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: textColor, width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares
  bool _isPositionOccupied(String position) {
    if (widget.canteiro == null) return false;
    
    try {
      final pos = widget.canteiro!.posicoes.firstWhere((p) => p.posicao == position);
      // Posição está ocupada APENAS se tem dados reais de teste
      // Verificar se tem dados significativos (total > 0 E tem cultura/lote válidos)
      return pos.total > 0 && 
             (pos.loteId != null && pos.loteId!.isNotEmpty) && 
             (pos.cultura != null && pos.cultura!.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _getPositionData(String position) {
    if (widget.canteiro == null) return {'germinadas': 0, 'total': 0, 'percentual': 0};
    
    final pos = widget.canteiro!.posicoes.firstWhere(
      (p) => p.posicao == position,
      orElse: () => CanteiroPosition(
        posicao: position,
        cor: Colors.green.value,
        germinadas: 0,
        total: 0,
        percentual: 0.0,
        dadosDiarios: {},
      ),
    );
    
    return {
      'germinadas': pos.germinadas,
      'total': pos.total,
      'percentual': pos.percentual.round(),
    };
  }

  int _getOccupiedPositions() {
    if (widget.canteiro == null) return 0;
    return widget.canteiro!.posicoes.where((pos) => pos.total > 0).length;
  }

  LinearGradient _getPositionGradient(String position, bool isOccupied, bool isSelected) {
    if (isSelected) {
      return LinearGradient(
        colors: [Colors.orange.shade300, Colors.orange.shade500],
      );
    } else if (isOccupied) {
      return LinearGradient(
        colors: [Colors.blue.shade300, Colors.blue.shade500],
      );
    } else {
      return LinearGradient(
        colors: [Colors.green.shade100, Colors.green.shade200],
      );
    }
  }

  Color _getPositionBorderColor(String position, bool isOccupied, bool isSelected) {
    if (isSelected) {
      return Colors.orange.shade600;
    } else if (isOccupied) {
      return Colors.blue.shade600;
    } else {
      return Colors.green.shade400;
    }
  }

  void _onPositionTap(String position) {
    setState(() {
      _selectedPosition = _selectedPosition == position ? null : position;
    });
    widget.onPositionTap?.call(position);
  }

  void _onPositionLongPress(String position) {
    widget.onPositionLongPress?.call(position);
  }

  void _onPositionHover(String position) {
    setState(() {
      _hoveredPosition = position;
    });
    _hoverController.forward();
  }

  void _onPositionLeave() {
    setState(() {
      _hoveredPosition = null;
    });
    _hoverController.reverse();
  }
}

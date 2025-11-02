import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🎯 Canteiro 2D Avançado - Simulação Realista
/// Grid 4x5 com visualização detalhada e interativa
class AdvancedCanteiro2DWidget extends StatefulWidget {
  final List<CanteiroPosition> positions;
  final Function(String position)? onPositionTap;
  final Function(String position)? onPositionLongPress;
  
  const AdvancedCanteiro2DWidget({
    super.key,
    required this.positions,
    this.onPositionTap,
    this.onPositionLongPress,
  });

  @override
  State<AdvancedCanteiro2DWidget> createState() => _AdvancedCanteiro2DWidgetState();
}

class _AdvancedCanteiro2DWidgetState extends State<AdvancedCanteiro2DWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  
  String? _hoveredPosition;
  String? _selectedPosition;

  @override
  void initState() {
    super.initState();
    
    // Animação de pulsação para posições ativas
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Animação de brilho para posições com alta germinação
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.green.shade100,
            Colors.green.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildCanteiroGrid(),
          const SizedBox(height: 20),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.grid_view,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canteiro de Germinação 4x5',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Simulação 2D - ${widget.positions.length} posições',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final occupied = widget.positions.where((p) => !p.isEmpty).length;
    final total = widget.positions.length;
    final percentage = (occupied / total) * 100;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: percentage > 80 ? Colors.red : percentage > 50 ? Colors.orange : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanteiroGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Linha de coordenadas (A, B, C, D)
          Row(
            children: [
              const SizedBox(width: 40), // Espaço para números das linhas
              ...List.generate(4, (col) => Container(
                width: 60,
                height: 30,
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + col), // A, B, C, D
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              )),
            ],
          ),
          
          // Grid principal
          ...List.generate(5, (row) => Row(
            children: [
              // Número da linha
              Container(
                width: 40,
                height: 60,
                alignment: Alignment.center,
                child: Text(
                  '${row + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              
              // Posições da linha
              ...List.generate(4, (col) => _buildPositionCell(row, col)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildPositionCell(int row, int col) {
    final position = '${String.fromCharCode(65 + col)}${row + 1}';
    final cellData = widget.positions.firstWhere(
      (p) => p.posicao == position,
      orElse: () => CanteiroPosition(
        posicao: position,
        cor: Colors.grey.shade200,
        germinadas: 0,
        total: 0,
        percentual: 0,
      ),
    );
    
    final isOccupied = !cellData.isEmpty;
    final isHovered = _hoveredPosition == position;
    final isSelected = _selectedPosition == position;
    
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(2),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPosition = _selectedPosition == position ? null : position;
          });
          widget.onPositionTap?.call(position);
        },
        onLongPress: () {
          widget.onPositionLongPress?.call(position);
        },
        onTapDown: (_) {
          setState(() {
            _hoveredPosition = position;
          });
        },
        onTapUp: (_) {
          setState(() {
            _hoveredPosition = null;
          });
        },
        onTapCancel: () {
          setState(() {
            _hoveredPosition = null;
          });
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isOccupied ? _pulseAnimation.value : 1.0,
              child: _buildPositionContent(cellData, isOccupied, isHovered, isSelected),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPositionContent(CanteiroPosition data, bool isOccupied, bool isHovered, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? Colors.blue.shade600
              : isHovered 
                  ? Colors.orange.shade400
                  : Colors.grey.shade300,
          width: isSelected ? 3 : isHovered ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          if (isHovered)
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
      child: isOccupied ? _buildOccupiedCell(data) : _buildEmptyCell(data),
    );
  }

  Widget _buildOccupiedCell(CanteiroPosition data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.cor.withOpacity(0.8),
            data.cor.withOpacity(0.6),
            data.cor.withOpacity(0.4),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Conteúdo principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Percentual de germinação
                Text(
                  '${data.percentual.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                
                // Sementes germinadas
                Text(
                  '${data.germinadas}/${data.total}',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Indicador de qualidade
          if (data.percentual >= 80)
            Positioned(
              top: 4,
              right: 4,
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.5 + (_shimmerAnimation.value * 0.5),
                    child: Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 12,
                    ),
                  );
                },
              ),
            ),
          
          // Indicador de contaminação
          if (data.percentual < 50)
            Positioned(
              top: 4,
              left: 4,
              child: Icon(
                Icons.warning,
                color: Colors.red.shade700,
                size: 12,
              ),
            ),
          
          // Cultura (se disponível)
          if (data.cultura != null)
            Positioned(
              bottom: 2,
              left: 2,
              right: 2,
              child: Text(
                data.cultura!.substring(0, math.min(3, data.cultura!.length)),
                style: TextStyle(
                  fontSize: 6,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCell(CanteiroPosition data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              'Vazio',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final occupiedPositions = widget.positions.where((p) => !p.isEmpty).toList();
    final uniqueLotes = occupiedPositions.map((p) => p.loteId).toSet().toList();
    
    if (uniqueLotes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda de Lotes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: uniqueLotes.map((loteId) {
              final lotePositions = occupiedPositions.where((p) => p.loteId == loteId).toList();
              final avgGermination = lotePositions.isNotEmpty
                  ? lotePositions.map((p) => p.percentual).reduce((a, b) => a + b) / lotePositions.length
                  : 0.0;
              
              final color = lotePositions.isNotEmpty ? lotePositions.first.cor : Colors.grey;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lote $loteId',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${lotePositions.length} pos)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${avgGermination.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: avgGermination >= 80 ? Colors.green : avgGermination >= 60 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Modelo de posição no canteiro (compatível com o existente)
class CanteiroPosition {
  final String posicao;
  final String? loteId;
  final String? subteste;
  final Color cor;
  final int germinadas;
  final int total;
  final double percentual;
  final String? cultura;
  final DateTime? dataInicio;
  final dynamic test; // Pode ser GerminationTestModel ou null

  CanteiroPosition({
    required this.posicao,
    this.loteId,
    this.subteste,
    required this.cor,
    required this.germinadas,
    required this.total,
    required this.percentual,
    this.cultura,
    this.dataInicio,
    this.test,
  });

  bool get isEmpty => loteId == null;
}

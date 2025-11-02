import 'package:flutter/material.dart';
import '../models/germination_test_model.dart';
import '../screens/plantio/submods/germination_test/screens/canteiro_position_detail_screen.dart';

/// Widget para exibir um canteiro 2D clicável (4x5)
/// Cada célula representa uma posição (A1, B1, C1, D1, E1, A2, B2, etc.)
class Canteiro2DGridWidget extends StatelessWidget {
  final String canteiroId;
  final String canteiroName;
  final List<GerminationTest>? tests;
  final Function(String position)? onPositionTap;
  final bool showTestInfo;
  final Color? primaryColor;
  final Color? secondaryColor;
  final List<String>? selectedPositions; // Para mostrar posições selecionadas

  const Canteiro2DGridWidget({
    Key? key,
    required this.canteiroId,
    required this.canteiroName,
    this.tests,
    this.onPositionTap,
    this.showTestInfo = true,
    this.primaryColor,
    this.secondaryColor,
    this.selectedPositions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Colors.green.shade600;
    final secondary = secondaryColor ?? Colors.green.shade100;
    
    print('🔍 DEBUG - Canteiro2DGridWidget build: tests=${tests?.length ?? 0}');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(primary),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: _buildGrid(context, primary, secondary),
            ),
            if (showTestInfo) ...[
              const SizedBox(height: 16),
              _buildLegend(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.grid_view,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canteiroName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text(
                'Canteiro $canteiroId - Grade 4x5',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_getOccupiedPositions().length}/20',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, Color primaryColor, Color secondaryColor) {
    print('🔍 DEBUG - _buildGrid: criando GridView com 20 células');
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5, // 5 colunas (A, B, C, D, E)
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2, // Ajustado para melhor visualização
      children: List.generate(20, (index) {
        final row = (index ~/ 5) + 1; // 1 a 4
        final col = String.fromCharCode(65 + (index % 5)); // A, B, C, D, E
        final position = "$col$row";
        
        if (index == 0) {
          print('🔍 DEBUG - Primeira célula: $position');
        }
        
        return _buildPositionCell(context, position, primaryColor, secondaryColor);
      }),
    );
  }

  Widget _buildPositionCell(BuildContext context, String position, Color primaryColor, Color secondaryColor) {
    final test = _getTestAtPosition(position);
    final isOccupied = test != null;
    final hasSubtests = test?.hasSubtests ?? false;
    final isSelected = selectedPositions?.contains(position) ?? false;
    
    // Debug para verificar se está funcionando
    if (position == 'A1') {
      print('🔍 DEBUG - Posição A1: test=$test, isOccupied=$isOccupied, isSelected=$isSelected');
    }

    return GestureDetector(
      onTap: () => _onCellTap(context, position, test),
      child: Container(
        height: 60, // Altura fixa para garantir visibilidade
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.shade100  // Azul para posições selecionadas
              : isOccupied 
                  ? primaryColor.withOpacity(0.1) 
                  : secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.blue.shade600  // Borda azul para selecionadas
                : isOccupied 
                    ? primaryColor 
                    : Colors.grey.shade300,
            width: isSelected || isOccupied ? 2 : 1,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Posição (A1, B2, etc.) ou rótulo do subteste
            Text(
              isSelected && selectedPositions != null 
                  ? _getSubtestLabel(position)
                  : position,
              style: TextStyle(
                fontSize: 12, // Reduzido de 14 para 12
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? Colors.blue.shade700
                    : isOccupied 
                        ? primaryColor 
                        : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (isOccupied) ...[
              const SizedBox(height: 4),
              
              // Ícone do tipo de teste
              Icon(
                hasSubtests ? Icons.grid_view : Icons.science,
                size: 16,
                color: primaryColor,
              ),
              
              const SizedBox(height: 2),
              
              // Cultura (abreviada)
              Text(
                _getCultureAbbreviation(test!.culture),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Status do teste
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getStatusColor(test.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(test.status),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Icon(
                Icons.add,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(Icons.science, 'Teste Individual', Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem(Icons.grid_view, 'Subtestes A,B,C', Colors.purple),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildLegendItem(Icons.play_circle, 'Ativo', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem(Icons.check_circle, 'Concluído', Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem(Icons.cancel, 'Cancelado', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _onCellTap(BuildContext context, String position, GerminationTest? test) {
    if (onPositionTap != null) {
      onPositionTap!(position);
    } else {
      // Navegação padrão para detalhes da posição
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CanteiroPositionDetailScreen(
            canteiroId: canteiroId,
            canteiroName: canteiroName,
            position: position,
            test: test,
          ),
        ),
      );
    }
  }

  GerminationTest? _getTestAtPosition(String position) {
    if (tests == null) return null;
    try {
      return tests!.firstWhere(
        (test) => test.position == position,
      );
    } catch (e) {
      return null; // Retorna null se não encontrar teste na posição
    }
  }

  List<String> _getOccupiedPositions() {
    if (tests == null || tests!.isEmpty) return [];
    return tests!.where((test) => test.position != null && test.position!.isNotEmpty).map((test) => test.position!).toList();
  }

  String _getCultureAbbreviation(String culture) {
    if (culture.length <= 4) return culture;
    return culture.substring(0, 4).toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'ATIVO';
      case 'completed':
        return 'OK';
      case 'cancelled':
        return 'CANC';
      default:
        return status.toUpperCase();
    }
  }

  String _getSubtestLabel(String position) {
    if (selectedPositions == null) return position;
    final index = selectedPositions!.indexOf(position);
    if (index == -1) return position;
    final subtestLabel = String.fromCharCode(65 + index); // A, B, C
    return 'Sub $subtestLabel'; // Rótulo mais curto para evitar overflow
  }
}

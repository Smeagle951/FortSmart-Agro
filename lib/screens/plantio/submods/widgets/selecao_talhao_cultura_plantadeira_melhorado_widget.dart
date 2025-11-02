import 'package:flutter/material.dart';
import '../../../../models/agricultural_product.dart';
import '../../../../models/talhao_model.dart';
import '../../../../widgets/fortsmart_card.dart';

class SelecaoTalhaoCulturaPlantadeiraMelhoradoWidget extends StatelessWidget {
  final TalhaoModel? talhaoSelecionado;
  final AgriculturalProduct? culturaSelecionada;
  final VoidCallback onSelecionarTalhao;
  final VoidCallback onSelecionarCultura;

  const SelecaoTalhaoCulturaPlantadeiraMelhoradoWidget({
    Key? key,
    required this.talhaoSelecionado,
    required this.culturaSelecionada,
    required this.onSelecionarTalhao,
    required this.onSelecionarCultura,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FortSmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌱 Talhão e Cultura',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          
          // Campo Talhão
          GestureDetector(
            onTap: onSelecionarTalhao,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getTalhaoColor(),
                    child: const Icon(Icons.landscape, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Talhão', 
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          talhaoSelecionado?.name ?? 'Selecione um talhão',
                          style: TextStyle(
                            fontSize: 16,
                            color: talhaoSelecionado != null ? Colors.black87 : Colors.grey.shade600,
                            fontWeight: talhaoSelecionado != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        if (talhaoSelecionado?.area != null)
                          Text(
                            '${talhaoSelecionado!.area!.toStringAsFixed(2)} ha',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Campo Cultura
          GestureDetector(
            onTap: onSelecionarCultura,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getCulturaColor(),
                    child: const Icon(Icons.grass, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cultura', 
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          culturaSelecionada?.name ?? 'Selecione uma cultura',
                          style: TextStyle(
                            fontSize: 16,
                            color: culturaSelecionada != null ? Colors.black87 : Colors.grey.shade600,
                            fontWeight: culturaSelecionada != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTalhaoColor() {
    if (talhaoSelecionado?.cor != null) {
      return talhaoSelecionado!.cor!;
    }
    return Colors.green;
  }

  Color _getCulturaColor() {
    if (culturaSelecionada?.colorValue == null) {
      return Colors.grey;
    }

    try {
      String colorString = culturaSelecionada!.colorValue!.trim();
      
      // Se começa com #
      if (colorString.startsWith('#')) {
        String hex = colorString.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        } else if (hex.length == 3) {
          // Expandir cores de 3 dígitos
          hex = hex.split('').map((c) => c + c).join();
          return Color(int.parse('0xFF$hex'));
        }
      }
      // Se começa com 0x
      else if (colorString.startsWith('0x')) {
        return Color(int.parse(colorString));
      }
      // Se é apenas um número
      else if (RegExp(r'^[0-9]+$').hasMatch(colorString)) {
        return Color(int.parse(colorString));
      }
    } catch (e) {
      print('Erro ao parsear cor da cultura: ${culturaSelecionada!.colorValue} - $e');
    }
    
    return Colors.grey;
  }
}

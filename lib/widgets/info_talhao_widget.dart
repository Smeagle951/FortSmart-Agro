import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/geo_math.dart';

/// Widget para exibir informações do talhão em tempo real
/// Mostra área, perímetro e outros dados relevantes
class InfoTalhaoWidget extends StatelessWidget {
  final List<LatLng> pontos;
  final Color cor;
  final String? nomeTalhao;
  final String? nomeCultura;
  final IconData? iconeCultura;
  final bool mostrarPerimetro;
  final bool expandido;
  final VoidCallback? onTap;

  const InfoTalhaoWidget({
    Key? key,
    required this.pontos,
    required this.cor,
    this.nomeTalhao,
    this.nomeCultura,
    this.iconeCultura,
    this.mostrarPerimetro = false,
    this.expandido = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcular área e perímetro
    final area = GeoMath.calcularArea(pontos);
    final perimetro = mostrarPerimetro ? GeoMath.calcularPerimetro(pontos) : 0.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: cor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com ícone e título
            Row(
              children: [
                Icon(
                  iconeCultura ?? Icons.eco,
                  color: cor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nomeTalhao ?? 'Novo Talhão',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (expandido)
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.grey[600],
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
              ],
            ),
            
            // Informações principais
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  context,
                  'Área',
                  GeoMath.formatarArea(area),
                  Icons.area_chart,
                ),
                if (mostrarPerimetro)
                  _buildInfoItem(
                    context,
                    'Perímetro',
                    _formatarPerimetro(perimetro),
                    Icons.straighten,
                  ),
                _buildInfoItem(
                  context,
                  'Pontos',
                  '${pontos.length}',
                  Icons.location_on,
                ),
              ],
            ),
            
            // Informações expandidas
            if (expandido && nomeCultura != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.grass,
                    color: Colors.green[700],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cultura:',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      nomeCultura!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.blue[700],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Criado em:',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatarData(DateTime.now()),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói um item de informação com ícone, título e valor
  Widget _buildInfoItem(
    BuildContext context,
    String titulo,
    String valor,
    IconData icone,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              color: cor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              titulo,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
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

  /// Formata a data para exibição
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
           '${data.month.toString().padLeft(2, '0')}/'
           '${data.year}';
  }
}

import 'package:flutter/material.dart';
import '../utils/area_formatter.dart';

/// Popup/card flutuante com informações do talhão
class TalhaoPopupInfo extends StatelessWidget {
  final String nomeTalhao;
  final String culturaNome;
  final String safra;
  final double area;
  final Color corCultura;
  final String iconeCultura;
  final VoidCallback? onEditar;
  final VoidCallback? onDeletar;

  const TalhaoPopupInfo({
    Key? key,
    required this.nomeTalhao,
    required this.culturaNome,
    required this.safra,
    required this.area,
    required this.corCultura,
    required this.iconeCultura,
    this.onEditar,
    this.onDeletar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: corCultura,
                  child: Text(iconeCultura, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nomeTalhao,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cultura: $culturaNome'),
            Text('Safra: $safra'),
            Text('Área: ${AreaFormatter.formatHectaresFixed(area)}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEditar,
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDeletar,
                  tooltip: 'Excluir',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

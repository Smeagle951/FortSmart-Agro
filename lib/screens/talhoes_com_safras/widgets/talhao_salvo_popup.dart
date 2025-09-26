import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/talhoes/talhao_safra_model.dart';
import '../../../utils/geo_math.dart';
import '../providers/talhao_provider.dart';

class TalhaoSalvoPopup extends StatelessWidget {
  final TalhaoSafraModel talhao;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TalhaoSalvoPopup({
    Key? key,
    required this.talhao,
    this.onClose,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final areaTotal = talhao.calcularAreaTotal();
    final areaFormatada = GeoMath.formatarArea(areaTotal);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ícone e cor da cultura
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: talhao.safras.isNotEmpty ? talhao.safras.first.culturaCor : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.grass,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Nome e área
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      talhao.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Área: $areaFormatada',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              // Botão de fechar
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Informações da safra
          if (talhao.safras.isNotEmpty) ...[
            Text(
              'Safra: ${talhao.safras.first.idSafra}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Cultura: ${talhao.safras.first.culturaNome}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          // Botões de ação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                icon: Icons.edit,
                label: 'Editar',
                onPressed: onEdit,
                color: Colors.blue,
              ),
              _buildActionButton(
                context,
                icon: Icons.delete,
                label: 'Excluir',
                onPressed: onDelete,
                color: Colors.red,
              ),
              // _buildActionButton(
              //   context,
              //   icon: Icons.file_download,
              //   label: 'Exportar',
              //   onPressed: () => _exportarTalhao(context),
              //   color: Colors.green,
              // ),
              // _buildActionButton(
              //   context,
              //   icon: Icons.share,
              //   label: 'Compartilhar',
              //   onPressed: () => _compartilharTalhao(context),
              //   color: Colors.purple,
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Future<void> _exportarTalhao(BuildContext context) async {
  //   final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
  //   
  //   try {
  //     final filePath = await talhaoProvider.exportarTalhaoParaGeoJSON(talhao.id);
  //     
  //     if (filePath != null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Talhão exportado com sucesso para: $filePath'),
  //           backgroundColor: Colors.green,
  //           action: SnackBarAction(
  //             label: 'OK',
  //             textColor: Colors.white,
  //             onPressed: () {},
  //           ),
  //         ),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Não foi possível exportar o talhão'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Erro ao exportar talhão: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }

  // Future<void> _compartilharTalhao(BuildContext context) async {
  //   final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
  //   
  //   try {
  //     await talhaoProvider.compartilharTalhaoComoGeoJSON(talhao.id);
  //     
  //     // Não exibimos mensagem de sucesso aqui porque o compartilhamento
  //     // já mostra uma interface do sistema
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Erro ao compartilhar talhão: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/talhao_provider.dart';
import '../utils/area_formatter.dart';
import '../utils/logger.dart';

/// Card mini elegante para exibir informações do talhão
class TalhaoMiniCard extends StatelessWidget {
  final dynamic talhao;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TalhaoMiniCard({
    Key? key,
    required this.talhao,
    this.onEdit,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obter cultura principal do talhão
    final culturaPrincipal = talhao.safras.isNotEmpty 
        ? talhao.safras.first 
        : null;
    
    // Obter área total (soma de todas as safras ou área do talhão)
    double areaTotal = talhao.area ?? 0.0;
    if (talhao.safras.isNotEmpty) {
      areaTotal = talhao.safras.fold(0.0, (sum, safra) => sum + safra.area);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com nome e ações
              Row(
                children: [
                  // Ícone da cultura
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: culturaPrincipal?.culturaCor ?? Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Nome do talhão
                  Expanded(
                    child: Text(
                      talhao.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Botões de ação
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: onEdit,
                          tooltip: 'Editar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _showDeleteConfirmation(context),
                          tooltip: 'Excluir',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações do talhão
              Row(
                children: [
                  // Cultura
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.eco,
                      label: 'Cultura',
                      value: culturaPrincipal?.culturaNome ?? 'Não definida',
                      color: culturaPrincipal?.culturaCor ?? Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Safra
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Safra',
                      value: culturaPrincipal?.idSafra ?? 'Não definida',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Área
              _buildInfoItem(
                icon: Icons.area_chart,
                label: 'Área',
                value: AreaFormatter.formatHectaresFixed(areaTotal),
                color: Colors.green,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói um item de informação
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra confirmação de exclusão
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir o talhão "${talhao.name}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

/// Lista de cards mini para exibir múltiplos talhões
class TalhaoMiniCardList extends StatelessWidget {
  final List<dynamic> talhoes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TalhaoMiniCardList({
    Key? key,
    required this.talhoes,
    this.onEdit,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (talhoes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum talhão encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: talhoes.length,
      itemBuilder: (context, index) {
        final talhao = talhoes[index];
        return TalhaoMiniCard(
          talhao: talhao,
          onEdit: onEdit,
          onDelete: onDelete,
          onTap: onTap,
        );
      },
    );
  }
}

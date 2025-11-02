import 'package:flutter/material.dart';
import '../utils/area_formatter.dart';
import 'package:provider/provider.dart';

import '../providers/talhao_provider.dart';
import '../services/cultura_icon_service.dart';
import 'talhao_salvo_popup.dart';

class ListaTalhoesWidget extends StatelessWidget {
  final String? idFazenda;
  final Function(TalhaoSafraModel)? onTalhaoSelecionado;
  
  const ListaTalhoesWidget({
    Key? key,
    this.idFazenda,
    this.onTalhaoSelecionado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TalhaoProvider>(
      builder: (context, talhaoProvider, child) {
        // Carregar talhões inicialmente
        return FutureBuilder<List<TalhaoSafraModel>>(
          future: talhaoProvider.carregarTalhoes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro ao carregar talhões: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            
            final talhoes = snapshot.data ?? <TalhaoSafraModel>[];
            
            if (talhoes.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhum talhão encontrado',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
            
            return ListView.builder(
              itemCount: talhoes.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final talhao = talhoes[index];
                return _buildTalhaoCard(context, talhao);
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildTalhaoCard(BuildContext context, TalhaoSafraModel talhao) {
    final theme = Theme.of(context);
    final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (onTalhaoSelecionado != null) {
            onTalhaoSelecionado!(talhao);
          } else {
            _mostrarDetalhes(context, talhao);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cor e ícone da cultura
              CulturaIconService.getCulturaIcon(
                culturaNome: talhao.culturaId.isNotEmpty ? talhao.culturaId : 'Sem Cultura',
                size: 48,
                backgroundColor: talhao.corCultura,
              ),
              const SizedBox(width: 16),
              // Informações do talhão
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      talhao.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cultura: ${talhao.culturaId}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Área: ${_formatarArea(talhao.area)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Botões de ação
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      // Implementar edição
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmarExclusao(context, talhao, talhaoProvider);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _mostrarDetalhes(BuildContext context, TalhaoSafraModel talhao) {
    final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TalhaoSalvoPopup(
          talhao: talhao as dynamic,
          onClose: () => Navigator.of(context).pop(),
          onEdit: () {
            Navigator.of(context).pop();
            // Implementar navegação para edição
          },
          onDelete: () {
            Navigator.of(context).pop();
            _confirmarExclusao(context, talhao, talhaoProvider);
          },
        ),
      ),
    );
  }
  
  void _confirmarExclusao(
    BuildContext context, 
    TalhaoSafraModel talhao, 
    TalhaoProvider talhaoProvider
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o talhão "${talhao.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              talhaoProvider.removeTalhao(talhao.id);
              final success = true;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Talhão excluído com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Erro ao excluir talhão: ${talhaoProvider.errorMessage}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
  
  String _formatarArea(double area) {
    if (area < 10000) {
      return AreaFormatter.formatSquareMeters(area);
    } else {
      final hectares = area / 10000;
      return AreaFormatter.formatHectaresFixed(hectares);
    }
  }
}

import 'package:flutter/material.dart';
import '../../../utils/area_formatter.dart';
import 'package:provider/provider.dart';

import '../../../models/talhoes/talhao_safra_model.dart';
import '../providers/talhao_provider.dart';
import 'talhao_salvo_popup.dart';

class ListaTalhoesWidget extends StatefulWidget {
  final String? idFazenda;
  final Function(TalhaoSafraModel)? onTalhaoSelecionado;
  
  const ListaTalhoesWidget({
    Key? key,
    this.idFazenda,
    this.onTalhaoSelecionado,
  }) : super(key: key);

  @override
  State<ListaTalhoesWidget> createState() => _ListaTalhoesWidgetState();
}

class _ListaTalhoesWidgetState extends State<ListaTalhoesWidget> {
  late Future<List<TalhaoSafraModel>> _futureTalhoes;
  
  @override
  void initState() {
    super.initState();
    // CORREÇÃO: Criar o Future apenas uma vez no initState
    final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
    _futureTalhoes = talhaoProvider.carregarTalhoes(idFazenda: widget.idFazenda);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TalhaoSafraModel>>(
      future: _futureTalhoes,
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
            
            final talhoes = snapshot.data ?? [];
            
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
          if (widget.onTalhaoSelecionado != null) {
            widget.onTalhaoSelecionado!(talhao);
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: talhao.safras.isNotEmpty 
                      ? talhao.safras.first.culturaCor 
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grass,
                  color: Colors.white,
                  size: 24,
                ),
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
                    if (talhao.safras.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Cultura: ${talhao.safras.first.culturaNome}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Área: ${AreaFormatter.formatHectaresFixed(talhao.calcularAreaTotal())}',
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
          talhao: talhao,
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
              final success = await talhaoProvider.excluirTalhao(talhao.id);
              
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

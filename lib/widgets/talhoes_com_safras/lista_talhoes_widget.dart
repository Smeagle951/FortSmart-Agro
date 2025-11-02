import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/talhoes_com_safras/providers/talhao_provider.dart';
import '../../utils/area_formatter.dart';
import '../talhao_mini_card.dart';
import '../../models/talhoes/talhao_safra_model.dart' as talhao_model;

class ListaTalhoesWidget extends StatefulWidget {
  const ListaTalhoesWidget({Key? key}) : super(key: key);

  @override
  State<ListaTalhoesWidget> createState() => _ListaTalhoesWidgetState();
}

class _ListaTalhoesWidgetState extends State<ListaTalhoesWidget> {
  @override
  void initState() {
    super.initState();
    // CORREÇÃO: Usar o provider em vez de criar repository diretamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTalhoes();
    });
  }

  /// Carrega os talhões do banco de dados usando o provider
  Future<void> _carregarTalhoes() async {
    try {
      final provider = Provider.of<TalhaoProvider>(context, listen: false);
      await provider.forcarReload();
    } catch (e) {
      print('❌ Erro ao carregar talhões: $e');
    }
  }

  /// Edita um talhão
  void _editarTalhao(talhao_model.TalhaoSafraModel talhao) {
    // TODO: Implementar edição do talhão
    print('🔄 Editando talhão: ${talhao.name}');
    
    // Por enquanto, apenas mostra um snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando talhão: ${talhao.name}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Remove um talhão usando o provider
  Future<void> _removerTalhao(talhao_model.TalhaoSafraModel talhao) async {
    // Mostrar confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tem certeza que deseja remover o talhão "${talhao.name}"?'),
            const SizedBox(height: 8),
            const Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    
    if (confirmar != true) return;
    
    try {
      // Mostrar indicador de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Removendo talhão...'),
            ],
          ),
        ),
      );
      
      // CORREÇÃO: Usar provider em vez de repository diretamente
      final provider = Provider.of<TalhaoProvider>(context, listen: false);
      final sucesso = await provider.removerTalhao(talhao.id);
      
      // Fechar diálogo de progresso
      if (mounted) Navigator.pop(context);
      
      if (sucesso) {
        // CORREÇÃO: NÃO recarregar após remoção
        // O provider já removeu o talhão da lista local
        // Recarregar faria o talhão voltar do banco
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Talhão "${talhao.name}" removido com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao remover talhão'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Fechar diálogo de progresso se ainda estiver aberto
      if (mounted) Navigator.pop(context);
      
      print('❌ Erro ao remover talhão: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover talhão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Visualiza detalhes do talhão
  void _visualizarTalhao(talhao_model.TalhaoSafraModel talhao) {
    // TODO: Implementar visualização detalhada
    print('👁️ Visualizando talhão: ${talhao.name}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando talhão: ${talhao.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CORREÇÃO: Usar Consumer para reagir às mudanças do provider
    return Consumer<TalhaoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Carregando talhões...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (provider.talhoes.isEmpty) {
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
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Crie seu primeiro talhão para começar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _carregarTalhoes,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.talhoes.length,
            itemBuilder: (context, index) {
              final talhao = provider.talhoes[index];
              return TalhaoMiniCard(
                talhao: talhao,
                onEdit: () => _editarTalhao(talhao),
                onDelete: () => _removerTalhao(talhao),
                onTap: () => _visualizarTalhao(talhao),
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../models/experimento_model.dart';
import '../services/experimento_service.dart';
import 'experimento_screen_updated.dart';
import 'experimento_screen_updated_part2.dart';

/// Esse arquivo exemplifica como usar a nova tela de experimento atualizada
/// É um exemplo de implementação que pode ser usado como referência

class ExperimentoListScreen extends StatefulWidget {
  const ExperimentoListScreen({Key? key}) : super(key: key);

  @override
  _ExperimentoListScreenState createState() => _ExperimentoListScreenState();
}

class _ExperimentoListScreenState extends State<ExperimentoListScreen> {
  final _experimento = ExperimentoService();
  List<ExperimentoModel> _experimentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarExperimentos();
  }

  Future<void> _carregarExperimentos() async {
    setState(() => _isLoading = true);
    try {
      _experimentos = await _experimento.getAllExperimentos();
    } catch (e) {
      // Tratar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar experimentos: $e'),
          backgroundColor: const Color(0xFF228B22),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experimentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregarExperimentos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _experimentos.isEmpty
              ? const Center(child: Text('Nenhum experimento encontrado'))
              : ListView.builder(
                  itemCount: _experimentos.length,
                  itemBuilder: (context, index) {
                    final experimento = _experimentos[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 2,
                      child: ListTile(
                        title: Text(experimento.nome),
                        subtitle: Text('Talhão: ${experimento.talhaoId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editarExperimento(experimento),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmarExclusao(experimento),
                            ),
                          ],
                        ),
                        onTap: () => _editarExperimento(experimento),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoExperimento,
        tooltip: 'Novo Experimento',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _novoExperimento() async {
    // Usando a nova tela de experimento - ExperimentoScreenUpdated criada nas partes anteriores
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExperimentoScreenUpdated(),
      ),
    );

    if (result == true) {
      _carregarExperimentos();
    }
  }

  void _editarExperimento(ExperimentoModel experimento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperimentoScreenUpdated(
          experimento: experimento,
        ),
      ),
    );

    if (result == true) {
      _carregarExperimentos();
    }
  }

  void _confirmarExclusao(ExperimentoModel experimento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o experimento "${experimento.nome}"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Excluir'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _experimento.deleteExperimento(experimento.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Experimento excluído com sucesso'),
                    backgroundColor: const Color(0xFF228B22),
                  ),
                );
                _carregarExperimentos();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir experimento: $e'),
                    backgroundColor: const Color(0xFF228B22),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/// INSTRUÇÕES DE USO DA NOVA IMPLEMENTAÇÃO:
/// 
/// 1. Implemente a tela completa combinando as classes dos arquivos:
///    - experimento_screen_updated.dart (estrutura base e lógica)
///    - experimento_screen_updated_part2.dart (UI e extensões)
/// 
/// 2. Certifique-se de que o método build() da classe ExperimentoScreenUpdated está implementado,
///    conforme definido no arquivo experimento_screen_updated_part2.dart
/// 
/// 3. Os widgets aprimorados (EnhancedPlotSelector, EnhancedCropSelector, EnhancedCropVarietySelector)
///    já estão configurados para usar o serviço de integração ModulesIntegrationService
/// 
/// 4. Para implementar em seu aplicativo, você pode:
///    a. Usar o ExperimentoIntegrator.getScreen() para obter a tela completa
///    b. Ou combinar manualmente as duas partes da implementação
/// 
/// 5. Para testar a integração, utilize este exemplo adaptando-o à sua estrutura de navegação

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../database/models/aplicacao_model.dart';
import '../../database/repositories/aplicacao_repository.dart';
import '../../services/database_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/app_bar_widget.dart';
import '../../routes.dart';

/// Tela de detalhes de uma aplicação agrícola
class AplicacaoDetalhesScreen extends StatefulWidget {
  final String aplicacaoId;
  
  const AplicacaoDetalhesScreen({super.key, required this.aplicacaoId});

  @override
  _AplicacaoDetalhesScreenState createState() => _AplicacaoDetalhesScreenState();
}

class _AplicacaoDetalhesScreenState extends State<AplicacaoDetalhesScreen> {
  late AplicacaoRepository _repository;
  bool _isLoading = true;
  AplicacaoModel? _aplicacao;
  
  @override
  void initState() {
    super.initState();
    _repository = AplicacaoRepository();
    _carregarAplicacao();
  }

  /// Carrega os dados da aplicação
  Future<void> _carregarAplicacao() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final aplicacao = await _repository.getById(int.tryParse(widget.aplicacaoId) ?? 0);
      if (aplicacao != null) {
        if (mounted) {
          setState(() {
            _aplicacao = aplicacao;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
              context, 'Aplicação não encontrada');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar aplicação: ${e.toString()}');
        Navigator.of(context).pop();
      }
    }
  }

  /// Exclui a aplicação atual
  Future<void> _excluirAplicacao() async {
    try {
      await _repository.delete(_aplicacao!.id!);
      if (mounted) {
        SnackbarUtils.showSuccessSnackBar(context, 'Aplicação excluída com sucesso');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao excluir aplicação');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Detalhes da Aplicação',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.aplicacaoRegistro,
                arguments: _aplicacao,
              );
              if (mounted) {
                _carregarAplicacao();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar exclusão'),
                  content: const Text('Deseja realmente excluir esta aplicação?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _excluirAplicacao();
                      },
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _aplicacao == null
              ? const Center(child: Text('Aplicação não encontrada'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildProdutosCard(),
                      const SizedBox(height: 16),
                      _buildImagensCard(),
                    ],
                  ),
                ),
    );
  }

  /// Constrói o card com informações gerais da aplicação
  Widget _buildInfoCard() {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(DateTime.parse(_aplicacao!.data));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Gerais',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Text('Talhão: ${_aplicacao?.talhaoId ?? ""}'),
            _buildInfoRow('Data', dataFormatada),
            _buildInfoRow('Tipo de Aplicação', _aplicacao!.tipoAplicacao),
            _buildInfoRow('Equipamento', _aplicacao!.equipamento),
            _buildInfoRow('Condições Climáticas', _aplicacao!.condicoesClimaticas),
            _buildInfoRow('Área Total (ha)', _aplicacao!.areaTotal.toString()),
            _buildInfoRow('Total de Bombas', _aplicacao!.totalBombas.toString()),
            Text('Observações: ${_aplicacao?.observacoes ?? ""}'),
            _buildInfoRow('Status de Sincronização', _aplicacao!.statusSync),
          ],
        ),
      ),
    );
  }

  /// Constrói o card com a lista de produtos aplicados
  Widget _buildProdutosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produtos Aplicados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _aplicacao!.produtos.isEmpty
                ? const Center(child: Text('Nenhum produto aplicado'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _aplicacao!.produtos.length,
                    itemBuilder: (context, index) {
                      final produto = _aplicacao!.produtos[index];
                      return ListTile(
                        title: Text(produto),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Produto: $produto'),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  /// Constrói o card com as imagens da aplicação
  Widget _buildImagensCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imagens',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _aplicacao!.imagens.isEmpty
                ? const Center(child: Text('Nenhuma imagem disponível'))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _aplicacao!.imagens.length,
                    itemBuilder: (context, index) {
                      final imagemPath = _aplicacao!.imagens[index];
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: InteractiveViewer(
                                child: Image.file(File(imagemPath)),
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(imagemPath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  /// Constrói uma linha de informação
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value ?? ''),
          ),
        ],
      ),
    );
  }
}

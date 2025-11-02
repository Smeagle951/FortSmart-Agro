import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/models/aplicacao_model.dart';
import '../../database/repositories/aplicacao_repository.dart';
import '../../services/database_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/app_drawer.dart';
import '../../routes.dart';

/// Tela de listagem de aplicações agrícolas
class AplicacaoListaScreen extends StatefulWidget {
  const AplicacaoListaScreen({super.key});

  @override
  _AplicacaoListaScreenState createState() => _AplicacaoListaScreenState();
}

class _AplicacaoListaScreenState extends State<AplicacaoListaScreen> {
  late AplicacaoRepository _repository;
  bool _isLoading = true;
  List<AplicacaoModel> _aplicacoes = [];
  String _filtro = 'Todas';
  
  @override
  void initState() {
    super.initState();
    _repository = AplicacaoRepository();
    _carregarAplicacoes();
  }

  /// Carrega a lista de aplicações
  Future<void> _carregarAplicacoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final aplicacoes = await _repository.getAll();
      setState(() {
        _aplicacoes = aplicacoes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar aplicações');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Filtra as aplicações por tipo
  List<AplicacaoModel> _getAplicacoesFiltradas() {
    if (_filtro == 'Todas') {
      return _aplicacoes;
    } else {
      return _aplicacoes.where((a) => a.tipoAplicacao == _filtro).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final aplicacoesFiltradas = _getAplicacoesFiltradas();
    
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Histórico de Aplicações',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarAplicacoes,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text('Filtrar por: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _filtro,
                        items: const [
                          DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                          DropdownMenuItem(value: 'Terrestre', child: Text('Terrestre')),
                          DropdownMenuItem(value: 'Aérea', child: Text('Aérea')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filtro = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: aplicacoesFiltradas.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhuma aplicação encontrada',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        )
                      : ListView.builder(
                          itemCount: aplicacoesFiltradas.length,
                          itemBuilder: (context, index) {
                            final aplicacao = aplicacoesFiltradas[index];
                            return _buildAplicacaoCard(aplicacao);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.aplicacaoRegistro)
              .then((_) => _carregarAplicacoes());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Constrói o card de uma aplicação
  Widget _buildAplicacaoCard(AplicacaoModel aplicacao) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(DateTime.parse(aplicacao.data));
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: aplicacao.tipoAplicacao == 'Terrestre' ? Colors.green : Colors.blue,
          child: Icon(
            aplicacao.tipoAplicacao == 'Terrestre' ? Icons.agriculture : Icons.airplanemode_active,
            color: Colors.white,
          ),
        ),
        title: Text('Talhão ID: ${aplicacao.talhaoId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: $dataFormatada'),
            Text('Tipo: ${aplicacao.tipoAplicacao}'),
            Text('Equipamento: ${aplicacao.equipamento}'),
          ],
        ),
        trailing: Icon(
          aplicacao.statusSync == 'Sincronizado' ? Icons.cloud_done : Icons.cloud_upload,
          color: aplicacao.statusSync == 'Sincronizado' ? Colors.green : Colors.orange,
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.aplicacaoDetalhes,
            arguments: aplicacao.id.toString(),
          ).then((_) => _carregarAplicacoes());
        },
      ),
    );
  }
}

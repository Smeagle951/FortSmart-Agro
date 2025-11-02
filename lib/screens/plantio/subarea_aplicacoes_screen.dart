import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/subarea_model.dart';
import '../../database/models/aplicacao_model.dart';
import 'subarea_aplicacao_form_screen.dart';

/// Tela para gerenciar aplicações de uma subárea
class SubareaAplicacoesScreen extends StatefulWidget {
  final SubareaModel subarea;

  const SubareaAplicacoesScreen({
    Key? key,
    required this.subarea,
  }) : super(key: key);

  @override
  State<SubareaAplicacoesScreen> createState() => _SubareaAplicacoesScreenState();
}

class _SubareaAplicacoesScreenState extends State<SubareaAplicacoesScreen> {
  List<AplicacaoModel> _aplicacoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAplicacoes();
  }

  Future<void> _loadAplicacoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implementar carregamento real do banco
      // Por enquanto, dados mock
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _aplicacoes = [
          AplicacaoModel.create(
            subareaId: widget.subarea.id,
            experimentoId: widget.subarea.experimentoId,
            dataAplicacao: DateTime.now().subtract(const Duration(days: 5)),
            tipoAplicacao: 'fertilizante',
            produto: 'NPK 20-10-10',
            principioAtivo: 'Nitrogênio, Fósforo, Potássio',
            dosagem: 300.0,
            unidadeDosagem: 'kg/ha',
            volumeCalda: 200.0,
            equipamento: 'Pulverizador costal',
            condicoesTempo: 'ensolarado',
            temperatura: 28.0,
            umidadeRelativa: 65.0,
            velocidadeVento: 8.0,
            observacoes: 'Aplicação realizada pela manhã',
            responsavelTecnico: 'João Silva',
            crmResponsavel: 'SP-12345',
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar aplicações: $e');
    }
  }

  Future<void> _addNovaAplicacao() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubareaAplicacaoFormScreen(
          subarea: widget.subarea,
          aplicacao: null, // Nova aplicação
        ),
      ),
    );

    if (result != null) {
      await _loadAplicacoes();
      SnackbarUtils.showSuccessSnackBar(context, 'Aplicação adicionada com sucesso!');
    }
  }

  Future<void> _editAplicacao(AplicacaoModel aplicacao) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubareaAplicacaoFormScreen(
          subarea: widget.subarea,
          aplicacao: aplicacao,
        ),
      ),
    );

    if (result != null) {
      await _loadAplicacoes();
      SnackbarUtils.showSuccessSnackBar(context, 'Aplicação atualizada com sucesso!');
    }
  }

  Future<void> _deleteAplicacao(AplicacaoModel aplicacao) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a aplicação de ${aplicacao.produto}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implementar exclusão real do banco
        setState(() {
          _aplicacoes.remove(aplicacao);
        });
        SnackbarUtils.showSuccessSnackBar(context, 'Aplicação excluída com sucesso!');
      } catch (e) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao excluir aplicação: $e');
      }
    }
  }

  Widget _buildAplicacaoCard(AplicacaoModel aplicacao) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTipoColor(aplicacao.tipoAplicacao),
          child: Icon(
            _getTipoIcon(aplicacao.tipoAplicacao),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          aplicacao.produto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${aplicacao.dosagem} ${aplicacao.unidadeDosagem}'),
            Text(
              DateFormat('dd/MM/yyyy').format(aplicacao.dataAplicacao),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editAplicacao(aplicacao);
                break;
              case 'delete':
                _deleteAplicacao(aplicacao);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Excluir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showAplicacaoDetails(aplicacao),
      ),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'fertilizante':
        return Colors.green;
      case 'defensivo':
        return Colors.orange;
      case 'corretivo':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'fertilizante':
        return Icons.eco;
      case 'defensivo':
        return Icons.bug_report;
      case 'corretivo':
        return Icons.science;
      default:
        return Icons.agriculture;
    }
  }

  void _showAplicacaoDetails(AplicacaoModel aplicacao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aplicacao.produto,
                style: FortSmartTheme.headingStyle.copyWith(
                  color: FortSmartTheme.primaryColor,
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Data', DateFormat('dd/MM/yyyy HH:mm').format(aplicacao.dataAplicacao)),
                      _buildDetailRow('Tipo', aplicacao.tipoAplicacao.toUpperCase()),
                      _buildDetailRow('Princípio Ativo', aplicacao.principioAtivo),
                      _buildDetailRow('Dosagem', '${aplicacao.dosagem} ${aplicacao.unidadeDosagem}'),
                      _buildDetailRow('Volume de Calda', '${aplicacao.volumeCalda} L/ha'),
                      _buildDetailRow('Equipamento', aplicacao.equipamento),
                      _buildDetailRow('Condições do Tempo', aplicacao.condicoesTempo.toUpperCase()),
                      _buildDetailRow('Temperatura', '${aplicacao.temperatura}°C'),
                      _buildDetailRow('Umidade Relativa', '${aplicacao.umidadeRelativa}%'),
                      _buildDetailRow('Velocidade do Vento', '${aplicacao.velocidadeVento} km/h'),
                      _buildDetailRow('Responsável Técnico', aplicacao.responsavelTecnico),
                      _buildDetailRow('CRM', aplicacao.crmResponsavel),
                      if (aplicacao.observacoes.isNotEmpty)
                        _buildDetailRow('Observações', aplicacao.observacoes),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aplicações - ${widget.subarea.nome}'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNovaAplicacao,
            tooltip: 'Nova Aplicação',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _aplicacoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma aplicação registrada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para adicionar a primeira aplicação',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumo da subárea
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: FortSmartTheme.primaryColor.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subárea: ${widget.subarea.nome}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text('Área: ${NumberFormat("#,##0.00", "pt_BR").format(widget.subarea.areaHa)} ha'),
                          Text('Cultura: ${widget.subarea.cultura ?? 'Não informado'}'),
                          Text('Total de aplicações: ${_aplicacoes.length}'),
                        ],
                      ),
                    ),
                    
                    // Lista de aplicações
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _aplicacoes.length,
                        itemBuilder: (context, index) {
                          return _buildAplicacaoCard(_aplicacoes[index]);
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNovaAplicacao,
        backgroundColor: FortSmartTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Nova Aplicação',
      ),
    );
  }
}

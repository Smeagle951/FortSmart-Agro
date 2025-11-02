import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/subarea_model.dart';
import '../../database/models/colheita_model.dart';
import 'subarea_colheita_form_screen.dart';

/// Tela para gerenciar colheitas de uma subárea
class SubareaColheitasScreen extends StatefulWidget {
  final SubareaModel subarea;

  const SubareaColheitasScreen({
    Key? key,
    required this.subarea,
  }) : super(key: key);

  @override
  State<SubareaColheitasScreen> createState() => _SubareaColheitasScreenState();
}

class _SubareaColheitasScreenState extends State<SubareaColheitasScreen> {
  List<ColheitaModel> _colheitas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadColheitas();
  }

  Future<void> _loadColheitas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implementar carregamento real do banco
      // Por enquanto, dados mock
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _colheitas = [
          ColheitaModel.create(
            subareaId: widget.subarea.id,
            experimentoId: widget.subarea.experimentoId,
            dataColheita: DateTime.now().subtract(const Duration(days: 10)),
            tipoColheita: 'mecanizada',
            areaColhida: 2.5,
            producaoTotal: 7500.0,
            unidadeProducao: 'kg',
            produtividade: 3000.0,
            unidadeProdutividade: 'kg/ha',
            qualidade: 'boa',
            umidade: 14.5,
            impurezas: 2.0,
            danos: 1.5,
            equipamento: 'Colheitadeira John Deere',
            observacoes: 'Colheita realizada em condições ideais',
            responsavelColheita: 'Maria Santos',
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar colheitas: $e');
    }
  }

  Future<void> _addNovaColheita() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubareaColheitaFormScreen(
          subarea: widget.subarea,
          colheita: null, // Nova colheita
        ),
      ),
    );

    if (result != null) {
      await _loadColheitas();
      SnackbarUtils.showSuccessSnackBar(context, 'Colheita adicionada com sucesso!');
    }
  }

  Future<void> _editColheita(ColheitaModel colheita) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubareaColheitaFormScreen(
          subarea: widget.subarea,
          colheita: colheita,
        ),
      ),
    );

    if (result != null) {
      await _loadColheitas();
      SnackbarUtils.showSuccessSnackBar(context, 'Colheita atualizada com sucesso!');
    }
  }

  Future<void> _deleteColheita(ColheitaModel colheita) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a colheita de ${DateFormat('dd/MM/yyyy').format(colheita.dataColheita)}?'),
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
          _colheitas.remove(colheita);
        });
        SnackbarUtils.showSuccessSnackBar(context, 'Colheita excluída com sucesso!');
      } catch (e) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao excluir colheita: $e');
      }
    }
  }

  Widget _buildColheitaCard(ColheitaModel colheita) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getQualidadeColor(colheita.qualidade),
          child: Icon(
            Icons.agriculture,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '${colheita.produtividade.toStringAsFixed(0)} ${colheita.unidadeProdutividade}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${NumberFormat("#,##0.0", "pt_BR").format(colheita.producaoTotal)} ${colheita.unidadeProducao}'),
            Text(
              DateFormat('dd/MM/yyyy').format(colheita.dataColheita),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editColheita(colheita);
                break;
              case 'delete':
                _deleteColheita(colheita);
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
        onTap: () => _showColheitaDetails(colheita),
      ),
    );
  }

  Color _getQualidadeColor(String qualidade) {
    switch (qualidade) {
      case 'excelente':
        return Colors.green;
      case 'boa':
        return Colors.blue;
      case 'regular':
        return Colors.orange;
      case 'ruim':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showColheitaDetails(ColheitaModel colheita) {
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
                'Colheita - ${DateFormat('dd/MM/yyyy').format(colheita.dataColheita)}',
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
                      _buildDetailRow('Data da Colheita', DateFormat('dd/MM/yyyy HH:mm').format(colheita.dataColheita)),
                      _buildDetailRow('Tipo', colheita.tipoColheita.toUpperCase()),
                      _buildDetailRow('Área Colhida', '${NumberFormat("#,##0.00", "pt_BR").format(colheita.areaColhida)} ha'),
                      _buildDetailRow('Produção Total', '${NumberFormat("#,##0.0", "pt_BR").format(colheita.producaoTotal)} ${colheita.unidadeProducao}'),
                      _buildDetailRow('Produtividade', '${NumberFormat("#,##0.0", "pt_BR").format(colheita.produtividade)} ${colheita.unidadeProdutividade}'),
                      _buildDetailRow('Qualidade', colheita.qualidade.toUpperCase()),
                      _buildDetailRow('Umidade', '${colheita.umidade}%'),
                      _buildDetailRow('Impurezas', '${colheita.impurezas}%'),
                      _buildDetailRow('Danos', '${colheita.danos}%'),
                      _buildDetailRow('Equipamento', colheita.equipamento),
                      _buildDetailRow('Responsável', colheita.responsavelColheita),
                      if (colheita.observacoes.isNotEmpty)
                        _buildDetailRow('Observações', colheita.observacoes),
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

  Widget _buildResumoEstatisticas() {
    if (_colheitas.isEmpty) return const SizedBox.shrink();

    final totalProducao = _colheitas.fold<double>(0, (sum, c) => sum + c.producaoTotal);
    final mediaProdutividade = _colheitas.fold<double>(0, (sum, c) => sum + c.produtividade) / _colheitas.length;
    final totalArea = _colheitas.fold<double>(0, (sum, c) => sum + c.areaColhida);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FortSmartTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FortSmartTheme.primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo Estatístico',
            style: FortSmartTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: FortSmartTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Produção',
                  '${NumberFormat("#,##0.0", "pt_BR").format(totalProducao)} kg',
                  Icons.scale,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Média Produtividade',
                  '${NumberFormat("#,##0.0", "pt_BR").format(mediaProdutividade)} kg/ha',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Área',
                  '${NumberFormat("#,##0.00", "pt_BR").format(totalArea)} ha',
                  Icons.area_chart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Nº Colheitas',
                  '${_colheitas.length}',
                  Icons.repeat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: FortSmartTheme.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Colheitas - ${widget.subarea.nome}'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNovaColheita,
            tooltip: 'Nova Colheita',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _colheitas.isEmpty
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
                        'Nenhuma colheita registrada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para registrar a primeira colheita',
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
                          Text('Total de colheitas: ${_colheitas.length}'),
                        ],
                      ),
                    ),
                    
                    // Resumo estatístico
                    _buildResumoEstatisticas(),
                    
                    // Lista de colheitas
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _colheitas.length,
                        itemBuilder: (context, index) {
                          return _buildColheitaCard(_colheitas[index]);
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNovaColheita,
        backgroundColor: FortSmartTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Nova Colheita',
      ),
    );
  }
}

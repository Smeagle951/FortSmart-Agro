import 'package:flutter/material.dart';
import '../models/calculo_basico_model.dart';
import '../repositories/calculo_basico_repository.dart';

/// Tela para visualizar o histórico de calibrações
class HistoricoCalibracoesScreen extends StatefulWidget {
  const HistoricoCalibracoesScreen({super.key});

  @override
  State<HistoricoCalibracoesScreen> createState() => _HistoricoCalibracoesScreenState();
}

class _HistoricoCalibracoesScreenState extends State<HistoricoCalibracoesScreen> {
  final CalculoBasicoRepository _repository = CalculoBasicoRepository();
  List<CalculoBasicoModel> _calibracoes = [];
  bool _carregando = true;
  String _filtroEquipamento = '';
  String _filtroOperador = '';
  String _filtroFertilizante = '';
  String _filtroStatus = '';

  @override
  void initState() {
    super.initState();
    _carregarCalibracoes();
  }

  Future<void> _carregarCalibracoes() async {
    setState(() {
      _carregando = true;
    });

    try {
      final calibracoes = await _repository.buscarCalibracoesComFiltros(
        equipamento: _filtroEquipamento.isNotEmpty ? _filtroEquipamento : null,
        operador: _filtroOperador.isNotEmpty ? _filtroOperador : null,
        fertilizante: _filtroFertilizante.isNotEmpty ? _filtroFertilizante : null,
        statusCalibragem: _filtroStatus.isNotEmpty ? _filtroStatus : null,
      );

      setState(() {
        _calibracoes = calibracoes;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar calibrações: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _excluirCalibracao(String id) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta calibração?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      try {
        await _repository.removerCalibracao(id);
        await _carregarCalibracoes();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calibração excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir calibração: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Calibrações'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarCalibracoes,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _calibracoes.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildEstatisticas(),
                    Expanded(child: _buildListaCalibracoes()),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma calibração encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Execute algumas calibrações para ver o histórico aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticas() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEstatisticaItem(
            'Total',
              _calibracoes.length.toString(),
            Icons.analytics,
            Colors.blue,
          ),
          _buildEstatisticaItem(
            'Dentro da Meta',
            '${_calibracoes.where((c) => c.statusCalibragem == "Dentro da meta").length}',
            Icons.check_circle,
            Colors.green,
          ),
          _buildEstatisticaItem(
            'Precisa Ajuste',
            '${_calibracoes.where((c) => c.statusCalibragem != "Dentro da meta" && c.statusCalibragem != null).length}',
            Icons.warning,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticaItem(String label, String valor, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildListaCalibracoes() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _calibracoes.length,
      itemBuilder: (context, index) {
        final calibracao = _calibracoes[index];
        return _buildCalibracaoCard(calibracao);
      },
    );
  }

  Widget _buildCalibracaoCard(CalculoBasicoModel calibracao) {
    Color statusColor;
    IconData statusIcon;
    
    if (calibracao.statusCalibragem == "Dentro da meta") {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (calibracao.statusCalibragem == "Acima da meta") {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (calibracao.statusCalibragem == "Abaixo da meta") {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetalhes(calibracao),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calibracao.nome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${calibracao.equipamento} • ${calibracao.operador}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Fertilizante',
                      calibracao.fertilizante,
                      Icons.eco,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Data',
                      _formatarData(calibracao.dataCalibragem),
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Taxa (kg/ha)',
                      calibracao.taxaAplicadaKg?.toStringAsFixed(1) ?? 'N/A',
                      Icons.speed,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Taxa (L/ha)',
                      calibracao.taxaAplicadaL?.toStringAsFixed(1) ?? 'N/A',
                      Icons.opacity,
                    ),
                  ),
                ],
              ),
              if (calibracao.statusCalibragem != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    calibracao.statusCalibragem!,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String valor, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarDetalhes(CalculoBasicoModel calibracao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(calibracao.nome),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalheItem('Equipamento', calibracao.equipamento),
              _buildDetalheItem('Operador', calibracao.operador),
              _buildDetalheItem('Fertilizante', calibracao.fertilizante),
              _buildDetalheItem('Data', _formatarData(calibracao.dataCalibragem)),
              _buildDetalheItem('Velocidade', '${calibracao.velocidadeTrator} km/h'),
              _buildDetalheItem('Largura de Trabalho', '${calibracao.larguraTrabalho} m'),
              _buildDetalheItem('Área', '${calibracao.areaHectares} ha'),
              _buildDetalheItem('Taxa (kg/ha)', calibracao.taxaAplicadaKg?.toStringAsFixed(1) ?? 'N/A'),
              _buildDetalheItem('Taxa (L/ha)', calibracao.taxaAplicadaL?.toStringAsFixed(1) ?? 'N/A'),
              if (calibracao.sacasHa != null)
                _buildDetalheItem('Sacas/ha', '${calibracao.sacasHa!.toStringAsFixed(2)}'),
              if (calibracao.statusCalibragem != null)
                _buildDetalheItem('Status', calibracao.statusCalibragem!),
              if (calibracao.sugestaoAjuste != null)
                _buildDetalheItem('Sugestão', calibracao.sugestaoAjuste!),
              if (calibracao.observacoes != null && calibracao.observacoes!.isNotEmpty)
                _buildDetalheItem('Observações', calibracao.observacoes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _excluirCalibracao(calibracao.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(valor),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Equipamento',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _filtroEquipamento = value,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Operador',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _filtroOperador = value,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Fertilizante',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _filtroFertilizante = value,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              value: _filtroStatus.isEmpty ? null : _filtroStatus,
              items: const [
                DropdownMenuItem(value: '', child: Text('Todos')),
                DropdownMenuItem(value: 'Dentro da meta', child: Text('Dentro da meta')),
                DropdownMenuItem(value: 'Acima da meta', child: Text('Acima da meta')),
                DropdownMenuItem(value: 'Abaixo da meta', child: Text('Abaixo da meta')),
              ],
              onChanged: (value) => _filtroStatus = value ?? '',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _filtroEquipamento = '';
              _filtroOperador = '';
              _filtroFertilizante = '';
              _filtroStatus = '';
              Navigator.of(context).pop();
              _carregarCalibracoes();
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _carregarCalibracoes();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

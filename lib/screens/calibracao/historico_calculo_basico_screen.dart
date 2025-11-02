import 'package:flutter/material.dart';
import '../../models/calculo_basico_calibracao_model.dart';
import '../../services/calculo_basico_calibracao_service.dart';

/// Tela de histórico de cálculos básicos de calibração
/// Seguindo o padrão FortSmart elegante
class HistoricoCalculoBasicoScreen extends StatefulWidget {
  const HistoricoCalculoBasicoScreen({super.key});

  @override
  State<HistoricoCalculoBasicoScreen> createState() => _HistoricoCalculoBasicoScreenState();
}

class _HistoricoCalculoBasicoScreenState extends State<HistoricoCalculoBasicoScreen> {
  final _service = CalculoBasicoCalibracaoService();
  final _searchController = TextEditingController();
  
  List<CalculoBasicoCalibracaoModel> _calibracoes = [];
  List<CalculoBasicoCalibracaoModel> _calibracoesFiltradas = [];
  bool _isLoading = true;
  String _filtroAtivo = 'Todas';

  @override
  void initState() {
    super.initState();
    _carregarCalibracoes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarCalibracoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final calibracoes = await _service.buscarTodas();
      setState(() {
        _calibracoes = calibracoes;
        _calibracoesFiltradas = calibracoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarErro('Erro ao carregar histórico: $e');
    }
  }

  void _filtrarCalibracoes(String filtro) {
    setState(() {
      _filtroAtivo = filtro;
      
      switch (filtro) {
        case 'Todas':
          _calibracoesFiltradas = _calibracoes;
          break;
        case 'Por Tempo':
          _calibracoesFiltradas = _calibracoes
              .where((c) => c.rawInputs.mode == InputMode.time)
              .toList();
          break;
        case 'Por Distância':
          _calibracoesFiltradas = _calibracoes
              .where((c) => c.rawInputs.mode == InputMode.distance)
              .toList();
          break;
        case 'Precisas':
          _calibracoesFiltradas = _calibracoes
              .where((c) => c.computedResults.erroPercent.abs() <= 2)
              .toList();
          break;
        case 'Com Erro':
          _calibracoesFiltradas = _calibracoes
              .where((c) => c.computedResults.erroPercent.abs() > 2)
              .toList();
          break;
      }
      
      _aplicarBusca();
    });
  }

  void _aplicarBusca() {
    final busca = _searchController.text.toLowerCase();
    if (busca.isEmpty) return;
    
    _calibracoesFiltradas = _calibracoesFiltradas.where((calibracao) {
      final operador = calibracao.operador?.toLowerCase() ?? '';
      final maquina = calibracao.maquina?.toLowerCase() ?? '';
      final fertilizante = calibracao.fertilizante?.toLowerCase() ?? '';
      final nome = calibracao.nomeCalibracao?.toLowerCase() ?? '';
      
      return operador.contains(busca) ||
             maquina.contains(busca) ||
             fertilizante.contains(busca) ||
             nome.contains(busca);
    }).toList();
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarDetalhes(CalculoBasicoCalibracaoModel calibracao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes da Calibração'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalheItem('Data', _formatarData(calibracao.dataCriacao)),
              _buildDetalheItem('Modo', calibracao.rawInputs.mode == InputMode.time ? 'Por Tempo' : 'Por Distância'),
              _buildDetalheItem('Largura da Faixa', '${calibracao.rawInputs.widthMeters} m'),
              _buildDetalheItem('Velocidade', '${calibracao.rawInputs.speedKmh} km/h'),
              _buildDetalheItem('Valor Coletado', '${calibracao.rawInputs.collectedKg} kg'),
              _buildDetalheItem('Taxa Desejada', '${calibracao.rawInputs.desiredKgHa} kg/ha'),
              const Divider(),
              _buildDetalheItem('Taxa Real', '${calibracao.computedResults.taxaKgHa.toStringAsFixed(2)} kg/ha'),
              _buildDetalheItem('Erro vs Meta', '${calibracao.computedResults.erroPercent.toStringAsFixed(2)}%'),
              _buildDetalheItem('Área Percorrida', '${calibracao.computedResults.areaHa.toStringAsFixed(4)} ha'),
              if (calibracao.operador != null) _buildDetalheItem('Operador', calibracao.operador!),
              if (calibracao.maquina != null) _buildDetalheItem('Máquina', calibracao.maquina!),
              if (calibracao.fertilizante != null) _buildDetalheItem('Fertilizante', calibracao.fertilizante!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _gerarRelatorio(calibracao);
            },
            child: const Text('Relatório'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _gerarRelatorio(CalculoBasicoCalibracaoModel calibracao) {
    final relatorio = _service.gerarRelatorio(calibracao);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatório de Calibração'),
        content: SingleChildScrollView(
          child: SelectableText(relatorio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementar exportação do relatório
              Navigator.pop(context);
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCalibracao(CalculoBasicoCalibracaoModel calibracao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir esta calibração?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final sucesso = await _service.excluir(calibracao.id);
      if (mounted) {
        if (sucesso) {
          await _carregarCalibracoes();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calibração excluída com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _mostrarErro('Erro ao excluir calibração');
        }
      }
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  Color _getErroColor(double erro) {
    if (erro.abs() <= 2) return Colors.green;
    if (erro.abs() <= 10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Calibrações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarCalibracoes,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _mostrarEstatisticas,
            tooltip: 'Estatísticas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca e filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                // Barra de busca
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por operador, máquina, fertilizante...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _carregarCalibracoes();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    _carregarCalibracoes();
                    _aplicarBusca();
                  },
                ),
                const SizedBox(height: 12),
                
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroChip('Todas', _calibracoes.length),
                      _buildFiltroChip('Por Tempo', _calibracoes.where((c) => c.rawInputs.mode == InputMode.time).length),
                      _buildFiltroChip('Por Distância', _calibracoes.where((c) => c.rawInputs.mode == InputMode.distance).length),
                      _buildFiltroChip('Precisas', _calibracoes.where((c) => c.computedResults.erroPercent.abs() <= 2).length),
                      _buildFiltroChip('Com Erro', _calibracoes.where((c) => c.computedResults.erroPercent.abs() > 2).length),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de calibrações
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _calibracoesFiltradas.isEmpty
                    ? _buildListaVazia()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _calibracoesFiltradas.length,
                        itemBuilder: (context, index) {
                          final calibracao = _calibracoesFiltradas[index];
                          return _buildCalibracaoCard(calibracao);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, int count) {
    final isActive = _filtroAtivo == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isActive,
        onSelected: (selected) {
          if (selected) {
            _filtrarCalibracoes(label);
          }
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildListaVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma calibração encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Realize sua primeira calibração',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibracaoCard(CalculoBasicoCalibracaoModel calibracao) {
    final erro = calibracao.computedResults.erroPercent;
    final erroColor = _getErroColor(erro);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _mostrarDetalhes(calibracao),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calibracao.nomeCalibracao ?? 'Calibração ${_formatarData(calibracao.dataCriacao)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatarData(calibracao.dataCriacao),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: erroColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: erroColor),
                        ),
                        child: Text(
                          '${erro.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: erroColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'detalhes':
                              _mostrarDetalhes(calibracao);
                              break;
                            case 'relatorio':
                              _gerarRelatorio(calibracao);
                              break;
                            case 'excluir':
                              _excluirCalibracao(calibracao);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'detalhes',
                            child: Row(
                              children: [
                                Icon(Icons.info, size: 16),
                                SizedBox(width: 8),
                                Text('Detalhes'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'relatorio',
                            child: Row(
                              children: [
                                Icon(Icons.description, size: 16),
                                SizedBox(width: 8),
                                Text('Relatório'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações principais
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.speed,
                      'Taxa Real',
                      '${calibracao.computedResults.taxaKgHa.toStringAsFixed(2)} kg/ha',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.straighten,
                      'Área',
                      '${calibracao.computedResults.areaHa.toStringAsFixed(3)} ha',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.timeline,
                      'Modo',
                      calibracao.rawInputs.mode == InputMode.time ? 'Tempo' : 'Distância',
                    ),
                  ),
                ],
              ),
              
              // Informações adicionais
              if (calibracao.operador != null || calibracao.maquina != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (calibracao.operador != null) ...[
                      Expanded(
                        child: _buildInfoItem(
                          Icons.person,
                          'Operador',
                          calibracao.operador!,
                        ),
                      ),
                    ],
                    if (calibracao.maquina != null) ...[
                      Expanded(
                        child: _buildInfoItem(
                          Icons.agriculture,
                          'Máquina',
                          calibracao.maquina!,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarEstatisticas() {
    final stats = _service.gerarEstatisticas();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estatísticas'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('Total de Calibrações', stats['total'].toString()),
              _buildStatItem('Por Tempo', stats['porModo']['tempo'].toString()),
              _buildStatItem('Por Distância', stats['porModo']['distancia'].toString()),
              _buildStatItem('Calibrações Precisas', stats['calibracoesPrecisas'].toString()),
              _buildStatItem('Média de Erro', '${stats['mediaErro'].toStringAsFixed(2)}%'),
              if (stats['periodo'] != null) ...[
                const Divider(),
                _buildStatItem('Período', '${stats['periodo']['inicio']} - ${stats['periodo']['fim']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

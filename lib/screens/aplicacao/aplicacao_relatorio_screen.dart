import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/models/aplicacao_model.dart';
import '../../database/repositories/aplicacao_repository.dart';
import '../../services/database_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/app_drawer.dart';

/// Tela de relatórios de aplicações agrícolas
class AplicacaoRelatorioScreen extends StatefulWidget {
  const AplicacaoRelatorioScreen({super.key});

  @override
  _AplicacaoRelatorioScreenState createState() => _AplicacaoRelatorioScreenState();
}

class _AplicacaoRelatorioScreenState extends State<AplicacaoRelatorioScreen> {
  late AplicacaoRepository _repository;
  bool _isLoading = true;
  List<AplicacaoModel> _aplicacoes = [];
  String _periodoSelecionado = 'Último Mês';
  String _tipoGraficoSelecionado = 'Tipo de Aplicação';
  
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
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar dados para relatório');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Filtra as aplicações por período
  List<AplicacaoModel> _getAplicacoesFiltradas() {
    final hoje = DateTime.now();
    DateTime dataInicial;
    
    switch (_periodoSelecionado) {
      case 'Última Semana':
        dataInicial = hoje.subtract(const Duration(days: 7));
        break;
      case 'Último Mês':
        dataInicial = DateTime(hoje.year, hoje.month - 1, hoje.day);
        break;
      case 'Último Trimestre':
        dataInicial = DateTime(hoje.year, hoje.month - 3, hoje.day);
        break;
      case 'Último Ano':
        dataInicial = DateTime(hoje.year - 1, hoje.month, hoje.day);
        break;
      default:
        dataInicial = DateTime(hoje.year, hoje.month - 1, hoje.day);
    }
    
    return _aplicacoes.where((a) {
      final dataAplicacao = DateTime.parse(a.data);
      return dataAplicacao.isAfter(dataInicial) && dataAplicacao.isBefore(hoje);
    }).toList();
  }

  /// Obtém dados para o gráfico de tipo de aplicação
  Map<String, int> _getDadosTipoAplicacao() {
    final aplicacoesFiltradas = _getAplicacoesFiltradas();
    final Map<String, int> dados = {};
    
    for (var aplicacao in aplicacoesFiltradas) {
      final tipo = aplicacao.tipoAplicacao;
      dados[tipo] = (dados[tipo] ?? 0) + 1;
    }
    
    return dados;
  }

  /// Obtém dados para o gráfico de área tratada
  Map<String, double> _getDadosAreaTratada() {
    final aplicacoesFiltradas = _getAplicacoesFiltradas();
    final Map<String, double> dados = {};
    
    for (var aplicacao in aplicacoesFiltradas) {
      final talhaoId = aplicacao.talhaoId ?? 'Sem talhão';
      dados[talhaoId] = (dados[talhaoId] ?? 0) + aplicacao.areaTotal;
    }
    
    return dados;
  }

  /// Obtém dados para o gráfico de produtos utilizados
  Map<String, double> _getDadosProdutosUtilizados() {
    final aplicacoesFiltradas = _getAplicacoesFiltradas();
    final Map<String, double> dados = {};
    
    for (var aplicacao in aplicacoesFiltradas) {
      for (var produto in aplicacao.produtos) {
        final nomeProduto = produto;
        dados[nomeProduto] = (dados[nomeProduto] ?? 0) + 1.0; // Contar ocorrências
      }
    }
    
    return dados;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Relatórios de Aplicação',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFiltros(),
                  const SizedBox(height: 24),
                  _buildGrafico(),
                  const SizedBox(height: 24),
                  _buildEstatisticas(),
                ],
              ),
            ),
    );
  }

  /// Constrói a seção de filtros
  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Período:'),
                      DropdownButton<String>(
                        value: _periodoSelecionado,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Última Semana', child: Text('Última Semana')),
                          DropdownMenuItem(value: 'Último Mês', child: Text('Último Mês')),
                          DropdownMenuItem(value: 'Último Trimestre', child: Text('Último Trimestre')),
                          DropdownMenuItem(value: 'Último Ano', child: Text('Último Ano')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _periodoSelecionado = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo de Gráfico:'),
                      DropdownButton<String>(
                        value: _tipoGraficoSelecionado,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Tipo de Aplicação', child: Text('Tipo de Aplicação')),
                          DropdownMenuItem(value: 'Área Tratada', child: Text('Área Tratada')),
                          DropdownMenuItem(value: 'Produtos Utilizados', child: Text('Produtos Utilizados')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tipoGraficoSelecionado = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o gráfico de acordo com o tipo selecionado
  Widget _buildGrafico() {
    final aplicacoesFiltradas = _getAplicacoesFiltradas();
    
    if (aplicacoesFiltradas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Nenhum dado disponível para o período selecionado'),
          ),
        ),
      );
    }

    Map<String, dynamic> dados;
    List<Color> cores = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
    ];
    
    switch (_tipoGraficoSelecionado) {
      case 'Tipo de Aplicação':
        dados = _getDadosTipoAplicacao();
        break;
      case 'Área Tratada':
        dados = _getDadosAreaTratada();
        break;
      case 'Produtos Utilizados':
        dados = _getDadosProdutosUtilizados();
        break;
      default:
        dados = _getDadosTipoAplicacao();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tipoGraficoSelecionado,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(dados, cores),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegenda(dados, cores),
          ],
        ),
      ),
    );
  }

  /// Constrói as seções do gráfico de pizza
  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> dados, List<Color> cores) {
    final List<PieChartSectionData> sections = [];
    final entries = dados.entries.toList();
    
    double total = 0;
    for (var entry in entries) {
      total += entry.value.toDouble();
    }
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final color = cores[i % cores.length];
      final percentual = (entry.value / total) * 100;
      
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${percentual.toStringAsFixed(1)}%',
          color: color,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return sections;
  }

  /// Constrói a legenda do gráfico
  Widget _buildLegenda(Map<String, dynamic> dados, List<Color> cores) {
    final entries = dados.entries.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final color = cores[index % cores.length];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(entry.key),
              ),
              Text(
                _tipoGraficoSelecionado == 'Tipo de Aplicação'
                    ? '${entry.value} aplicações'
                    : _tipoGraficoSelecionado == 'Área Tratada'
                        ? '${entry.value.toStringAsFixed(2)} ha'
                        : entry.value.toStringAsFixed(2),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Constrói a seção de estatísticas
  Widget _buildEstatisticas() {
    final aplicacoesFiltradas = _getAplicacoesFiltradas();
    
    if (aplicacoesFiltradas.isEmpty) {
      return const SizedBox();
    }

    double areaTotal = 0;
    int totalAplicacoes = aplicacoesFiltradas.length;
    int aplicacoesTerrestre = 0;
    int aplicacoesAerea = 0;
    
    for (var aplicacao in aplicacoesFiltradas) {
      areaTotal += aplicacao.areaTotal;
      if (aplicacao.tipoAplicacao == 'Terrestre') {
        aplicacoesTerrestre++;
      } else if (aplicacao.tipoAplicacao == 'Aérea') {
        aplicacoesAerea++;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildEstatisticaItem('Total de Aplicações', totalAplicacoes.toString()),
            _buildEstatisticaItem('Área Total Tratada', '${areaTotal.toStringAsFixed(2)} ha'),
            _buildEstatisticaItem('Aplicações Terrestres', aplicacoesTerrestre.toString()),
            _buildEstatisticaItem('Aplicações Aéreas', aplicacoesAerea.toString()),
            _buildEstatisticaItem('Média de Área por Aplicação', 
              totalAplicacoes > 0 
                ? '${(areaTotal / totalAplicacoes).toStringAsFixed(2)} ha' 
                : '0 ha'
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um item de estatística
  Widget _buildEstatisticaItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(valor),
        ],
      ),
    );
  }
}

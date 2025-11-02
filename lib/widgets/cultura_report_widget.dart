import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/talhao_model.dart';
import '../services/talhao_integration_service.dart';
import '../utils/logger.dart';

/// Widget para exibir relatórios de culturas em formato gráfico
class CulturaReportWidget extends StatefulWidget {
  /// Filtro de safra opcional
  final String? safraFiltro;
  
  /// Filtro de cultura opcional
  final String? culturaFiltro;
  
  /// Título do relatório
  final String titulo;
  
  /// Altura do gráfico
  final double altura;
  
  /// Mostrar legenda
  final bool mostrarLegenda;

  const CulturaReportWidget({
    Key? key,
    this.safraFiltro,
    this.culturaFiltro,
    this.titulo = 'Distribuição de Culturas',
    this.altura = 300,
    this.mostrarLegenda = true,
  }) : super(key: key);

  @override
  State<CulturaReportWidget> createState() => _CulturaReportWidgetState();
}

class _CulturaReportWidgetState extends State<CulturaReportWidget> {
  final TalhaoIntegrationService _integrationService = TalhaoIntegrationService();
  
  bool _isLoading = true;
  Map<String, double> _areaPorCultura = {};
  List<Color> _cores = [];
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  @override
  void didUpdateWidget(CulturaReportWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.safraFiltro != widget.safraFiltro || 
        oldWidget.culturaFiltro != widget.culturaFiltro) {
      _carregarDados();
    }
  }
  
  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    try {
      // Carregar dados consolidados do serviço de integração
      final dados = await _integrationService.getDadosConsolidados(
        safraFiltro: widget.safraFiltro,
        culturaFiltro: widget.culturaFiltro,
      );
      
      // Extrair área por cultura dos dados consolidados
      final areaPorCultura = dados['areaPorCultura'] as Map<String, dynamic>? ?? {};
      
      // Converter para o formato esperado pelo widget
      _areaPorCultura = {};
      areaPorCultura.forEach((cultura, area) {
        if (area is num) {
          _areaPorCultura[cultura] = area.toDouble();
        }
      });
      
      // Gerar cores para cada cultura
      _cores = _gerarCores(_areaPorCultura.length);
    } catch (e) {
      Logger.error('Erro ao carregar dados para o relatório: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  List<Color> _gerarCores(int quantidade) {
    // Cores base para o gráfico
    final coresPredefinidas = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    
    if (quantidade <= coresPredefinidas.length) {
      return coresPredefinidas.sublist(0, quantidade);
    }
    
    // Se precisar de mais cores, gerar aleatoriamente
    final cores = List<Color>.from(coresPredefinidas);
    
    for (int i = coresPredefinidas.length; i < quantidade; i++) {
      final hue = (360 * i / quantidade) % 360;
      cores.add(HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor());
    }
    
    return cores;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titulo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              SizedBox(
                height: widget.altura,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_areaPorCultura.isEmpty)
              SizedBox(
                height: widget.altura,
                child: const Center(
                  child: Text('Nenhum dado disponível'),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: widget.altura,
                    child: PieChart(
                      PieChartData(
                        sections: _criarSecoes(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  if (widget.mostrarLegenda) ...[
                    const SizedBox(height: 16),
                    _construirLegenda(),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _criarSecoes() {
    final List<PieChartSectionData> secoes = [];
    
    int i = 0;
    double areaTotal = _areaPorCultura.values.fold(0, (sum, area) => sum + area);
    
    for (final entry in _areaPorCultura.entries) {
      final percentual = (entry.value / areaTotal) * 100;
      
      secoes.add(
        PieChartSectionData(
          color: _cores[i % _cores.length],
          value: entry.value,
          title: '${percentual.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      i++;
    }
    
    return secoes;
  }
  
  Widget _construirLegenda() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children: List.generate(
        _areaPorCultura.length,
        (index) {
          final entry = _areaPorCultura.entries.elementAt(index);
          return _itemLegenda(
            entry.key,
            entry.value.toStringAsFixed(2),
            _cores[index % _cores.length],
          );
        },
      ),
    );
  }
  
  Widget _itemLegenda(String nome, String area, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$nome: $area ha'),
      ],
    );
  }
}

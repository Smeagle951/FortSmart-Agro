import 'package:flutter/material.dart';
import '../services/cost_management_service.dart';
import '../services/pdf_report_service.dart';
import '../../../../utils/logger.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/loading_widget.dart';

class CostReportScreen extends StatefulWidget {
  const CostReportScreen({Key? key}) : super(key: key);

  @override
  State<CostReportScreen> createState() => _CostReportScreenState();
}

class _CostReportScreenState extends State<CostReportScreen> {
  final CostManagementService _costManagementService = CostManagementService();
  final PdfReportService _pdfReportService = PdfReportService();

  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  
  // Filtros
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  String? _talhaoSelecionado;
  
  // Dados do relatório
  Map<String, dynamic> _resumoCustos = {};
  List<Map<String, dynamic>> _aplicacoesDetalhadas = [];
  List<Map<String, dynamic>> _custosPorTalhao = [];
  List<Map<String, dynamic>> _produtosMaisUtilizados = [];

  @override
  void initState() {
    super.initState();
    _gerarRelatorio();
  }

  Future<void> _gerarRelatorio() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('📊 Gerando relatório de custos...');

      // Carregar dados em paralelo
      final futures = await Future.wait([
        _costManagementService.calcularCustosPorPeriodo(
          dataInicio: _dataInicio,
          dataFim: _dataFim,
          talhaoId: _talhaoSelecionado,
        ),
        _costManagementService.obterAplicacoesDetalhadas(
          dataInicio: _dataInicio,
          dataFim: _dataFim,
          talhaoId: _talhaoSelecionado,
        ),
        _costManagementService.calcularCustosPorTalhao(
          dataInicio: _dataInicio,
          dataFim: _dataFim,
        ),
        _costManagementService.obterProdutosMaisUtilizados(
          dataInicio: _dataInicio,
          dataFim: _dataFim,
        ),
      ]);

      setState(() {
        _resumoCustos = futures[0] as Map<String, dynamic>;
        _aplicacoesDetalhadas = futures[1] as List<Map<String, dynamic>>;
        _custosPorTalhao = futures[2] as List<Map<String, dynamic>>;
        _produtosMaisUtilizados = futures[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });

      Logger.info('✅ Relatório gerado com sucesso!');
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar relatório: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Relatório de Custos',
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFiltros(),
          const SizedBox(height: 16),
          _buildResumoGeral(),
          const SizedBox(height: 16),
          _buildCustosPorTalhao(),
          const SizedBox(height: 16),
          _buildProdutosMaisUtilizados(),
          const SizedBox(height: 16),
          _buildAplicacoesDetalhadas(),
          const SizedBox(height: 16),
          _buildBotoesAcao(),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    'Data Início',
                    _dataInicio,
                    (date) => setState(() => _dataInicio = date),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDatePicker(
                    'Data Fim',
                    _dataFim,
                    (date) => setState(() => _dataFim = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _gerarRelatorio,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar Relatório'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoGeral() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo Geral',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Custo Total',
                    'R\$ ${(_resumoCustos['custoTotal'] ?? 0.0).toStringAsFixed(2)}',
                    Colors.green,
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Aplicações',
                    (_resumoCustos['totalAplicacoes'] ?? 0).toString(),
                    Colors.blue,
                    Icons.agriculture,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Custo Médio/ha',
                    'R\$ ${(_resumoCustos['custoPorHectare'] ?? 0.0).toStringAsFixed(2)}',
                    Colors.orange,
                    Icons.analytics,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Área Total',
                    '${(_resumoCustos['areaTotal'] ?? 0.0).toStringAsFixed(2)} ha',
                    Colors.purple,
                    Icons.map,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustosPorTalhao() {
    if (_custosPorTalhao.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custos por Talhão',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_custosPorTalhao.map((talhao) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      talhao['talhaoNome'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${(talhao['areaHa'] ?? 0.0).toStringAsFixed(2)} ha',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'R\$ ${(talhao['custoTotal'] ?? 0.0).toStringAsFixed(2)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutosMaisUtilizados() {
    if (_produtosMaisUtilizados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produtos Mais Utilizados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_produtosMaisUtilizados.take(5).map((produto) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      produto['produtoNome'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${produto['aplicacoes'] ?? 0} aplicações',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'R\$ ${(produto['custoTotal'] ?? 0.0).toStringAsFixed(2)}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildAplicacoesDetalhadas() {
    if (_aplicacoesDetalhadas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aplicações Detalhadas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_aplicacoesDetalhadas.length} registros',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_aplicacoesDetalhadas.take(10).map((aplicacao) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          aplicacao['talhaoNome'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        'R\$ ${(aplicacao['custoTotal'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '${_formatDate(aplicacao['dataAplicacao'])} • ${aplicacao['operador'] ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(),
                ],
              ),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isGeneratingPdf ? null : _exportarRelatorio,
            icon: _isGeneratingPdf 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download),
            label: Text(_isGeneratingPdf ? 'Gerando...' : 'Exportar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isGeneratingPdf ? null : _compartilharRelatorio,
            icon: _isGeneratingPdf 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share),
            label: Text(_isGeneratingPdf ? 'Gerando...' : 'Compartilhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportarRelatorio() async {
    if (_isGeneratingPdf) return;
    
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      Logger.info('📄 Iniciando exportação do relatório PDF...');
      
      // Mostrar diálogo de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Gerando relatório PDF...'),
            ],
          ),
        ),
      );

      // Gerar PDF
      final filePath = await _pdfReportService.gerarRelatorioPremium(
        aplicacoes: _aplicacoesDetalhadas,
        resumoCustos: _resumoCustos,
        custosPorTalhao: _custosPorTalhao,
        produtosMaisUtilizados: _produtosMaisUtilizados,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        talhaoFiltro: _talhaoSelecionado,
      );

      // Fechar diálogo de progresso
      Navigator.of(context).pop();

      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Relatório PDF gerado com sucesso!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Abrir',
            textColor: Colors.white,
            onPressed: () => _pdfReportService.compartilharRelatorio(filePath),
          ),
        ),
      );

      Logger.info('✅ Relatório PDF exportado com sucesso: $filePath');
    } catch (e) {
      // Fechar diálogo de progresso se estiver aberto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      Logger.error('❌ Erro ao exportar relatório: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar relatório: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  Future<void> _compartilharRelatorio() async {
    if (_isGeneratingPdf) return;
    
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      Logger.info('📤 Iniciando compartilhamento do relatório PDF...');
      
      // Mostrar diálogo de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Gerando relatório para compartilhamento...'),
            ],
          ),
        ),
      );

      // Gerar PDF
      final filePath = await _pdfReportService.gerarRelatorioPremium(
        aplicacoes: _aplicacoesDetalhadas,
        resumoCustos: _resumoCustos,
        custosPorTalhao: _custosPorTalhao,
        produtosMaisUtilizados: _produtosMaisUtilizados,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        talhaoFiltro: _talhaoSelecionado,
      );

      // Fechar diálogo de progresso
      Navigator.of(context).pop();

      // Compartilhar PDF
      await _pdfReportService.compartilharRelatorio(filePath);

      Logger.info('✅ Relatório PDF compartilhado com sucesso!');
    } catch (e) {
      // Fechar diálogo de progresso se estiver aberto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      Logger.error('❌ Erro ao compartilhar relatório: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar relatório: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}

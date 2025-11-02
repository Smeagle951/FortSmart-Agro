import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/planting_quality_report_model.dart';
import '../../../../database/repositories/planting_quality_report_repository.dart';
import '../../../../utils/fortsmart_theme.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/custom_button.dart';
import 'planting_quality_report_screen.dart';
import 'widgets/planting_quality_report_widget.dart';

/// Tela de histórico de relatórios de qualidade de plantio
class PlantingQualityReportsHistoryScreen extends StatefulWidget {
  const PlantingQualityReportsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PlantingQualityReportsHistoryScreen> createState() => _PlantingQualityReportsHistoryScreenState();
}

class _PlantingQualityReportsHistoryScreenState extends State<PlantingQualityReportsHistoryScreen> {
  final _repository = PlantingQualityReportRepository();
  
  List<PlantingQualityReportModel> _relatorios = [];
  List<PlantingQualityReportModel> _relatoriosFiltrados = [];
  bool _isLoading = true;
  String _filtroSelecionado = 'Todos';
  String _busca = '';
  
  final List<String> _filtros = [
    'Todos',
    'Favoritos',
    'Alta qualidade',
    'Boa qualidade',
    'Regular',
    'Atenção',
  ];

  @override
  void initState() {
    super.initState();
    _carregarRelatorios();
  }

  Future<void> _carregarRelatorios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final relatorios = await _repository.buscarTodosRelatorios();
      setState(() {
        _relatorios = relatorios;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar relatórios: ${e.toString()}');
    }
  }

  void _aplicarFiltros() {
    List<PlantingQualityReportModel> filtrados = List.from(_relatorios);

    // Aplicar filtro de categoria
    switch (_filtroSelecionado) {
      case 'Favoritos':
        filtrados = filtrados.where((r) => r.id.isNotEmpty).toList(); // Assumindo que favoritos têm ID
        break;
      case 'Alta qualidade':
        filtrados = filtrados.where((r) => r.statusGeral == 'Alta qualidade').toList();
        break;
      case 'Boa qualidade':
        filtrados = filtrados.where((r) => r.statusGeral == 'Boa qualidade').toList();
        break;
      case 'Regular':
        filtrados = filtrados.where((r) => r.statusGeral == 'Regular').toList();
        break;
      case 'Atenção':
        filtrados = filtrados.where((r) => r.statusGeral == 'Atenção').toList();
        break;
    }

    // Aplicar filtro de busca
    if (_busca.isNotEmpty) {
      filtrados = filtrados.where((r) =>
          r.talhaoNome.toLowerCase().contains(_busca.toLowerCase()) ||
          r.culturaNome.toLowerCase().contains(_busca.toLowerCase()) ||
          r.executor.toLowerCase().contains(_busca.toLowerCase())
      ).toList();
    }

    setState(() {
      _relatoriosFiltrados = filtrados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Histórico de Relatórios',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarRelatorios,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros e busca
          _buildFiltrosEBusca(),
          
          // Conteúdo
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _relatoriosFiltrados.isEmpty
                    ? _buildEmptyState()
                    : _buildListaRelatorios(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosEBusca() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Barra de busca
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por talhão, cultura ou executor...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _busca = value;
              });
              _aplicarFiltros();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filtros
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filtros.length,
              itemBuilder: (context, index) {
                final filtro = _filtros[index];
                final isSelected = _filtroSelecionado == filtro;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filtro),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filtroSelecionado = filtro;
                      });
                      _aplicarFiltros();
                    },
                    selectedColor: FortSmartTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: FortSmartTheme.primaryColor,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Contador de resultados
          Text(
            '${_relatoriosFiltrados.length} relatório(s) encontrado(s)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum relatório encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gere seu primeiro relatório de qualidade de plantio',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Gerar Relatório',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaRelatorios() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _relatoriosFiltrados.length,
      itemBuilder: (context, index) {
        final relatorio = _relatoriosFiltrados[index];
        return _buildRelatorioCard(relatorio);
      },
    );
  }

  Widget _buildRelatorioCard(PlantingQualityReportModel relatorio) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _abrirRelatorio(relatorio),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(int.parse(relatorio.corStatusGeral.replaceAll('#', '0xFF'))).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.assessment,
                      color: Color(int.parse(relatorio.corStatusGeral.replaceAll('#', '0xFF'))),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          relatorio.talhaoNome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${relatorio.culturaNome} • ${DateFormat('dd/MM/yyyy').format(relatorio.dataAvaliacao)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(relatorio.corStatusGeral.replaceAll('#', '0xFF'))).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${relatorio.emojiStatusGeral} ${relatorio.statusGeral}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(int.parse(relatorio.corStatusGeral.replaceAll('#', '0xFF'))),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Métricas principais
              Row(
                children: [
                  Expanded(
                    child: _buildMetricaCard(
                      'CV%',
                      '${relatorio.coeficienteVariacao.toStringAsFixed(1)}%',
                      relatorio.emojiCV,
                      Color(int.parse(relatorio.corCV.replaceAll('#', '0xFF'))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricaCard(
                      'Singulação',
                      '${relatorio.singulacao.toStringAsFixed(1)}%',
                      relatorio.singulacao >= 95 ? '✅' : '⚠️',
                      Color(int.parse(relatorio.corSingulacao.replaceAll('#', '0xFF'))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricaCard(
                      'Plantas/ha',
                      '${(relatorio.populacaoEstimadaPorHectare / 1000).toStringAsFixed(0)}k',
                      '🌱',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Rodapé do card
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    relatorio.executor,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(relatorio.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricaCard(String titulo, String valor, String emoji, Color cor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  void _abrirRelatorio(PlantingQualityReportModel relatorio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantingQualityReportScreen(
          relatorio: relatorio,
        ),
      ),
    );
  }
}

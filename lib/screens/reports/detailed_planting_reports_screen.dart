import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/plantio_complete_data_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import 'widgets/complete_planting_report_card.dart';

/// 📊 RELATÓRIO DETALHADO DE PLANTIOS - FortSmart Agro
/// 
/// Tela principal para visualização de relatórios completos de cada plantio
/// Similar ao relatório do Novo Estande de Plantas, mas agregando TODOS os dados:
/// - Dados básicos do plantio (talhão, cultura, variedade, data)
/// - População REAL do estande
/// - Eficiência e CV%
/// - Evolução fenológica
/// 
/// FILTROS DISPONÍVEIS:
/// - Por safra
/// - Por cultura
/// - Por talhão
/// - Por período

class DetailedPlantingReportsScreen extends StatefulWidget {
  const DetailedPlantingReportsScreen({Key? key}) : super(key: key);

  @override
  State<DetailedPlantingReportsScreen> createState() => _DetailedPlantingReportsScreenState();
}

class _DetailedPlantingReportsScreenState extends State<DetailedPlantingReportsScreen> {
  final PlantioCompleteDataService _completeDataService = PlantioCompleteDataService();
  
  // Dados
  Map<String, dynamic>? _estatisticas;
  List<Map<String, dynamic>> _plantiosDetalhados = [];
  
  // Filtros
  String? _safraFiltro;
  String? _culturaFiltro;
  String? _talhaoFiltro;
  DateTime? _dataInicioFiltro;
  DateTime? _dataFimFiltro;
  
  // Estado
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('🔄 RELATÓRIOS DETALHADOS: Carregando dados completos...');
      
      final estatisticas = await _completeDataService.gerarEstatisticasAgregadas(
        safraId: _safraFiltro,
        culturaId: _culturaFiltro,
        talhaoId: _talhaoFiltro,
        dataInicio: _dataInicioFiltro,
        dataFim: _dataFimFiltro,
      );
      
      print('📊 Estatísticas carregadas: ${estatisticas['total_plantios']} plantios');
      
      setState(() {
        _estatisticas = estatisticas;
        _plantiosDetalhados = List<Map<String, dynamic>>.from(
          estatisticas['plantios_detalhados'] ?? []
        );
        _isLoading = false;
      });
      
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar dados: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Relatórios Detalhados de Plantio',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando relatórios completos...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar dados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _carregarDados,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_plantiosDetalhados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.agriculture_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Nenhum plantio encontrado',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Não há plantios registrados para os filtros selecionados.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _limparFiltros,
                icon: const Icon(Icons.clear),
                label: const Text('Limpar Filtros'),
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumo geral
          _buildResumoGeral(),
          
          const SizedBox(height: 24),
          
          // Filtros ativos
          if (_temFiltrosAtivos())
            _buildFiltrosAtivos(),
          
          if (_temFiltrosAtivos())
            const SizedBox(height: 16),
          
          // Header da lista
          _buildHeaderLista(),
          
          const SizedBox(height: 16),
          
          // Lista de plantios detalhados
          ..._plantiosDetalhados.map((plantio) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CompletePlantingReportCard(
              plantioData: plantio,
              onTap: () => _abrirRelatorioCompleto(plantio),
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  Widget _buildResumoGeral() {
    if (_estatisticas == null) return const SizedBox.shrink();
    
    final totalPlantios = _estatisticas!['total_plantios'] ?? 0;
    final cobertura = _estatisticas!['cobertura_dados'] as Map<String, dynamic>? ?? {};
    final qualidade = _estatisticas!['qualidade_geral'] as Map<String, dynamic>? ?? {};
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Resumo Geral',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Métricas principais
            Row(
              children: [
                Expanded(
                  child: _buildMetricaSumario(
                    'Total Plantios',
                    totalPlantios.toString(),
                    Icons.agriculture,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricaSumario(
                    'Com Estande',
                    '${cobertura['com_estande'] ?? 0}',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricaSumario(
                    'Qualidade',
                    '${qualidade['score'] ?? 0}%',
                    Icons.star,
                    _getQualidadeColor(qualidade['score'] ?? 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricaSumario(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Color _getQualidadeColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
  
  bool _temFiltrosAtivos() {
    return _safraFiltro != null ||
           _culturaFiltro != null ||
           _talhaoFiltro != null ||
           _dataInicioFiltro != null ||
           _dataFimFiltro != null;
  }
  
  Widget _buildFiltrosAtivos() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_culturaFiltro != null)
                    _buildChipFiltro('Cultura: $_culturaFiltro', () {
                      setState(() => _culturaFiltro = null);
                      _carregarDados();
                    }),
                  if (_safraFiltro != null)
                    _buildChipFiltro('Safra: $_safraFiltro', () {
                      setState(() => _safraFiltro = null);
                      _carregarDados();
                    }),
                  if (_talhaoFiltro != null)
                    _buildChipFiltro('Talhão: $_talhaoFiltro', () {
                      setState(() => _talhaoFiltro = null);
                      _carregarDados();
                    }),
                ],
              ),
            ),
            TextButton(
              onPressed: _limparFiltros,
              child: const Text('Limpar Todos'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChipFiltro(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: Colors.white,
    );
  }
  
  Widget _buildHeaderLista() {
    return Row(
      children: [
        Icon(Icons.list, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          'Plantios Cadastrados (${_plantiosDetalhados.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'Ordenar',
          onSelected: _ordenarPor,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'data_recente', child: Text('Data (Mais Recente)')),
            const PopupMenuItem(value: 'data_antiga', child: Text('Data (Mais Antiga)')),
            const PopupMenuItem(value: 'talhao', child: Text('Talhão')),
            const PopupMenuItem(value: 'cultura', child: Text('Cultura)')),
            const PopupMenuItem(value: 'qualidade', child: Text('Qualidade de Dados')),
          ],
        ),
      ],
    );
  }
  
  void _ordenarPor(String criterio) {
    setState(() {
      switch (criterio) {
        case 'data_recente':
          _plantiosDetalhados.sort((a, b) => 
            DateTime.parse(b['data_plantio']).compareTo(DateTime.parse(a['data_plantio']))
          );
          break;
        case 'data_antiga':
          _plantiosDetalhados.sort((a, b) => 
            DateTime.parse(a['data_plantio']).compareTo(DateTime.parse(b['data_plantio']))
          );
          break;
        case 'talhao':
          _plantiosDetalhados.sort((a, b) => 
            (a['talhao_nome'] as String).compareTo(b['talhao_nome'] as String)
          );
          break;
        case 'cultura':
          _plantiosDetalhados.sort((a, b) => 
            (a['cultura_id'] as String).compareTo(b['cultura_id'] as String)
          );
          break;
        case 'qualidade':
          _plantiosDetalhados.sort((a, b) {
            final qualidadeA = (a['metricas_calculadas'] as Map)['completude_dados_percentual'] ?? 0;
            final qualidadeB = (b['metricas_calculadas'] as Map)['completude_dados_percentual'] ?? 0;
            return (qualidadeB as num).compareTo(qualidadeA as num);
          });
          break;
      }
    });
  }
  
  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) {
        String? culturaTemp = _culturaFiltro;
        String? talhaoTemp = _talhaoFiltro;
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Criar controllers fora do build para manter o foco
          final culturaController = TextEditingController(text: culturaTemp ?? '');
          final talhaoController = TextEditingController(text: talhaoTemp ?? '');
          
          return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Filtros de Plantio'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro de Cultura
                    const Text(
                      'Cultura',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: culturaController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Soja, Milho, Algodão',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.grass),
                        suffixIcon: culturaController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  culturaController.clear();
                                  setStateDialog(() => culturaTemp = null);
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        culturaTemp = value.isEmpty ? null : value;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Filtro de Talhão
                    const Text(
                      'Talhão',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: talhaoController,
                      decoration: InputDecoration(
                        hintText: 'Ex: TH 5A, Pivô 3',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: talhaoController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  talhaoController.clear();
                                  setStateDialog(() => talhaoTemp = null);
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        talhaoTemp = value.isEmpty ? null : value;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Informação sobre filtros avançados
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filtros de safra e período em breve!',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _culturaFiltro = culturaTemp;
                      _talhaoFiltro = talhaoTemp;
                    });
                    Navigator.pop(context);
                    _carregarDados();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _limparFiltros() {
    setState(() {
      _safraFiltro = null;
      _culturaFiltro = null;
      _talhaoFiltro = null;
      _dataInicioFiltro = null;
      _dataFimFiltro = null;
    });
    _carregarDados();
  }
  
  void _abrirRelatorioCompleto(Map<String, dynamic> plantio) {
    // TODO: Navegar para tela de relatório completo individual
    Navigator.pushNamed(
      context,
      '/reports/planting/complete',
      arguments: plantio,
    );
  }
}


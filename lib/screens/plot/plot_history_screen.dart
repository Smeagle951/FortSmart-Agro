import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:printing/printing.dart';
import '../../../services/plot_history_pdf_service.dart';
import 'soil_analysis_import_screen.dart';
import 'plot_record_form_screen.dart';

class PlotHistoryScreen extends StatefulWidget {
  final String? plotId;
  final String? plotName;

  const PlotHistoryScreen({
    Key? key, 
    this.plotId,
    this.plotName,
  }) : super(key: key);

  @override
  State<PlotHistoryScreen> createState() => _PlotHistoryScreenState();
}

class _PlotHistoryScreenState extends State<PlotHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _anoSelecionado = DateTime.now().year;
  List<int> _anosDisponiveis = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  
  // Serviço para geração de PDF
  final PlotHistoryPdfService _pdfService = PlotHistoryPdfService();
  
  // Dados do talhão (simulados por enquanto)
  String _talhaoNome = '';
  List<String> _culturas = ['Soja', 'Milho'];
  
  // Dados de resumo operacional
  List<Map<String, dynamic>> _registrosTalhao = [];
  
  // Dados de análise de solo
  Map<String, dynamic>? _analiseSolo;
  Map<String, dynamic>? _analiseSoloAnterior;
  
  // Dados de produtividade
  Map<String, dynamic>? _produtividadeAtual;
  List<Map<String, dynamic>> _historicoProducao = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _talhaoNome = widget.plotName ?? 'Talhão não identificado';
    _carregarAnos();
    _carregarDados();
  }
  
  void _carregarAnos() {
    // Simular anos disponíveis (normalmente viriam do banco de dados)
    setState(() {
      _anosDisponiveis = [DateTime.now().year, DateTime.now().year - 1, DateTime.now().year - 2];
    });
  }
  
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simular carregamento de dados do banco
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() {
      // Carregar dados simulados para o ano selecionado
      _carregarDadosSimulados();
      _isLoading = false;
    });
  }
  
  void _carregarDadosSimulados() {
    // Dados simulados para 2024
    if (_anoSelecionado == 2024) {
      _registrosTalhao = [
        {
          'data': '2024-03-15',
          'tipo': 'Colheita',
          'descricao': 'Colheita de soja',
          'quantidade': null,
          'unidade': null,
        },
        {
          'data': '2023-11-20',
          'tipo': 'Adubação',
          'descricao': 'Adubação NPK',
          'quantidade': 400,
          'unidade': 'kg de adubo 05-25-15',
        },
        {
          'data': '2023-10-05',
          'tipo': 'Gessagem',
          'descricao': 'Aplicação de gesso',
          'quantidade': 600,
          'unidade': 'kg de gesso',
        },
        {
          'data': '2023-09-20',
          'tipo': 'Calagem',
          'descricao': 'Aplicação de calcário',
          'quantidade': 2500,
          'unidade': 'kg de calcário',
        },
      ];
      
      _analiseSolo = {
        'ph': 6.0,
        'v_porcentagem': 63,
        'fosforo': 10,
        'potassio': 0.25,
      };
      
      _analiseSoloAnterior = {
        'ph': 5.7,
        'v_porcentagem': 58,
        'fosforo': 8,
        'potassio': 0.21,
      };
      
      _produtividadeAtual = {
        'produtividade': 70,
        'unidade': 'sacos/ha',
        'cultura': 'Soja',
      };
      
      _historicoProducao = [
        {'ano': 2024, 'produtividade': 70, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
        {'ano': 2023, 'produtividade': 65, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
        {'ano': 2022, 'produtividade': 62, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
      ];
    } 
    // Dados simulados para 2023
    else if (_anoSelecionado == 2023) {
      _registrosTalhao = [
        {
          'data': '2023-03-20',
          'tipo': 'Colheita',
          'descricao': 'Colheita de soja',
          'quantidade': null,
          'unidade': null,
        },
        {
          'data': '2022-11-15',
          'tipo': 'Adubação',
          'descricao': 'Adubação NPK',
          'quantidade': 350,
          'unidade': 'kg de adubo 04-30-10',
        },
        {
          'data': '2022-10-10',
          'tipo': 'Gessagem',
          'descricao': 'Aplicação de gesso',
          'quantidade': 800,
          'unidade': 'kg de gesso',
        },
        {
          'data': '2022-09-15',
          'tipo': 'Calagem',
          'descricao': 'Aplicação de calcário',
          'quantidade': 2000,
          'unidade': 'kg de calcário',
        },
      ];
      
      _analiseSolo = {
        'ph': 5.7,
        'v_porcentagem': 58,
        'fosforo': 8,
        'potassio': 0.21,
      };
      
      _analiseSoloAnterior = {
        'ph': 5.5,
        'v_porcentagem': 52,
        'fosforo': 6,
        'potassio': 0.18,
      };
      
      _produtividadeAtual = {
        'produtividade': 65,
        'unidade': 'sacos/ha',
        'cultura': 'Soja',
      };
      
      _historicoProducao = [
        {'ano': 2023, 'produtividade': 65, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
        {'ano': 2022, 'produtividade': 62, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
        {'ano': 2021, 'produtividade': 60, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
      ];
    }
    // Dados simulados para 2022
    else {
      _registrosTalhao = [
        {
          'data': '2022-03-25',
          'tipo': 'Colheita',
          'descricao': 'Colheita de soja',
          'quantidade': null,
          'unidade': null,
        },
        {
          'data': '2021-11-10',
          'tipo': 'Adubação',
          'descricao': 'Adubação NPK',
          'quantidade': 300,
          'unidade': 'kg de adubo 04-28-08',
        },
        {
          'data': '2021-10-05',
          'tipo': 'Gessagem',
          'descricao': 'Aplicação de gesso',
          'quantidade': 700,
          'unidade': 'kg de gesso',
        },
        {
          'data': '2021-09-10',
          'tipo': 'Calagem',
          'descricao': 'Aplicação de calcário',
          'quantidade': 1800,
          'unidade': 'kg de calcário',
        },
      ];
      
      _analiseSolo = {
        'ph': 5.5,
        'v_porcentagem': 52,
        'fosforo': 6,
        'potassio': 0.18,
      };
      
      _analiseSoloAnterior = {
        'ph': 5.3,
        'v_porcentagem': 48,
        'fosforo': 5,
        'potassio': 0.15,
      };
      
      _produtividadeAtual = {
        'produtividade': 62,
        'unidade': 'sacos/ha',
        'cultura': 'Soja',
      };
      
      _historicoProducao = [
        {'ano': 2022, 'produtividade': 62, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
        {'ano': 2021, 'produtividade': 60, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
        {'ano': 2020, 'produtividade': 58, 'unidade': 'sacos/ha', 'cultura': 'Soja'},
      ];
    }
  }
  
  void _alterarAno(int novoAno) {
    setState(() {
      _anoSelecionado = novoAno;
    });
    _carregarDados();
  }
  
  // Método para gerar relatório em PDF
  Future<void> _gerarRelatorioPdf(BuildContext context) async {
    setState(() {
      _isGeneratingPdf = true;
    });
    
    // Mostrar mensagem de geração em andamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gerando relatório PDF...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    try {
      // Preparar dados para o relatório
      Map<String, Map<String, dynamic>> mediasInsumos = {
        'Fertilizante': {
          'media': 350,
          'unidade': 'kg/ha',
          'periodo': '2022-2024',
        },
        'Calcário': {
          'media': 2100,
          'unidade': 'kg/ha',
          'periodo': '2022-2024',
        },
        'Gesso': {
          'media': 700,
          'unidade': 'kg/ha',
          'periodo': '2022-2024',
        },
      };
      
      Map<String, Map<String, dynamic>> mediasIndicadoresSolo = {
        'pH': {
          'valor': 5.7,
          'periodo': '2022-2024',
        },
        'V%': {
          'valor': 58,
          'periodo': '2022-2024',
        },
        'Fósforo': {
          'valor': 8,
          'periodo': '2022-2024',
        },
      };
      
      Map<String, double> mediaProdutividadePorCultura = {
        'Soja': 65.7,
        'Milho': 120.0,
      };
      
      // Gerar PDF com os dados carregados
      final pdfBytes = await _pdfService.gerarRelatorioPdf(
        talhaoNome: _talhaoNome,
        ano: _anoSelecionado,
        registros: _registrosTalhao.map((registro) => {
          'data': registro['data'],
          'tipo_registro': registro['tipo'],
          'descricao': registro['descricao'],
          'quantidade': registro['quantidade'],
          'unidade': registro['unidade'],
        }).toList(),
        analiseSolo: _analiseSolo,
        analiseSoloAnterior: _analiseSoloAnterior,
        produtividade: _produtividadeAtual != null ? {
          'produtividade': _produtividadeAtual!['produtividade'],
          'unidade': _produtividadeAtual!['unidade'],
          'cultura_id': _produtividadeAtual!['cultura'],
          'data_colheita': DateTime.now().toString(),
        } : null,
        historicoProducao: _historicoProducao.map((producao) => {
          'produtividade': producao['produtividade'],
          'unidade': producao['unidade'],
          'cultura_id': producao['cultura'],
          'data_colheita': '${producao['ano']}-03-15',
        }).toList(),
        mediasInsumos: mediasInsumos,
        mediasIndicadoresSolo: mediasIndicadoresSolo,
        mediaProdutividadePorCultura: mediaProdutividadePorCultura,
      );
      
      // Salvar e abrir o PDF
      await _pdfService.salvarEAbrirPdf(
        pdfBytes,
        _talhaoNome,
        _anoSelecionado,
      );
      
      // Exibir mensagem de sucesso
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relatório PDF gerado com sucesso!'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
          action: SnackBarAction(
            label: 'VISUALIZAR',
            textColor: Colors.white,
            onPressed: () async {
              // await Printing.sharePdf(
              //   bytes: pdfBytes,
              //   filename: 'Historico_${_talhaoNome.replaceAll(' ', '_')}_$_anoSelecionado.pdf',
              // );
            },
          ),
        ),
      );
    } catch (e) {
      // Exibir mensagem de erro
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      // Finalizar processo de geração
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico: $_talhaoNome'),
        // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPdf ? null : () => _gerarRelatorioPdf(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF228B22)))
          : Column(
              children: [
                // Cabeçalho com informações do talhão
                _buildHeader(),
                
                // TabBar
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF228B22),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF228B22),
                  tabs: const [
                    Tab(text: 'Resumo Operacional'),
                    Tab(text: 'Análise Técnica'),
                    Tab(text: 'Produtividade'),
                    Tab(text: 'Indicadores'),
                  ],
                ),
                
                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildResumoOperacional(),
                      _buildAnaliseTecnica(),
                      _buildProdutividade(),
                      _buildIndicadores(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar para a tela de adicionar novo registro
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlotRecordFormScreen(
                plotId: widget.plotId,
                plotName: _talhaoNome,
              ),
            ),
          ).then((value) {
            // Recarregar os dados quando retornar da tela de formulário
            if (value == true) {
              _carregarDados();
            }
          });
        },
        // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _talhaoNome,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _culturas.join(' · '),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _mostrarSeletorAno(context);
                }, // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$_anoSelecionado',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _mostrarSeletorAno(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _anosDisponiveis.length,
          itemBuilder: (context, index) {
            final ano = _anosDisponiveis[index];
            return ListTile(
              title: Text(
                '$ano',
                style: TextStyle(
                  fontWeight: ano == _anoSelecionado
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: ano == _anoSelecionado
                      ? const Color(0xFF228B22)
                      : Colors.black,
                ),
              ),
              leading: ano == _anoSelecionado
                  ? const Icon(
                      Icons.check_circle,
                      color: Color(0xFF228B22),
                    )
                  : const Icon(
                      Icons.circle_outlined,
                      color: Colors.grey,
                    ),
              onTap: () {
                Navigator.pop(context);
                _alterarAno(ano);
              }, // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
            );
          },
        );
      },
    );
  }
  
  Widget _buildResumoOperacional() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registrosTalhao.length,
      itemBuilder: (context, index) {
        final registro = _registrosTalhao[index];
        final data = DateTime.parse(registro['data']);
        final dataFormatada = DateFormat('dd \'de\' MMMM').format(data);
        
        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                dataFormatada,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                registro['tipo'],
                style: const TextStyle(
                  color: Color(0xFF228B22),
                ),
              ),
              trailing: registro['quantidade'] != null
                  ? Text(
                      '${registro['quantidade']} ${registro['unidade']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const Divider(),
          ],
        );
      },
    );
  }
  
  Widget _buildAnaliseTecnica() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Análise de Solo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirImportacaoAnaliseSolo(),
                icon: const Icon(Icons.upload_file),
                label: const Text('Importar'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tabela de análise
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${_anoSelecionado - 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '$_anoSelecionado',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF228B22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildLinhaAnalise('pH', 
                    _analiseSoloAnterior?['ph']?.toString() ?? '-', 
                    _analiseSolo?['ph']?.toString() ?? '-'),
                  _buildLinhaAnalise('V%', 
                    _analiseSoloAnterior != null ? '${_analiseSoloAnterior!['v_porcentagem']}%' : '-', 
                    _analiseSolo != null ? '${_analiseSolo!['v_porcentagem']}%' : '-'),
                  _buildLinhaAnalise('P', 
                    _analiseSoloAnterior?['fosforo']?.toString() ?? '-', 
                    _analiseSolo?['fosforo']?.toString() ?? '-'),
                  _buildLinhaAnalise('K', 
                    _analiseSoloAnterior?['potassio']?.toString() ?? '-', 
                    _analiseSolo?['potassio']?.toString() ?? '-'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Gráfico (simulado)
          const Text(
            'Evolução dos Indicadores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Gráfico de evolução dos indicadores'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLinhaAnalise(String label, String valorAnterior, String valorAtual) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              valorAnterior,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              valorAtual,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF228B22),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProdutividade() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produção',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_produtividadeAtual?['produtividade']} ${_produtividadeAtual?['unidade']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF228B22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Média por Talhão',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Média:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '65 sacos/ha',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Comparativo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+5 sacos/ha em relação a ${_anoSelecionado - 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Histórico de produção
          const Text(
            'Histórico de Produção',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _historicoProducao.length,
            itemBuilder: (context, index) {
              final producao = _historicoProducao[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    '${producao['ano']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${producao['cultura']}',
                  ),
                  trailing: Text(
                    '${producao['produtividade']} ${producao['unidade']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: producao['ano'] == _anoSelecionado
                          ? const Color(0xFF228B22)
                          : Colors.grey[800],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicadores() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Média de Consumo de Insumos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCardIndicador('Calcário', '2.100 kg/ano', 'Últimos 3 anos'),
          _buildCardIndicador('Gesso', '700 kg/ano', 'Últimos 3 anos'),
          _buildCardIndicador('Adubo Base', '350 kg/ano', 'Últimos 3 anos'),
          
          const SizedBox(height: 24),
          
          const Text(
            'Média de Produtividade por Cultura',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCardIndicador('Soja', '65 sacos/ha', 'Últimos 3 anos'),
          _buildCardIndicador('Milho', '150 sacos/ha', 'Últimos 2 anos'),
          
          const SizedBox(height: 24),
          
          const Text(
            'Média dos Indicadores de Solo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCardIndicador('pH Médio', '5.8', 'Últimos 3 anos'),
          _buildCardIndicador('V% Médio', '58%', 'Últimos 3 anos'),
          _buildCardIndicador('Fósforo Médio', '8.0', 'Últimos 3 anos'),
        ],
      ),
    );
  }
  
  Widget _buildCardIndicador(String titulo, String valor, String periodo) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    periodo,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF228B22),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Método para abrir a tela de importação de análise de solo
  void _abrirImportacaoAnaliseSolo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SoilAnalysisImportScreen(
          talhaoId: widget.plotId ?? '',
          talhaoNome: _talhaoNome,
          onAnalysisImported: (analiseSolo) {
            // Atualizar os dados quando uma nova análise for importada
            setState(() {
              _analiseSolo = analiseSolo;
              // Mover a análise anterior para histórico
              if (_analiseSolo != null) {
                _analiseSoloAnterior = _analiseSolo;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

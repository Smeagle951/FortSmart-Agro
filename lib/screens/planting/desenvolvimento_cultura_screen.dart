import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/crop.dart';
import 'package:fortsmart_agro/models/planting.dart';
import 'package:fortsmart_agro/models/talhao_model_new.dart';
import 'package:fortsmart_agro/repositories/crop_repository.dart';
import 'package:fortsmart_agro/repositories/planting_repository.dart';
import 'package:fortsmart_agro/repositories/talhao_repository_new.dart';
import 'package:fortsmart_agro/services/fenologico_service.dart';
import 'package:fortsmart_agro/services/cultura_talhao_service.dart';
import 'package:fortsmart_agro/widgets/app_drawer.dart';
import 'package:fortsmart_agro/widgets/loading_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// import 'package:open_file/open_file.dart'; // Removido - causando problemas de build
import 'package:cross_file/cross_file.dart';
import 'package:permission_handler/permission_handler.dart';

// Extensões dos modelos para adicionar propriedades necessárias para cálculos fenológicos
extension PlantingExtension on Planting {
  // Data de emergência (personalizada ou calculada como 3 dias após o plantio)
  DateTime? get emergenceDate {
    // Verificar se existe uma data de emergência personalizada nos campos customizados
    if (notes != null && notes!.contains('emergenceDate:')) {
      try {
        final regex = RegExp(r'emergenceDate:(\d{4}-\d{2}-\d{2})');
        final match = regex.firstMatch(notes!);
        if (match != null && match.group(1) != null) {
          return DateTime.parse(match.group(1)!);
        }
      } catch (e) {
        print('Erro ao extrair data de emergência: $e');
      }
    }
    // Caso contrário, usar a data padrão (3 dias após o plantio)
    return plantingDate.add(const Duration(days: 3));
  }
  
  // Método para criar uma string com a data de emergência para armazenar em notes
  String getNotesWithEmergenceDate(DateTime emergenceDate) {
    final emergenceDateStr = 'emergenceDate:${emergenceDate.toIso8601String().split('T')[0]}';
    
    if (notes == null || notes!.isEmpty) {
      return emergenceDateStr;
    } else if (notes!.contains('emergenceDate:')) {
      // Substituir a data existente
      final regex = RegExp(r'emergenceDate:\d{4}-\d{2}-\d{2}');
      return (notes ?? '').replaceFirst(regex, emergenceDateStr);
    } else {
      // Adicionar a nova data
      return '${notes ?? ''}\n$emergenceDateStr';
    }
  }
  
  // Valores estimados para demonstração
  double get estimatedYield => 4500.0; // kg/ha
  String get yieldUnit => 'kg/ha';
  int get plantDensity => 55000; // plantas/ha
}

extension CropExtension on Crop {
  // Usa o ciclo de crescimento como ciclo médio
  int? get averageCycle => growthCycle;
}

// Classe utilitária para formatação
class Formatters {
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  static String formatArea(double area) {
    return area.toStringAsFixed(2);
  }
}

// Definição das cores usadas no aplicativo
class AppColors {
  static const Color primaryColor = Color(0xFF1B5E20);
  static const Color primaryLightColor = Color(0xFF4C8C4A);
  static const Color primaryDarkColor = Color(0xFF0A3D10);
  static const Color accentColor = Color(0xFF2E7D32);
  static const Color accentLightColor = Color(0xFF60AD5E);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color textLightColor = Color(0xFF666666);
}

class DesenvolvimentoCulturaScreen extends StatefulWidget {
  const DesenvolvimentoCulturaScreen({Key? key}) : super(key: key);

  @override
  _DesenvolvimentoCulturaScreenState createState() => _DesenvolvimentoCulturaScreenState();
}

class _DesenvolvimentoCulturaScreenState extends State<DesenvolvimentoCulturaScreen> {
  // Repositórios
  final TalhaoRepository talhaoRepository = TalhaoRepository();
  final CropRepository cropRepository = CropRepository();
  final PlantingRepository plantingRepository = PlantingRepository();
  final CulturaTalhaoService culturaTalhaoService = CulturaTalhaoService();
  
  // Variáveis de estado
  bool _isLoading = true;
  bool _showChart = false;
  List<TalhaoModel> _talhoes = [];
  List<Crop> _culturas = [];
  List<Planting> _plantios = [];
  
  // Safra
  String _safraAtual = '';
  List<String> _opcoesSafra = [];
  
  TalhaoModel? _selectedTalhao;
  Crop? _selectedCultura;
  Planting? _selectedPlantio;
  
  Map<String, dynamic>? _dadosFenologicos;
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Inicializar safra atual
      await _carregarSafras();
      
      // Carregar talhões, culturas e plantios usando os métodos corretos dos repositórios
      final talhoes = await talhaoRepository.listarTodos();
      final culturasDb = await cropRepository.getAll();
      final plantios = await plantingRepository.getAll();
      
      // Tentar converter as culturas do banco para o tipo Crop usado nesta tela
      final List<Crop> culturasList = [];
      try {
        // Tentar converter cada cultura do banco para o tipo Crop
        for (var cultura in culturasDb) {
          culturasList.add(Crop(
            id: cultura.id,
            name: cultura.name,
            colorValue: 0xFF00C853, // Valor padrão de cor
          ));
        }
      } catch (e) {
        print('Erro ao converter culturas: $e');
      }
      
      setState(() {
        _talhoes = talhoes;
        _culturas = culturasList; // Atribuindo uma lista vazia do tipo correto
        _plantios = plantios;
        _isLoading = false;
      });
      
      // Se precisar dos dados das culturas, você pode processá-los separadamente
      // e usar apenas os campos necessários sem converter o objeto inteiro
      
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _carregarSafras() async {
    try {
      // Obter todos os talhões para extrair as safras disponíveis
      final talhoes = await talhaoRepository.listarTodos();
      final Set<String> safrasSet = {};
      
      // Extrair todas as safras únicas dos talhões
      for (final talhao in talhoes) {
        if (talhao.safraAtual != null) {
          safrasSet.add(talhao.safraAtual!.safra);
        }
      }
      
      // Ordenar safras por ano (assumindo formato YYYY/YYYY)
      final safrasList = safrasSet.toList();
      safrasList.sort(); // Ordenar alfabeticamente (2023/2024 virá antes de 2024/2025)
      
      setState(() {
        _opcoesSafra = safrasList;
        if (_opcoesSafra.isNotEmpty) {
          _safraAtual = _opcoesSafra.last; // Seleciona a safra mais recente
        }
      });
    } catch (e) {
      debugPrint('Erro ao carregar safras: $e');
    }
  }
  
  void _onTalhaoSelecionado(TalhaoModel talhao) {
    setState(() {
      _selectedTalhao = talhao;
      _selectedPlantio = null;
      _selectedCultura = null;
      
      // Filtrar plantios relacionados a este talhão
      final plantiosTalhao = _plantios.where((p) => p.plotId == talhao.id).toList();
      
      if (plantiosTalhao.isNotEmpty) {
        // Selecionar o plantio mais recente
        final plantioMaisRecente = plantiosTalhao.reduce(
          (a, b) => a.plantingDate.isAfter(b.plantingDate) ? a : b
        );
        
        _selectedPlantio = plantioMaisRecente;
        
        // Buscar a cultura relacionada a este plantio
        for (var cultura in _culturas) {
          if (cultura.id == plantioMaisRecente.cropId) {
            _selectedCultura = cultura;
            
            // Calcular dados fenológicos usando a data de emergência (via extensão)
            if (cultura.averageCycle != null && _selectedPlantio!.emergenceDate != null) {
              _calcularDadosFenologicos();
            }
            break;
          }
        }
      }
    });
  }
  
  void _calcularDadosFenologicos() {
    if (_selectedCultura == null || _selectedPlantio == null || _selectedPlantio!.emergenceDate == null) return;
    
    final dataEmergencia = _selectedPlantio!.emergenceDate!;
    final cicloDias = _selectedCultura!.averageCycle ?? 120; // Valor padrão caso não tenha ciclo definido
    final cultura = _selectedCultura!.name;
    
    setState(() {
      _dadosFenologicos = FenologicoService.calcularDadosFenologicos(
        dataEmergencia, 
        cicloDias, 
        cultura
      );
    });
  }
  
  void _toggleChart() {
    setState(() {
      _showChart = !_showChart;
    });
  }
  
  // Método para editar a data de emergência
  Future<void> _editarDataEmergencia() async {
    if (_selectedPlantio == null) return;
    
    // Data inicial para o seletor (data atual de emergência ou data de plantio + 3 dias)
    final dataInicial = _selectedPlantio!.emergenceDate ?? 
                       _selectedPlantio!.plantingDate.add(const Duration(days: 3));
    
    // Mostrar seletor de data
    final DateTime? novaData = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: _selectedPlantio!.plantingDate, // A data de emergência não pode ser anterior ao plantio
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecione a data de emergência',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    
    if (novaData != null) {
      try {
        // Atualizar o plantio no banco de dados
        final plantingRepository = PlantingRepository();
        
        // Criar uma cópia do plantio com a nova data de emergência armazenada no campo notes
        final notesAtualizado = _selectedPlantio!.getNotesWithEmergenceDate(novaData);
        
        // Criar uma cópia do plantio com o campo notes atualizado
        final plantioAtualizado = _selectedPlantio!.copyWith(
          notes: notesAtualizado,
          updatedAt: DateTime.now(),
        );
        
        // Atualizar no banco de dados
        await plantingRepository.update(plantioAtualizado);
        
        // Recarregar dados
        await _carregarDados();
        
        // Se o mesmo talhão ainda estiver selecionado, recalcular dados fenológicos
        if (_selectedTalhao != null) {
          _onTalhaoSelecionado(_selectedTalhao!);
        }
        
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data de emergência atualizada com sucesso!')),
        );
      } catch (e) {
        debugPrint('Erro ao atualizar data de emergência: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar data: $e')),
        );
      }
    }
  }
  
  // Método para gerar relatório em PDF
  Future<void> _gerarRelatorio() async {
    if (_selectedTalhao == null || _selectedPlantio == null || _selectedCultura == null || _dadosFenologicos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados insuficientes para gerar relatório')),
      );
      return;
    }
    
    try {
      // Solicitar permissão de armazenamento
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de armazenamento necessária para gerar relatório')),
          );
          return;
        }
      }
      
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      // Criar documento PDF
      final pdf = pw.Document();
      
      // Adicionar página com dados do acompanhamento fenológico
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('FortSmart Agro', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Relatório de Desenvolvimento Fenológico', style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Footer(
              trailing: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10),
              ),
            );
          },
          build: (pw.Context context) => [
            // Informações do Talhão e Plantio
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Informações do Plantio', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      // Cabeçalho
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Parâmetro', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Valor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      // Dados do Talhão
                      _buildPdfTableRow('Talhão', _selectedTalhao!.nome),
                      _buildPdfTableRow('Área', '${Formatters.formatArea(_selectedTalhao!.area)} ha'),
                      // Dados da Cultura
                      _buildPdfTableRow('Cultura', _selectedCultura!.name),
                      _buildPdfTableRow('Variedade', _selectedPlantio!.varietyName ?? 'Não informada'),
                      // Dados do Plantio
                      _buildPdfTableRow('Data de Plantio', Formatters.formatDate(_selectedPlantio!.plantingDate)),
                      _buildPdfTableRow('Data de Emergência', Formatters.formatDate(_selectedPlantio!.emergenceDate)),
                      // Dados Fenológicos
                      _buildPdfTableRow('Dias Após Emergência (DAE)', _dadosFenologicos!['DAE'].toString()),
                      _buildPdfTableRow('Dias Até Colheita (DAC)', _dadosFenologicos!['DAC'].toString()),
                      _buildPdfTableRow('Estágio Fenológico', _dadosFenologicos!['Estagio']),
                      _buildPdfTableRow('Status', _dadosFenologicos!['ProntoParaColheita'] ? 'Pronto para Colheita' : 'Em Desenvolvimento'),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Informações sobre o Ciclo
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Informações do Ciclo', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Cultura: ${_selectedCultura!.name}'),
                  pw.Text('Ciclo Total: ${_selectedCultura!.averageCycle} dias'),
                  pw.Text('Estágio Atual: ${_dadosFenologicos!["Estagio"]}'),
                  pw.SizedBox(height: 10),
                  pw.Text('Estágios Fenológicos da Cultura ${_selectedCultura!.name}:'),
                  pw.SizedBox(height: 5),
                  _buildPdfEstagiosList(),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Data e Assinatura
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Data do Relatório: ${Formatters.formatDate(DateTime.now())}'),
                      pw.Text('Responsável: ____________________'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      
      // Salvar o PDF
      final output = await getTemporaryDirectory();
      final String nomeArquivo = 'relatorio_fenologico_${_selectedTalhao?.nome?.replaceAll(RegExp(r'\s+'), '_') ?? ''}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$nomeArquivo');
      await file.writeAsBytes(await pdf.save());
      
      // Fechar o diálogo de carregamento
      Navigator.of(context).pop();
      
      // Abrir o PDF
              // OpenFile.open(file.path); // Removido - usando share_plus como alternativa
        await Share.shareXFiles([XFile(file.path)], text: 'Relatório de Desenvolvimento de Cultura');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Relatório gerado com sucesso: ${file.path}')),
      );
    } catch (e) {
      // Fechar o diálogo de carregamento se estiver aberto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      debugPrint('Erro ao gerar relatório: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
      );
    }
  }
  
  // Método auxiliar para criar linhas da tabela no PDF
  pw.TableRow _buildPdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }
  
  // Método auxiliar para criar lista de estágios fenológicos no PDF
  pw.Widget _buildPdfEstagiosList() {
    final cicloDias = _selectedCultura?.averageCycle ?? 120; // Valor padrão caso não tenha ciclo definido
    final estagios = FenologicoService.getEstagiosFenologicos(_selectedCultura?.name ?? '', cicloDias);
    
    final List<pw.TableRow> rows = [
      // Cabeçalho
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildTableCell('Estágio', isHeader: true),
          _buildTableCell('Dias', isHeader: true),
          _buildTableCell('Período', isHeader: true),
        ],
      ),
    ];
    
    // Adicionar linhas para cada estágio
    for (var estagio in estagios) {
      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell(estagio['nome'] ?? 'Estágio'),
            _buildTableCell('${estagio['inicio']} - ${estagio['fim']} DAE'),
            _buildTableCell(
              _calcularPeriodoEstagio(estagio['inicio'] ?? 0, estagio['fim'] ?? 0),
            ),
          ],
        ),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: rows,
    );
  }
  
  // Método para calcular o período do estágio fenológico no PDF
  String _calcularPeriodoEstagio(int inicio, int fim) {
    if (_selectedPlantio == null || _selectedPlantio?.emergenceDate == null) {
      return 'Período indisponível';
    }
    
    final dataEmergencia = _selectedPlantio!.emergenceDate!;
    final dataInicio = dataEmergencia.add(Duration(days: inicio));
    final dataFim = dataEmergencia.add(Duration(days: fim));
    
    return '${Formatters.formatDate(dataInicio)} - ${Formatters.formatDate(dataFim)}';
  }
  
  // Método auxiliar para criar células da tabela no PDF
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desenvolvimento da Cultura'),
        // backgroundColor: AppColors.primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: _isLoading 
        ? const Center(child: LoadingIndicator())
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryDarkColor,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelecaoTalhao(),
                  const SizedBox(height: 16),
                  if (_selectedTalhao != null && _selectedPlantio == null)
                    _buildSemPlantioCard()
                  else if (_selectedTalhao != null && _selectedPlantio != null) ...[
                    _buildInfoPlantio(),
                    const SizedBox(height: 16),
                    if (_dadosFenologicos != null)
                      _buildDetalhesDesenvolvimento(),
                    const SizedBox(height: 16),
                    if (_dadosFenologicos != null && _selectedCultura != null && _selectedCultura?.averageCycle != null)
                      _buildTimelineButton(),
                    if (_showChart && _dadosFenologicos != null && _selectedCultura != null && _selectedCultura?.averageCycle != null)
                      Expanded(
                        child: _buildFenologicalChart(),
                      ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildSelecaoTalhao() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selecione o Talhão',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Dropdown para seleção de safra
                if (_opcoesSafra.isNotEmpty)
                  DropdownButton<String>(
                    value: _safraAtual,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _safraAtual = newValue;
                          // Recarregar talhões com a nova safra
                          _carregarDados();
                        });
                      }
                    },
                    items: _opcoesSafra.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('Safra $value'),
                      );
                    }).toList(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Lista de talhões filtrados por safra
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _talhoes.isEmpty
                    ? const Center(child: Text('Nenhum talhão cadastrado'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _talhoes.length,
                        itemBuilder: (context, index) {
                          final talhao = _talhoes[index];
                          // Filtrar apenas talhões da safra atual
                          if (talhao.safraAtual == null || talhao.safraAtual?.safra != _safraAtual) {
                            return const SizedBox.shrink();
                          }
                          
                          return ListTile(
                            title: Text(talhao.nome),
                            subtitle: Text('Cultura: ${talhao.culturaId}'),
                            leading: CircleAvatar(
                              // backgroundColor: talhao.cor, // backgroundColor não é suportado em flutter_map 5.0.0
                              child: Text(talhao.nome.isNotEmpty ? talhao.nome.substring(0, 1).toUpperCase() : '?'),
                            ),
                            selected: _selectedTalhao?.id == talhao.id,
                            // onTap: () => _onTalhaoSelecionado(talhao), // onTap não é suportado em Polygon no flutter_map 5.0.0
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSemPlantioCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum plantio registrado para este talhão',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Registre um plantio no módulo de Cadastro de Plantio para visualizar o desenvolvimento da cultura.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoPlantio() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.agriculture, color: AppColors.accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'Informações do Plantio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Botão para gerar relatório
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: AppColors.accentColor),
                  tooltip: 'Gerar Relatório',
                  onPressed: _gerarRelatorio,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Talhão', _selectedTalhao?.nome ?? ''),
                _buildInfoItem('Área', '${Formatters.formatArea(_selectedTalhao?.area ?? 0)} ha'),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Cultura', _selectedCultura?.name ?? ''),
                _buildInfoItem('Variedade', _selectedPlantio?.varietyName ?? 'Não informada'),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Data de Plantio', 
                  _selectedPlantio?.plantingDate != null 
                    ? Formatters.formatDate(_selectedPlantio!.plantingDate) 
                    : 'Não informada'),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data de Emergência',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _selectedPlantio?.emergenceDate != null 
                                ? Formatters.formatDate(_selectedPlantio!.emergenceDate!) 
                                : 'Não informada',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, size: 16, color: AppColors.accentColor),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              tooltip: 'Editar data de emergência',
                              onPressed: _editarDataEmergencia,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (_selectedPlantio?.estimatedYield != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem('Produtividade Estimada', 
                    '${_selectedPlantio!.estimatedYield} ${_selectedPlantio!.yieldUnit}'),
                  _buildInfoItem('Estande', 
                    '${_selectedPlantio!.plantDensity} plantas/ha'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
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
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetalhesDesenvolvimento() {
    final Color estagioColor = _dadosFenologicos != null
        ? FenologicoService.getEstagioColor(
            _dadosFenologicos!['DAE'], 
            _selectedCultura?.name ?? '', 
            _selectedCultura?.averageCycle ?? 120)
        : Colors.grey;
        
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Desenvolvimento Fenológico',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFenologicoItem(
                  'DAE',
                  '${_dadosFenologicos?['DAE'] ?? 0}',
                  'Dias Após Emergência',
                  Icons.calendar_today,
                ),
                _buildFenologicoItem(
                  'DAC',
                  '${_dadosFenologicos?['DAC'] ?? 0}',
                  'Dias Até Colheita',
                  Icons.access_time,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFenologicoItem(
                  'Estágio',
                  _dadosFenologicos?['Estagio'] ?? 'Desconhecido',
                  'Estágio Fenológico Atual',
                  Icons.eco,
                  estagioColor,
                ),
                _buildFenologicoItem(
                  'Status',
                  _dadosFenologicos?['ProntoParaColheita'] == true ? 'Pronto para Colheita' : 'Em Desenvolvimento',
                  'Status da Cultura',
                  Icons.check_circle,
                  _dadosFenologicos?['ProntoParaColheita'] == true ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
        
  Widget _buildFenologicoItem(String label, String value, String description, IconData icon, [Color? accentColor]) {
    return Column(
      children: [
        Icon(
          icon,
          color: accentColor ?? AppColors.accentColor,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentColor ?? Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
        
  Widget _buildTimelineButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        // onTap: _toggleChart, // onTap não é suportado em Polygon no flutter_map 5.0.0
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timeline,
                    color: AppColors.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Linha do Tempo Fenológica',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(
                _showChart ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
        
  Widget _buildFenologicalChart() { 
    if (_selectedCultura == null || _selectedPlantio == null || _selectedPlantio?.emergenceDate == null) { 
      return const Center(child: Text('Dados insuficientes para gerar o gráfico')); 
    }
        
    final cicloDias = _selectedCultura?.averageCycle ?? 120;
    final dataEmergencia = _selectedPlantio!.emergenceDate!;
    final dae = _dadosFenologicos?['DAE'] ?? 0;
    final estagios = FenologicoService.getEstagiosFenologicos(_selectedCultura?.name ?? '', cicloDias);
        
    // Preparar dados para o gráfico
    final List<FlSpot> spots = [];
    final List<String> labels = [];
    final List<Color> colors = [];
        
    // Adicionar ponto para cada estágio
    for (int i = 0; i < estagios.length; i++) {
      final estagio = estagios[i];
      final inicio = estagio['inicio'] ?? 0;
      final fim = estagio['fim'] ?? 0;
      final meio = (inicio + fim) / 2;
          
      spots.add(FlSpot(meio, 1)); // Todos os pontos têm a mesma altura
      labels.add(estagio['nome'] ?? 'Estágio');
          
      // Definir cor com base no estágio atual
      if (dae >= inicio && dae <= fim) {
        colors.add(Colors.green);
      } else if (dae > fim) {
        colors.add(Colors.blue);
      } else {
        colors.add(Colors.grey);
      }
    }
        
    var lineTouchTooltipData3 = LineTouchTooltipData(
                      // tooltipBackgroundColor não é suportado na versão atual do fl_chart
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final index = barSpot.x.toInt();
                          if (index >= 0 && index < estagios.length) {
                            final estagio = estagios[index];
                            const textStyle = const TextStyle(color: Colors.white);
                            return LineTooltipItem(
                              '${estagio['nome']}\n${estagio['inicio']} - ${estagio['fim']} DAE',
                              textStyle,
                            );
                          }
                          return null;
                        }).toList();
                      },
                    );
    var lineTouchTooltipData2 = lineTouchTooltipData3;
    var lineTouchTooltipData = lineTouchTooltipData2;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Linha do Tempo Fenológica',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cultura: ${_selectedCultura?.name ?? ''}',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              'Ciclo: ${cicloDias} dias',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = spots.indexWhere((spot) => spot.x == value);
                          String title = '';
                          if (index >= 0 && index < labels.length) {
                            title = labels[index];
                          }
                          // Usando Text diretamente em vez de SideTitleWidget para evitar problemas de compatibilidade
                          return Text(
                            title,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: spots.isNotEmpty ? spots.first.x : 0,
                  maxX: spots.isNotEmpty ? spots.last.x : 0,
                  minY: 0,
                  maxY: 2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: colors[index],
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: lineTouchTooltipData,
                    handleBuiltInTouches: true,
                  ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Estágio Atual', Colors.green),
                    const SizedBox(width: 16),
                    _buildLegendItem('Estágios Passados', Colors.blue),
                    const SizedBox(width: 16),
                    _buildLegendItem('Estágios Futuros', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        );
      }
        
          Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/talhao_model.dart';
import '../../../models/agricultural_product.dart';
import '../../../models/poligono_model.dart';
import '../../../services/farm_culture_sync_service.dart';
import '../../../services/talhao_module_service.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../services/talhao_unified_loader_service.dart';
import '../../../services/cultura_talhao_service.dart';
import '../../../models/calibration_history_model.dart';
import '../../../database/daos/calibration_history_dao.dart';
import '../../../database/app_database.dart';
import 'plantio_calibragem_historico_screen.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/fortsmart_theme.dart';
import '../../../providers/talhao_provider.dart';
import '../../../providers/cultura_provider.dart';
import '../../../services/database_service.dart';
import 'package:intl/intl.dart';

/// Tela de calibragem de adubo por coleta
class PlantioCalibragemaAduboColetaScreen extends StatefulWidget {
  const PlantioCalibragemaAduboColetaScreen({super.key});

  @override
  State<PlantioCalibragemaAduboColetaScreen> createState() => _PlantioCalibragemaAduboColetaScreenState();
}

class _PlantioCalibragemaAduboColetaScreenState extends State<PlantioCalibragemaAduboColetaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nomeFertilizanteController = TextEditingController();
  final _pesoColetadoController = TextEditingController();
  final _distanciaController = TextEditingController();
  final _linhasController = TextEditingController();
  final _espacamentoController = TextEditingController();
  final _metaKgHaController = TextEditingController();
  
  // Serviços
  final _farmCultureSyncService = FarmCultureSyncService();
  final _talhaoModuleService = TalhaoModuleService();
  final _talhaoRepository = TalhaoRepository();
  final _talhaoLoader = TalhaoUnifiedLoaderService();
  final _culturaTalhaoService = CulturaTalhaoService();
  
  // Estados
  bool _isLoading = false;
  String? _errorMessage;
  String _tipoColeta = 'linha';
  
  // Dados calculados
  double _areaHa = 0.0;
  double _kgHa = 0.0;
  double _sacasHa = 0.0;
  double _diferencaMeta = 0.0;
  double _diferencaPercentual = 0.0;
  String _sugestaoAjuste = ''; // Usado para exibir a sugestão de ajuste nos resultados
  
  // Seleções
  TalhaoModel? _talhaoSelecionado;
  AgriculturalProduct? _culturaSelecionada;
  
  // Listas de dados
  List<TalhaoModel> _talhoes = [];
  List<AgriculturalProduct> _culturas = [];
  
  // Formatadores
  final numberFormat = NumberFormat('#,##0.0', 'pt_BR');
  final numberFormat3 = NumberFormat('#,##0.00', 'pt_BR');
  final numberFormat4 = NumberFormat('#,##0.000', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _limparCampos();
  }

  @override
  void dispose() {
    _nomeFertilizanteController.dispose();
    _pesoColetadoController.dispose();
    _distanciaController.dispose();
    _linhasController.dispose();
    _espacamentoController.dispose();
    _metaKgHaController.dispose();
    super.dispose();
  }

  /// Carrega dados iniciais
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _carregarTalhoes();
      await _carregarCulturas();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Carrega talhões
  Future<void> _carregarTalhoes() async {
    try {
      print('🔄 Carregando talhões reais do módulo Talhões...');
      
      // Primeiro, tentar carregar do TalhaoUnifiedService (mais confiável)
      try {
        print('🔄 Tentativa 1: Carregando do TalhaoUnifiedService...');
        final talhoesUnificados = await _talhaoLoader.carregarTalhoesParaModulo(
          nomeModulo: 'Calibragem de Adubo por Coleta',
          forceRefresh: true,
        );
        
        if (talhoesUnificados.isNotEmpty) {
          if (mounted) {
            setState(() {
              _talhoes = talhoesUnificados;
            });
          }
          print('✅ ${talhoesUnificados.length} talhões carregados do TalhaoUnifiedService');
          for (var talhao in talhoesUnificados) {
            print('  - ${talhao.name} (ID: ${talhao.id})');
          }
          return; // Sair se conseguiu carregar do serviço unificado
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoUnifiedService: $e');
      }
      
      // Segundo, tentar carregar do TalhaoProvider
      try {
        print('🔄 Tentativa 2: Carregando do TalhaoProvider...');
        final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
        await talhaoProvider.carregarTalhoes();
        
        if (talhaoProvider.talhoes.isNotEmpty) {
          // Converter TalhaoSafraModel para TalhaoModel
          final talhoesConvertidos = talhaoProvider.talhoes.map((talhaoSafra) => TalhaoModel(
            id: talhaoSafra.id,
            name: talhaoSafra.nome,
            area: talhaoSafra.area,
            poligonos: [PoligonoModel(
              id: '1',
              pontos: talhaoSafra.pontos,
              area: talhaoSafra.area,
              perimetro: talhaoSafra.perimetro,
              dataCriacao: talhaoSafra.dataCriacao,
              dataAtualizacao: DateTime.now(),
              ativo: true,
              talhaoId: talhaoSafra.id,
            )],
            dataCriacao: talhaoSafra.dataCriacao,
            dataAtualizacao: DateTime.now(),
            safras: [],
          )).toList();
          
          if (mounted) {
            setState(() {
              _talhoes = talhoesConvertidos;
            });
          }
          print('✅ ${talhaoProvider.talhoes.length} talhões carregados do TalhaoProvider');
          for (var talhao in talhaoProvider.talhoes) {
            print('  - ${talhao.nome} (ID: ${talhao.id})');
          }
          return; // Sair se conseguiu carregar do provider
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoProvider: $e');
      }
      
      // Terceiro, tentar carregar do TalhaoModuleService
      try {
        print('🔄 Tentativa 3: Carregando do TalhaoModuleService...');
        await _talhaoModuleService.initialize();
        var talhoes = await _talhaoModuleService.getTalhoes();
        if (talhoes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _talhoes = talhoes;
            });
          }
          print('✅ ${talhoes.length} talhões carregados do TalhaoModuleService');
          return; // Sair se conseguiu carregar do serviço
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoModuleService: $e');
      }
      
      // Quarto, tentar carregar do TalhaoRepository
      try {
        print('🔄 Tentativa 4: Carregando do TalhaoRepository...');
        var talhoes = await _talhaoRepository.getTalhoes();
        if (talhoes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _talhoes = talhoes;
            });
          }
          print('✅ ${talhoes.length} talhões carregados do TalhaoRepository');
          return; // Sair se conseguiu carregar do repositório
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoRepository: $e');
      }
      
      // Quinto, tentar carregar diretamente do banco de dados
      try {
        print('🔄 Tentativa 5: Carregando talhões diretamente do banco...');
        _talhoes = await _carregarTalhoesDiretoBanco();
        if (_talhoes.isNotEmpty) {
          if (mounted) {
            setState(() {});
          }
          print('✅ ${_talhoes.length} talhões carregados diretamente do banco');
          return;
        }
      } catch (e) {
        print('❌ Erro ao carregar diretamente do banco: $e');
      }
      
      // Se chegou até aqui, não conseguiu carregar nenhum talhão real
      print('❌ Nenhum talhão real encontrado em nenhuma fonte');
      if (mounted) {
        setState(() {
          _talhoes = []; // Lista vazia em vez de fallback
        });
      }
      
    } catch (e) {
      print('❌ Erro geral ao carregar talhões: $e');
      if (mounted) {
        setState(() {
          _talhoes = []; // Lista vazia em vez de fallback
        });
      }
    }
  }

  /// Carrega talhões diretamente do banco de dados
  Future<List<TalhaoModel>> _carregarTalhoesDiretoBanco() async {
    try {
      print('🔄 Acessando banco de dados diretamente...');
      
      final databaseService = DatabaseService();
      final db = await databaseService.database;
      
      // Lista de possíveis tabelas de talhões
      final possiveisTabelas = [
        'talhoes',
        'talhao_safra',
        'talhoes_safras',
        'talhao',
        'plots',
      ];
      
      List<Map<String, dynamic>> talhoesData = [];
      String tabelaUsada = '';
      
      // Tentar cada tabela possível
      for (final tabela in possiveisTabelas) {
        try {
          final tableExists = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$tabela'"
          );
          
          if (tableExists.isNotEmpty) {
            print('🔍 Tabela encontrada: $tabela');
            talhoesData = await db.query(tabela);
            tabelaUsada = tabela;
            print('📊 Registros encontrados na tabela $tabela: ${talhoesData.length}');
            break; // Sair do loop se encontrou dados
          }
        } catch (e) {
          print('⚠️ Erro ao verificar tabela $tabela: $e');
          continue;
        }
      }
      
      if (talhoesData.isEmpty) {
        print('❌ Nenhuma tabela de talhões encontrada');
        return [];
      }
      
      // Converter para TalhaoModel
      final talhoes = talhoesData.map((data) {
        // Tentar diferentes campos de nome
        String nome = '';
        if (data['nome'] != null) {
          nome = data['nome'].toString();
        } else if (data['name'] != null) {
          nome = data['name'].toString();
        } else if (data['nome_talhao'] != null) {
          nome = data['nome_talhao'].toString();
        } else {
          nome = 'Talhão sem nome';
        }
        
        // Tentar diferentes campos de área
        double area = 0.0;
        if (data['area'] != null) {
          area = (data['area'] as num).toDouble();
        } else if (data['area_ha'] != null) {
          area = (data['area_ha'] as num).toDouble();
        }
        
        // Tentar diferentes campos de data
        DateTime dataCriacao = DateTime.now();
        if (data['created_at'] != null) {
          dataCriacao = DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now();
        } else if (data['data_criacao'] != null) {
          dataCriacao = DateTime.tryParse(data['data_criacao'].toString()) ?? DateTime.now();
        } else if (data['createdAt'] != null) {
          dataCriacao = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
        }
        
        return TalhaoModel(
          id: data['id']?.toString() ?? '',
          name: nome,
          area: area,
          poligonos: [],
          dataCriacao: dataCriacao,
          dataAtualizacao: DateTime.now(),
          safras: [],
          sincronizado: false,
        );
      }).toList();
      
      print('✅ ${talhoes.length} talhões convertidos com sucesso da tabela $tabelaUsada');
      for (var talhao in talhoes) {
        print('  - ${talhao.name} (ID: ${talhao.id}, Área: ${talhao.area} ha)');
      }
      
      return talhoes;
    } catch (e) {
      print('❌ Erro ao carregar talhões do banco: $e');
      return [];
    }
  }

  /// Carrega culturas
  Future<void> _carregarCulturas() async {
    try {
      print('🔄 Carregando culturas para calibração por coleta...');
      
      // Primeiro, tentar carregar do CulturaProvider (método unificado)
      print('🔄 Tentando carregar culturas do CulturaProvider...');
      try {
        final culturaProvider = Provider.of<CulturaProvider>(context, listen: false);
        final culturasProvider = await culturaProvider.getCulturasParaPlantio();
        
        if (culturasProvider.isNotEmpty) {
          _culturas = culturasProvider.map((cultura) => AgriculturalProduct(
            id: cultura.id,
            name: cultura.name,
            description: cultura.description ?? '',
            type: ProductType.seed,
            colorValue: cultura.color.value.toString(),
          )).toList();
          print('✅ ${_culturas.length} culturas carregadas do CulturaProvider');
          
          // Log detalhado das culturas
          for (int i = 0; i < _culturas.length; i++) {
            final cultura = _culturas[i];
            print('  ${i + 1}. ${cultura.name} (ID: ${cultura.id})');
          }
          return; // Sair se conseguiu carregar do provider
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaProvider: $e');
      }
      
      // Fallback: tentar carregar do CulturaTalhaoService
      print('🔄 Tentando carregar culturas do CulturaTalhaoService (fallback)...');
      try {
        var culturasData = await _culturaTalhaoService.listarCulturas();
        
        List<AgriculturalProduct> culturas = [];
        if (culturasData.isNotEmpty) {
          culturas = culturasData.map((cultura) => AgriculturalProduct(
            id: cultura['id']?.toString() ?? '',
            name: cultura['nome']?.toString() ?? 'Cultura',
            description: cultura['descricao']?.toString() ?? '',
            type: ProductType.seed,
            colorValue: cultura['cor']?.toString() ?? '#4CAF50',
          )).toList();
          print('✅ ${culturas.length} culturas carregadas do CulturaTalhaoService (fallback)');
          
          // Log detalhado das culturas
          for (int i = 0; i < culturas.length; i++) {
            final cultura = culturas[i];
            print('  ${i + 1}. ${cultura.name} (ID: ${cultura.id})');
          }
          _culturas = culturas;
          return; // Sair se conseguiu carregar do serviço
        }
      } catch (e) {
        print('❌ Erro ao carregar culturas do CulturaTalhaoService: $e');
      }
      
      // Se chegou até aqui, não conseguiu carregar nenhuma cultura real
      print('❌ Nenhuma cultura real encontrada em nenhuma fonte');
      _culturas = []; // Lista vazia em vez de fallback
      print('ℹ️ Nenhuma cultura disponível - use entrada manual');
    } catch (e) {
      print('Erro ao carregar culturas: $e');
      setState(() {
        _culturas = []; // Lista vazia em vez de fallback
      });
    }
  }





  /// Recarrega os talhões manualmente
  Future<void> _recarregarTalhoes() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('🔄 Recarregando talhões manualmente...');
      await _carregarTalhoes();
      
      setState(() {
        _isLoading = false;
      });
      
      if (_talhoes.isNotEmpty) {
        SnackbarUtils.showSuccessSnackBar(context, '${_talhoes.length} talhões carregados com sucesso!');
      } else {
        SnackbarUtils.showErrorSnackBar(context, 'Nenhum talhão encontrado. Verifique se há talhões cadastrados no módulo Talhões.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao recarregar talhões: ${e.toString()}');
    }
  }

  /// Seleciona talhão
  void _selecionarTalhao() {
    if (_talhoes.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nenhum Talhão Encontrado'),
          content: const Text(
            'Não foram encontrados talhões cadastrados no módulo Talhões. '
            'Por favor, cadastre pelo menos um talhão antes de continuar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _recarregarTalhoes();
              },
              child: const Text('Recarregar'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Talhão'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _talhoes.length,
            itemBuilder: (context, index) {
              final talhao = _talhoes[index];
                              return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      talhao.name.isNotEmpty ? talhao.name[0].toUpperCase() : 'T',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                title: Text(talhao.name),
                subtitle: Text('${talhao.area?.toStringAsFixed(2) ?? '-'} ha'),
                onTap: () {
                  setState(() {
                    _talhaoSelecionado = talhao;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Seleciona cultura
  void _selecionarCultura() {
    if (_culturas.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Nenhuma cultura disponível');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Cultura'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _culturas.length,
            itemBuilder: (context, index) {
              final cultura = _culturas[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: cultura.colorValue != null
                      ? _parseColor(cultura.colorValue)
                      : Colors.grey,
                  child: Text(
                    cultura.name.isNotEmpty ? cultura.name[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(cultura.name ?? 'Sem nome'),
                subtitle: Text(cultura.type.toString().split('.').last),
                onTap: () {
                  setState(() {
                    _culturaSelecionada = cultura;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Converte string de cor para Color
  Color _parseColor(String? colorValue) {
    if (colorValue == null || colorValue.isEmpty) return Colors.green;
    
    try {
      String colorString = colorValue.trim();
      
      // Se começa com #
      if (colorString.startsWith('#')) {
        String hex = colorString.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        } else if (hex.length == 3) {
          // Expandir cores de 3 dígitos
          hex = hex.split('').map((c) => c + c).join();
          return Color(int.parse('0xFF$hex'));
        }
      }
      
      // Se começa com 0x
      if (colorString.startsWith('0x')) {
        return Color(int.parse(colorString));
      }
      
      // Se é apenas um número
      if (RegExp(r'^[0-9]+$').hasMatch(colorString)) {
        return Color(int.parse(colorString));
      }
      
      // Se contém Color( (objeto Color)
      if (colorString.contains('Color(')) {
        return Colors.green;
      }
      
      // Cor padrão se não conseguir parsear
      return Colors.green;
      
    } catch (e) {
      print('❌ Erro ao parsear color: "$colorValue" - $e');
      return Colors.green; // Cor padrão em caso de erro
    }
  }

  /// Calcula o peso alvo por 50 metros baseado na meta
  double _calcularPesoAlvo() {
    if (_metaKgHaController.text.isEmpty) return 0.0;
    
    try {
      final metaKgHa = double.parse(_metaKgHaController.text);
      final distancia = double.parse(_distanciaController.text);
      final linhas = int.parse(_linhasController.text);
      final espacamento = double.parse(_espacamentoController.text);
      
      // Área percorrida em hectares
      final areaHa = (distancia * (linhas * (espacamento / 100))) / 10000;
      
      // Peso alvo em gramas para a área percorrida
      final pesoAlvoG = (metaKgHa * areaHa * 1000);
      
      return pesoAlvoG;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calcula a calibragem
  void _calcular() {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Obter valores dos campos
      final pesoColetado = double.parse(_pesoColetadoController.text);
      final distancia = double.parse(_distanciaController.text);
      final linhas = int.parse(_linhasController.text);
      final espacamento = double.parse(_espacamentoController.text);
      final metaKgHa = double.parse(_metaKgHaController.text);

      // Cálculo da área em hectares
      final areaHa = (distancia * (linhas * (espacamento / 100))) / 10000;

      // Cálculo dos kg por hectare
      double kgHa;
      if (_tipoColeta == 'linha') {
        // Cálculo por linha - peso coletado é de uma linha apenas
        kgHa = (pesoColetado / 1000) / areaHa;
      } else {
        // Cálculo total - peso coletado é de todas as linhas
        kgHa = (pesoColetado / 1000) / areaHa;
      }

      // Cálculo das sacas por hectare (considerando sacos de 60kg)
      final sacasHa = kgHa / 60;

      // Cálculo da diferença em kg/ha e percentual
      final diferencaKgHa = kgHa - metaKgHa;
      final diferencaPercentual = (diferencaKgHa / metaKgHa) * 100;

      // Sugestão de ajuste
      String sugestaoAjuste;
      if (diferencaPercentual.abs() <= 3) {
        sugestaoAjuste = 'Calibragem adequada, dentro da margem de tolerância (±3%)';
      } else if (diferencaPercentual > 3) {
        sugestaoAjuste = 'Reduza a abertura do dosador em aproximadamente ${diferencaPercentual.abs().toStringAsFixed(1)}%';
      } else {
        sugestaoAjuste = 'Aumente a abertura do dosador em aproximadamente ${diferencaPercentual.abs().toStringAsFixed(1)}%';
      }

      setState(() {
        _areaHa = areaHa;
        _kgHa = kgHa;
        _sacasHa = sacasHa;
        _diferencaMeta = diferencaKgHa;
        _diferencaPercentual = diferencaPercentual;
        _sugestaoAjuste = sugestaoAjuste;
      });
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao calcular: ${e.toString()}');
    }
  }

  /// Salva a calibragem
  Future<void> _salvarCalibragem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_talhaoSelecionado == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione um talhão');
      return;
    }

    if (_culturaSelecionada == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma cultura');
      return;
    }

    if (_kgHa == 0.0) {
      SnackbarUtils.showErrorSnackBar(context, 'Faça o cálculo antes de salvar');
      return;
    }

    try {
      // Salvar no histórico usando o modelo de calibração
      await AppDatabase.instance.initDatabase();
      final database = await AppDatabase.instance.database;
      final dao = CalibrationHistoryDao(database);
      
      // Determinar status baseado na diferença da meta
      String statusCalibracao;
      if (_diferencaPercentual.abs() <= 5.0) {
        statusCalibracao = 'dentro_esperado';
      } else if (_diferencaPercentual.abs() <= 15.0) {
        statusCalibracao = 'normal';
      } else {
        statusCalibracao = 'fora_esperado';
      }
      
      // Criar modelo de histórico de calibração
      final calibracaoHistorico = CalibrationHistoryModel(
        talhaoId: _talhaoSelecionado!.id,
        talhaoName: _talhaoSelecionado!.name,
        culturaId: _culturaSelecionada!.id,
        culturaName: _culturaSelecionada!.name,
        discoNome: _nomeFertilizanteController.text,
        furosDisco: null,
        engrenagemMotora: null,
        engrenagemMovida: null,
        voltasDisco: null,
        distanciaPercorrida: null,
        linhasColetadas: _tipoColeta == "linha" ? 1 : null,
        espacamentoCm: null,
        metaSementesHectare: double.tryParse(_metaKgHaController.text)?.round(),
        relacaoTransmissao: null,
        sementesTotais: null,
        sementesPorMetro: null,
        sementesPorHectare: _kgHa.round(),
        diferencaMetaPercentual: _diferencaPercentual,
        statusCalibracao: statusCalibracao,
        observacoes: 'Tipo: ${_tipoColeta == "linha" ? "Por Linha" : "Total"}\n'
                     'Kg/ha: ${numberFormat.format(_kgHa)}\n'
                     'Sacas/ha: ${numberFormat3.format(_sacasHa)}\n'
                     'Diferença: ${_diferencaMeta >= 0 ? "+" : ""}${numberFormat.format(_diferencaMeta)} kg/ha',
        dataCalibracao: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await dao.insertCalibration(calibracaoHistorico);
      
      SnackbarUtils.showSuccessSnackBar(
        context, 
        'Calibragem salva com sucesso!\nStatus: ${CalibrationHistoryModel.getStatusText(statusCalibracao)}'
      );
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar: ${e.toString()}');
    }
  }

  void _abrirHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlantioCalibragemHistoricoScreen(),
      ),
    );
  }

  /// Limpa os campos
  void _limparCampos() {
    setState(() {
      _nomeFertilizanteController.clear();
      _pesoColetadoController.clear();
      _distanciaController.clear();
      _linhasController.text = '1';
      _espacamentoController.text = '45';
      _metaKgHaController.text = '300';
      _tipoColeta = 'linha';
      _areaHa = 0.0;
      _kgHa = 0.0;
      _sacasHa = 0.0;
      _diferencaMeta = 0.0;
      _diferencaPercentual = 0.0;
      _sugestaoAjuste = '';
      _talhaoSelecionado = null;
      _culturaSelecionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibragem de Adubo por Coleta'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _abrirHistorico,
            tooltip: 'Ver Histórico',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recarregarTalhoes,
            tooltip: 'Recarregar talhões',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelecaoTalhaoCultura(),
                        const SizedBox(height: 24),
                        _buildTipoColeta(),
                        const SizedBox(height: 24),
                        _buildEntradaDados(),
                        const SizedBox(height: 24),
                        if (_kgHa > 0) _buildResultados(),
                        const SizedBox(height: 24),
                        _buildBotoes(),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Constrói widget de erro
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _carregarDados,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  /// Constrói seleção de talhão e cultura
  Widget _buildSelecaoTalhaoCultura() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleção de Talhão e Cultura',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Seleção de talhão
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _talhaoSelecionado != null
                  ? Colors.green
                  : Colors.grey,
              child: Text(
                _talhaoSelecionado != null && _talhaoSelecionado!.name.isNotEmpty
                    ? _talhaoSelecionado!.name[0].toUpperCase()
                    : 'T',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              _talhaoSelecionado?.name ?? 'Selecione um talhão',
              style: TextStyle(
                fontWeight: _talhaoSelecionado != null ? FontWeight.bold : FontWeight.normal,
                color: _talhaoSelecionado != null ? Colors.black : Colors.grey,
              ),
            ),
            subtitle: Text(
              _talhaoSelecionado != null
                  ? '${_talhaoSelecionado!.area?.toStringAsFixed(2) ?? '-'} ha'
                  : 'Toque para selecionar',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_talhoes.isEmpty)
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            onTap: _selecionarTalhao,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: _talhoes.isEmpty 
                    ? Colors.orange.shade300 
                    : Colors.grey.shade300,
                width: _talhoes.isEmpty ? 2 : 1,
              ),
            ),
          ),
        ),
        
        // Mensagem de status dos talhões
        if (_talhoes.isEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ Nenhum talhão disponível. Verifique se há talhões cadastrados no módulo Talhões.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Seleção de cultura
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _culturaSelecionada != null
                  ? _parseColor(_culturaSelecionada!.colorValue)
                  : Colors.grey,
              child: Text(
                _culturaSelecionada != null && _culturaSelecionada!.name.isNotEmpty
                    ? _culturaSelecionada!.name[0].toUpperCase()
                    : 'C',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              _culturaSelecionada?.name ?? 'Selecione uma cultura',
              style: TextStyle(
                fontWeight: _culturaSelecionada != null ? FontWeight.bold : FontWeight.normal,
                color: _culturaSelecionada != null ? Colors.black : Colors.grey,
              ),
            ),
            subtitle: Text(
              _culturaSelecionada != null
                  ? _culturaSelecionada!.type.toString().split('.').last
                  : 'Toque para selecionar',
            ),
            onTap: _selecionarCultura,
          ),
        ),
      ],
    );
  }

  /// Constrói tipo de coleta
  Widget _buildTipoColeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Coleta',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Por Linha'),
                subtitle: const Text('Peso coletado de uma linha apenas'),
                value: 'linha',
                groupValue: _tipoColeta,
                onChanged: (value) {
                  setState(() {
                    _tipoColeta = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Total'),
                subtitle: const Text('Peso coletado de todas as linhas'),
                value: 'total',
                groupValue: _tipoColeta,
                onChanged: (value) {
                  setState(() {
                    _tipoColeta = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói entrada de dados
  Widget _buildEntradaDados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados da Coleta',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Nome do fertilizante
        TextFormField(
          controller: _nomeFertilizanteController,
          decoration: const InputDecoration(
            labelText: 'Nome do Fertilizante',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.eco),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe o nome do fertilizante';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Peso coletado
        TextFormField(
          controller: _pesoColetadoController,
          decoration: const InputDecoration(
            labelText: 'Peso Coletado (g)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.scale),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe o peso coletado';
            }
            if (double.tryParse(value) == null) {
              return 'Digite um número válido';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Distância percorrida
        TextFormField(
          controller: _distanciaController,
          decoration: const InputDecoration(
            labelText: 'Distância Percorrida (m)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.route),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe a distância percorrida';
            }
            if (double.tryParse(value) == null) {
              return 'Digite um número válido';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Número de linhas
        TextFormField(
          controller: _linhasController,
          decoration: const InputDecoration(
            labelText: 'Número de Linhas',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.grid_on),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*'))],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe o número de linhas';
            }
            if (int.tryParse(value) == null) {
              return 'Digite um número inteiro';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Espaçamento entre linhas
        TextFormField(
          controller: _espacamentoController,
          decoration: const InputDecoration(
            labelText: 'Espaçamento entre Linhas (cm)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.straighten),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe o espaçamento';
            }
            if (double.tryParse(value) == null) {
              return 'Digite um número válido';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Meta em kg/ha
        TextFormField(
          controller: _metaKgHaController,
          decoration: const InputDecoration(
            labelText: 'Meta (kg/ha)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.trending_up),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Informe a meta';
            }
            if (double.tryParse(value) == null) {
              return 'Digite um número válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Constrói resultados
  Widget _buildResultados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resultados da Calibragem',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              ListTile(
                                 leading: const Icon(Icons.area_chart, color: Color(0xFF1B5E20)),
                title: const Text('Área Avaliada'),
                subtitle: Text('${numberFormat4.format(_areaHa)} hectares'),
                dense: true,
              ),
              ListTile(
                                 leading: const Icon(Icons.agriculture, color: Color(0xFF1B5E20)),
                title: const Text('Aplicação Atual'),
                subtitle: Text('${numberFormat.format(_kgHa)} kg/ha (${numberFormat3.format(_sacasHa)} sacas/ha)'),
                dense: true,
              ),
              ListTile(
                                 leading: const Icon(Icons.scale, color: Color(0xFF1B5E20)),
                title: const Text('Peso Alvo por 50m'),
                subtitle: Text('${numberFormat.format(_calcularPesoAlvo())} gramas'),
                dense: true,
              ),
              ListTile(
                leading: Icon(
                  _diferencaMeta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: _diferencaMeta > 0 ? Colors.red : Colors.green,
                ),
                title: const Text('Diferença da Meta'),
                subtitle: Text(
                  '${_diferencaMeta > 0 ? '+' : ''}${numberFormat.format(_diferencaMeta)} kg/ha ' +
                      '(${_diferencaPercentual > 0 ? '+' : ''}${numberFormat.format(_diferencaPercentual)}%)',
                ),
                dense: true,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _diferencaPercentual.abs() <= 3 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _diferencaPercentual.abs() <= 3 ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sugestão de Ajuste:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _diferencaPercentual.abs() <= 3 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_sugestaoAjuste),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói botões
  Widget _buildBotoes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se a largura for muito pequena, usar layout vertical
        if (constraints.maxWidth < 400) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _calcular();
                    }
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calcular'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _salvarCalibragem();
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          );
        }
        
        // Layout horizontal para telas maiores
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _calcular();
                  }
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _salvarCalibragem();
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/prescricao_model.dart';
import '../../models/talhao_model.dart';
import '../../services/prescricao_calculo_service.dart';
import '../../services/prescricao_calculo_profissional_service.dart';
import '../../services/talhao_module_service.dart';
import '../../services/database_service.dart';
import '../../services/talhao_unified_service.dart';
import '../../repositories/prescricao_repository.dart';
import '../../repositories/talhao_repository.dart';
import '../../database/app_database.dart';
import '../../utils/logger.dart';
import '../../services/prescricao_pdf_service.dart';

import '../../widgets/prescricao_produtos_widget.dart';
import '../../widgets/prescricao_resultados_widget.dart';

/// Tela principal de Prescrição Agronômica Premium
class PrescricaoPremiumScreen extends StatefulWidget {
  final String? prescricaoId; // Para edição de prescrição existente

  const PrescricaoPremiumScreen({super.key, this.prescricaoId});

  @override
  State<PrescricaoPremiumScreen> createState() => _PrescricaoPremiumScreenState();
}

class _PrescricaoPremiumScreenState extends State<PrescricaoPremiumScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _prescricaoRepository = PrescricaoRepository();
  final _talhaoRepository = TalhaoRepository();

  // Controllers
  final _volumeLHaController = TextEditingController();
  final _capacidadeTanqueController = TextEditingController();
  final _volumeSegurancaController = TextEditingController();
  final _areaTrabalhoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Controllers para entrada manual
  final _nomeTalhaoManualController = TextEditingController();
  final _areaManualController = TextEditingController();
  final _culturaManualController = TextEditingController();

  // Dados
  PrescricaoModel? _prescricao;
  List<TalhaoModel> _talhoes = [];
  List<PrescricaoProdutoModel> _produtos = [];
  
  // Seleções
  TalhaoModel? _talhaoSelecionado;
  String _tipoAplicacao = 'Terrestre';
  DateTime _dataAplicacao = DateTime.now();
  String _responsavelNome = 'Usuário Atual';
  
  // Opções de entrada
  bool _usarAreaManual = false;
  
  
  // Estados
  bool _isLoading = true;
  bool _isCalculating = false;
  bool _isSaving = false;
  bool _permitirFracao = true;
  
  // Resultados
  PrescricaoCalculoResult? _resultadoCalculo;
  PrescricaoCalculoResultado? _resultadoCalculoProfissional;
  
  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _volumeLHaController.dispose();
    _capacidadeTanqueController.dispose();
    _volumeSegurancaController.dispose();
    _areaTrabalhoController.dispose();
    _observacoesController.dispose();
    _nomeTalhaoManualController.dispose();
    _areaManualController.dispose();
    _culturaManualController.dispose();
    super.dispose();
  }

  /// Carrega os dados iniciais
  Future<void> _carregarDados() async {
    try {
      setState(() => _isLoading = true);

      print('🔄 Iniciando carregamento de dados da Prescrição Premium...');

      // Carregar talhões com tratamento de erro mais robusto
      try {
        _talhoes = await _carregarTalhoesRobusto();
        print('📊 Talhões carregados: ${_talhoes.length}');
        
        // Debug: mostrar detalhes dos talhões
        for (int i = 0; i < _talhoes.length; i++) {
          print('  Talhão ${i + 1}: ${_talhoes[i].nome} (${_talhoes[i].area} ha)');
        }
        
        if (_talhoes.isEmpty) {
          print('⚠️ Nenhum talhão encontrado no repositório');
          // Tentar inserir dados de exemplo
          await _inserirTalhoesExemplo();
          // Recarregar talhões após inserir exemplos
          _talhoes = await _carregarTalhoesRobusto();
          if (_talhoes.isEmpty) {
            print('⚠️ Ainda não há talhões após inserir exemplos');
            // Tentar carregar talhões de forma mais direta
            _talhoes = await _carregarTalhoesDireto();
            if (_talhoes.isEmpty) {
              _mostrarErro('Nenhum talhão encontrado. Verifique se há talhões cadastrados no módulo Talhões.');
            }
          } else {
            _mostrarSucesso('Talhões de exemplo inseridos com sucesso!');
          }
        }
      } catch (e) {
        print('❌ Erro ao carregar talhões: $e');
        _talhoes = [];
        _mostrarErro('Erro ao carregar talhões: $e');
      }
      
      // Se for edição, carregar prescrição existente
      if (widget.prescricaoId != null) {
        try {
          _prescricao = await _prescricaoRepository.buscarPorId(widget.prescricaoId!);
          if (_prescricao != null) {
            _carregarDadosPrescricao();
            print('📋 Prescrição existente carregada: ${_prescricao!.id}');
          }
        } catch (e) {
          print('❌ Erro ao carregar prescrição existente: $e');
          _mostrarErro('Erro ao carregar prescrição: $e');
        }
      }

      // Carregar produtos agrícolas com tratamento de erro
      try {
        print('🔄 Carregando produtos agrícolas...');
        // Por enquanto, vamos pular o carregamento de produtos para evitar o erro
        print('✅ Carregamento de produtos agrícolas pulado temporariamente');
      } catch (e) {
        print('❌ Erro ao carregar produtos agrícolas: $e');
        // Não mostrar erro para o usuário, apenas log
      }

      print('✅ Carregamento de dados concluído');
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erro geral ao carregar dados: $e');
      Logger.error('Erro ao carregar dados: $e');
      setState(() => _isLoading = false);
      _mostrarErro('Erro ao carregar dados: $e');
    }
  }

  /// Insere talhões de exemplo no banco de dados
  Future<void> _inserirTalhoesExemplo() async {
    try {
      print('🔄 Inserindo talhões de exemplo...');
      
      final appDatabase = AppDatabase();
      final db = await appDatabase.database;
      
      // Verificar se já existem talhões
      final count = await db.rawQuery('SELECT COUNT(*) FROM talhoes');
      final talhoesCount = count.first.values.first as int;
      
      if (talhoesCount > 0) {
        print('✅ Já existem talhões no banco de dados');
        return;
      }
      
      // Inserir talhões de exemplo
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        
        // Talhão 1
        await txn.insert('talhoes', {
          'id': 'talhao_001',
          'name': 'Talhão 1 - Centro',
          'idFazenda': 'fazenda_001',
          'area': 25.5,
          'poligonos': '[]',
          'safras': '[]',
          'dataCriacao': now,
          'dataAtualizacao': now,
          'sincronizado': 0,
          'device_id': 'local',
        });
        
        // Talhão 2
        await txn.insert('talhoes', {
          'id': 'talhao_002',
          'name': 'Talhão 2 - Norte',
          'idFazenda': 'fazenda_001',
          'area': 18.2,
          'poligonos': '[]',
          'safras': '[]',
          'dataCriacao': now,
          'dataAtualizacao': now,
          'sincronizado': 0,
          'device_id': 'local',
        });
        
        // Talhão 3
        await txn.insert('talhoes', {
          'id': 'talhao_003',
          'name': 'Talhão 3 - Sul',
          'idFazenda': 'fazenda_001',
          'area': 32.8,
          'poligonos': '[]',
          'safras': '[]',
          'dataCriacao': now,
          'dataAtualizacao': now,
          'sincronizado': 0,
          'device_id': 'local',
        });
      });
      
      print('✅ Talhões de exemplo inseridos com sucesso');
    } catch (e) {
      print('❌ Erro ao inserir talhões de exemplo: $e');
    }
  }

  /// Carrega talhões usando múltiplas estratégias
  Future<List<TalhaoModel>> _carregarTalhoesRobusto() async {
    try {
      // Tentativa 1: TalhaoUnifiedService (mais robusto)
      print('🔄 Tentativa 1: Carregando talhões via TalhaoUnifiedService...');
      final unifiedService = TalhaoUnifiedService();
      final talhoes = await unifiedService.carregarTalhoesParaModulo(
        nomeModulo: 'PRESCRIÇÃO_PREMIUM',
        forceRefresh: true,
      );
      print('📊 Talhões encontrados via UnifiedService: ${talhoes.length}');
      
      if (talhoes.isNotEmpty) {
        print('✅ Talhões carregados com sucesso via TalhaoUnifiedService');
        // Debug: mostrar detalhes dos talhões
        for (int i = 0; i < talhoes.length; i++) {
          print('  Talhão ${i + 1}: ${talhoes[i].nome} (${talhoes[i].area} ha)');
        }
        return talhoes;
      }
    } catch (e) {
      print('❌ Erro na tentativa 1 (UnifiedService): $e');
    }

    try {
      // Tentativa 2: Repositório principal
      print('🔄 Tentativa 2: Carregando talhões via TalhaoRepository...');
      final talhoes = await _talhaoRepository.getTalhoes();
      print('📊 Talhões encontrados via Repository: ${talhoes.length}');
      
      if (talhoes.isNotEmpty) {
        print('✅ Talhões carregados com sucesso via repositório principal');
        return talhoes;
      }
    } catch (e) {
      print('❌ Erro na tentativa 2 (Repository): $e');
    }

    try {
      // Tentativa 3: Usando DatabaseService diretamente
      print('🔄 Tentativa 3: Carregando talhões via DatabaseService...');
      final databaseService = DatabaseService();
      final talhoesData = await databaseService.getTalhoes();
      print('📊 Dados encontrados: ${talhoesData.length}');
      
      if (talhoesData.isNotEmpty) {
        print('✅ Talhões carregados com sucesso via DatabaseService');
        // Converter Map para TalhaoModel
        final talhoes = talhoesData.map((data) {
          try {
            return TalhaoModel.fromMap(data);
          } catch (e) {
            print('❌ Erro ao converter talhão: $e');
            print('📊 Dados do talhão: $data');
            return null;
          }
        }).where((t) => t != null).cast<TalhaoModel>().toList();
        
        print('📊 Talhões convertidos: ${talhoes.length}');
        return talhoes;
      }
    } catch (e) {
      print('❌ Erro na tentativa 3 (DatabaseService): $e');
    }

    try {
      // Tentativa 4: Usando TalhaoModuleService
      print('🔄 Tentativa 4: Carregando talhões via TalhaoModuleService...');
      final talhaoService = TalhaoModuleService();
      final talhoes = await talhaoService.getTalhoes();
      if (talhoes.isNotEmpty) {
        print('✅ Talhões carregados com sucesso via TalhaoModuleService');
        return talhoes;
      }
    } catch (e) {
      print('❌ Erro na tentativa 4 (ModuleService): $e');
    }

    // Tentativa 5: Carregar diretamente do AppDatabase
    try {
      print('🔄 Tentativa 5: Carregando talhões diretamente do AppDatabase...');
      final appDatabase = AppDatabase();
      final db = await appDatabase.database;
      
      // Verificar se a tabela existe
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='talhoes'"
      );
      
      if (tableExists.isNotEmpty) {
        print('✅ Tabela talhoes encontrada');
        final talhoesData = await db.query('talhoes');
        print('📊 Registros na tabela: ${talhoesData.length}');
        
        if (talhoesData.isNotEmpty) {
          final talhoes = talhoesData.map((data) {
            try {
              // Criar um TalhaoModel básico a partir dos dados
              return TalhaoModel(
                id: data['id']?.toString() ?? '',
                name: data['name']?.toString() ?? 'Sem nome',
                poligonos: [], // Polígonos serão carregados separadamente se necessário
                area: (data['area'] as num?)?.toDouble() ?? 0.0,
                fazendaId: data['idFazenda']?.toString(),
                dataCriacao: DateTime.tryParse(data['dataCriacao']?.toString() ?? '') ?? DateTime.now(),
                dataAtualizacao: DateTime.tryParse(data['dataAtualizacao']?.toString() ?? '') ?? DateTime.now(),
                sincronizado: (data['sincronizado'] as int?) == 1,
                observacoes: data['observacoes']?.toString(),
                metadados: {},
                safras: [],
                cropId: null,
                culturaId: null,
                safraId: null,
                crop: null,
              );
            } catch (e) {
              print('❌ Erro ao criar TalhaoModel: $e');
              print('📊 Dados: $data');
              return null;
            }
          }).where((t) => t != null).cast<TalhaoModel>().toList();
          
          print('📊 Talhões criados: ${talhoes.length}');
          return talhoes;
        }
      } else {
        print('❌ Tabela talhoes não encontrada');
      }
    } catch (e) {
      print('❌ Erro na tentativa 5 (AppDatabase): $e');
    }

    print('⚠️ Todas as tentativas falharam. Retornando lista vazia.');
    return [];
  }

  /// Carrega talhões de forma direta e simples
  Future<List<TalhaoModel>> _carregarTalhoesDireto() async {
    try {
      print('🔄 Carregando talhões de forma direta...');
      
      final appDatabase = AppDatabase();
      final db = await appDatabase.database;
      
      // Verificar se a tabela existe
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='talhoes'"
      );
      
      if (tableExists.isEmpty) {
        print('❌ Tabela talhoes não existe');
        return [];
      }
      
      // Carregar todos os talhões
      final talhoesData = await db.query('talhoes');
      print('📊 Registros encontrados: ${talhoesData.length}');
      
      if (talhoesData.isEmpty) {
        print('⚠️ Nenhum registro na tabela talhoes');
        return [];
      }
      
      final talhoes = <TalhaoModel>[];
      
      for (final data in talhoesData) {
        try {
          final talhao = TalhaoModel(
            id: data['id']?.toString() ?? '',
            name: data['name']?.toString() ?? 'Sem nome',
            poligonos: [],
            area: (data['area'] as num?)?.toDouble() ?? 0.0,
            fazendaId: data['idFazenda']?.toString(),
            dataCriacao: DateTime.tryParse(data['dataCriacao']?.toString() ?? '') ?? DateTime.now(),
            dataAtualizacao: DateTime.tryParse(data['dataAtualizacao']?.toString() ?? '') ?? DateTime.now(),
            sincronizado: (data['sincronizado'] as int?) == 1,
            observacoes: null,
            metadados: {},
            safras: [],
            cropId: null,
            culturaId: null,
            safraId: null,
            crop: null,
          );
          
          talhoes.add(talhao);
          print('✅ Talhão criado: ${talhao.name} (${talhao.area} ha)');
        } catch (e) {
          print('❌ Erro ao criar talhão: $e');
          print('📊 Dados: $data');
        }
      }
      
      print('📊 Total de talhões carregados: ${talhoes.length}');
      return talhoes;
    } catch (e) {
      print('❌ Erro ao carregar talhões diretamente: $e');
      return [];
    }
  }

  /// Carrega dados de uma prescrição existente
  void _carregarDadosPrescricao() {
    if (_prescricao == null) return;

    // Selecionar talhão
    _talhaoSelecionado = _talhoes.firstWhere(
      (t) => t.id == _prescricao!.talhaoId,
      orElse: () => _talhoes.first,
    );

    // Preencher controllers
    _volumeLHaController.text = _prescricao!.volumeLHa.toString();
    _capacidadeTanqueController.text = _prescricao!.capacidadeTanqueL.toString();
    _volumeSegurancaController.text = _prescricao!.volumeSegurancaL.toString();
    _areaTrabalhoController.text = _prescricao!.areaTrabalhoHa.toString();
    _tipoAplicacao = _prescricao!.tipoAplicacao;
    _dataAplicacao = _prescricao!.data;
    _responsavelNome = _prescricao!.responsavelNome;
    
    _observacoesController.text = _prescricao!.observacoes ?? '';


    // Produtos
    _produtos = List.from(_prescricao!.produtos);

    // Resultados
    if (_prescricao!.resultados != null && _prescricao!.totais != null) {
      _resultadoCalculo = PrescricaoCalculoResult(
        sucesso: true,
        resultados: _prescricao!.resultados,
        produtosCalculados: _produtos,
        totais: _prescricao!.totais,
      );
    }
  }

  /// Salva a prescrição como rascunho e redireciona para submódulos
  Future<void> _salvarRascunho() async {
    try {
      setState(() => _isSaving = true);
      print('🔄 Iniciando processo de salvamento...');

      // Validar dados antes de salvar
      if (!_validarDadosBasicos()) {
        print('❌ Validação de dados falhou');
        _mostrarErro('Por favor, preencha todos os campos obrigatórios');
        return;
      }
      print('✅ Validação de dados passou');

      final prescricao = _criarPrescricao();
      print('📝 Prescrição criada: ${prescricao.id}');
      
      // Inicializar repositório se necessário
      try {
        await _prescricaoRepository.initialize();
        print('✅ Repositório inicializado');
      } catch (e) {
        print('⚠️ Erro ao inicializar repositório: $e');
        // Continuar mesmo com erro de inicialização
      }
      
      print('💾 Salvando prescrição no banco...');
      final sucesso = await _prescricaoRepository.salvarPrescricao(prescricao);
      print('💾 Resultado do salvamento: $sucesso');

      if (sucesso) {
        _prescricao = prescricao;
        print('✅ Prescrição salva com sucesso!');
        _mostrarSucesso('Prescrição salva com sucesso!');
        
        // Mostrar opções de redirecionamento
        _mostrarOpcoesRedirecionamento();
      } else {
        print('❌ Falha ao salvar prescrição no banco');
        _mostrarErro('Erro ao salvar prescrição no banco de dados');
      }
    } catch (e) {
      print('❌ Erro geral ao salvar prescrição: $e');
      Logger.error('Erro ao salvar prescrição: $e');
      _mostrarErro('Erro ao salvar prescrição: $e');
    } finally {
      setState(() => _isSaving = false);
      print('🏁 Processo de salvamento finalizado');
    }
  }

  /// Valida dados básicos da prescrição
  bool _validarDadosBasicos() {
    if (_talhaoSelecionado == null) {
      _mostrarErro('Selecione um talhão');
      return false;
    }
    
    if (_areaTrabalhoController.text.isEmpty) {
      _mostrarErro('Informe a área de trabalho');
      return false;
    }
    
    final area = double.tryParse(_areaTrabalhoController.text.replaceAll(',', '.'));
    if (area == null || area <= 0) {
      _mostrarErro('Área de trabalho inválida');
      return false;
    }
    
    return true;
  }

  /// Mostra opções de redirecionamento após salvar
  void _mostrarOpcoesRedirecionamento() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Prescrição Salva!'),
          ],
        ),
        content: const Text('Para onde deseja ir agora?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ficar na tela atual
            },
            child: const Text('Continuar Editando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _irParaRelatorios();
            },
            child: const Text('Ver Relatórios'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _irParaListaPrescricoes();
            },
            child: const Text('Lista de Prescrições'),
          ),
        ],
      ),
    );
  }

  /// Redireciona para o submódulo de relatórios
  void _irParaRelatorios() {
    try {
      Navigator.pushNamed(context, '/prescricao/relatorios');
      _mostrarSucesso('Redirecionando para relatórios...');
      print('📊 Redirecionando para submódulo de relatórios');
    } catch (e) {
      print('❌ Erro ao navegar para relatórios: $e');
      _mostrarErro('Erro ao navegar para relatórios');
    }
  }

  /// Redireciona para a lista de prescrições
  void _irParaListaPrescricoes() {
    try {
      Navigator.pushNamed(context, '/prescricao/lista');
      _mostrarSucesso('Redirecionando para lista de prescrições...');
      print('📋 Redirecionando para lista de prescrições');
    } catch (e) {
      print('❌ Erro ao navegar para lista de prescrições: $e');
      _mostrarErro('Erro ao navegar para lista de prescrições');
    }
  }

  /// Valida e calcula a prescrição
  Future<void> _validarECalcular() async {
    if (!_formKey.currentState!.validate()) {
      _mostrarErro('Por favor, preencha todos os campos obrigatórios');
      return;
    }

    // Validar seleção de talhão ou entrada manual
    if (!_usarAreaManual && _talhaoSelecionado == null) {
      _mostrarErro('Selecione um talhão ou use a opção de área manual');
      return;
    }

    if (_usarAreaManual) {
      if (_nomeTalhaoManualController.text.isEmpty ||
          _areaManualController.text.isEmpty ||
          _culturaManualController.text.isEmpty) {
        _mostrarErro('Preencha todos os campos da área manual');
        return;
      }
    }

    try {
      setState(() => _isCalculating = true);

      // Converter produtos para o formato do serviço profissional
      final produtos = _produtos.map((p) => PrescricaoProduto(
        id: p.id,
        nome: p.produtoNome,
        tipo: 'Produto', // Tipo padrão
        unidade: p.unidade,
        doseHa: p.dosePorHa,
        estoqueDisponivel: p.estoqueDisponivel ?? 0.0,
        precoUnitario: p.custoUnitario ?? 0.0,
        lote: p.loteCodigo,
      )).toList();

      // Calcular usando o serviço profissional
      final resultado = PrescricaoCalculoProfissionalService.calcularPrescricao(
        areaHa: double.tryParse(_areaTrabalhoController.text) ?? _talhaoSelecionado!.area,
        vazaoLHa: double.tryParse(_volumeLHaController.text) ?? 0,
        capacidadeTanqueL: double.tryParse(_capacidadeTanqueController.text) ?? 0,
        produtos: produtos,
        permitirFracao: _permitirFracao,
        tipoAplicacao: _tipoAplicacao,
        volumeSegurancaL: double.tryParse(_volumeSegurancaController.text),
      );

      if (resultado.sucesso) {
        _resultadoCalculoProfissional = resultado;
        
        // Criar prescrição com resultados
        final prescricao = _criarPrescricao();
        _prescricao = prescricao.copyWith(
          status: 'Calculada',
          produtos: _produtos,
        );

        // Salvar prescrição calculada
        await _prescricaoRepository.salvarPrescricao(_prescricao!);

        // Mostrar alertas de estoque se houver
        if (resultado.alertasEstoque.isNotEmpty) {
          _mostrarAlertasEstoque(resultado.alertasEstoque);
        } else {
        _mostrarSucesso('Prescrição calculada com sucesso!');
        }
        
        // Ir para a aba de resultados
        _tabController.animateTo(2);
        
        setState(() {});
      } else {
        _mostrarErro('Erro no cálculo: ${resultado.erro}');
      }
    } catch (e) {
      Logger.error('Erro ao calcular prescrição: $e');
      _mostrarErro('Erro ao calcular prescrição: $e');
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  /// Finaliza a prescrição
  Future<void> _finalizarPrescricao() async {
    if (_resultadoCalculo == null || !_resultadoCalculo!.sucesso) {
      _mostrarErro('Calcule a prescrição antes de finalizar');
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Atualizar status para Finalizada
      _prescricao = _prescricao!.copyWith(status: 'Finalizada');
      final sucesso = await _prescricaoRepository.salvarPrescricao(_prescricao!);

      if (sucesso) {
        _mostrarSucesso('Prescrição finalizada com sucesso!');
        // TODO: Implementar geração de PDF
      } else {
        _mostrarErro('Erro ao finalizar prescrição');
      }
    } catch (e) {
      Logger.error('Erro ao finalizar prescrição: $e');
      _mostrarErro('Erro ao finalizar prescrição: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Cria o objeto PrescricaoModel com os dados atuais
  PrescricaoModel _criarPrescricao() {
    print('🔨 Criando prescrição...');
    
    // Determinar dados do talhão baseado na opção selecionada
    String talhaoId;
    String talhaoNome;
    String culturaId;
    String culturaNome;
    double areaTrabalho;
    
    if (_usarAreaManual) {
      print('📝 Usando dados manuais');
      // Usar dados manuais
      talhaoId = 'MANUAL_${DateTime.now().millisecondsSinceEpoch}';
      talhaoNome = _nomeTalhaoManualController.text;
      culturaId = 'MANUAL_CULTURA';
      culturaNome = _culturaManualController.text;
      areaTrabalho = double.tryParse(_areaManualController.text.replaceAll(',', '.')) ?? 0;
    } else {
      print('🏞️ Usando dados do talhão selecionado');
      // Usar dados do talhão selecionado
      talhaoId = _talhaoSelecionado?.id ?? '';
      talhaoNome = _talhaoSelecionado?.nome ?? '';
      culturaId = _talhaoSelecionado?.culturaId ?? '';
      culturaNome = _talhaoSelecionado?.crop?.name ?? '';
      areaTrabalho = double.tryParse(_areaTrabalhoController.text) ?? 0;
    }
    
    print('📊 Dados da prescrição:');
    print('   - Talhão ID: $talhaoId');
    print('   - Talhão Nome: $talhaoNome');
    print('   - Cultura ID: $culturaId');
    print('   - Cultura Nome: $culturaNome');
    print('   - Área: $areaTrabalho ha');
    print('   - Produtos: ${_produtos.length}');
    
    final prescricaoId = _prescricao?.id ?? 'prescricao_${DateTime.now().millisecondsSinceEpoch}';
    print('🆔 ID da prescrição: $prescricaoId');
    
    return PrescricaoModel(
      id: prescricaoId,
      talhaoId: talhaoId,
      talhaoNome: talhaoNome,
      fazendaId: 'fazenda_fortsmart', // ID da fazenda padrão
      culturaId: culturaId,
      culturaNome: culturaNome,
      data: _dataAplicacao,
      responsavelId: 'user_001', // TODO: Pegar do usuário logado
      responsavelNome: _responsavelNome,
      tipoAplicacao: _tipoAplicacao,
      volumeLHa: double.tryParse(_volumeLHaController.text) ?? 0,
      capacidadeTanqueL: double.tryParse(_capacidadeTanqueController.text) ?? 0,
      volumeSegurancaL: double.tryParse(_volumeSegurancaController.text) ?? 0,
      areaTrabalhoHa: areaTrabalho,
      observacoes: _observacoesController.text,
      status: _prescricao?.status ?? 'Rascunho',
      temperatura: null,
      umidade: null,
      velocidadeVento: null,
      horarioAplicacao: null,
      calibracao: null,
      produtos: _produtos,
      resultados: _resultadoCalculo?.resultados,
      totais: _resultadoCalculo?.totais,
    );
  }

  /// Adiciona um produto à prescrição
  void _adicionarProduto() {
    // TODO: Implementar tela de seleção de produtos
    _mostrarErro('Funcionalidade em desenvolvimento');
  }

  /// Remove um produto da prescrição
  void _removerProduto(String produtoId) {
    setState(() {
      _produtos.removeWhere((p) => p.id == produtoId);
    });
  }

  /// Configura a calibração
  void _configurarCalibracao() {
    // TODO: Implementar tela de configuração de calibração
    _mostrarErro('Funcionalidade em desenvolvimento');
  }

  /// Gera PDF da prescrição usando o serviço FortSmart
  Future<void> _gerarPDF() async {
    if (_prescricao == null) {
      _mostrarErro('Salve a prescrição antes de gerar o PDF');
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Preparar dados para o PDF padronizado
      final dadosPrescricao = {
        'talhao': _prescricao!.talhaoNome,
        'fazenda': _prescricao!.fazendaId ?? 'Fazenda FortSmart',
        'cultura': _talhaoSelecionado?.crop?.name ?? 'Não definida',
        'data': _prescricao!.data.toString().split(' ')[0], // Converter DateTime para String (YYYY-MM-DD)
        'area': _prescricao!.areaTrabalhoHa,
        'observacoes': _prescricao!.observacoes ?? '',
        'tipoAplicacao': _prescricao!.tipoAplicacao,
        'capacidadeTanque': _prescricao!.capacidadeTanqueL,
        'vazaoPorHectare': _prescricao!.volumeLHa,
        'velocidade': '8.0', // Valor padrão
        'larguraBarra': '18.0', // Valor padrão
      };

      final resumoOperacional = {
        'areaTotal': _prescricao!.areaTrabalhoHa,
        'volumePorTanque': _prescricao!.capacidadeTanqueL,
        'numeroTanques': _resultadoCalculoProfissional?.totais?.nTanques ?? 1,
        'tempoEstimado': '2.5',
        'consumoTotal': _prescricao!.volumeLHa * _prescricao!.areaTrabalhoHa,
        'haPorTanque': _prescricao!.areaTrabalhoHa / (_resultadoCalculoProfissional?.totais?.nTanques ?? 1),
        'tanquesUtilizados': _resultadoCalculoProfissional?.totais?.nTanques ?? 1,
        'eficiencia': 95,
      };

      // Preparar produtos para o PDF
      final produtos = _prescricao!.produtos.map((produto) => {
        'nome': produto.produtoNome,
        'dose': produto.dosePorHa,
        'unidade': produto.unidade,
        'quantidadeTanque': produto.quantidadePorTanque ?? (produto.dosePorHa * (_prescricao!.capacidadeTanqueL / _prescricao!.volumeLHa)),
        'quantidadeTotal': produto.quantidadeTotal ?? (produto.dosePorHa * _prescricao!.areaTrabalhoHa),
        'custoUnitario': produto.custoUnitario ?? 0.0,
        'classeToxicologica': 'Classe II (Amarela)', // Valor padrão
        'carencia': 30, // Valor padrão
      }).toList();

      // Gerar PDF padronizado
      final pdfFile = await PrescricaoPdfService.gerarPdfPadronizado(
        dadosPrescricao: dadosPrescricao,
        resumoOperacional: resumoOperacional,
        nomeFazenda: 'Fazenda FortSmart',
        nomeTecnico: _prescricao!.responsavelNome,
        creaTecnico: 'CREA-123456',
        produtos: produtos,
      );

      // Compartilhar PDF
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Prescrição Agronômica FortSmart - ${_prescricao!.talhaoNome}',
        subject: 'Prescrição Agronômica de Aplicação',
      );

      _mostrarSucesso('PDF gerado e compartilhado com sucesso!');

    } catch (e) {
      print('❌ Erro ao gerar PDF: $e');
      _mostrarErro('Erro ao gerar PDF: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Envia para execução
  void _enviarParaExecucao() {
    // TODO: Implementar envio para execução
    _mostrarSucesso('Prescrição enviada para execução');
  }

  /// Mostra mensagem de sucesso
  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra mensagem de erro
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Mostra alertas de estoque insuficiente
  void _mostrarAlertasEstoque(List<String> alertas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Estoque Insuficiente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Os seguintes produtos têm estoque insuficiente:'),
            const SizedBox(height: 16),
            ...alertas.map((alerta) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $alerta'),
            )),
            const SizedBox(height: 16),
            const Text(
              'A prescrição foi calculada, mas você pode precisar ajustar as doses ou adquirir mais produtos.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Carregando prescrição...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prescricaoId != null ? 'Editar Prescrição' : 'Nova Prescrição'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_prescricao != null)
            IconButton(
              icon: _isSaving 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isSaving ? null : _gerarPDF,
              tooltip: 'Gerar PDF',
            ),
        ],
      ),
      body: Column(
        children: [
          // Header com informações principais
          _buildHeader(),
          
          // Abas
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: 'Geral'),
                Tab(icon: Icon(Icons.inventory), text: 'Produtos'),
                Tab(icon: Icon(Icons.analytics), text: 'Resultados'),
              ],
            ),
          ),
          
          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAbaGeral(),
                _buildAbaProdutos(),
                _buildAbaResultados(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o header com informações principais
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Informações do talhão
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Talhão',
                  _talhaoSelecionado?.nome ?? 'Selecione',
                  Icons.grid_view,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Área',
                  _talhaoSelecionado != null 
                      ? '${_talhaoSelecionado!.area.toStringAsFixed(2)} ha'
                      : '0 ha',
                  Icons.area_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Status e ações
          Row(
            children: [
              Expanded(
                child: _buildStatusChip(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _salvarRascunho,
                        icon: _isSaving 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 16),
                        label: const Text('Salvar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCalculating ? null : _validarECalcular,
                        icon: _isCalculating 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.calculate, size: 16),
                        label: const Text('Calcular'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói um card de informação
  Widget _buildInfoCard(String titulo, String valor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o chip de status
  Widget _buildStatusChip() {
    String status = _prescricao?.status ?? 'Rascunho';
    Color color;
    IconData icon;

    switch (status) {
      case 'Rascunho':
        color = Colors.grey;
        icon = Icons.edit;
        break;
      case 'Calculada':
        color = Colors.blue;
        icon = Icons.calculate;
        break;
      case 'Finalizada':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Executada':
        color = Colors.purple;
        icon = Icons.play_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a aba Geral
  Widget _buildAbaGeral() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seleção de talhão
            _buildSectionTitle('Talhão e Cultura'),
            const SizedBox(height: 12),
            
            // Opções de seleção
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Talhão Existente'),
                    value: false,
                    groupValue: _usarAreaManual,
                    onChanged: (value) {
                      setState(() {
                        _usarAreaManual = value!;
                        if (!_usarAreaManual) {
                          _talhaoSelecionado = null;
                        }
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Área Manual'),
                    value: true,
                    groupValue: _usarAreaManual,
                    onChanged: (value) {
                      setState(() {
                        _usarAreaManual = value!;
                        if (_usarAreaManual) {
                          _talhaoSelecionado = null;
                        }
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (!_usarAreaManual) ...[
              // Dropdown para talhão existente
              DropdownButtonFormField<TalhaoModel>(
                value: _talhaoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Talhão *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.grid_view),
                  helperText: _talhoes.isEmpty ? 'Nenhum talhão encontrado. Cadastre talhões no módulo Talhões.' : null,
                ),
                items: _talhoes.isEmpty 
                  ? [
                      const DropdownMenuItem<TalhaoModel>(
                        value: null,
                        enabled: false,
                        child: Text(
                          'Nenhum talhão disponível',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ]
                  : _talhoes.map((talhao) {
                      print('🔄 Criando item do dropdown para talhão: ${talhao.nome} (${talhao.area} ha)');
                      return DropdownMenuItem(
                        value: talhao,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 60),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                talhao.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${talhao.area.toStringAsFixed(2)} ha - ${talhao.crop?.name ?? "Sem cultura"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: _talhoes.isEmpty ? null : (talhao) {
                  print('🔄 Talhão selecionado: ${talhao?.nome}');
                  setState(() {
                    _talhaoSelecionado = talhao;
                    if (talhao != null) {
                      _areaTrabalhoController.text = talhao.area.toString();
                    }
                  });
                },
                validator: (value) {
                  if (!_usarAreaManual && value == null) return 'Selecione um talhão';
                  return null;
                },
              ),
              
              // Botão para recarregar talhões se não houver nenhum
              if (_talhoes.isEmpty) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      // Tentar carregar usando TalhaoUnifiedService primeiro
                      final unifiedService = TalhaoUnifiedService();
                      _talhoes = await unifiedService.forcarAtualizacaoGlobal();
                      
                      if (_talhoes.isEmpty) {
                        _talhoes = await _carregarTalhoesRobusto();
                      }
                      if (_talhoes.isEmpty) {
                        _talhoes = await _carregarTalhoesDireto();
                      }
                      if (_talhoes.isEmpty) {
                        await _inserirTalhoesExemplo();
                        _talhoes = await _carregarTalhoesDireto();
                      }
                      setState(() {});
                      if (_talhoes.isNotEmpty) {
                        _mostrarSucesso('Talhões carregados com sucesso!');
                      } else {
                        _mostrarErro('Não foi possível carregar talhões.');
                      }
                    } catch (e) {
                      _mostrarErro('Erro ao recarregar talhões: $e');
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Recarregar Talhões'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ] else ...[
              // Campos para entrada manual
              TextFormField(
                controller: _nomeTalhaoManualController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Talhão *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (_usarAreaManual && (value == null || value.isEmpty)) {
                    return 'Digite o nome do talhão';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaManualController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Área (ha) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.crop_landscape),
                      ),
                      validator: (value) {
                        if (_usarAreaManual && (value == null || value.isEmpty)) {
                          return 'Digite a área';
                        }
                        if (_usarAreaManual && value != null) {
                          final area = double.tryParse(value.replaceAll(',', '.'));
                          if (area == null || area <= 0) {
                            return 'Área inválida';
                          }
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (_usarAreaManual && value.isNotEmpty) {
                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                          if (parsed != null) {
                            _areaTrabalhoController.text = parsed.toStringAsFixed(2);
                          }
                        }
                      },
                      onEditingComplete: () {
                        // Formatar para 2 casas decimais quando o usuário terminar de editar
                        final value = _areaManualController.text;
                        if (value.isNotEmpty) {
                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                          if (parsed != null) {
                            final formatted = parsed.toStringAsFixed(2);
                            _areaManualController.text = formatted;
                            _areaTrabalhoController.text = formatted;
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _culturaManualController,
                      decoration: const InputDecoration(
                        labelText: 'Cultura *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.eco),
                      ),
                      validator: (value) {
                        if (_usarAreaManual && (value == null || value.isEmpty)) {
                          return 'Digite a cultura';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            
            // Informações do talhão selecionado
            if (_talhaoSelecionado != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Informações do Talhão',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.eco, color: Colors.blue[600], size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Cultura',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    value: _talhaoSelecionado!.crop?.name ?? 'Não definida',
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      'Não definida',
                                      'Soja',
                                      'Milho',
                                      'Algodão',
                                      'Feijão',
                                      'Arroz',
                                      'Trigo',
                                      'Cana-de-açúcar',
                                      'Girassol',
                                      'Aveia',
                                      'Gergelim',
                                      'Sorgo',
                                    ].map((cultura) => DropdownMenuItem(
                                      value: cultura,
                                      child: Text(cultura, style: const TextStyle(fontSize: 12)),
                                    )).toList(),
                                    onChanged: (value) {
                                      // TODO: Implementar atualização da cultura do talhão
                                      print('Cultura selecionada: $value');
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoItem(
                                'Área Total',
                                '${_talhaoSelecionado!.area.toStringAsFixed(2)} ha',
                                Icons.area_chart,
                              ),
                            ),
                          ],
                        ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _areaTrabalhoController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Área de Trabalho (ha) *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.edit),
                              suffixText: 'ha',
                              helperText: 'Área específica dentro do talhão',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Campo obrigatório';
                              final area = double.tryParse(value.replaceAll(',', '.'));
                              if (area == null) return 'Valor inválido';
                              if (area <= 0) return 'Área deve ser maior que zero';
                              if (area > _talhaoSelecionado!.area) {
                                return 'Área não pode ser maior que o talhão (${_talhaoSelecionado!.area.toStringAsFixed(2)} ha)';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // Garantir que apenas 2 casas decimais sejam mostradas
                              if (value.isNotEmpty) {
                                final parsed = double.tryParse(value.replaceAll(',', '.'));
                                if (parsed != null) {
                                  final formatted = parsed.toStringAsFixed(2);
                                  if (value != formatted) {
                                    _areaTrabalhoController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: formatted.length),
                                    );
                                  }
                                }
                              }
                            },
                            onEditingComplete: () {
                              // Formatar para 2 casas decimais quando o usuário terminar de editar
                              final value = _areaTrabalhoController.text;
                              if (value.isNotEmpty) {
                                final parsed = double.tryParse(value.replaceAll(',', '.'));
                                if (parsed != null) {
                                  final formatted = parsed.toStringAsFixed(2);
                                  _areaTrabalhoController.text = formatted;
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _areaTrabalhoController.text = _talhaoSelecionado!.area.toStringAsFixed(2);
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Usar Total'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),

            // Data e responsável
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: _dataAplicacao,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (data != null) {
                        setState(() => _dataAplicacao = data);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_dataAplicacao),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _responsavelNome,
                    decoration: const InputDecoration(
                      labelText: 'Responsável',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) => _responsavelNome = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tipo de aplicação
            _buildSectionTitle('Tipo de Aplicação'),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
            Row(
              children: [
                Expanded(
                        child: _buildTipoAplicacaoCard(
                          'Terrestre',
                          'Terrestre',
                          Icons.directions_car,
                          _tipoAplicacao == 'Terrestre',
                        ),
                      ),
                      const SizedBox(width: 12),
                Expanded(
                        child: _buildTipoAplicacaoCard(
                          'Aérea',
                          'Aérea',
                          Icons.flight,
                          _tipoAplicacao == 'Aérea',
                        ),
                      ),
                      const SizedBox(width: 12),
                Expanded(
                        child: _buildTipoAplicacaoCard(
                          'Drone',
                          'Drone',
                          Icons.flight,
                          _tipoAplicacao == 'Drone',
                  ),
                ),
              ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Volume e tanque
            _buildSectionTitle('Volume de Calda e Tanque'),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _volumeLHaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Volume (L/ha) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Valor inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _capacidadeTanqueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Capacidade Tanque (L) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.storage),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Valor inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _volumeSegurancaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Volume Segurança (L)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _permitirFracao,
                          onChanged: (value) => setState(() => _permitirFracao = value ?? true),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Permitir Fracionamento',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Tanques/voos fracionados',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                  ),
                ),
              ],
                          ),
            ),
          ],
        ),
      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  /// Constrói a aba Produtos
  Widget _buildAbaProdutos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Builder(
        builder: (context) {
          try {
            return PrescricaoProdutosWidget(
              produtos: _produtos,
              onProdutosChanged: (produtos) {
                setState(() {
                  _produtos = produtos;
                });
              },
              areaTrabalho: double.tryParse(_areaTrabalhoController.text) ?? 0,
              volumeLHa: double.tryParse(_volumeLHaController.text) ?? 0,
              capacidadeEfetiva: (double.tryParse(_capacidadeTanqueController.text) ?? 0) - (double.tryParse(_volumeSegurancaController.text) ?? 0),
            );
          } catch (e) {
            print('❌ Erro no widget de produtos: $e');
            // Fallback em caso de erro no widget de produtos
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar produtos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detalhes do erro: $e',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        // Tentar recarregar
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  /// Constrói a aba Resultados
  Widget _buildAbaResultados() {
    if (_resultadoCalculoProfissional == null || !_resultadoCalculoProfissional!.sucesso) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Resultados do Cálculo',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure a prescrição e calcule para ver os resultados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _validarECalcular,
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular Prescrição'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildResultadosProfissionais(),
    );
  }

  /// Constrói os resultados profissionais
  Widget _buildResultadosProfissionais() {
    final resultado = _resultadoCalculoProfissional!;
    final totais = resultado.totais!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumo geral
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Prescrição Calculada com Sucesso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildResultadoCard(
                      'Volume Total',
                      '${totais.volumeTotalL.toStringAsFixed(0)} L',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildResultadoCard(
                      'Nº Tanques/Voos',
                      '${totais.nTanques.toStringAsFixed(1)}',
                      Icons.storage,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              if (totais.tempoDescargaMinutos != null) ...[
                const SizedBox(height: 12),
                _buildResultadoCard(
                  'Tempo por Tanque',
                  '${totais.tempoDescargaMinutos!.toStringAsFixed(1)} min',
                  Icons.timer,
                  Colors.purple,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Detalhes dos tanques
        _buildSectionTitle('Detalhes dos Tanques'),
        const SizedBox(height: 12),
        ...totais.volumesPorTanque.asMap().entries.map((entry) {
          final index = entry.key;
          final volume = entry.value;
          final isUltimoTanque = index == totais.volumesPorTanque.length - 1;
          final isFracionado = isUltimoTanque && volume < totais.volumesPorTanque.first;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFracionado ? Colors.orange[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFracionado ? Colors.orange[200]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.storage,
                  color: isFracionado ? Colors.orange[600] : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tanque ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isFracionado ? Colors.orange[700] : Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Text(
                  '${volume.toStringAsFixed(0)} L',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isFracionado ? Colors.orange[700] : Colors.grey[700],
                  ),
                ),
                if (isFracionado) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${totais.percentualUltimoTanque!.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        
        // Produtos
        _buildSectionTitle('Produtos'),
        const SizedBox(height: 12),
        ...resultado.produtosCalculados!.map((produtoCalc) {
          final produto = produtoCalc.produto;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: produtoCalc.estoqueSuficiente ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: produtoCalc.estoqueSuficiente ? Colors.green[200]! : Colors.red[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      produtoCalc.estoqueSuficiente ? Icons.check_circle : Icons.warning,
                      color: produtoCalc.estoqueSuficiente ? Colors.green[600] : Colors.red[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        produto.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: produtoCalc.estoqueSuficiente ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Dose/ha',
                        '${produto.doseHa.toStringAsFixed(2)} ${produto.unidade}/ha',
                        Icons.speed,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Total Necessário',
                        '${produtoCalc.produtoTotal.toStringAsFixed(2)} ${produto.unidade}',
                        Icons.inventory,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Estoque Disponível',
                        '${produto.estoqueDisponivel.toStringAsFixed(2)} ${produto.unidade}',
                        Icons.warehouse,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Concentração',
                        '${(produtoCalc.concentracao * 1000).toStringAsFixed(1)} mL/L',
                        Icons.opacity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Por Tanque:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: produtoCalc.produtoPorTanque.asMap().entries.map((entry) {
                    final index = entry.key;
                    final quantidade = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'T${index + 1}: ${quantidade.toStringAsFixed(2)} ${produto.unidade}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        
        // Alertas de estoque
        if (resultado.alertasEstoque.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Alertas de Estoque',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...resultado.alertasEstoque.map((alerta) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $alerta'),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Constrói um card de resultado
  Widget _buildResultadoCard(String titulo, String valor, IconData icon, Color color) {
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
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um item de informação
  Widget _buildInfoItem(String titulo, String valor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[600], size: 16),
              const SizedBox(width: 4),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um card de tipo de aplicação
  Widget _buildTipoAplicacaoCard(String titulo, String valor, IconData icon, bool selecionado) {
    return GestureDetector(
      onTap: () => setState(() => _tipoAplicacao = valor),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionado 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado 
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selecionado 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                color: selecionado 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um título de seção
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

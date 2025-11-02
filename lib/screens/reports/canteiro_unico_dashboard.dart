/// 🎯 Dashboard de Canteiro Elegante 7x3
/// UM canteiro com 21 posições físicas (7 colunas x 3 linhas)
/// Subtestes A, B, C em posições separadas
/// Design elegante com animações e gradientes
/// 100% Offline com Sistema FortSmart

import 'package:flutter/material.dart';
import '../../modules/tratamento_sementes/models/germination_test_model.dart';
import '../../modules/tratamento_sementes/repositories/germination_test_repository.dart';
import '../../services/fortsmart_agronomic_ai.dart';
import '../../services/germination_model_integration_service.dart';
import '../../widgets/germination_alerts_widget.dart';
import '../../widgets/elegant_canteiro_2d_widget.dart';
import '../../models/canteiro_model.dart';
import '../../utils/logger.dart';
import 'package:intl/intl.dart';

/// Dashboard de Canteiro Elegante 7x3
class CanteiroUnicoDashboard extends StatefulWidget {
  const CanteiroUnicoDashboard({Key? key}) : super(key: key);

  @override
  State<CanteiroUnicoDashboard> createState() => _CanteiroUnicoDashboardState();
}

class _CanteiroUnicoDashboardState extends State<CanteiroUnicoDashboard> {
  final GerminationTestRepository _repository = GerminationTestRepository();
  final GerminationModelIntegrationService _integrationService = GerminationModelIntegrationService();
  final FortSmartAgronomicAI _ai = FortSmartAgronomicAI();
  
  // Canteiro elegante
  CanteiroModel? _canteiro;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _loadCanteiro();
  }

  Future<void> _initializeAI() async {
    try {
      await _ai.initialize();
      Logger.info('✅ Sistema FortSmart inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar Sistema FortSmart: $e');
    }
  }

  Future<void> _loadCanteiro() async {
    setState(() => _isLoading = true);
    
    try {
      // Sincronizar testes entre sistemas
      await _integrationService.syncTests();
      
      // Buscar todos os testes
      final tests = await _integrationService.getTestsForCanteiro();
      
      // Criar canteiro elegante 7x3
      final posicoes = <CanteiroPosition>[];
      
      // Criar grid 7x3 - Mesa de xadrez
      for (int i = 0; i < 21; i++) {
        final linha = (i ~/ 7) + 1;
        final coluna = String.fromCharCode(65 + (i % 7));
        final posicao = '$coluna$linha';
        
        // Alternar cores como xadrez
        final isEven = (i ~/ 7 + i % 7) % 2 == 0;
        final corBase = isEven ? Colors.grey[100]! : Colors.grey[200]!;
        
        posicoes.add(CanteiroPosition(
          posicao: posicao,
          cor: corBase.value,
          germinadas: 0,
          total: 25,
          percentual: 0,
          dadosDiarios: {},
        ));
      }
      
      // Mapear testes para posições
      for (var test in tests) {
        // Buscar registros para obter dados atuais
        final registros = await _repository.buscarRegistrosPorTeste(test.id);
        final ultimoRegistro = registros.isNotEmpty 
            ? registros.reduce((a, b) => a.dia > b.dia ? a : b)
            : null;
        
        // Encontrar primeira posição vazia
        final posIndex = posicoes.indexWhere((p) => p.isEmpty);
        if (posIndex != -1) {
          posicoes[posIndex] = CanteiroPosition(
            posicao: posicoes[posIndex].posicao,
            loteId: test.loteId,
            subteste: 'A',
            cor: Colors.blue.value,
            germinadas: ultimoRegistro?.germinadas ?? 0,
            total: 25,
            percentual: ultimoRegistro?.percentualGerminacao ?? 0.0,
            cultura: test.cultura,
            dataInicio: test.dataInicio,
            dadosDiarios: {},
            test: test,
          );
        }
      }
      
      // Criar canteiro elegante
      _canteiro = CanteiroModel(
        id: 'canteiro_elegante_7x3',
        nome: 'Canteiro Elegante 7x3',
        loteId: 'principal',
        cultura: 'Múltiplas',
        variedade: 'Diversas',
        dataCriacao: DateTime.now(),
        status: 'ativo',
        posicoes: posicoes,
        dadosAgronomicos: {
          'total_posicoes': 21,
          'posicoes_ocupadas': posicoes.where((p) => !p.isEmpty).length,
          'media_germinacao': posicoes.where((p) => !p.isEmpty).isNotEmpty
              ? posicoes.where((p) => !p.isEmpty).map((p) => p.percentual).reduce((a, b) => a + b) / posicoes.where((p) => !p.isEmpty).length
              : 0.0,
        },
      );
      
      setState(() => _isLoading = false);
      
      Logger.info('✅ Canteiro elegante 7x3 carregado: ${posicoes.where((p) => !p.isEmpty).length} posições ocupadas');
    } catch (e) {
      Logger.error('❌ Erro ao carregar canteiro elegante: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '📊 Canteiro Elegante 7x3',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCanteiro,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildElegantCanteiro(),
    );
  }

  Widget _buildElegantCanteiro() {
    if (_canteiro == null) {
      return const Center(
        child: Text(
          'Nenhum canteiro encontrado',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Alertas automáticos
          const GerminationAlertsWidget(),
          
          // Estatísticas do canteiro
          _buildStatsCard(),
          
          // Canteiro elegante 7x3
          Container(
            padding: const EdgeInsets.all(16),
            child: ElegantCanteiro2DWidget(
              canteiro: _canteiro,
              onPositionTap: _onPositionTap,
              onPositionLongPress: _onPositionLongPress,
              showGridLabels: true,
              interactive: true,
            ),
          ),
          
          // Espaço extra no final
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _canteiro!.estatisticas;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Estatísticas do Canteiro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  '${stats['totalPosicoes']}',
                  Colors.blue,
                ),
                _buildStatItem(
                  'Ocupadas',
                  '${stats['posicoesPreenchidas']}',
                  Colors.green,
                ),
                _buildStatItem(
                  'Vazias',
                  '${stats['posicoesVazias']}',
                  Colors.grey,
                ),
                _buildStatItem(
                  'Média',
                  '${(stats['mediaGerminacao'] as double).toStringAsFixed(1)}%',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Manipula clique em posição do canteiro
  void _onPositionTap(String position) {
    Logger.info('🎯 Clique na posição: $position');
    
    // Encontrar a posição no canteiro
    final posicao = _canteiro!.posicoes.firstWhere(
      (p) => p.posicao == position,
      orElse: () => _canteiro!.posicoes.first,
    );
    
    if (posicao.isEmpty) {
      // Posição vazia - criar novo teste
      _criarNovoTeste(position);
    } else {
      // Posição ocupada - navegar para registro diário
      _navegarParaRegistroDiario(posicao);
    }
  }

  /// Manipula long press em posição
  void _onPositionLongPress(String position) {
    Logger.info('🎯 Long press na posição: $position');
    
    // Mostrar opções da posição
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Posição $position',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _onPositionTap(position);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Informações'),
              onTap: () {
                Navigator.pop(context);
                _mostrarInformacoes(position);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Cria novo teste de germinação
  void _criarNovoTeste(String position) {
    Logger.info('📊 Criando novo teste na posição $position');
    
    Navigator.pushNamed(
      context,
      '/germination-test-create',
      arguments: {
        'posicao_canteiro': position,
        'canteiro_id': 'canteiro_elegante_7x3',
      },
    ).then((_) {
      _loadCanteiro(); // Recarregar após criar teste
    });
  }

  /// Navega para registro diário
  void _navegarParaRegistroDiario(CanteiroPosition position) {
    Logger.info('📊 Navegando para registro diário: ${position.posicao}');
    
    Navigator.pushNamed(
      context,
      '/germination-daily-record',
      arguments: {
        'test_id': position.test?.id,
        'subtest_id': position.subtestId,
        'posicao_canteiro': position.posicao,
        'subteste': position.subteste,
      },
    ).then((_) {
      _loadCanteiro(); // Recarregar após registro
    });
  }

  /// Mostra informações da posição
  void _mostrarInformacoes(String position) {
    final posicao = _canteiro!.posicoes.firstWhere(
      (p) => p.posicao == position,
      orElse: () => _canteiro!.posicoes.first,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Posição $position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (posicao.isEmpty) ...[
              const Text('Posição vazia'),
              const Text('Clique para adicionar um teste'),
            ] else ...[
              Text('Lote: ${posicao.loteId}'),
              Text('Cultura: ${posicao.cultura}'),
              Text('Subteste: ${posicao.subteste}'),
              Text('Germinadas: ${posicao.germinadas}/${posicao.total}'),
              Text('Percentual: ${posicao.percentual.toStringAsFixed(1)}%'),
              if (posicao.dataInicio != null)
                Text('Início: ${DateFormat('dd/MM/yyyy').format(posicao.dataInicio!)}'),
            ],
          ],
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
}
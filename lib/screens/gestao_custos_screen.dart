import 'package:flutter/material.dart';
import '../models/produto_estoque.dart';
import '../models/aplicacao.dart';
import '../services/gestao_custos_service.dart';
import '../database/daos/produto_estoque_dao.dart';
import '../database/daos/aplicacao_dao.dart';
import '../utils/logger.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../modules/cost_management/screens/cost_report_screen.dart';
import '../modules/cost_management/screens/new_application_screen.dart';

class GestaoCustosScreen extends StatefulWidget {
  const GestaoCustosScreen({Key? key}) : super(key: key);

  @override
  State<GestaoCustosScreen> createState() => _GestaoCustosScreenState();
}

class _GestaoCustosScreenState extends State<GestaoCustosScreen> {
  final GestaoCustosService _gestaoCustosService = GestaoCustosService();
  final ProdutoEstoqueDao _produtoDao = ProdutoEstoqueDao();
  final AplicacaoDao _aplicacaoDao = AplicacaoDao();

  bool _isLoading = true;
  String? _error;
  
  // Dados do dashboard
  Map<String, dynamic> _estatisticasEstoque = {};
  List<Map<String, dynamic>> _produtosMaisUtilizados = [];
  Map<String, dynamic> _alertasEstoque = {};
  double _custoTotalPeriodo = 0.0;
  int _totalAplicacoesPeriodo = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Logger.info('🔄 Carregando dados de gestão de custos...');

      // Carregar dados em paralelo
      final futures = await Future.wait([
        _produtoDao.obterEstatisticas(),
        _gestaoCustosService.obterProdutosMaisUtilizados(),
        _gestaoCustosService.obterAlertasEstoque(),
        _gestaoCustosService.calcularCustosPorPeriodo(
          dataInicio: DateTime.now().subtract(const Duration(days: 30)),
          dataFim: DateTime.now(),
        ),
      ]);

      setState(() {
        _estatisticasEstoque = futures[0] as Map<String, dynamic>;
        _produtosMaisUtilizados = futures[1] as List<Map<String, dynamic>>;
        _alertasEstoque = futures[2] as Map<String, dynamic>;
        
        final custosPeriodo = futures[3] as Map<String, dynamic>;
        _custoTotalPeriodo = custosPeriodo['custo_total_periodo'] as double? ?? 0.0;
        _totalAplicacoesPeriodo = custosPeriodo['total_aplicacoes'] as int? ?? 0;
        
        _isLoading = false;
      });

      Logger.info('✅ Dados carregados com sucesso!');
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gestão de Custos',
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _carregarDados,
                )
              : _buildContent(),

    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardCards(),
            const SizedBox(height: 24),
            _buildAlertasEstoque(),
            const SizedBox(height: 24),
            _buildProdutosMaisUtilizados(),
            const SizedBox(height: 24),
            _buildAcoesRapidas(),
            const SizedBox(height: 24),
            _buildAplicacoesRecentes(),
            const SizedBox(height: 100), // Espaço para FAB
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildCard(
          title: 'Custo Total (30d)',
          value: 'R\$ ${_custoTotalPeriodo.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        _buildCard(
          title: 'Aplicações (30d)',
          value: _totalAplicacoesPeriodo.toString(),
          icon: Icons.agriculture,
          color: Colors.blue,
        ),
        _buildCard(
          title: 'Produtos em Estoque',
          value: (_estatisticasEstoque['total_produtos'] ?? 0).toString(),
          icon: Icons.inventory,
          color: Colors.orange,
        ),
        _buildCard(
          title: 'Valor em Estoque',
          value: 'R\$ ${(_estatisticasEstoque['valor_total_estoque'] ?? 0.0).toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildAlertasEstoque() {
    final totalAlertas = _alertasEstoque['total_alertas'] ?? 0;
    
    if (totalAlertas == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Alertas de Estoque ($totalAlertas)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_alertasEstoque['estoque_baixo']?.isNotEmpty ?? false) ...[
              _buildAlertaItem(
                'Estoque Baixo',
                _alertasEstoque['estoque_baixo'].length.toString(),
                Colors.red,
              ),
            ],
            if (_alertasEstoque['proximos_vencimento']?.isNotEmpty ?? false) ...[
              _buildAlertaItem(
                'Próximos do Vencimento',
                _alertasEstoque['proximos_vencimento'].length.toString(),
                Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertaItem(String title, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(title),
          const Spacer(),
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutosMaisUtilizados() {
    if (_produtosMaisUtilizados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
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
            ...(_produtosMaisUtilizados.take(5).map((produto) => _buildProdutoItem(produto))),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutoItem(Map<String, dynamic> produto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto['nome_produto'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${produto['tipo_produto'] ?? ''} • ${produto['unidade'] ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${(produto['custo_total'] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${produto['total_aplicacoes'] ?? 0} aplicações',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcoesRapidas() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações Rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Relatório',
                    Icons.assessment,
                    Colors.green,
                    () => _mostrarRelatorio(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Nova Aplicação',
                    Icons.add_circle,
                    Colors.blue,
                    () => _mostrarNovaAplicacao(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }



  void _mostrarNovaAplicacao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewApplicationScreen(),
      ),
    );
  }

  void _mostrarRelatorio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CostReportScreen(),
      ),
    );
  }

  /// Constrói seção de aplicações recentes
  Widget _buildAplicacoesRecentes() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Aplicações Recentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navegar para lista completa de aplicações
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lista completa em desenvolvimento')),
                    );
                  },
                  child: const Text('Ver Todas'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAplicacoesLista(),
          ],
        ),
      ),
    );
  }

  /// Constrói lista de aplicações recentes
  Widget _buildAplicacoesLista() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _carregarAplicacoesRecentes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar aplicações: ${snapshot.error}',
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        }

        final aplicacoes = snapshot.data ?? [];

        if (aplicacoes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.agriculture,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma aplicação encontrada',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'As aplicações do módulo Prescrições Premium aparecerão aqui',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: aplicacoes.map((aplicacao) => _buildAplicacaoCard(aplicacao)).toList(),
        );
      },
    );
  }

  /// Carrega aplicações recentes do banco de dados
  Future<List<Map<String, dynamic>>> _carregarAplicacoesRecentes() async {
    try {
      // TODO: Implementar busca real de aplicações do módulo Prescrições Premium
      // Por enquanto, retorna dados simulados
      await Future.delayed(const Duration(seconds: 1)); // Simula carregamento
      
      return [
        {
          'id': '1',
          'tipo': 'Fungicida',
          'data': DateTime.now().subtract(const Duration(days: 2)),
          'talhao': 'Talhão A1',
          'area': 25.5,
          'custoTotal': 1250.75,
          'produtos': [
            {'nome': 'Mancozeb', 'dose': 2.5, 'unidade': 'kg/ha', 'custo': 850.50},
            {'nome': 'Adjuvante', 'dose': 0.5, 'unidade': 'L/ha', 'custo': 400.25},
          ],
          'responsavel': 'João Silva',
          'observacoes': 'Aplicação preventiva para controle de ferrugem',
        },
        {
          'id': '2',
          'tipo': 'Inseticida',
          'data': DateTime.now().subtract(const Duration(days: 5)),
          'talhao': 'Talhão B2',
          'area': 18.0,
          'custoTotal': 980.30,
          'produtos': [
            {'nome': 'Deltametrina', 'dose': 1.2, 'unidade': 'L/ha', 'custo': 650.20},
            {'nome': 'Adjuvante', 'dose': 0.3, 'unidade': 'L/ha', 'custo': 330.10},
          ],
          'responsavel': 'Maria Santos',
          'observacoes': 'Controle de lagartas do cartucho',
        },
      ];
    } catch (e) {
      Logger.error('❌ Erro ao carregar aplicações recentes: $e');
      return [];
    }
  }

  /// Constrói card de aplicação individual
  Widget _buildAplicacaoCard(Map<String, dynamic> aplicacao) {
    final data = aplicacao['data'] as DateTime;
    final produtos = aplicacao['produtos'] as List<Map<String, dynamic>>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTipoColor(aplicacao['tipo']),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                aplicacao['tipo'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aplicacao['talhao'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${aplicacao['area']} ha • ${_formatarData(data)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'R\$ ${aplicacao['custoTotal'].toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetalhesAplicacao(aplicacao),
                const SizedBox(height: 12),
                _buildProdutosAplicacao(produtos),
                if (aplicacao['observacoes'] != null && aplicacao['observacoes'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildObservacoes(aplicacao['observacoes']),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói detalhes da aplicação
  Widget _buildDetalhesAplicacao(Map<String, dynamic> aplicacao) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDetalheItem('Área', '${aplicacao['area']} ha', Icons.crop_square),
          ),
          Expanded(
            child: _buildDetalheItem('Responsável', aplicacao['responsavel'], Icons.person),
          ),
          Expanded(
            child: _buildDetalheItem('Custo/ha', 'R\$ ${(aplicacao['custoTotal'] / aplicacao['area']).toStringAsFixed(2)}', Icons.attach_money),
          ),
        ],
      ),
    );
  }

  /// Constrói item de detalhe
  Widget _buildDetalheItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Constrói lista de produtos da aplicação
  Widget _buildProdutosAplicacao(List<Map<String, dynamic>> produtos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produtos Utilizados',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...produtos.map((produto) => Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  produto['nome'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${produto['dose']} ${produto['unidade']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'R\$ ${produto['custo'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  /// Constrói observações da aplicação
  Widget _buildObservacoes(String observacoes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note, size: 16, color: Colors.amber[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              observacoes,
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtém cor baseada no tipo de aplicação
  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'fungicida':
        return Colors.blue;
      case 'inseticida':
        return Colors.red;
      case 'herbicida':
        return Colors.orange;
      case 'fertilizante':
        return Colors.green;
      case 'adjuvante':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Formata data para exibição
  String _formatarData(DateTime data) {
    final now = DateTime.now();
    final difference = now.difference(data);
    
    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return 'Há ${difference.inDays} dias';
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }
}

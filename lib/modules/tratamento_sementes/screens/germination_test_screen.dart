import 'package:flutter/material.dart';
import '../models/germination_test_model.dart';
import '../repositories/germination_test_repository.dart';
import '../services/germination_ai_integration_service.dart';
import '../../utils/fortsmart_theme.dart';
import '../../utils/logger.dart';

/// Tela principal para gerenciar testes de germinação
class GerminationTestScreen extends StatefulWidget {
  const GerminationTestScreen({Key? key}) : super(key: key);

  @override
  State<GerminationTestScreen> createState() => _GerminationTestScreenState();
}

class _GerminationTestScreenState extends State<GerminationTestScreen> {
  final GerminationTestRepository _repository = GerminationTestRepository();
  final GerminationAIIntegrationService _aiService = GerminationAIIntegrationService();
  
  List<GerminationTestModel> _testes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filtroStatus = 'todos';

  @override
  void initState() {
    super.initState();
    _carregarTestes();
  }

  Future<void> _carregarTestes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<GerminationTestModel> testes;
      
      if (_filtroStatus == 'todos') {
        testes = await _repository.buscarTodosTestes();
      } else {
        testes = await _repository.buscarTestesPorStatus(_filtroStatus);
      }
      
      setState(() {
        _testes = testes;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('❌ Erro ao carregar testes: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar testes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testes de Germinação'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarTestes,
          ),
          PopupMenuButton<String>(
            onSelected: (status) {
              setState(() {
                _filtroStatus = status;
              });
              _carregarTestes();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'em_andamento',
                child: Text('Em Andamento'),
              ),
              const PopupMenuItem(
                value: 'concluido',
                child: Text('Concluídos'),
              ),
              const PopupMenuItem(
                value: 'cancelado',
                child: Text('Cancelados'),
              ),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _criarNovoTeste,
        backgroundColor: FortSmartTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarTestes,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_testes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum teste de germinação encontrado',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque no + para criar um novo teste',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _testes.length,
      itemBuilder: (context, index) {
        final teste = _testes[index];
        return _buildTesteCard(teste);
      },
    );
  }

  Widget _buildTesteCard(GerminationTestModel teste) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _abrirDetalhesTeste(teste),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lote: ${teste.loteId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${teste.cultura} - ${teste.variedade}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(teste.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Início: ${_formatarData(teste.dataInicio)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (teste.dataFim != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Fim: ${_formatarData(teste.dataFim!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (teste.percentualFinal != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Resultado: ${teste.percentualFinal!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoriaChip(teste.categoriaFinal ?? ''),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (teste.status == 'em_andamento') ...[
                    TextButton.icon(
                      onPressed: () => _abrirRegistroDiario(teste),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Registrar'),
                      style: TextButton.styleFrom(
                        foregroundColor: FortSmartTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: () => _abrirDetalhesTeste(teste),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver Detalhes'),
                    style: TextButton.styleFrom(
                      foregroundColor: FortSmartTheme.primaryColor,
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'em_andamento':
        color = Colors.orange;
        label = 'Em Andamento';
        break;
      case 'concluido':
        color = Colors.green;
        label = 'Concluído';
        break;
      case 'cancelado':
        color = Colors.red;
        label = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoriaChip(String categoria) {
    Color color;
    
    switch (categoria) {
      case 'Excelente':
        color = Colors.green;
        break;
      case 'Boa':
        color = Colors.blue;
        break;
      case 'Regular':
        color = Colors.orange;
        break;
      case 'Ruim':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        categoria,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  void _criarNovoTeste() {
    // TODO: Implementar navegação para tela de criação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
      ),
    );
  }

  void _abrirDetalhesTeste(GerminationTestModel teste) {
    // TODO: Implementar navegação para tela de detalhes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
      ),
    );
  }

  void _abrirRegistroDiario(GerminationTestModel teste) {
    // TODO: Implementar navegação para tela de registro diário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
      ),
    );
  }
}

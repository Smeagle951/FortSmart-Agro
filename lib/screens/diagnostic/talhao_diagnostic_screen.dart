import 'package:flutter/material.dart';
import '../../services/talhao_diagnostic_service.dart';
import '../../constants/app_colors.dart';

/// Tela de diagnóstico para problemas com talhões
class TalhaoDiagnosticScreen extends StatefulWidget {
  const TalhaoDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<TalhaoDiagnosticScreen> createState() => _TalhaoDiagnosticScreenState();
}

class _TalhaoDiagnosticScreenState extends State<TalhaoDiagnosticScreen> {
  final TalhaoDiagnosticService _diagnosticService = TalhaoDiagnosticService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _resultadoDiagnostico;

  @override
  void initState() {
    super.initState();
    _executarDiagnostico();
  }

  Future<void> _executarDiagnostico() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await _diagnosticService.executarDiagnostico();
      setState(() {
        _resultadoDiagnostico = resultado;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao executar diagnóstico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diagnóstico de Talhões',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0057A3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _executarDiagnostico,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar diagnóstico',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Executando diagnóstico...'),
                ],
              ),
            )
          : _resultadoDiagnostico != null
              ? _buildDiagnostico()
              : const Center(
                  child: Text('Nenhum resultado de diagnóstico disponível'),
                ),
    );
  }

  Widget _buildDiagnostico() {
    final resumo = _resultadoDiagnostico!['resumo'] as Map<String, dynamic>;
    final temTalhoes = resumo['tem_talhoes'] as bool;
    final totalTalhoes = resumo['total_talhoes'] as int;
    final fontesComDados = resumo['fontes_com_dados'] as List<String>;
    final problemas = resumo['problemas'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo geral
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        temTalhoes ? Icons.check_circle : Icons.error,
                        color: temTalhoes ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumo do Diagnóstico',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              temTalhoes 
                                  ? '$totalTalhoes talhão(ões) encontrado(s)'
                                  : 'Nenhum talhão encontrado',
                              style: TextStyle(
                                color: temTalhoes ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (fontesComDados.isNotEmpty) ...[
                    const Text(
                      'Fontes com dados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...fontesComDados.map((fonte) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(fonte),
                        ],
                      ),
                    )),
                  ],
                  
                  if (problemas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Problemas encontrados:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ...problemas.map((problema) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(problema)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Detalhes por fonte
          _buildDetalhesFonte('SQLite Repository', _resultadoDiagnostico!['sqlite']),
          const SizedBox(height: 12),
          _buildDetalhesFonte('Repository V2', _resultadoDiagnostico!['repository_v2']),
          const SizedBox(height: 12),
          _buildDetalhesFonte('Plot Repository', _resultadoDiagnostico!['plot_repository']),
          const SizedBox(height: 12),
          _buildDetalhesFonte('Database Direct', _resultadoDiagnostico!['database_direct']),
          
          const SizedBox(height: 24),
          
          // Ações
          if (!temTalhoes) ...[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ações Disponíveis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _criarTalhoesExemplo,
                            icon: const Icon(Icons.add),
                            label: const Text('Criar Talhões de Exemplo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _navegarParaTalhoes,
                            icon: const Icon(Icons.agriculture),
                            label: const Text('Ir para Talhões'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetalhesFonte(String titulo, Map<String, dynamic> dados) {
    final sucesso = dados['sucesso'] as bool;
    final quantidade = dados['quantidade'] as int;
    final erro = dados['erro'] as String?;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  sucesso ? Icons.check_circle : Icons.error,
                  color: sucesso ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '$quantidade talhão(ões)',
                  style: TextStyle(
                    color: sucesso ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (erro != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  erro,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            
            if (dados['talhoes'] != null && (dados['talhoes'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Talhões encontrados:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ...(dados['talhoes'] as List).take(3).map((talhao) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Text(
                  '• ${talhao['nome']} (${talhao['area']} ha)',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
              if ((dados['talhoes'] as List).length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '... e mais ${(dados['talhoes'] as List).length - 3} talhão(ões)',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _criarTalhoesExemplo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sucesso = await _diagnosticService.criarTalhoesExemplo();
      
      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Talhões de exemplo criados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _executarDiagnostico();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao criar talhões de exemplo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navegarParaTalhoes() {
    Navigator.pushNamed(context, '/talhoes');
  }
}

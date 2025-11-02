import 'package:flutter/material.dart';
import '../../database/models/historico_plantio_model.dart';
import '../../database/repositories/historico_plantio_repository.dart';
import '../../utils/fortsmart_theme.dart';
import '../../services/talhao_service.dart';

class HistoricoPlantioScreen extends StatefulWidget {
  final HistoricoPlantioRepository repository;
  final List<Map<String, String>> talhoes; // [{id, nome}]
  const HistoricoPlantioScreen({required this.repository, required this.talhoes, Key? key}) : super(key: key);
  @override
  State<HistoricoPlantioScreen> createState() => _HistoricoPlantioScreenState();
}

class _HistoricoPlantioScreenState extends State<HistoricoPlantioScreen> {
  String? _talhaoSelecionado;
  List<HistoricoPlantioModel> _historico = [];
  bool _loading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Inicializar o repositório quando a tela for carregada
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    try {
      setState(() => _loading = true);
      // Aguardar a inicialização do banco de dados
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isInitialized = true;
      });
      
      // CARREGAR AUTOMATICAMENTE TODOS OS HISTÓRICOS
      await _buscarHistorico();
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao inicializar: $e')),
        );
      }
    }
  }

  Future<void> _buscarHistorico() async {
    if (!_isInitialized) return;
    
    try {
      setState(() => _loading = true);
      
      List<HistoricoPlantioModel> result;
      
      if (_talhaoSelecionado == null) {
        // Buscar TODOS os históricos
        print('🔍 DEBUG: Buscando TODOS os históricos...');
        result = await widget.repository.listarTodos();
        print('✅ DEBUG: ${result.length} históricos encontrados');
      } else {
        // Buscar por talhão específico
        print('🔍 DEBUG: Buscando históricos do talhão: $_talhaoSelecionado');
        result = await widget.repository.listarPorTalhao(_talhaoSelecionado!);
        print('✅ DEBUG: ${result.length} históricos encontrados para o talhão');
      }
      
      // Enriquecer com nomes de talhões
      result = await _enriquecerComNomesTalhoes(result);
      
      setState(() {
        _historico = result;
        _loading = false;
      });
    } catch (e) {
      print('❌ DEBUG: Erro ao buscar histórico: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar histórico: $e')),
        );
      }
    }
  }

  /// Enriquece os históricos com os nomes dos talhões
  Future<List<HistoricoPlantioModel>> _enriquecerComNomesTalhoes(List<HistoricoPlantioModel> historicos) async {
    final List<HistoricoPlantioModel> resultado = [];
    final talhaoService = TalhaoService();
    
    print('🔍 DEBUG ENRIQUECIMENTO: Iniciando enriquecimento de ${historicos.length} históricos');
    print('🔍 DEBUG WIDGET.TALHOES: ${widget.talhoes.length} talhões na lista do widget');
    
    for (final hist in historicos) {
      // Se já tem nome, manter
      if (hist.talhaoNome != null && hist.talhaoNome!.isNotEmpty) {
        print('✅ Histórico ${hist.id} já tem nome: ${hist.talhaoNome}');
        resultado.add(hist);
        continue;
      }
      
      print('🔍 Buscando nome para talhão ID: ${hist.talhaoId}');
      
      // Buscar nome diretamente do TalhaoService
      String? nomeTalhao;
      try {
        final talhao = await talhaoService.obterPorId(hist.talhaoId);
        if (talhao != null) {
          nomeTalhao = talhao.name;
          print('✅ Nome encontrado no TalhaoService: $nomeTalhao');
        } else {
          print('⚠️ Talhão não encontrado no TalhaoService');
        }
      } catch (e) {
        print('❌ Erro ao buscar talhão: $e');
      }
      
      // Fallback: tentar na lista do widget
      if (nomeTalhao == null || nomeTalhao.isEmpty) {
        final talhaoWidget = widget.talhoes.where((t) => t['id'] == hist.talhaoId).firstOrNull;
        if (talhaoWidget != null) {
          nomeTalhao = talhaoWidget['nome'];
          print('✅ Nome encontrado no widget: $nomeTalhao');
        }
      }
      
      // Criar cópia com nome atualizado
      final historicoAtualizado = HistoricoPlantioModel(
        id: hist.id,
        calculoId: hist.calculoId,
        talhaoId: hist.talhaoId,
        talhaoNome: nomeTalhao, // Nome do talhão (pode ser null se não encontrado)
        safraId: hist.safraId,
        culturaId: hist.culturaId,
        tipo: hist.tipo,
        data: hist.data,
        resumo: hist.resumo,
        createdAt: hist.createdAt,
        updatedAt: hist.updatedAt,
      );
      
      resultado.add(historicoAtualizado);
      print('📝 Histórico atualizado com nome: ${nomeTalhao ?? "null"}');
    }
    
    print('✅ ENRIQUECIMENTO COMPLETO: ${resultado.length} históricos processados');
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Plantio'),
        backgroundColor: FortSmartTheme.plantioAppBar,
      ),
      backgroundColor: FortSmartTheme.plantioBackground,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _talhaoSelecionado,
              decoration: FortSmartTheme.inputDecoration('Filtrar por Talhão'),
              items: widget.talhoes.map((t) => DropdownMenuItem(
                value: t['id'],
                child: Text(t['nome'] ?? ''),
              )).toList(),
              onChanged: (val) {
                setState(() => _talhaoSelecionado = val);
                _buscarHistorico();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _historico.isEmpty
                      ? const Center(child: Text('Nenhum histórico encontrado.'))
                      : ListView.builder(
                          itemCount: _historico.length,
                          itemBuilder: (context, idx) {
                            final hist = _historico[idx];
                            return _buildHistoricoCard(hist);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoricoCard(HistoricoPlantioModel hist) {
    // Parsear o resumo para extrair dados
    final resumoStr = hist.resumo;
    String cultura = '';
    String variedade = '';
    String dataPlantio = '';
    String observacao = '';
    
    try {
      // Parsear o resumo que está em formato {key: value, ...}
      // Remover chaves e processar
      String cleanResumo = resumoStr.replaceAll('{', '').replaceAll('}', '');
      
      // Dividir por vírgula e processar cada par key: value
      final parts = cleanResumo.split(',');
      
      for (final part in parts) {
        if (part.contains(':')) {
          final kv = part.split(':');
          if (kv.length >= 2) {
            final key = kv[0].trim();
            final value = kv.sublist(1).join(':').trim(); // Rejuntar caso tenha : no valor
            
            if (key == 'cultura') cultura = value;
            if (key == 'variedade') variedade = value;
            if (key == 'data_plantio') {
              try {
                final dt = DateTime.parse(value);
                dataPlantio = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
              } catch (_) {
                dataPlantio = value;
              }
            }
            // ❌ REMOVIDO: espacamento_cm e populacao_por_m (eram fictícios!)
            if (key == 'observacao' || key == 'observacoes') observacao = value;
            if (key == 'hectares') {} // Manter hectares se existir
          }
        }
      }
    } catch (e) {
      print('⚠️ Erro ao parsear resumo: $e');
    }
    
    // Formatar a data do histórico
    String dataHistorico = '';
    try {
      final dt = hist.data;
      dataHistorico = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      dataHistorico = hist.data.toString();
    }
    
    // Definir cor e ícone baseado no tipo
    Color corTipo = Colors.green;
    IconData iconeTipo = Icons.add_circle;
    String nomeTipo = hist.tipo.replaceAll('_', ' ').toUpperCase();
    
    if (hist.tipo.contains('novo')) {
      corTipo = Colors.green;
      iconeTipo = Icons.add_circle;
    } else if (hist.tipo.contains('atualizacao')) {
      corTipo = Colors.blue;
      iconeTipo = Icons.edit;
    } else if (hist.tipo.contains('calculo')) {
      corTipo = Colors.orange;
      iconeTipo = Icons.calculate;
    }
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Mostrar detalhes completos em diálogo
          _showDetalhesDialog(hist);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: corTipo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(iconeTipo, color: corTipo, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeTipo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: corTipo,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dataHistorico,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botões de ação
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'editar') {
                        _showEditDialog(hist);
                      } else if (value == 'excluir') {
                        _showDeleteConfirmDialog(hist);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'excluir',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Dados do plantio
              _buildInfoRow('Talhão', hist.talhaoNome ?? 'Talhão ${hist.talhaoId}', Icons.location_on),
              if (cultura.isNotEmpty) _buildInfoRow('Cultura', cultura, Icons.grass),
              if (variedade.isNotEmpty) _buildInfoRow('Variedade', variedade, Icons.eco),
              if (dataPlantio.isNotEmpty) _buildInfoRow('Data Plantio', dataPlantio, Icons.calendar_today),
              // ❌ População e Espaçamento REMOVIDOS - dados fictícios!
              // ✅ Dados REAIS estão no Estande de Plantas e Relatório Agronômico
              
              // Observação (se houver)
              if (observacao.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          observacao,
                          style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDetalhesDialog(HistoricoPlantioModel hist) {
    // Parsear o resumo
    String cultura = '';
    String variedade = '';
    String dataPlantio = '';
    String espacamento = '';
    String populacao = '';
    String observacao = '';
    
    try {
      String cleanResumo = hist.resumo.replaceAll('{', '').replaceAll('}', '');
      final parts = cleanResumo.split(',');
      
      for (final part in parts) {
        if (part.contains(':')) {
          final kv = part.split(':');
          if (kv.length >= 2) {
            final key = kv[0].trim();
            final value = kv.sublist(1).join(':').trim();
            
            if (key == 'cultura') cultura = value;
            if (key == 'variedade') variedade = value;
            if (key == 'data_plantio') {
              try {
                final dt = DateTime.parse(value);
                dataPlantio = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
              } catch (_) {
                dataPlantio = value;
              }
            }
            if (key == 'espacamento_cm') espacamento = value;
            if (key == 'populacao_por_m') populacao = value;
            if (key == 'observacao') observacao = value;
          }
        }
      }
    } catch (e) {
      print('⚠️ Erro ao parsear resumo: $e');
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Plantio'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Informações principais
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cultura.isNotEmpty) _buildDetalheItem('🌱 Cultura', cultura),
                    if (variedade.isNotEmpty) _buildDetalheItem('🌾 Variedade', variedade),
                    if (dataPlantio.isNotEmpty) _buildDetalheItem('📅 Data Plantio', dataPlantio),
                    // ❌ População e Espaçamento REMOVIDOS - eram dados fictícios!
                    const SizedBox(height: 8),
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
                              'População e Espaçamento reais estão disponíveis no Estande de Plantas',
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
              
              const SizedBox(height: 16),
              
              // Observações
              if (observacao.isNotEmpty) ...[
                const Text('Observações:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    observacao,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Informações técnicas
              const Divider(),
              const Text('Informações Técnicas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildDetalheItemSmall('ID do Plantio', hist.calculoId ?? 'N/A'),
              _buildDetalheItemSmall('Tipo', hist.tipo.replaceAll('_', ' ')),
              _buildDetalheItemSmall('Data de Registro', '${hist.data.day.toString().padLeft(2, '0')}/${hist.data.month.toString().padLeft(2, '0')}/${hist.data.year} ${hist.data.hour.toString().padLeft(2, '0')}:${hist.data.minute.toString().padLeft(2, '0')}'),
            ],
          ),
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
  
  Widget _buildDetalheItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetalheItemSmall(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black54, fontSize: 11),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
  
  void _showEditDialog(HistoricoPlantioModel hist) {
    final observacoesController = TextEditingController(text: hist.resumo);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Observações'),
        content: TextField(
          controller: observacoesController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Observações',
            border: OutlineInputBorder(),
            hintText: 'Digite as observações...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final historicoAtualizado = HistoricoPlantioModel(
                  id: hist.id,
                  calculoId: hist.calculoId,
                  talhaoId: hist.talhaoId,
                  talhaoNome: hist.talhaoNome,
                  safraId: hist.safraId,
                  culturaId: hist.culturaId,
                  tipo: hist.tipo,
                  data: hist.data,
                  resumo: observacoesController.text,
                );
                
                await widget.repository.atualizar(historicoAtualizado);
                
                Navigator.pop(context);
                await _buscarHistorico();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Histórico atualizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao atualizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmDialog(HistoricoPlantioModel hist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este registro do histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                if (hist.id != null) {
                  await widget.repository.excluir(hist.id!);
                  
                  Navigator.pop(context);
                  await _buscarHistorico();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Histórico excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  throw Exception('ID do histórico não encontrado');
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

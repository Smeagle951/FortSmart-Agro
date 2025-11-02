import 'package:flutter/material.dart';

import '../../models/subarea_model.dart';
import '../../services/subarea_service.dart';
import '../../utils/subarea_geodetic_service.dart';
import '../../widgets/fortsmart_app_bar.dart';
import '../../widgets/fortsmart_card.dart';
import '../../widgets/fortsmart_loading.dart';

/// Tela de detalhes de uma subárea
/// Segue o padrão visual do FortSmart Agro
class DetalhesSubareaScreen extends StatefulWidget {
  final SubareaModel subarea;
  final double talhaoAreaHa;

  const DetalhesSubareaScreen({
    super.key,
    required this.subarea,
    required this.talhaoAreaHa,
  });

  @override
  State<DetalhesSubareaScreen> createState() => _DetalhesSubareaScreenState();
}

class _DetalhesSubareaScreenState extends State<DetalhesSubareaScreen>
    with TickerProviderStateMixin {
  
  // Serviços
  final SubareaService _subareaService = SubareaService();
  
  // Estados
  bool _isLoading = false;
  
  // UI Controllers
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Exclui a subárea
  Future<void> _excluirSubarea() async {
    final confirmacao = await _mostrarDialogoConfirmacao(
      'Excluir Subárea',
      'Tem certeza que deseja excluir a subárea "${widget.subarea.nome}"?\n\nEsta ação não pode ser desfeita.',
    );

    if (confirmacao == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _subareaService.deleteSubarea(widget.subarea.id);
        
        // Verificar se o widget ainda está montado antes de navegar
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _mostrarMensagem('Erro ao excluir subárea: $e');
      }
    }
  }

  /// Mostra diálogo de confirmação
  Future<bool?> _mostrarDialogoConfirmacao(String titulo, String mensagem) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// Mostra mensagem de feedback
  void _mostrarMensagem(String mensagem, {bool isSuccess = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: FortSmartAppBar(
        title: widget.subarea.nome,
        subtitle: 'Detalhes da Subárea',
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'editar':
                  // TODO: Implementar edição
                  _mostrarMensagem('Edição será implementada na próxima versão');
                  break;
                case 'excluir':
                  _excluirSubarea();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excluir',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const FortSmartLoading()
          : Column(
              children: [
                // Header com informações principais
                _buildHeader(),
                
                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    tabs: const [
                      Tab(text: 'Informações'),
                      Tab(text: 'Métricas'),
                      Tab(text: 'Mapa'),
                    ],
                  ),
                ),
                
                // Conteúdo das tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInformacoesTab(),
                      _buildMetricasTab(),
                      _buildMapaTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Constrói header com informações principais
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: FortSmartCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Nome e cor
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.subarea.cor.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: widget.subarea.cor.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.subarea.ordem ?? 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subarea.nome,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.subarea.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.subarea.statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.subarea.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.subarea.statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Métricas principais
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderMetrica(
                      'Área',
                      SubareaGeodeticService.formatAreaBrazilian(widget.subarea.areaHa),
                      Icons.area_chart,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildHeaderMetrica(
                      'Percentual',
                      '${widget.subarea.calcularPercentualTalhao(widget.talhaoAreaHa).toStringAsFixed(1)}%',
                      Icons.pie_chart,
                      Colors.blue,
                    ),
                  ),
                  if (widget.subarea.dae != null)
                    Expanded(
                      child: _buildHeaderMetrica(
                        'DAE',
                        '${widget.subarea.dae} dias',
                        Icons.calendar_today,
                        Colors.orange,
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

  /// Constrói métrica do header
  Widget _buildHeaderMetrica(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Constrói tab de informações
  Widget _buildInformacoesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Informações básicas
          FortSmartCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações Básicas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Nome', widget.subarea.nome),
                  _buildInfoRow('ID', widget.subarea.id),
                  _buildInfoRow('Talhão', widget.subarea.talhaoId),
                  _buildInfoRow('Criada em', 
                      '${widget.subarea.criadoEm.day}/${widget.subarea.criadoEm.month}/${widget.subarea.criadoEm.year}'),
                  
                  if (widget.subarea.atualizadoEm != null)
                    _buildInfoRow('Atualizada em', 
                        '${widget.subarea.atualizadoEm!.day}/${widget.subarea.atualizadoEm!.month}/${widget.subarea.atualizadoEm!.year}'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informações agrícolas
          if (widget.subarea.cultura != null || 
              widget.subarea.variedade != null || 
              widget.subarea.populacao != null ||
              widget.subarea.dataInicio != null)
            FortSmartCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações Agrícolas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (widget.subarea.cultura != null)
                      _buildInfoRow('Cultura', widget.subarea.cultura!),
                    if (widget.subarea.variedade != null)
                      _buildInfoRow('Variedade', widget.subarea.variedade!),
                    if (widget.subarea.populacao != null)
                      _buildInfoRow('População', '${widget.subarea.populacao} pl/ha'),
                    if (widget.subarea.dataInicio != null)
                      _buildInfoRow('Data de Início', 
                          '${widget.subarea.dataInicio!.day}/${widget.subarea.dataInicio!.month}/${widget.subarea.dataInicio!.year}'),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Observações
          if (widget.subarea.observacoes != null && widget.subarea.observacoes!.isNotEmpty)
            FortSmartCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.subarea.observacoes!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói tab de métricas
  Widget _buildMetricasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Métricas geométricas
          FortSmartCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Métricas Geométricas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricaItem(
                          'Área',
                          SubareaGeodeticService.formatAreaBrazilian(widget.subarea.areaHa),
                          Icons.area_chart,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricaItem(
                          'Perímetro',
                          SubareaGeodeticService.formatPerimeterBrazilian(widget.subarea.perimetroM),
                          Icons.straighten,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricaItem(
                          'Percentual do Talhão',
                          '${widget.subarea.calcularPercentualTalhao(widget.talhaoAreaHa).toStringAsFixed(2)}%',
                          Icons.pie_chart,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricaItem(
                          'Centroide',
                          '${widget.subarea.centroide.latitude.toStringAsFixed(6)}, ${widget.subarea.centroide.longitude.toStringAsFixed(6)}',
                          Icons.location_on,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status e desenvolvimento
          FortSmartCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status e Desenvolvimento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatusItem('Status Atual', widget.subarea.status.label, widget.subarea.statusColor),
                  
                  if (widget.subarea.dae != null) ...[
                    const SizedBox(height: 12),
                    _buildStatusItem('DAE (Dias Após Emergência)', '${widget.subarea.dae} dias', 
                        _getDAEColor(widget.subarea.dae!)),
                  ],
                  
                  const SizedBox(height: 12),
                  _buildStatusItem('Em Desenvolvimento', 
                      widget.subarea.isEmDesenvolvimento ? 'Sim' : 'Não',
                      widget.subarea.isEmDesenvolvimento ? Colors.green : Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informações do polígono
          FortSmartCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações do Polígono',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Número de Vértices', '${widget.subarea.pontos.length}'),
                  _buildInfoRow('Cor', widget.subarea.cor.nome),
                  _buildInfoRow('Ativa', widget.subarea.ativa ? 'Sim' : 'Não'),
                  
                  if (widget.subarea.ordem != null)
                    _buildInfoRow('Ordem', '${widget.subarea.ordem}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói tab do mapa
  Widget _buildMapaTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: FortSmartCard(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Localização da Subárea',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Text(
                    'Mapa será implementado\nna próxima versão',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói item de métrica
  Widget _buildMetricaItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Constrói item de status
  Widget _buildStatusItem(String label, String value, Color color) {
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Retorna cor baseada no DAE
  Color _getDAEColor(int dae) {
    if (dae < 30) return Colors.blue;
    if (dae < 60) return Colors.green;
    if (dae < 90) return Colors.orange;
    if (dae < 120) return Colors.amber;
    return Colors.red;
  }
}

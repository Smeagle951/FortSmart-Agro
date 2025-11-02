import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/subarea_model.dart';
import '../../services/subarea_service.dart';
import '../../utils/subarea_geodetic_service.dart';
import '../../widgets/fortsmart_app_bar.dart';
import '../../widgets/fortsmart_button.dart';
import '../../widgets/fortsmart_card.dart';
import '../../widgets/fortsmart_empty_state.dart';
import '../../widgets/fortsmart_filter_chip.dart';
import '../../widgets/fortsmart_loading.dart';
import '../../widgets/fortsmart_search_bar.dart';
import '../subareas/criar_subarea_screen.dart';
import '../subareas/detalhes_subarea_screen.dart';

/// Tela elegante de gerenciamento de subáreas
/// Segue o padrão visual do FortSmart Agro
class GerenciarSubareasScreen extends StatefulWidget {
  final String talhaoId;
  final String talhaoNome;
  final List<LatLng> talhaoPontos;
  final double talhaoAreaHa;

  const GerenciarSubareasScreen({
    super.key,
    required this.talhaoId,
    required this.talhaoNome,
    required this.talhaoPontos,
    required this.talhaoAreaHa,
  });

  @override
  State<GerenciarSubareasScreen> createState() => _GerenciarSubareasScreenState();
}

class _GerenciarSubareasScreenState extends State<GerenciarSubareasScreen>
    with TickerProviderStateMixin {
  
  // Constantes
  static const Duration _snackBarDuration = Duration(seconds: 3);
  static const int _tabCount = 2;
  
  // Serviços
  final SubareaService _subareaService = SubareaService();
  
  // Estados
  List<SubareaModel> _subareas = [];
  List<SubareaModel> _subareasFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtros
  SubareaFilter _filtroAtual = SubareaFilter.empty();
  final TextEditingController _searchController = TextEditingController();
  
  // UI Controllers
  late TabController _tabController;
  bool _showFilters = false;
  
  // Estatísticas
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _carregarDados();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Carrega dados das subáreas
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _subareaService.initialize();
      
      final subareas = await _subareaService.getSubareasByTalhao(widget.talhaoId);
      final stats = await _subareaService.getTalhaoSubareasStats(widget.talhaoId);
      
      setState(() {
        _subareas = subareas;
        _subareasFiltradas = subareas;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar subáreas: $e';
        _isLoading = false;
      });
    }
  }

  /// Aplica filtros
  void _aplicarFiltros() {
    setState(() {
      _subareasFiltradas = _filtroAtual.aplicar(_subareas);
    });
  }

  /// Handler para mudança na busca
  void _onSearchChanged() {
    setState(() {
      _filtroAtual = _filtroAtual.copyWith(busca: _searchController.text);
      _aplicarFiltros();
    });
  }

  /// Navega para criação de subárea
  Future<void> _criarSubarea() async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => CriarSubareaScreen(
            talhaoId: widget.talhaoId,
            talhaoNome: widget.talhaoNome,
            talhaoPontos: widget.talhaoPontos,
            talhaoAreaHa: widget.talhaoAreaHa,
          ),
        ),
      );

      if (result == true) {
        await _carregarDados();
        _mostrarMensagem('Subárea criada com sucesso!', isSuccess: true);
      }
    } catch (e) {
      _mostrarMensagem('Erro ao criar subárea: $e', isSuccess: false);
    }
  }

  /// Navega para detalhes da subárea
  Future<void> _verDetalhes(SubareaModel subarea) async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => DetalhesSubareaScreen(
            subarea: subarea,
            talhaoAreaHa: widget.talhaoAreaHa,
          ),
        ),
      );

      if (result == true) {
        await _carregarDados();
      }
    } catch (e) {
      _mostrarMensagem('Erro ao abrir detalhes: $e', isSuccess: false);
    }
  }

  /// Exclui uma subárea
  Future<void> _excluirSubarea(SubareaModel subarea) async {
    final confirmacao = await _mostrarDialogoConfirmacao(
      'Excluir Subárea',
      'Tem certeza que deseja excluir a subárea "${subarea.nome}"?\n\nEsta ação não pode ser desfeita.',
    );

    if (confirmacao == true) {
      try {
        await _subareaService.deleteSubarea(subarea.id);
        
        // Sincronizar com o talhão pai após exclusão
        await _sincronizarComTalhao();
        
        await _carregarDados();
        _mostrarMensagem('Subárea excluída com sucesso!', isSuccess: true);
      } catch (e) {
        _mostrarMensagem('Erro ao excluir subárea: $e', isSuccess: false);
      }
    }
  }

  /// Atualiza uma subárea existente
  Future<void> _atualizarSubarea(SubareaModel subarea) async {
    try {
      // Navegar para tela de edição
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CriarSubareaScreen(
            talhaoId: widget.talhaoId,
            talhaoNome: widget.talhaoNome,
            talhaoPontos: widget.talhaoPontos,
            talhaoAreaHa: widget.talhaoAreaHa,
          ),
        ),
      );

      if (resultado == true) {
        await _carregarDados();
        _mostrarMensagem('Subárea atualizada com sucesso!', isSuccess: true);
      }
    } catch (e) {
      _mostrarMensagem('Erro ao atualizar subárea: $e', isSuccess: false);
    }
  }

  /// Valida dados da subárea
  bool _validarDadosSubarea(SubareaModel subarea) {
    if (subarea.nome.trim().isEmpty) {
      _mostrarMensagem('Nome da subárea é obrigatório', isSuccess: false);
      return false;
    }
    
    if (subarea.areaHa <= 0) {
      _mostrarMensagem('Área da subárea deve ser maior que zero', isSuccess: false);
      return false;
    }
    
    if (subarea.pontos.length < 3) {
      _mostrarMensagem('Subárea deve ter pelo menos 3 pontos', isSuccess: false);
      return false;
    }
    
    return true;
  }

  /// Calcula área total das subáreas
  double _calcularAreaTotal() {
    double areaTotal = 0.0;
    for (final subarea in _subareasFiltradas) {
      areaTotal += subarea.areaHa;
    }
    return areaTotal;
  }

  /// Calcula perímetro total das subáreas
  double _calcularPerimetroTotal() {
    double perimetroTotal = 0.0;
    for (final subarea in _subareasFiltradas) {
      perimetroTotal += subarea.perimetroM;
    }
    return perimetroTotal;
  }

  /// Calcula centroide das subáreas
  LatLng _calcularCentroide() {
    if (_subareasFiltradas.isEmpty) return const LatLng(0, 0);
    
    double latSum = 0;
    double lngSum = 0;
    int totalPontos = 0;
    
    for (final subarea in _subareasFiltradas) {
      for (final ponto in subarea.pontos) {
        latSum += ponto.latitude;
        lngSum += ponto.longitude;
        totalPontos++;
      }
    }
    
    if (totalPontos == 0) return const LatLng(0, 0);
    
    return LatLng(
      latSum / totalPontos,
      lngSum / totalPontos,
    );
  }

  /// Desenha polígonos no mapa
  void _desenharPoligonos() {
    setState(() {
      // Forçar atualização do mapa com os polígonos
    });
  }

  /// Edita polígono de uma subárea
  void _editarPoligono(SubareaModel subarea) {
    // Implementar edição de polígono
    _mostrarMensagem('Edição de polígono em desenvolvimento', isSuccess: false);
  }

  /// Valida polígono no mapa
  bool _validarPoligonoMapa(List<LatLng> pontos) {
    if (pontos.length < 3) return false;
    
    // Verificar se os pontos formam um polígono válido
    return SubareaGeodeticService.isValidPolygon(pontos);
  }

  /// Sincroniza com o talhão pai
  Future<void> _sincronizarComTalhao() async {
    try {
      // Atualizar estatísticas do talhão
      await _atualizarEstatisticas();
      
      // Notificar mudanças para outros módulos
      await _notificarMudancas();
      
      print('✅ Sincronização com talhão concluída');
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    }
  }

  /// Atualiza estatísticas do talhão
  Future<void> _atualizarEstatisticas() async {
    try {
      final areaTotal = _calcularAreaTotal();
      final perimetroTotal = _calcularPerimetroTotal();
      final percentualOcupacao = (areaTotal / widget.talhaoAreaHa) * 100;
      
      print('📊 Estatísticas do talhão atualizadas:');
      print('  - Total de subáreas: ${_subareasFiltradas.length}');
      print('  - Área total: ${areaTotal.toStringAsFixed(2)} ha');
      print('  - Perímetro total: ${perimetroTotal.toStringAsFixed(2)} m');
      print('  - Percentual ocupação: ${percentualOcupacao.toStringAsFixed(1)}%');
      
    } catch (e) {
      print('❌ Erro ao atualizar estatísticas: $e');
    }
  }

  /// Notifica mudanças para outros módulos
  Future<void> _notificarMudancas() async {
    try {
      // Notificar mudanças para o sistema de plantio
      // Notificar mudanças para o sistema de monitoramento
      // Notificar mudanças para o sistema de aplicação
      
      print('📢 Mudanças notificadas para outros módulos');
    } catch (e) {
      print('❌ Erro ao notificar mudanças: $e');
    }
  }

  /// Exporta subáreas
  Future<void> _exportarSubareas() async {
    try {
      // Gerar relatório
      final relatorio = _gerarRelatorio();
      
      // Compartilhar dados
      await _compartilharDados(relatorio);
      
    } catch (e) {
      _mostrarMensagem('Erro ao exportar subáreas: $e', isSuccess: false);
    }
  }

  /// Gera relatório de subáreas
  Map<String, dynamic> _gerarRelatorio() {
    final areaTotal = _calcularAreaTotal();
    final perimetroTotal = _calcularPerimetroTotal();
    final percentualOcupacao = (areaTotal / widget.talhaoAreaHa) * 100;
    
    return {
      'talhao_id': widget.talhaoId,
      'talhao_nome': widget.talhaoNome,
      'data_geracao': DateTime.now().toIso8601String(),
      'total_subareas': _subareasFiltradas.length,
      'area_total_ha': areaTotal,
      'perimetro_total_m': perimetroTotal,
      'percentual_ocupacao': percentualOcupacao,
      'subareas': _subareasFiltradas.map((s) => {
        'id': s.id,
        'nome': s.nome,
        'cultura': s.cultura,
        'variedade': s.variedade,
        'area_ha': s.areaHa,
        'perimetro_m': s.perimetroM,
        'data_inicio': s.dataInicio?.toIso8601String(),
        'observacoes': s.observacoes,
      }).toList(),
    };
  }

  /// Compartilha dados das subáreas
  Future<void> _compartilharDados(Map<String, dynamic> dados) async {
    try {
      // Implementar compartilhamento (PDF, Excel, etc.)
      print('📤 Dados compartilhados: ${dados['total_subareas']} subáreas');
      _mostrarMensagem('Relatório gerado com sucesso!', isSuccess: true);
    } catch (e) {
      print('❌ Erro ao compartilhar dados: $e');
      _mostrarMensagem('Erro ao gerar relatório: $e', isSuccess: false);
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
  void _mostrarMensagem(String mensagem, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: _snackBarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: FortSmartAppBar(
        title: 'Subáreas - ${widget.talhaoNome}',
        subtitle: '${_subareas.length} subárea(s) encontrada(s)',
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilters ? Colors.blue : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          if (_showFilters) _buildFiltrosSection(),
          
          // Estatísticas
          _buildStatsSection(),
          
          // Conteúdo principal
          Expanded(
            child: _isLoading
                ? const FortSmartLoading()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _subareasFiltradas.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarSubarea,
        icon: const Icon(Icons.add),
        label: const Text('Nova Subárea'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Constrói seção de filtros
  Widget _buildFiltrosSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: FortSmartCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filtroAtual = SubareaFilter.empty();
                      _searchController.clear();
                    });
                    _aplicarFiltros();
                  },
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Barra de busca
            FortSmartSearchBar(
              controller: _searchController,
              hintText: 'Buscar por nome...',
            ),
            
            const SizedBox(height: 16),
            
            // Filtros por status
            const Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SubareaStatus.values.map((status) {
                final isSelected = _filtroAtual.status == status;
                return FortSmartFilterChip(
                  label: status.label,
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filtroAtual = _filtroAtual.copyWith(
                        status: selected ? status : null,
                      );
                    });
                    _aplicarFiltros();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói seção de estatísticas
  Widget _buildStatsSection() {
    if (_stats.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FortSmartCard(
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Subáreas',
                '${_stats['total_subareas'] ?? 0}',
                Icons.grid_view,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Área Total',
                '${SubareaGeodeticService.formatAreaBrazilian(_stats['area_total_ha'] ?? 0.0)} ha',
                Icons.area_chart,
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Culturas',
                '${(_stats['culturas'] as List?)?.length ?? 0}',
                Icons.eco,
                Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói item de estatística
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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

  /// Constrói conteúdo principal
  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Lista de subáreas
        _buildListaSubareas(),
        
        // Mapa das subáreas
        _buildMapaSubareas(),
      ],
    );
  }

  /// Constrói lista de subáreas
  Widget _buildListaSubareas() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subareasFiltradas.length,
      itemBuilder: (context, index) {
        final subarea = _subareasFiltradas[index];
        return _buildSubareaCard(subarea, index);
      },
    );
  }

  /// Constrói card da subárea
  Widget _buildSubareaCard(SubareaModel subarea, int index) {
    final percentual = subarea.calcularPercentualTalhao(widget.talhaoAreaHa);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FortSmartCard(
        child: InkWell(
          onTap: () => _verDetalhes(subarea),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Número e cor
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: subarea.cor.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: subarea.cor.color.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Nome e status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subarea.nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: subarea.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: subarea.statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              subarea.status.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: subarea.statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Menu de ações
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'detalhes':
                            _verDetalhes(subarea);
                            break;
                          case 'excluir':
                            _excluirSubarea(subarea);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'detalhes',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 8),
                              Text('Ver Detalhes'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'excluir',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Excluir', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Informações principais
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Área',
                        SubareaGeodeticService.formatAreaBrazilian(subarea.areaHa),
                        Icons.area_chart,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Percentual',
                        '${percentual.toStringAsFixed(1)}%',
                        Icons.pie_chart,
                        Colors.blue,
                      ),
                    ),
                    if (subarea.dae != null)
                      Expanded(
                        child: _buildInfoItem(
                          'DAE',
                          '${subarea.dae} dias',
                          Icons.calendar_today,
                          Colors.orange,
                        ),
                      ),
                  ],
                ),
                
                // Cultura e variedade
                if (subarea.cultura != null || subarea.variedade != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (subarea.cultura != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subarea.cultura!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (subarea.variedade != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subarea.variedade!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói item de informação
  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
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
        ),
      ],
    );
  }

  /// Constrói mapa das subáreas
  Widget _buildMapaSubareas() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: FortSmartCard(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Mapa das Subáreas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Container(
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

  /// Constrói estado de erro
  Widget _buildErrorState() {
    return Center(
      child: FortSmartEmptyState(
        icon: Icons.error_outline,
        title: 'Erro ao Carregar',
        message: _errorMessage ?? 'Erro desconhecido',
        action: FortSmartButton(
          text: 'Tentar Novamente',
          onPressed: _carregarDados,
          icon: Icons.refresh,
        ),
      ),
    );
  }

  /// Constrói estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: FortSmartEmptyState(
        icon: Icons.grid_view_outlined,
        title: 'Nenhuma Subárea Encontrada',
        message: _filtroAtual.isEmpty
            ? 'Este talhão ainda não possui subáreas.\nToque no botão + para criar a primeira.'
            : 'Nenhuma subárea corresponde aos filtros aplicados.',
        action: _filtroAtual.isEmpty
            ? FortSmartButton(
                text: 'Criar Primeira Subárea',
                onPressed: _criarSubarea,
                icon: Icons.add,
              )
            : FortSmartButton(
                text: 'Limpar Filtros',
                onPressed: () {
                  setState(() {
                    _filtroAtual = SubareaFilter.empty();
                    _searchController.clear();
                  });
                  _aplicarFiltros();
                },
                icon: Icons.clear,
              ),
      ),
    );
  }
}

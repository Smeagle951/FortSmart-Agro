import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../models/experimento_completo_model.dart';
import '../../services/experimento_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/responsive_utils.dart';
import 'subarea_map_screen.dart';
import 'experimento_gestao_screen.dart';
import '../../widgets/responsive_widgets.dart';
import 'criar_subarea_fullscreen_screen.dart';
import 'editar_experimento_screen.dart';
import 'detalhes_subarea_screen.dart';

/// Tela melhorada do experimento com funcionalidades completas
class ExperimentoMelhoradoScreen extends StatefulWidget {
  final ExperimentoCompleto experimento;

  const ExperimentoMelhoradoScreen({
    Key? key,
    required this.experimento,
  }) : super(key: key);

  @override
  State<ExperimentoMelhoradoScreen> createState() => _ExperimentoMelhoradoScreenState();
}

class _ExperimentoMelhoradoScreenState extends State<ExperimentoMelhoradoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ExperimentoService _experimentoService = ExperimentoService();
  
  // Estado
  bool _isLoading = true;
  ExperimentoCompleto? _experimento;
  List<SubareaCompleta> _subareas = [];
  bool _showSubareaMarkers = true;
  
  // Controle do mapa
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    try {
      final experimento = await _experimentoService.buscarExperimentoPorId(widget.experimento.id);
      
      if (experimento != null) {
        setState(() {
          _experimento = experimento;
          _subareas = experimento.subareas;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        SnackbarUtils.showErrorSnackBar(context, 'Experimento não encontrado');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar experimento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'Carregando...',
          showBackButton: true,
        ),
        body: const LoadingWidget(),
      );
    }

    if (_experimento == null) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'Experimento',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Experimento não encontrado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBarWidget(
        title: _experimento!.nome,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
          PopupMenuButton<String>(
            onSelected: _handleAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Editar Experimento'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.assessment, size: 20),
                    SizedBox(width: 8),
                    Text('Relatórios'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Card do Experimento (Topo)
          _buildExperimentoCard(),
          
          // Tabs de Navegação
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Subáreas', icon: Icon(Icons.grid_view)),
                Tab(text: 'Mapa', icon: Icon(Icons.map)),
                Tab(text: 'Histórico', icon: Icon(Icons.history)),
              ],
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue[700],
            ),
          ),
          
          // Conteúdo das Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubareasTab(),
                _buildMapTab(),
                _buildHistoricoTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _experimento!.podeCriarSubarea
          ? FloatingActionButton.extended(
              onPressed: _criarSubarea,
              icon: const Icon(Icons.add),
              label: const Text('Nova Subárea'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildExperimentoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do Card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _experimento!.nome,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Talhão: ${_experimento!.talhaoNome}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _experimento!.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _experimento!.statusColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _experimento!.statusText,
                      style: TextStyle(
                        color: _experimento!.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Informações do Experimento
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.calendar_today,
                      label: 'Início',
                      value: DateFormat('dd/MM/yyyy').format(_experimento!.dataInicio),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.calendar_today,
                      label: 'Fim',
                      value: DateFormat('dd/MM/yyyy').format(_experimento!.dataFim),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.grid_view,
                      label: 'Subáreas',
                      value: '${_subareas.length}/6',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Dias Restantes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _experimento!.isAtivo ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _experimento!.isAtivo ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: _experimento!.isAtivo ? Colors.green[700] : Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _experimento!.isAtivo 
                          ? '${_experimento!.diasRestantes ?? 0} dias restantes'
                          : _experimento!.isConcluido 
                              ? 'Experimento concluído'
                              : 'Experimento pendente',
                      style: TextStyle(
                        color: _experimento!.isAtivo ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editarExperimento,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _experimento!.podeCriarSubarea ? _criarSubarea : null,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ Subárea'),
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
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubareasTab() {
    if (_subareas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma subárea criada',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + Subárea para começar',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subareas.length,
      itemBuilder: (context, index) {
        final subarea = _subareas[index];
        return _buildSubareaCard(subarea);
      },
    );
  }

  Widget _buildSubareaCard(SubareaCompleta subarea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _verDetalhesSubarea(subarea),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Cor da subárea
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: subarea.cor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          subarea.tipo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: subarea.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subarea.statusText,
                      style: TextStyle(
                        color: subarea.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações da subárea
              Row(
                children: [
                  Expanded(
                    child: _buildSubareaInfo(
                      icon: Icons.crop_square,
                      label: 'Área',
                      value: subarea.areaFormatada,
                    ),
                  ),
                  Expanded(
                    child: _buildSubareaInfo(
                      icon: Icons.calendar_today,
                      label: 'Criada',
                      value: DateFormat('dd/MM/yy').format(subarea.dataCriacao),
                    ),
                  ),
                  if (subarea.cultura != null)
                    Expanded(
                      child: _buildSubareaInfo(
                        icon: Icons.eco,
                        label: 'Cultura',
                        value: subarea.cultura!,
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

  Widget _buildSubareaInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    return Column(
      children: [
        // Opções do mapa
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Opções do mapa:'),
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('Mostrar marcadores'),
                selected: _showSubareaMarkers,
                onSelected: (selected) {
                  setState(() {
                    _showSubareaMarkers = selected;
                  });
                },
                selectedColor: Colors.green[100],
                checkmarkColor: Colors.green[700],
              ),
            ],
          ),
        ),
        
        // Mapa
        Expanded(
          child: _subareas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma subárea para exibir no mapa',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : _buildMap(),
        ),
      ],
    );
  }

  Widget _buildMap() {
    // Calcular bounds das subáreas
    double minLat = _subareas.first.pontos.first.latitude;
    double maxLat = _subareas.first.pontos.first.latitude;
    double minLng = _subareas.first.pontos.first.longitude;
    double maxLng = _subareas.first.pontos.first.longitude;

    for (final subarea in _subareas) {
      for (final ponto in subarea.pontos) {
        minLat = minLat < ponto.latitude ? minLat : ponto.latitude;
        maxLat = maxLat > ponto.latitude ? maxLat : ponto.latitude;
        minLng = minLng < ponto.longitude ? minLng : ponto.longitude;
        maxLng = maxLng > ponto.longitude ? maxLng : ponto.longitude;
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          (minLat + maxLat) / 2,
          (minLng + maxLng) / 2,
        ),
        initialZoom: 15,
        maxZoom: 18,
        minZoom: 10,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        PolygonLayer(
          polygons: _subareas.map((subarea) => Polygon(
            points: subarea.pontos,
            color: subarea.cor.withOpacity(0.3),
            borderColor: subarea.cor,
            borderStrokeWidth: 2,
          )).toList(),
        ),
        if (_showSubareaMarkers)
          MarkerLayer(
            markers: _subareas.map((subarea) {
              // Calcular centro da subárea
              double centerLat = subarea.pontos.map((p) => p.latitude).reduce((a, b) => a + b) / subarea.pontos.length;
              double centerLng = subarea.pontos.map((p) => p.longitude).reduce((a, b) => a + b) / subarea.pontos.length;
              
              return Marker(
                point: LatLng(centerLat, centerLng),
                width: 120,
                height: 60,
                child: GestureDetector(
                  onTap: () => _verDetalhesSubarea(subarea),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: subarea.cor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      subarea.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildHistoricoTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Histórico em desenvolvimento',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        _editarExperimento();
        break;
      case 'reports':
        // Navegar para gestão de experimentos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ExperimentoGestaoScreen(),
          ),
        );
        break;
      case 'export':
        // TODO: Implementar exportação
        SnackbarUtils.showInfoSnackBar(context, 'Exportação em desenvolvimento');
        break;
    }
  }

  void _editarExperimento() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarExperimentoScreen(experimento: _experimento!),
      ),
    );

    if (result == true) {
      _carregarDados();
    }
  }

  void _criarSubarea() async {
    // Obter dados do talhão para o mapa
    LatLng? talhaoCenter;
    List<LatLng>? talhaoPolygon;
    
    if (_experimento!.subareas.isNotEmpty) {
      final firstSubarea = _experimento!.subareas.first;
      if (firstSubarea.pontos.isNotEmpty) {
        // Calcular centro do talhão
        double lat = 0, lng = 0;
        for (var ponto in firstSubarea.pontos) {
          lat += ponto.latitude;
          lng += ponto.longitude;
        }
        talhaoCenter = LatLng(
          lat / firstSubarea.pontos.length,
          lng / firstSubarea.pontos.length,
        );
        
        // Converter pontos para LatLng
        talhaoPolygon = firstSubarea.pontos.map((p) => LatLng(p.latitude, p.longitude)).toList();
      }
    }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SubareaMapScreen(
          experimentoId: _experimento!.id,
          talhaoId: _experimento!.talhaoId,
          talhaoCenter: talhaoCenter,
          talhaoPolygon: talhaoPolygon,
        ),
      ),
    );

    if (result == true) {
      _carregarDados();
    }
  }

  void _verDetalhesSubarea(SubareaCompleta subarea) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesSubareaScreen(subarea: subarea),
      ),
    );

    if (result == true) {
      _carregarDados();
    }
  }
}

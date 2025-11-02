import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/experimento_talhao_model.dart';
import '../../models/subarea_experimento_model.dart';
import '../../models/drawing_polygon_model.dart';
import '../../widgets/subarea_info_chip.dart';
import '../../widgets/subarea_info_item.dart';
import '../../utils/api_config.dart';
import '../../utils/constants.dart';
import '../../utils/type_utils.dart';
import 'subarea_routes.dart';

class TalhaoDetalhesScreen extends StatefulWidget {
  final Experimento experimento;

  const TalhaoDetalhesScreen({
    Key? key,
    required this.experimento,
  }) : super(key: key);

  @override
  State<TalhaoDetalhesScreen> createState() => _TalhaoDetalhesScreenState();
}

class _TalhaoDetalhesScreenState extends State<TalhaoDetalhesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showMap = false;
  bool _showSubareaMarkers = true;
  List<Subarea> _subareas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _subareas = widget.experimento.subareas;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.experimento.nome),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                    Text('Editar'),
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
              const PopupMenuItem(
                value: 'map',
                child: Row(
                  children: [
                    Icon(Icons.map, size: 20),
                    SizedBox(width: 8),
                    Text('Ver no Mapa'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Subáreas'),
            Tab(text: 'Aplicações'),
            Tab(text: 'Colheitas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubareasTab(),
          _buildAplicacoesTab(),
          _buildColheitasTab(),
        ],
      ),
    );
  }

  Widget _buildSubareasTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildExperimentoCard(),
          _buildMapToggle(),
          _showMap ? _buildMapView() : _buildSubareasList(),
        ],
      ),
    );
  }

  Widget _buildAplicacoesTab() {
    return const Center(
      child: Text(
        'Módulo de Aplicações\n(Em desenvolvimento)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildColheitasTab() {
    return const Center(
      child: Text(
        'Módulo de Colheitas\n(Em desenvolvimento)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildExperimentoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Ícone do experimento
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.science, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.experimento.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Talhão: ${widget.experimento.talhaoNome}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Status ativo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ativo',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Cards de informações
            Row(
              children: [
                Expanded(
                  child: SubareaInfoChip(
                    icon: Icons.calendar_today,
                    label: 'Início',
                    value: _formatDate(widget.experimento.dataInicio),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SubareaInfoChip(
                    icon: Icons.calendar_today,
                    label: 'Fim',
                    value: _formatDate(widget.experimento.dataFim ?? DateTime.now()),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SubareaInfoChip(
                    icon: Icons.grid_view,
                    label: 'Subáreas',
                    value: '${_subareas.length}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Barra de progresso
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.experimento.diasRestantes} dias restantes',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editarExperimento,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _criarSubarea,
                    icon: const Icon(Icons.add),
                    label: const Text('+ Subárea'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
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

  Widget _buildMapToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Visualização:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Lista'),
                selected: !_showMap,
                onSelected: (selected) => setState(() => _showMap = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Mapa'),
                selected: _showMap,
                onSelected: (selected) => setState(() => _showMap = true),
              ),
            ],
          ),
          if (_showMap) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Opções do mapa:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Mostrar marcadores'),
                  selected: _showSubareaMarkers,
                  onSelected: (selected) => setState(() => _showSubareaMarkers = selected),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubareasList() {
    if (_subareas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhuma subárea encontrada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Crie uma nova subárea para começar',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _subareas.length,
      itemBuilder: (context, index) {
        final subarea = _subareas[index];
        return _buildSubareaCard(subarea, index);
      },
    );
  }

  Widget _buildSubareaCard(Subarea subarea, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _abrirDetalhesSubarea(subarea),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ícone colorido
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: subarea.cor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                          subarea.cultura ?? 'Sem cultura',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (subarea.variedade != null)
                          Text(
                            'Variedade: ${subarea.variedade}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                    onSelected: (value) => _handleSubareaAction(value, subarea),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Métricas
              Row(
                children: [
                  Expanded(
                    child: SubareaInfoItem(
                      icon: Icons.area_chart,
                      label: 'Área',
                      value: '${subarea.areaHa.toStringAsFixed(2)} ha',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SubareaInfoItem(
                      icon: Icons.straighten,
                      label: 'Perímetro',
                      value: '${subarea.perimetroM.toStringAsFixed(0)} m',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SubareaInfoItem(
                      icon: Icons.grass,
                      label: 'População',
                      value: subarea.populacao != null
                          ? '${subarea.populacao} plantas/ha'
                          : 'N/A',
                      color: Colors.orange,
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

  Widget _buildMapView() {
    if (_subareas.isEmpty) {
      return const Center(
        child: Text('Nenhuma subárea para exibir no mapa'),
      );
    }

    // Calcular centro do mapa baseado nas subáreas
    final centroides = _subareas.map((s) => s.polygon.centroid).toList();
    final centerLat = centroides.map((c) => c.latitude).reduce((a, b) => a + b) / centroides.length;
    final centerLng = centroides.map((c) => c.longitude).reduce((a, b) => a + b) / centroides.length;

    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: APIConfig.getMapTilerUrl('satellite'),
              userAgentPackageName: 'com.fortsmart.agro',
              maxZoom: 20,
              minZoom: 10,
            ),
            // Polígonos das subáreas
            PolygonLayer(
              polygons: _subareas.map((subarea) {
                return Polygon(
                  points: subarea.polygon.latLngVertices,
                  color: subarea.cor.withOpacity(0.3),
                  borderColor: subarea.cor.withOpacity(0.8),
                  borderStrokeWidth: 2,
                );
              }).toList(),
            ),
            // Marcadores das subáreas
            if (_showSubareaMarkers)
              MarkerLayer(
                markers: _subareas.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subarea = entry.value;
                  return Marker(
                    point: subarea.polygon.centroid,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: subarea.cor.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _loadData() {
    // Recarregar dados
    setState(() {});
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        _editarExperimento();
        break;
      case 'reports':
        // Implementar relatórios
        break;
      case 'export':
        // Implementar exportação
        break;
      case 'map':
        setState(() => _showMap = true);
        break;
    }
  }

  void _editarExperimento() {
    // Implementar edição do experimento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento')),
    );
  }

  void _criarSubarea() {
    SubareaRoutes.navigateToCriarSubarea(
      context,
      widget.experimento.id,
      widget.experimento.talhaoId,
    ).then((_) {
      _loadData();
    });
  }

  void _abrirDetalhesSubarea(Subarea subarea) {
    SubareaRoutes.navigateToSubareaDetalhes(context, subarea);
  }

  void _handleSubareaAction(String action, Subarea subarea) {
    switch (action) {
      case 'edit':
        // Implementar edição da subárea
        break;
      case 'delete':
        _confirmarRemocao(subarea);
        break;
    }
  }

  void _confirmarRemocao(Subarea subarea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a subárea "${subarea.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar exclusão
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

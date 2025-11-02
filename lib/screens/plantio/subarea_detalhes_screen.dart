import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/subarea_experimento_model.dart';
import '../../widgets/subarea_info_item.dart';
import '../../utils/api_config.dart';
import '../../utils/constants.dart';
import '../../utils/type_utils.dart';
import 'subarea_routes.dart';

class SubareaDetalhesScreen extends StatefulWidget {
  final Subarea subarea;

  const SubareaDetalhesScreen({
    Key? key,
    required this.subarea,
  }) : super(key: key);

  @override
  State<SubareaDetalhesScreen> createState() => _SubareaDetalhesScreenState();
}

class _SubareaDetalhesScreenState extends State<SubareaDetalhesScreen> {
  bool _showMap = false;
  bool _showVertices = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.subarea.nome),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarSubarea,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _compartilharSubarea,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSubareaCard(),
            _buildMapToggle(),
            _showMap ? _buildMapView() : _buildDetailsView(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarNovaAplicacao,
        backgroundColor: Colors.blue[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Aplicação', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSubareaCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícone colorido da subárea
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.subarea.cor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.subarea.cor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.subarea.nome.split(' ').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Informações principais
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
                      Text(
                        '${widget.subarea.cultura ?? 'Sem cultura'} - ${widget.subarea.variedade ?? 'Sem variedade'}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.subarea.populacao ?? 0} plantas/ha',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Informações em cards
            Row(
              children: [
                Expanded(
                  child: SubareaInfoItem(
                    icon: Icons.area_chart,
                    label: 'Área',
                    value: '${widget.subarea.areaHa.toStringAsFixed(1)} ha',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SubareaInfoItem(
                    icon: Icons.straighten,
                    label: 'Perímetro',
                    value: '${widget.subarea.perimetroM.toStringAsFixed(0)} m',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SubareaInfoItem(
                    icon: Icons.calendar_today,
                    label: 'DAE',
                    value: widget.subarea.dae?.toString() ?? 'N/A',
                    color: Colors.orange,
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
                label: const Text('Detalhes'),
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
                  selected: _showVertices,
                  onSelected: (selected) => setState(() => _showVertices = selected),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final vertices = widget.subarea.polygon.latLngVertices;
    if (vertices.isEmpty) {
      return const Center(
        child: Text('Nenhum vértice encontrado para esta subárea'),
      );
    }

    final centerLat = widget.subarea.polygon.centroid.latitude;
    final centerLng = widget.subarea.polygon.centroid.longitude;
    final subareaColor = widget.subarea.cor;
    final subareaName = widget.subarea.nome;

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
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate: APIConfig.getMapTilerUrl('satellite'),
              userAgentPackageName: 'com.fortsmart.agro',
              maxZoom: 18,
              minZoom: 1,
            ),

            // Polígono da subárea
            PolygonLayer(
              polygons: [
                Polygon(
                  points: vertices,
                  color: subareaColor.withOpacity(0.3),
                  borderColor: subareaColor.withOpacity(0.8),
                  borderStrokeWidth: 2.5,
                ),
              ],
            ),

            // Marcadores dos vértices (apenas se habilitado e houver poucos vértices)
            if (_showVertices && vertices.length <= 8)
              MarkerLayer(
                markers: vertices.map((vertex) {
                  return Marker(
                    point: vertex,
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: subareaColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Marcador central da subárea
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(centerLat, centerLng),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: subareaColor.withOpacity(0.9),
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
                        subareaName.split(' ').last,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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

  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informações Técnicas
          _buildSectionCard(
            title: 'Informações Técnicas',
            icon: Icons.science,
            children: [
              _buildDetailItem('Cultura', widget.subarea.cultura ?? 'Não informado'),
              _buildDetailItem('Variedade', widget.subarea.variedade ?? 'Não informado'),
              _buildDetailItem('População', '${widget.subarea.populacao ?? 0} plantas/ha'),
              _buildDetailItem('Área', '${widget.subarea.areaHa.toStringAsFixed(2)} hectares'),
              _buildDetailItem('Perímetro', '${widget.subarea.perimetroM.toStringAsFixed(0)} metros'),
              _buildDetailItem('DAE', widget.subarea.dae?.toString() ?? 'Não calculado'),
            ],
          ),

          const SizedBox(height: 16),

          // Informações Temporais
          _buildSectionCard(
            title: 'Informações Temporais',
            icon: Icons.access_time,
            children: [
              _buildDetailItem('Data de Criação', _formatDate(widget.subarea.criadoEm)),
              _buildDetailItem('Última Atualização', _formatDate(widget.subarea.atualizadoEm ?? DateTime.now())),
            ],
          ),

          const SizedBox(height: 16),

          // Estatísticas
          _buildSectionCard(
            title: 'Estatísticas',
            icon: Icons.analytics,
            children: [
              _buildDetailItem('Vértices do Polígono', '${widget.subarea.polygon.vertices.length} pontos'),
              _buildDetailItem('Área em m²', '${(widget.subarea.areaHa * 10000).toStringAsFixed(0)} m²'),
              _buildDetailItem('Densidade', '${widget.subarea.populacao ?? 0} plantas/ha'),
            ],
          ),

          const SizedBox(height: 16),

          // Observações
          if (widget.subarea.observacoes != null && widget.subarea.observacoes!.isNotEmpty)
            _buildSectionCard(
              title: 'Observações',
              icon: Icons.note,
              children: [
                _buildDetailItem('', widget.subarea.observacoes!),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _editarSubarea() {
    // Implementar edição da subárea
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de edição em desenvolvimento')),
    );
  }

  void _compartilharSubarea() {
    // Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de compartilhamento em desenvolvimento')),
    );
  }

  void _criarNovaAplicacao() {
    // Implementar criação de nova aplicação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de aplicações em desenvolvimento')),
    );
  }
}

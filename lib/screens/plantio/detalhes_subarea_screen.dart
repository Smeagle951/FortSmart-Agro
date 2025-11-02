import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../models/experimento_completo_model.dart';
import '../../services/experimento_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import '../../widgets/integrar_plantio_widget.dart';

/// Tela de detalhes completos da subárea
class DetalhesSubareaScreen extends StatefulWidget {
  final SubareaCompleta subarea;

  const DetalhesSubareaScreen({
    Key? key,
    required this.subarea,
  }) : super(key: key);

  @override
  State<DetalhesSubareaScreen> createState() => _DetalhesSubareaScreenState();
}

class _DetalhesSubareaScreenState extends State<DetalhesSubareaScreen> {
  final ExperimentoService _experimentoService = ExperimentoService();
  SubareaCompleta? _subarea;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final subarea = await _experimentoService.buscarSubareaPorId(widget.subarea.id);
      if (subarea != null) {
        setState(() {
          _subarea = subarea;
        });
      }
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar dados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subarea = _subarea ?? widget.subarea;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBarWidget(
        title: subarea.nome,
        showBackButton: true,
        actions: [
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
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'plantio',
                child: Row(
                  children: [
                    Icon(Icons.agriculture, size: 20),
                    SizedBox(width: 8),
                    Text('Integrar com Plantio'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card Principal da Subárea
            _buildSubareaCard(subarea),
            
            const SizedBox(height: 16),
            
            // Mapa da Subárea
            _buildMapCard(subarea),
            
            const SizedBox(height: 16),
            
            // Informações Detalhadas
            _buildInfoCard(subarea),
            
            const SizedBox(height: 16),
            
            // Dados de Plantio (se existirem)
            if (subarea.dadosPlantio != null)
              _buildPlantioCard(subarea),
            
            const SizedBox(height: 16),
            
            // Dados de Colheita (se existirem)
            if (subarea.dadosColheita != null)
              _buildColheitaCard(subarea),
            
            const SizedBox(height: 16),
            
            // Botões de Ação
            _buildActionButtons(subarea),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSubareaCard(SubareaCompleta subarea) {
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
              // Header
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subarea.nome,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subarea.tipo,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: subarea.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: subarea.statusColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      subarea.statusText,
                      style: TextStyle(
                        color: subarea.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Informações Principais
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.crop_square,
                      label: 'Área',
                      value: subarea.areaFormatada,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.straighten,
                      label: 'Perímetro',
                      value: '${subarea.perimetro.toStringAsFixed(0)}m',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      icon: Icons.calendar_today,
                      label: 'Criada em',
                      value: DateFormat('dd/MM/yyyy').format(subarea.dataCriacao),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (subarea.dataFinalizacao != null)
                    Expanded(
                      child: _buildInfoBox(
                        icon: Icons.check_circle,
                        label: 'Finalizada em',
                        value: DateFormat('dd/MM/yyyy').format(subarea.dataFinalizacao!),
                        color: Colors.purple,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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

  Widget _buildMapCard(SubareaCompleta subarea) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.map, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Localização',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildSubareaMap(subarea),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubareaMap(SubareaCompleta subarea) {
    // Calcular bounds da subárea
    double minLat = subarea.pontos.first.latitude;
    double maxLat = subarea.pontos.first.latitude;
    double minLng = subarea.pontos.first.longitude;
    double maxLng = subarea.pontos.first.longitude;

    for (final ponto in subarea.pontos) {
      minLat = minLat < ponto.latitude ? minLat : ponto.latitude;
      maxLat = maxLat > ponto.latitude ? maxLat : ponto.latitude;
      minLng = minLng < ponto.longitude ? minLng : ponto.longitude;
      maxLng = maxLng > ponto.longitude ? maxLng : ponto.longitude;
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          (minLat + maxLat) / 2,
          (minLng + maxLng) / 2,
        ),
        initialZoom: 16,
        maxZoom: 18,
        minZoom: 10,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        PolygonLayer(
          polygons: [
            Polygon(
              points: subarea.pontos,
              color: subarea.cor.withOpacity(0.3),
              borderColor: subarea.cor,
              borderStrokeWidth: 3,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Calcular centro da subárea
            Marker(
              point: LatLng(
                subarea.pontos.map((p) => p.latitude).reduce((a, b) => a + b) / subarea.pontos.length,
                subarea.pontos.map((p) => p.longitude).reduce((a, b) => a + b) / subarea.pontos.length,
              ),
              width: 120,
              height: 40,
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(SubareaCompleta subarea) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Informações Detalhadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (subarea.descricao != null) ...[
                _buildInfoItem('Descrição', subarea.descricao!),
                const SizedBox(height: 12),
              ],
              
              if (subarea.cultura != null) ...[
                _buildInfoItem('Cultura', subarea.cultura!),
                const SizedBox(height: 12),
              ],
              
              if (subarea.variedade != null) ...[
                _buildInfoItem('Variedade', subarea.variedade!),
                const SizedBox(height: 12),
              ],
              
              if (subarea.observacoes != null) ...[
                _buildInfoItem('Observações', subarea.observacoes!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantioCard(SubareaCompleta subarea) {
    final dadosPlantio = subarea.dadosPlantio!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Row(
                children: [
                  Icon(Icons.agriculture, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Dados de Plantio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Exibir dados de plantio de forma organizada
              ...dadosPlantio.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInfoItem(entry.key, entry.value.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColheitaCard(SubareaCompleta subarea) {
    final dadosColheita = subarea.dadosColheita!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Dados de Colheita',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Exibir dados de colheita de forma organizada
              ...dadosColheita.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInfoItem(entry.key, entry.value.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(SubareaCompleta subarea) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editarSubarea,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _integrarComPlantio,
                  icon: const Icon(Icons.agriculture, size: 18),
                  label: const Text('Integrar Plantio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _excluirSubarea,
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Excluir Subárea'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        _editarSubarea();
        break;
      case 'delete':
        _excluirSubarea();
        break;
      case 'plantio':
        _integrarComPlantio();
        break;
    }
  }

  void _editarSubarea() {
    // TODO: Implementar edição de subárea
    SnackbarUtils.showInfoSnackBar(context, 'Edição de subárea em desenvolvimento');
  }

  void _integrarComPlantio() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => IntegrarPlantioWidget(subarea: _subarea ?? widget.subarea),
      ),
    );

    if (result == true) {
      _carregarDados();
    }
  }

  void _excluirSubarea() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Subárea'),
        content: Text('Tem certeza que deseja excluir a subárea "${widget.subarea.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmarExclusao();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarExclusao() async {
    try {
      await _experimentoService.removerSubarea(widget.subarea.id);
      SnackbarUtils.showSuccessSnackBar(context, 'Subárea excluída com sucesso');
      Navigator.of(context).pop(true);
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao excluir subárea: $e');
    }
  }
}

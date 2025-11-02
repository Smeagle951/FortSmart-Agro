import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/talhao_model.dart';
import '../../widgets/fluent_talhao_map_widget.dart';

/// Tela de edição de talhão com sistema de edição fluida integrado
/// Demonstra como integrar o sistema sem quebrar funcionalidades existentes
class FluentTalhaoEditorScreen extends StatefulWidget {
  final TalhaoModel talhao;
  final Function(TalhaoModel)? onTalhaoUpdated;
  final VoidCallback? onCancel;
  
  const FluentTalhaoEditorScreen({
    Key? key,
    required this.talhao,
    this.onTalhaoUpdated,
    this.onCancel,
  }) : super(key: key);
  
  @override
  State<FluentTalhaoEditorScreen> createState() => _FluentTalhaoEditorScreenState();
}

class _FluentTalhaoEditorScreenState extends State<FluentTalhaoEditorScreen> {
  late TalhaoModel _currentTalhao;
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _currentTalhao = widget.talhao;
  }
  
  void _onTalhaoUpdated(TalhaoModel updatedTalhao) {
    setState(() {
      _currentTalhao = updatedTalhao;
      _hasChanges = true;
    });
    
    // Recalcular área se necessário
    _recalculateArea();
  }
  
  void _recalculateArea() {
    if (_currentTalhao.poligonos.isNotEmpty && _currentTalhao.poligonos.first.isNotEmpty) {
      final points = _currentTalhao.poligonos.first
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      
      // Aqui você pode integrar com o PreciseGeoCalculator existente
      // final area = PreciseGeoCalculator.calculatePolygonArea(points);
      // _currentTalhao = _currentTalhao.copyWith(area: area);
    }
  }
  
  void _saveChanges() {
    if (_hasChanges) {
      widget.onTalhaoUpdated?.call(_currentTalhao);
      _showSuccessMessage('Talhão "${_currentTalhao.name}" atualizado com sucesso!');
    }
  }
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Talhão: ${_currentTalhao.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _saveChanges,
              icon: Icon(Icons.save),
              tooltip: 'Salvar alterações',
            ),
        ],
      ),
      body: Column(
        children: [
          // Informações do talhão
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informações do Talhão',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard('Nome', _currentTalhao.name),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard('Área', '${_currentTalhao.area?.toStringAsFixed(2) ?? "N/A"} ha'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard('Cultura', _currentTalhao.culturaName ?? 'N/A'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard('Pontos', '${_currentTalhao.poligonos.isNotEmpty ? _currentTalhao.poligonos.first.length : 0}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Mapa com edição fluida
          Expanded(
            child: FluentTalhaoMapWidget(
              talhoes: [_currentTalhao],
              selectedTalhao: _currentTalhao,
              enableFluentEditing: true,
              onTalhaoUpdated: _onTalhaoUpdated,
              mapOptions: MapOptions(
                initialCenter: _currentTalhao.poligonos.isNotEmpty 
                    ? LatLng(
                        _currentTalhao.poligonos.first.first.latitude,
                        _currentTalhao.poligonos.first.first.longitude,
                      )
                    : LatLng(-15.7801, -47.9292),
                initialZoom: 16.0,
              ),
            ),
          ),
          
          // Controles inferiores
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel ?? () => Navigator.pop(context),
                    icon: Icon(Icons.cancel),
                    label: Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasChanges ? _saveChanges : null,
                    icon: Icon(Icons.save),
                    label: Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de demonstração da integração
class FluentTalhaoEditorDemo extends StatefulWidget {
  const FluentTalhaoEditorDemo({Key? key}) : super(key: key);
  
  @override
  State<FluentTalhaoEditorDemo> createState() => _FluentTalhaoEditorDemoState();
}

class _FluentTalhaoEditorDemoState extends State<FluentTalhaoEditorDemo> {
  late TalhaoModel _demoTalhao;
  
  @override
  void initState() {
    super.initState();
    _createDemoTalhao();
  }
  
  void _createDemoTalhao() {
    _demoTalhao = TalhaoModel(
      id: 'demo-1',
      name: 'Talhão Demo',
      fazendaId: 'fazenda-1',
      poligonos: [
        [
          PoligonoPoint(latitude: -15.7801, longitude: -47.9292),
          PoligonoPoint(latitude: -15.7801, longitude: -47.9282),
          PoligonoPoint(latitude: -15.7791, longitude: -47.9282),
          PoligonoPoint(latitude: -15.7791, longitude: -47.9292),
        ]
      ],
      culturaName: 'Soja',
      area: 1.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  void _onTalhaoUpdated(TalhaoModel updatedTalhao) {
    setState(() {
      _demoTalhao = updatedTalhao;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demo - Edição Fluida de Talhão'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FluentTalhaoEditorScreen(
        talhao: _demoTalhao,
        onTalhaoUpdated: _onTalhaoUpdated,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

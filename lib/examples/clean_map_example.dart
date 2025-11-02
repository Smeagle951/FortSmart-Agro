import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../widgets/clean_map_widget.dart';
import '../utils/maptiler_constants.dart';

/// Exemplo de uso do novo CleanMapWidget
class CleanMapExample extends StatefulWidget {
  const CleanMapExample({Key? key}) : super(key: key);

  @override
  State<CleanMapExample> createState() => _CleanMapExampleState();
}

class _CleanMapExampleState extends State<CleanMapExample> {
  List<TalhaoModel> _talhoes = [];
  TalhaoModel? _selectedTalhao;
  List<LatLng> _drawingPoints = [];
  bool _isEditMode = false;
  
  @override
  void initState() {
    super.initState();
    _carregarTalhoes();
  }
  
  /// Carrega os talhões do repositório
  Future<void> _carregarTalhoes() async {
    // Aqui você carregaria os talhões do seu repositório
    // Por exemplo: _talhoes = await TalhaoRepository.listarTodos();
    
    // Para este exemplo, vamos criar alguns talhões fictícios
    setState(() {
      _talhoes = _criarTalhoesFicticios();
    });
  }
  
  /// Cria talhões fictícios para demonstração
  List<TalhaoModel> _criarTalhoesFicticios() {
    // Coordenadas para um talhão de exemplo (próximo a Brasília)
    final poligono1 = [
      LatLng(-15.7801, -47.9292),
      LatLng(-15.7901, -47.9292),
      LatLng(-15.7901, -47.9392),
      LatLng(-15.7801, -47.9392),
    ];
    
    // Coordenadas para outro talhão de exemplo
    final poligono2 = [
      LatLng(-15.7701, -47.9192),
      LatLng(-15.7801, -47.9192),
      LatLng(-15.7801, -47.9292),
      LatLng(-15.7701, -47.9292),
    ];
    
    // Converter para o formato esperado pelo TalhaoModel
    final mapboxPoligono1 = poligono1.map((p) => 
      MapboxLatLng(p.latitude, p.longitude)).toList();
    
    final mapboxPoligono2 = poligono2.map((p) => 
      MapboxLatLng(p.latitude, p.longitude)).toList();
    
    // Criar os talhões
    return [
      TalhaoModel(
        id: '1',
        name: 'Talhão Soja',
        area: 10.5,
        poligonos: [],
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        safras: [],
        sincronizado: true,
        metadados: {'criadoPor': 'usuario_teste', 'cultura': 'Soja'},
        fazendaId: '1',
      ),
      TalhaoModel(
        id: '2',
        name: 'Talhão Milho',
        area: 8.2,
        poligonos: [],
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        safras: [],
        sincronizado: true,
        metadados: {'criadoPor': 'usuario_teste', 'cultura': 'Milho'},
        fazendaId: '1',
      ),
    ];
  }
  
  /// Manipula o tap em um talhão
  void _handleTalhaoSelected(TalhaoModel talhao) {
    setState(() {
      _selectedTalhao = talhao;
    });
    
    // Exibir informações do talhão
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Talhão selecionado: ${talhao.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// Manipula o tap no mapa
  void _handleMapTap(LatLng point) {
    if (!_isEditMode) {
      // Se não estiver em modo de edição, apenas exibe as coordenadas
      print('Tap no mapa em: $point');
    }
  }
  
  /// Manipula mudanças nos pontos de desenho
  void _handleDrawingPointsChanged(List<LatLng> points) {
    setState(() {
      _drawingPoints = List.from(points);
    });
  }
  
  /// Alterna o modo de edição
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Limpar pontos de desenho ao sair do modo de edição
        _drawingPoints.clear();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Talhões'),
        actions: [
          // Botão para alternar modo de edição
          IconButton(
            icon: Icon(_isEditMode ? Icons.edit_off : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditMode ? 'Sair do modo de edição' : 'Entrar no modo de edição',
          ),
        ],
      ),
      body: CleanMapWidget(
        talhoes: _talhoes,
        selectedTalhao: _selectedTalhao,
        onTalhaoSelected: _handleTalhaoSelected,
        onMapTap: _handleMapTap,
        drawingPoints: _drawingPoints,
        onDrawingPointsChanged: _handleDrawingPointsChanged,
        isEditMode: _isEditMode,
        enableDrawing: _isEditMode,
        drawingColor: Colors.red,
        initialZoom: 14.0,
        initialCenter: LatLng(MapTilerConstants.defaultLatitude, MapTilerConstants.defaultLongitude),
        showControls: true,
      ),
    );
  }
}

/// Classe auxiliar para compatibilidade com o exemplo
/// Em uma implementação real, você usaria diretamente LatLng do latlong2
class MapboxLatLng {
  final double latitude;
  final double longitude;
  
  const MapboxLatLng(this.latitude, this.longitude);
}

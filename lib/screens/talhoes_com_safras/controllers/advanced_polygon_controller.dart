import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../utils/geo_math.dart';

/// Controller proprietário FortSmart para gerenciar polígonos agrícolas
/// Sistema único com funcionalidades diferenciadas do FortSmart Agro
class FortSmartPolygonController extends ChangeNotifier {
  // ===== ESTADO DO POLÍGONO =====
  List<LatLng> _vertices = [];
  List<LatLng> _midpoints = [];
  
  // ===== ESTADO DE EDIÇÃO =====
  bool _isEditing = false;
  int? _selectedVertexIndex;
  int? _selectedMidpointIndex;
  bool _isDragging = false;
  
  // ===== MÉTRICAS =====
  double _area = 0.0;
  double _perimeter = 0.0;
  
  // ===== CONFIGURAÇÕES VISUAIS FORTSMART =====
  Color _polygonColor = Colors.green;
  Color _vertexColor = Colors.blue;
  Color _smartPointColor = Colors.orange; // Cor única FortSmart
  double _vertexSize = 14.0; // Tamanho maior
  double _smartPointSize = 10.0;
  
  // ===== FUNCIONALIDADES ÚNICAS FORTSMART =====
  bool _smartMode = true; // Modo inteligente FortSmart
  bool _agroMode = true; // Modo agrícola
  String _polygonName = '';
  String _cropType = '';
  DateTime? _creationDate;
  Map<String, dynamic> _agroData = {};
  
  // ===== GETTERS =====
  List<LatLng> get vertices => List.unmodifiable(_vertices);
  List<LatLng> get midpoints => List.unmodifiable(_midpoints);
  bool get isEditing => _isEditing;
  int? get selectedVertexIndex => _selectedVertexIndex;
  int? get selectedMidpointIndex => _selectedMidpointIndex;
  bool get isDragging => _isDragging;
  double get area => _area;
  double get perimeter => _perimeter;
  Color get polygonColor => _polygonColor;
  Color get vertexColor => _vertexColor;
  Color get smartPointColor => _smartPointColor;
  double get vertexSize => _vertexSize;
  double get smartPointSize => _smartPointSize;
  
  // ===== GETTERS FORTSMART =====
  bool get smartMode => _smartMode;
  bool get agroMode => _agroMode;
  String get polygonName => _polygonName;
  String get cropType => _cropType;
  DateTime? get creationDate => _creationDate;
  Map<String, dynamic> get agroData => Map.unmodifiable(_agroData);
  
  // ===== VALIDAÇÕES =====
  bool get hasMinimumVertices => _vertices.length >= 3;
  bool get canRemoveVertex => _vertices.length > 3;
  bool get isEmpty => _vertices.isEmpty;
  
  // ===== MÉTODOS DE INICIALIZAÇÃO =====
  
  /// Inicializa o controller FortSmart com pontos existentes
  void initialize(List<LatLng>? initialPoints, {String? name, String? crop}) {
    _vertices = initialPoints != null ? List.from(initialPoints) : [];
    _polygonName = name ?? 'Polígono FortSmart';
    _cropType = crop ?? '';
    _creationDate = DateTime.now();
    _calculateMidpoints();
    _updateMetrics();
    _initializeAgroData();
    notifyListeners();
  }
  
  /// Limpa todos os dados
  void clear() {
    _vertices.clear();
    _midpoints.clear();
    _selectedVertexIndex = null;
    _selectedMidpointIndex = null;
    _isDragging = false;
    _area = 0.0;
    _perimeter = 0.0;
    notifyListeners();
  }
  
  // ===== MÉTODOS DE EDIÇÃO =====
  
  /// Ativa/desativa o modo de edição
  void setEditingMode(bool editing) {
    _isEditing = editing;
    if (!editing) {
      _selectedVertexIndex = null;
      _selectedMidpointIndex = null;
      _isDragging = false;
    }
    notifyListeners();
  }
  
  /// Adiciona um novo vértice
  void addVertex(LatLng point) {
    _vertices.add(point);
    _calculateMidpoints();
    _updateMetrics();
    notifyListeners();
  }
  
  /// Adiciona um vértice em uma posição específica
  void insertVertex(int index, LatLng point) {
    if (index >= 0 && index <= _vertices.length) {
      _vertices.insert(index, point);
      _calculateMidpoints();
      _updateMetrics();
      notifyListeners();
    }
  }
  
  /// Remove um vértice
  void removeVertex(int index) {
    if (index >= 0 && index < _vertices.length && canRemoveVertex) {
      _vertices.removeAt(index);
      _calculateMidpoints();
      _updateMetrics();
      
      // Ajustar índice selecionado se necessário
      if (_selectedVertexIndex == index) {
        _selectedVertexIndex = null;
      } else if (_selectedVertexIndex != null && _selectedVertexIndex! > index) {
        _selectedVertexIndex = _selectedVertexIndex! - 1;
      }
      
      notifyListeners();
    }
  }
  
  /// Move um vértice para nova posição
  void moveVertex(int index, LatLng newPosition) {
    if (index >= 0 && index < _vertices.length) {
      _vertices[index] = newPosition;
      _calculateMidpoints();
      _updateMetrics();
      notifyListeners();
    }
  }
  
  /// Converte um midpoint em vértice
  void convertMidpointToVertex(int midpointIndex) {
    if (midpointIndex >= 0 && midpointIndex < _midpoints.length) {
      final midpoint = _midpoints[midpointIndex];
      final vertexIndex = (midpointIndex + 1) % _vertices.length;
      insertVertex(vertexIndex, midpoint);
    }
  }
  
  // ===== MÉTODOS DE SELEÇÃO =====
  
  /// Seleciona um vértice
  void selectVertex(int index) {
    if (index >= 0 && index < _vertices.length) {
      _selectedVertexIndex = _selectedVertexIndex == index ? null : index;
      _selectedMidpointIndex = null;
      notifyListeners();
    }
  }
  
  /// Seleciona um midpoint
  void selectMidpoint(int index) {
    if (index >= 0 && index < _midpoints.length) {
      _selectedMidpointIndex = index;
      _selectedVertexIndex = null;
      notifyListeners();
    }
  }
  
  /// Limpa seleções
  void clearSelection() {
    _selectedVertexIndex = null;
    _selectedMidpointIndex = null;
    notifyListeners();
  }
  
  // ===== MÉTODOS DE ARRASTE =====
  
  /// Inicia arraste de vértice
  void startDraggingVertex(int index) {
    if (index >= 0 && index < _vertices.length) {
      _selectedVertexIndex = index;
      _isDragging = true;
      notifyListeners();
    }
  }
  
  /// Atualiza posição durante arraste
  void updateDraggingVertex(int index, LatLng newPosition) {
    if (_isDragging && index == _selectedVertexIndex) {
      moveVertex(index, newPosition);
    }
  }
  
  /// Finaliza arraste de vértice
  void endDraggingVertex() {
    _isDragging = false;
    notifyListeners();
  }
  
  // ===== MÉTODOS DE CÁLCULO =====
  
  /// Calcula os pontos intermediários (midpoints)
  void _calculateMidpoints() {
    _midpoints.clear();
    
    if (_vertices.length < 2) return;
    
    for (int i = 0; i < _vertices.length; i++) {
      final current = _vertices[i];
      final next = _vertices[(i + 1) % _vertices.length];
      
      // Calcular ponto médio
      final midLat = (current.latitude + next.latitude) / 2;
      final midLng = (current.longitude + next.longitude) / 2;
      
      _midpoints.add(LatLng(midLat, midLng));
    }
  }
  
  /// Atualiza métricas (área e perímetro)
  void _updateMetrics() {
    if (_vertices.length >= 3) {
      _area = GeoMath.calcularAreaDesenhoManual(_vertices);
      _perimeter = GeoMath.calcularPerimetroPoligono(_vertices);
    } else {
      _area = 0.0;
      _perimeter = 0.0;
    }
  }
  
  // ===== MÉTODOS DE CONFIGURAÇÃO =====
  
  /// Define cores do polígono
  void setPolygonColors({
    Color? polygonColor,
    Color? vertexColor,
    Color? midpointColor,
  }) {
    if (polygonColor != null) _polygonColor = polygonColor;
    if (vertexColor != null) _vertexColor = vertexColor;
    if (midpointColor != null) _midpointColor = midpointColor;
    notifyListeners();
  }
  
  /// Define tamanhos dos marcadores
  void setMarkerSizes({
    double? vertexSize,
    double? midpointSize,
  }) {
    if (vertexSize != null) _vertexSize = vertexSize;
    if (midpointSize != null) _midpointSize = midpointSize;
    notifyListeners();
  }
  
  // ===== MÉTODOS DE UTILIDADE =====
  
  /// Fecha o polígono automaticamente se necessário
  void closePolygon() {
    if (_vertices.length >= 3) {
      final first = _vertices.first;
      final last = _vertices.last;
      
      // Verificar se já está fechado
      final distance = GeoMath.calcularDistancia(first, last);
      if (distance > 5.0) { // Se distância > 5 metros
        _vertices.add(LatLng(first.latitude, first.longitude));
        _calculateMidpoints();
        _updateMetrics();
        notifyListeners();
      }
    }
  }
  
  /// Simplifica o polígono removendo pontos desnecessários
  void simplifyPolygon({double tolerance = 2.0}) {
    if (_vertices.length <= 3) return;
    
    final simplified = GeoMath.simplificarPoligono(_vertices, tolerancia: tolerance);
    if (simplified.length != _vertices.length) {
      _vertices = simplified;
      _calculateMidpoints();
      _updateMetrics();
      notifyListeners();
    }
  }
  
  /// Valida se o polígono é válido
  bool isValidPolygon() {
    return _vertices.length >= 3 && GeoMath.pontoEstaDentroDoPoligono(
      _vertices.first, 
      _vertices.sublist(1)
    );
  }
  
  /// Obtém o centroide do polígono
  LatLng? getCentroid() {
    if (_vertices.isEmpty) return null;
    return GeoMath.calcularCentroide(_vertices);
  }
  
  /// Obtém os limites (bounds) do polígono
  Map<String, double>? getBounds() {
    if (_vertices.isEmpty) return null;
    
    double minLat = _vertices.first.latitude;
    double maxLat = _vertices.first.latitude;
    double minLng = _vertices.first.longitude;
    double maxLng = _vertices.first.longitude;
    
    for (final vertex in _vertices) {
      if (vertex.latitude < minLat) minLat = vertex.latitude;
      if (vertex.latitude > maxLat) maxLat = vertex.latitude;
      if (vertex.longitude < minLng) minLng = vertex.longitude;
      if (vertex.longitude > maxLng) maxLng = vertex.longitude;
    }
    
    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }
  
  // ===== MÉTODOS DE EXPORTAÇÃO =====
  
  /// Exporta polígono para GeoJSON
  Map<String, dynamic> toGeoJSON({Map<String, dynamic>? properties}) {
    final coordinates = _vertices.map((v) => [v.longitude, v.latitude]).toList();
    
    return {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [coordinates]
      },
      "properties": {
        "area": _area,
        "perimeter": _perimeter,
        "vertices": _vertices.length,
        ...?properties,
      },
    };
  }
  
  /// Exporta polígono para formato simples
  Map<String, dynamic> toSimpleFormat() {
    return {
      'vertices': _vertices.map((v) => {
        'latitude': v.latitude,
        'longitude': v.longitude,
      }).toList(),
      'area': _area,
      'perimeter': _perimeter,
      'isValid': isValidPolygon(),
    };
  }
  
  // ===== MÉTODOS DE DEBUG =====
  
  /// Debug do estado atual
  void debugState() {
    print('🔍 FortSmartPolygonController Debug:');
    print('  - Vértices: ${_vertices.length}');
    print('  - Midpoints: ${_midpoints.length}');
    print('  - Área: ${_area.toStringAsFixed(4)} ha');
    print('  - Perímetro: ${_perimeter.toStringAsFixed(1)} m');
    print('  - Editando: $_isEditing');
    print('  - Vértice selecionado: $_selectedVertexIndex');
    print('  - Midpoint selecionado: $_selectedMidpointIndex');
    print('  - Arrastando: $_isDragging');
    print('  - Modo Smart: $_smartMode');
    print('  - Modo Agro: $_agroMode');
    print('  - Nome: $_polygonName');
    print('  - Cultura: $_cropType');
  }
  
  // ===== MÉTODOS ÚNICOS FORTSMART =====
  
  /// Inicializa dados agrícolas específicos
  void _initializeAgroData() {
    _agroData = {
      'area_hectares': _area,
      'perimeter_meters': _perimeter,
      'vertices_count': _vertices.length,
      'creation_date': _creationDate?.toIso8601String(),
      'crop_type': _cropType,
      'polygon_name': _polygonName,
      'fortsmart_version': '1.0.0',
      'smart_features': {
        'auto_calculation': true,
        'agro_metrics': true,
        'smart_points': true,
        'precision_mode': true,
      },
    };
  }
  
  /// Define nome do polígono
  void setPolygonName(String name) {
    _polygonName = name;
    _agroData['polygon_name'] = name;
    notifyListeners();
  }
  
  /// Define tipo de cultura
  void setCropType(String crop) {
    _cropType = crop;
    _agroData['crop_type'] = crop;
    notifyListeners();
  }
  
  /// Ativa/desativa modo inteligente FortSmart
  void setSmartMode(bool enabled) {
    _smartMode = enabled;
    _agroData['smart_features']['smart_mode'] = enabled;
    notifyListeners();
  }
  
  /// Ativa/desativa modo agrícola
  void setAgroMode(bool enabled) {
    _agroMode = enabled;
    _agroData['smart_features']['agro_mode'] = enabled;
    notifyListeners();
  }
  
  /// Calcula métricas agrícolas avançadas
  Map<String, dynamic> calculateAgroMetrics() {
    if (_vertices.length < 3) return {};
    
    final bounds = getBounds();
    if (bounds == null) return {};
    
    final width = GeoMath.calcularDistancia(
      LatLng(bounds['minLat']!, bounds['minLng']!),
      LatLng(bounds['minLat']!, bounds['maxLng']!),
    );
    
    final height = GeoMath.calcularDistancia(
      LatLng(bounds['minLat']!, bounds['minLng']!),
      LatLng(bounds['maxLat']!, bounds['minLng']!),
    );
    
    return {
      'area_hectares': _area,
      'area_square_meters': _area * 10000,
      'perimeter_meters': _perimeter,
      'perimeter_kilometers': _perimeter / 1000,
      'width_meters': width,
      'height_meters': height,
      'aspect_ratio': width / height,
      'vertices_count': _vertices.length,
      'complexity_score': _calculateComplexityScore(),
      'agricultural_suitability': _calculateAgriculturalSuitability(),
    };
  }
  
  /// Calcula score de complexidade do polígono
  double _calculateComplexityScore() {
    if (_vertices.length < 3) return 0.0;
    
    // Fórmula única FortSmart para complexidade
    final perimeter = _perimeter;
    final area = _area * 10000; // Converter para m²
    final vertices = _vertices.length;
    
    // Score baseado em perímetro/área e número de vértices
    final perimeterAreaRatio = perimeter / area;
    final vertexComplexity = vertices / 10.0; // Normalizar para 0-1
    
    return (perimeterAreaRatio * 0.7 + vertexComplexity * 0.3).clamp(0.0, 1.0);
  }
  
  /// Calcula adequação agrícola
  String _calculateAgriculturalSuitability() {
    if (_area < 0.1) return 'Muito Pequeno';
    if (_area < 1.0) return 'Pequeno';
    if (_area < 10.0) return 'Médio';
    if (_area < 100.0) return 'Grande';
    return 'Muito Grande';
  }
  
  /// Exporta dados FortSmart
  Map<String, dynamic> exportFortSmartData() {
    return {
      'fortsmart_polygon': {
        'version': '1.0.0',
        'created_at': _creationDate?.toIso8601String(),
        'polygon_name': _polygonName,
        'crop_type': _cropType,
        'vertices': _vertices.map((v) => {
          'latitude': v.latitude,
          'longitude': v.longitude,
        }).toList(),
        'metrics': calculateAgroMetrics(),
        'smart_features': _agroData['smart_features'],
        'fortsmart_signature': _generateFortSmartSignature(),
      },
    };
  }
  
  /// Gera assinatura única FortSmart
  String _generateFortSmartSignature() {
    final data = '${_polygonName}_${_cropType}_${_area}_${_perimeter}_${_vertices.length}';
    return data.hashCode.toString();
  }
  
  /// Valida polígono para uso agrícola
  Map<String, dynamic> validateForAgriculture() {
    final issues = <String>[];
    final warnings = <String>[];
    
    // Validações específicas agrícolas
    if (_area < 0.01) {
      issues.add('Área muito pequena para cultivo');
    }
    
    if (_vertices.length > 20) {
      warnings.add('Polígono muito complexo, considere simplificar');
    }
    
    if (_perimeter / _area > 1000) {
      warnings.add('Formato muito alongado, pode dificultar o cultivo');
    }
    
    return {
      'is_valid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'recommendations': _generateRecommendations(),
    };
  }
  
  /// Gera recomendações agrícolas
  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    
    if (_area < 1.0) {
      recommendations.add('Considere unir com áreas adjacentes para melhor eficiência');
    }
    
    if (_vertices.length > 15) {
      recommendations.add('Simplifique o polígono para facilitar o manejo');
    }
    
    if (_area > 50.0) {
      recommendations.add('Considere dividir em sub-áreas para melhor gestão');
    }
    
    return recommendations;
  }
}

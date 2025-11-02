import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// Serviço para edição fluida de polígonos com pontos arrastáveis
/// Implementa UX similar ao Fields Area Measure com tolerância de toque otimizada
class FluentPolygonEditorService {
  // Configurações de tolerância e visual
  static const double _pointRadius = 6.0; // Visual: pequeno e elegante
  static const double _hitboxRadius = 15.0; // Hitbox: ampla para facilitar toque
  static const double _intermediateHandleRadius = 4.0; // Handles intermediários
  static const double _intermediateHandleHitbox = 12.0; // Hitbox dos handles
  static const double _dragThreshold = 3.0; // Threshold para iniciar arraste
  
  // Estados de edição
  bool _isEditing = false;
  int? _selectedPointIndex;
  int? _selectedIntermediateIndex;
  bool _isDragging = false;
  Offset? _dragStartPosition;
  LatLng? _dragStartPoint;
  
  // Callbacks
  Function(List<LatLng>)? onPolygonChanged;
  Function(int, LatLng)? onPointMoved;
  Function(int, LatLng)? onPointAdded;
  Function(int)? onPointRemoved;
  Function(String)? onStatusChanged;
  
  // Getters
  bool get isEditing => _isEditing;
  int? get selectedPointIndex => _selectedPointIndex;
  int? get selectedIntermediateIndex => _selectedIntermediateIndex;
  bool get isDragging => _isDragging;
  
  /// Ativa o modo de edição fluida
  void enableEditing() {
    _isEditing = true;
    onStatusChanged?.call('Modo de edição ativado - Toque e arraste os pontos');
  }
  
  /// Desativa o modo de edição
  void disableEditing() {
    _isEditing = false;
    _selectedPointIndex = null;
    _selectedIntermediateIndex = null;
    _isDragging = false;
    onStatusChanged?.call('Modo de edição desativado');
  }
  
  /// Processa toque no mapa para edição
  bool handleMapTap(LatLng tapPosition, List<LatLng> polygonPoints, MapController mapController) {
    if (!_isEditing) return false;
    
    // Verificar se tocou em um ponto existente
    final pointIndex = _findNearestPoint(tapPosition, polygonPoints, mapController);
    if (pointIndex != null) {
      _selectPoint(pointIndex);
      return true;
    }
    
    // Verificar se tocou em um handle intermediário
    final intermediateIndex = _findNearestIntermediateHandle(tapPosition, polygonPoints, mapController);
    if (intermediateIndex != null) {
      _selectIntermediateHandle(intermediateIndex);
      return true;
    }
    
    // Desselecionar se tocou em área vazia
    _deselectAll();
    return false;
  }
  
  /// Processa início do arraste
  bool handleDragStart(Offset startPosition, LatLng mapPosition, List<LatLng> polygonPoints, MapController mapController) {
    if (!_isEditing) return false;
    
    _dragStartPosition = startPosition;
    _dragStartPoint = mapPosition;
    
    // Verificar se está arrastando um ponto
    final pointIndex = _findNearestPoint(mapPosition, polygonPoints, mapController);
    if (pointIndex != null) {
      _selectedPointIndex = pointIndex;
      _isDragging = true;
      onStatusChanged?.call('Arrastando ponto ${pointIndex + 1}');
      return true;
    }
    
    // Verificar se está arrastando um handle intermediário
    final intermediateIndex = _findNearestIntermediateHandle(mapPosition, polygonPoints, mapController);
    if (intermediateIndex != null) {
      _selectedIntermediateIndex = intermediateIndex;
      _isDragging = true;
      onStatusChanged?.call('Criando novo ponto');
      return true;
    }
    
    return false;
  }
  
  /// Processa movimento do arraste
  bool handleDragUpdate(Offset currentPosition, LatLng mapPosition, List<LatLng> polygonPoints) {
    if (!_isDragging || _dragStartPosition == null) return false;
    
    // Verificar se o movimento é suficiente para iniciar arraste
    final distance = (currentPosition - _dragStartPosition!).distance;
    if (distance < _dragThreshold) return false;
    
    if (_selectedPointIndex != null) {
      // Arrastando ponto existente
      _updatePointPosition(_selectedPointIndex!, mapPosition, polygonPoints);
    } else if (_selectedIntermediateIndex != null) {
      // Criando novo ponto
      _createNewPoint(_selectedIntermediateIndex!, mapPosition, polygonPoints);
    }
    
    return true;
  }
  
  /// Processa fim do arraste
  bool handleDragEnd(List<LatLng> polygonPoints) {
    if (!_isDragging) return false;
    
    _isDragging = false;
    _dragStartPosition = null;
    _dragStartPoint = null;
    
    if (_selectedPointIndex != null) {
      onStatusChanged?.call('Ponto ${_selectedPointIndex! + 1} movido');
    } else if (_selectedIntermediateIndex != null) {
      onStatusChanged?.call('Novo ponto adicionado');
      _selectedIntermediateIndex = null;
    }
    
    return true;
  }
  
  /// Encontra o ponto mais próximo do toque
  int? _findNearestPoint(LatLng tapPosition, List<LatLng> polygonPoints, MapController mapController) {
    for (int i = 0; i < polygonPoints.length; i++) {
      final point = polygonPoints[i];
      final screenPoint = mapController.camera.latLngToScreenPoint(point);
      final tapScreenPoint = mapController.camera.latLngToScreenPoint(tapPosition);
      
      final distance = (screenPoint - tapScreenPoint).distance;
      if (distance <= _hitboxRadius) {
        return i;
      }
    }
    return null;
  }
  
  /// Encontra o handle intermediário mais próximo
  int? _findNearestIntermediateHandle(LatLng tapPosition, List<LatLng> polygonPoints, MapController mapController) {
    for (int i = 0; i < polygonPoints.length; i++) {
      final nextIndex = (i + 1) % polygonPoints.length;
      final midPoint = _calculateMidpoint(polygonPoints[i], polygonPoints[nextIndex]);
      
      final screenPoint = mapController.camera.latLngToScreenPoint(midPoint);
      final tapScreenPoint = mapController.camera.latLngToScreenPoint(tapPosition);
      
      final distance = (screenPoint - tapScreenPoint).distance;
      if (distance <= _intermediateHandleHitbox) {
        return i; // Retorna o índice do primeiro ponto do segmento
      }
    }
    return null;
  }
  
  /// Calcula ponto médio entre dois pontos
  LatLng _calculateMidpoint(LatLng point1, LatLng point2) {
    return LatLng(
      (point1.latitude + point2.latitude) / 2,
      (point1.longitude + point2.longitude) / 2,
    );
  }
  
  /// Seleciona um ponto
  void _selectPoint(int index) {
    _selectedPointIndex = index;
    _selectedIntermediateIndex = null;
    onStatusChanged?.call('Ponto ${index + 1} selecionado - Arraste para mover');
  }
  
  /// Seleciona um handle intermediário
  void _selectIntermediateHandle(int index) {
    _selectedIntermediateIndex = index;
    _selectedPointIndex = null;
    onStatusChanged?.call('Handle intermediário selecionado - Arraste para criar novo ponto');
  }
  
  /// Desseleciona tudo
  void _deselectAll() {
    _selectedPointIndex = null;
    _selectedIntermediateIndex = null;
    onStatusChanged?.call('Nenhum ponto selecionado');
  }
  
  /// Atualiza posição de um ponto existente
  void _updatePointPosition(int index, LatLng newPosition, List<LatLng> polygonPoints) {
    if (index >= 0 && index < polygonPoints.length) {
      final oldPosition = polygonPoints[index];
      polygonPoints[index] = newPosition;
      
      onPointMoved?.call(index, newPosition);
      onPolygonChanged?.call(List.from(polygonPoints));
    }
  }
  
  /// Cria novo ponto a partir de handle intermediário
  void _createNewPoint(int segmentIndex, LatLng newPosition, List<LatLng> polygonPoints) {
    final insertIndex = segmentIndex + 1;
    polygonPoints.insert(insertIndex, newPosition);
    
    onPointAdded?.call(insertIndex, newPosition);
    onPolygonChanged?.call(List.from(polygonPoints));
  }
  
  /// Remove um ponto
  void removePoint(int index, List<LatLng> polygonPoints) {
    if (polygonPoints.length > 3 && index >= 0 && index < polygonPoints.length) {
      polygonPoints.removeAt(index);
      _deselectAll();
      
      onPointRemoved?.call(index);
      onPolygonChanged?.call(List.from(polygonPoints));
    }
  }
  
  /// Gera widgets para os pontos do polígono
  List<Widget> buildPolygonPoints(List<LatLng> polygonPoints, MapController mapController) {
    if (!_isEditing) return [];
    
    final widgets = <Widget>[];
    
    for (int i = 0; i < polygonPoints.length; i++) {
      final point = polygonPoints[i];
      final isSelected = _selectedPointIndex == i;
      
      // Ponto principal
      widgets.add(
        Marker(
          point: point,
          width: _hitboxRadius * 2,
          height: _hitboxRadius * 2,
          builder: (context) => GestureDetector(
            onTap: () => _selectPoint(i),
            child: Container(
              width: _hitboxRadius * 2,
              height: _hitboxRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent, // Hitbox invisível
              ),
              child: Center(
                child: Container(
                  width: _pointRadius * 2,
                  height: _pointRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.blue : Colors.red,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Handle intermediário
      final nextIndex = (i + 1) % polygonPoints.length;
      final midPoint = _calculateMidpoint(point, polygonPoints[nextIndex]);
      final isIntermediateSelected = _selectedIntermediateIndex == i;
      
      widgets.add(
        Marker(
          point: midPoint,
          width: _intermediateHandleHitbox * 2,
          height: _intermediateHandleHitbox * 2,
          builder: (context) => GestureDetector(
            onTap: () => _selectIntermediateHandle(i),
            child: Container(
              width: _intermediateHandleHitbox * 2,
              height: _intermediateHandleHitbox * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent, // Hitbox invisível
              ),
              child: Center(
                child: Container(
                  width: _intermediateHandleRadius * 2,
                  height: _intermediateHandleRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isIntermediateSelected ? Colors.green : Colors.orange,
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }
  
  /// Gera widget de status da edição
  Widget buildStatusWidget() {
    if (!_isEditing) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'Modo de Edição Ativo',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

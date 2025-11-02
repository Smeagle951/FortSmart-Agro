# Guia de Implementação: Melhorias na Tela de Monitoramento Avançado

Este guia explica como implementar as melhorias na tela de monitoramento avançado do FortSmart Agro, utilizando os novos componentes e serviços criados.

## Visão Geral das Melhorias

1. **Interface do Usuário Aprimorada**
   - Instruções claras para o usuário durante o monitoramento
   - Indicadores visuais para o status de navegação
   - Melhor visualização dos pontos de monitoramento e rotas

2. **Navegação Assistida Aprimorada**
   - Indicadores mais claros para a rota e pontos de monitoramento
   - Feedback visual sobre a proximidade dos pontos
   - Instruções contextuais baseadas no status da navegação

3. **Integração de Dados Aprimorada**
   - Melhor sincronização entre talhões, culturas e pragas
   - Gerenciamento de estado centralizado para o monitoramento
   - Salvamento e recuperação de dados mais robustos

## Componentes Criados

### 1. Widgets de Instrução e Status
- `MonitoringInstructionCard`: Exibe instruções claras para o usuário
- `NavigationAssistCard`: Fornece assistência de navegação com distância e direção
- `MonitoringStatusCard`: Exibe um resumo do monitoramento com estatísticas

### 2. Widgets de Mapa Aprimorados
- `EnhancedMonitoringMarker`: Marcadores de pontos com design melhorado
- `EnhancedMonitoringRoute`: Visualização de rota com design melhorado
- `EnhancedPlotPolygon`: Visualização de talhão com design melhorado
- `EnhancedCurrentLocationMarker`: Marcador de localização atual com indicador de direção

### 3. Serviço de Monitoramento Aprimorado
- `EnhancedMonitoringService`: Gerencia o estado do monitoramento e a integração de dados

## Passos para Implementação

### 1. Integrar o Serviço de Monitoramento Aprimorado

Substitua o gerenciamento de estado atual pelo `EnhancedMonitoringService`:

```dart
// Em _AdvancedMonitoringScreenState
final EnhancedMonitoringService _monitoringService = EnhancedMonitoringService();

@override
void initState() {
  super.initState();
  _setupMonitoringService();
  
  // Assine as streams para receber atualizações
  _monitoringService.monitoringStatusStream.listen(_handleMonitoringStatusChange);
  _monitoringService.navigationStatusStream.listen(_handleNavigationStatusChange);
}

Future<void> _setupMonitoringService() async {
  if (widget.monitoringId != null) {
    // Retomar monitoramento existente
    await _monitoringService.initializeMonitoring(
      plotId: widget.plotId ?? '',
      cropId: widget.cropId ?? '',
      existingMonitoringId: widget.monitoringId,
    );
  }
}

void _handleMonitoringStatusChange(MonitoringStatus status) {
  setState(() {
    _isMonitoringStarted = status != MonitoringStatus.notStarted;
    // Atualize outros estados conforme necessário
  });
}

void _handleNavigationStatusChange(NavigationStatus status) {
  setState(() {
    _isNavigating = status == NavigationStatus.navigating || status == NavigationStatus.nearPoint;
    _isNearPoint = status == NavigationStatus.nearPoint;
    // Atualize outros estados conforme necessário
  });
}

@override
void dispose() {
  _monitoringService.dispose();
  super.dispose();
}
```

### 2. Melhorar a Barra Inferior

Substitua o método `_buildBottomBar` pelo seguinte:

```dart
Widget _buildBottomBar() {
  if (_isMonitoringStarted) {
    return Container(
      height: 150, // Aumentado para acomodar as instruções
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruções para o usuário
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: _isNavigating ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isNavigating ? Colors.blue.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _isNavigating ? Icons.navigation : Icons.info_outline,
                  color: _isNavigating ? Colors.blue : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isNavigating
                        ? 'Navegando para o Ponto ${_currentPointIndex + 1}. Distância: ${_distanceToNextPoint.toStringAsFixed(1)}m'
                        : 'Toque em um ponto para iniciar a navegação ou adicione novos pontos com o botão de edição.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isNavigating ? Colors.blue[800] : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Título da seção de pontos
          Row(
            children: [
              Icon(Icons.route, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pontos a monitorar: ${_routePoints.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Lista horizontal de pontos
          Expanded(
            child: _routePoints.isEmpty
                ? Center(
                    child: Text(
                      'Toque no botão de edição e depois no mapa para adicionar pontos',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _routePoints.length,
                    itemBuilder: (context, index) {
                      final isCurrentPoint = index == _currentPointIndex && _isNavigating;
                      final isCompleted = _routePoints[index].completed;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentPointIndex = index;
                            if (!_isNavigating) {
                              _toggleNavigation();
                            }
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.only(right: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: isCurrentPoint 
                              ? Colors.blue.withOpacity(0.1) 
                              : isCompleted 
                                  ? Colors.green.withOpacity(0.1) 
                                  : Colors.white,
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isCurrentPoint 
                                            ? Colors.blue 
                                            : isCompleted 
                                                ? Colors.green 
                                                : Colors.grey[300],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: isCompleted
                                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                                            : Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (isCurrentPoint)
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ponto ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCurrentPoint ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrentPoint 
                                        ? Colors.blue 
                                        : isCompleted 
                                            ? Colors.green 
                                            : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  } else {
    // Quando o monitoramento não está iniciado, mostrar botão de iniciar
    final bool canStartMonitoring = _selectedPlot != null && _selectedCropId.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canStartMonitoring)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecione um talhão e uma cultura para iniciar o monitoramento',
                      style: TextStyle(color: Colors.amber[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton.icon(
            onPressed: canStartMonitoring ? _startMonitoring : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('INICIAR MONITORAMENTO'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Melhorar a Visualização do Mapa

Substitua os marcadores e polilinha atuais pelos componentes aprimorados:

```dart
// No método build, dentro do Stack do mapa
children: [
  // Mapa base
  FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      center: _getMapCenter(),
      zoom: 16.0,
      onTap: _handleMapTap,
    ),
    layers: [
      // Camadas de mapa existentes...
      
      // Polígono do talhão
      if (_selectedPlot != null && _selectedPlot!.coordinates.isNotEmpty)
        EnhancedPlotPolygon(
          points: _selectedPlot!.coordinates.map((coord) => LatLng(coord.latitude, coord.longitude)).toList(),
          label: _selectedPlot!.name,
        ),
      
      // Rota entre pontos
      if (_routePoints.isNotEmpty)
        EnhancedMonitoringRoute(
          points: _routeLatLngs,
          routeToCurrentPoint: _isNavigating && _currentPointIndex >= 0 
              ? [_routeLatLngs[_currentPointIndex]] 
              : [],
          currentPosition: _currentPosition != null 
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
              : null,
        ),
      
      // Marcadores de pontos
      MarkerLayer(
        markers: _routePoints.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return EnhancedMonitoringMarker(
            position: LatLng(point.latitude, point.longitude),
            label: '${index + 1}',
            isCurrentPoint: index == _currentPointIndex && _isNavigating,
            isCompleted: point.completed,
            onTap: () {
              setState(() {
                _currentPointIndex = index;
                if (!_isNavigating) {
                  _toggleNavigation();
                }
              });
            },
          );
        }).toList(),
      ),
      
      // Marcador de localização atual
      if (_currentPosition != null)
        EnhancedCurrentLocationMarker(
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          accuracy: _currentPosition!.accuracy,
          heading: _currentPosition!.heading,
        ),
    ],
  ),
  
  // Informações do ponto atual
  if (_isNavigating && _currentPointIndex >= 0 && _currentPointIndex < _routePoints.length)
    Positioned(
      left: 16,
      bottom: 160,
      child: NavigationAssistCard(
        distance: _distanceToNextPoint,
        pointName: 'Ponto ${_currentPointIndex + 1}',
        onCenterMap: _centerMapOnCurrentPoint,
      ),
    ),
  
  // Botões de controle existentes...
],
```

### 4. Adicionar Instruções Contextuais

Adicione um widget de instruções no topo do mapa:

```dart
// No método build, dentro do Stack do mapa, após o FlutterMap
Positioned(
  top: 16,
  left: 16,
  right: 16,
  child: MonitoringInstructionCard(
    title: _getInstructionTitle(),
    message: _getInstructionMessage(),
    icon: _getInstructionIcon(),
    color: _getInstructionColor(),
    onTap: _showHelpDialog,
  ),
),

// Adicione estes métodos auxiliares
String _getInstructionTitle() {
  if (!_isMonitoringStarted) return 'Prepare o monitoramento';
  if (_isDrawingMode) return 'Modo de adição de pontos';
  if (_isNavigating) {
    if (_isNearPoint) return 'Ponto encontrado!';
    return 'Navegando para o ponto';
  }
  if (_routePoints.isEmpty) return 'Adicione pontos de monitoramento';
  return 'Monitoramento em andamento';
}

String _getInstructionMessage() {
  if (!_isMonitoringStarted) return 'Selecione talhão, cultura e pragas para iniciar';
  if (_isDrawingMode) return 'Toque no mapa para adicionar pontos de monitoramento';
  if (_isNavigating) {
    if (_isNearPoint) return 'Você chegou ao ponto. Registre os dados de monitoramento.';
    return 'Siga em direção ao Ponto ${_currentPointIndex + 1}. Distância: ${_distanceToNextPoint.toStringAsFixed(1)}m';
  }
  if (_routePoints.isEmpty) return 'Use o botão de edição para adicionar pontos no mapa';
  return 'Toque em um ponto para iniciar a navegação';
}

IconData _getInstructionIcon() {
  if (!_isMonitoringStarted) return Icons.playlist_add_check;
  if (_isDrawingMode) return Icons.edit_location;
  if (_isNavigating) {
    if (_isNearPoint) return Icons.location_on;
    return Icons.navigation;
  }
  if (_routePoints.isEmpty) return Icons.add_location;
  return Icons.map;
}

Color _getInstructionColor() {
  if (!_isMonitoringStarted) return Colors.purple;
  if (_isDrawingMode) return Colors.red;
  if (_isNavigating) {
    if (_isNearPoint) return Colors.green;
    return Colors.blue;
  }
  if (_routePoints.isEmpty) return Colors.orange;
  return Colors.teal;
}
```

### 5. Melhorar o Diálogo de Ajuda

Adicione um diálogo de ajuda mais informativo:

```dart
void _showHelpDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.help_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text('Ajuda do Monitoramento'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHelpItem(
              'Selecionar talhão e cultura',
              'Use os menus no topo da tela para selecionar o talhão e a cultura a serem monitorados.',
              Icons.crop,
            ),
            const Divider(),
            _buildHelpItem(
              'Adicionar pontos',
              'Toque no botão de edição e depois no mapa para adicionar pontos de monitoramento.',
              Icons.edit_location,
            ),
            const Divider(),
            _buildHelpItem(
              'Navegar entre pontos',
              'Toque em um ponto na lista ou no mapa para iniciar a navegação até ele.',
              Icons.navigation,
            ),
            const Divider(),
            _buildHelpItem(
              'Registrar dados',
              'Quando chegar a um ponto, registre os dados de monitoramento para aquele ponto.',
              Icons.assignment,
            ),
            const Divider(),
            _buildHelpItem(
              'Finalizar monitoramento',
              'Após completar todos os pontos, toque no botão de finalizar para concluir o monitoramento.',
              Icons.check_circle,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ENTENDI'),
        ),
      ],
    ),
  );
}

Widget _buildHelpItem(String title, String description, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

## Considerações Finais

1. **Implementação Incremental**: Implemente essas melhorias em etapas pequenas e teste cada uma antes de prosseguir.

2. **Preservação de Funcionalidades**: Certifique-se de preservar todas as funcionalidades existentes ao integrar as melhorias.

3. **Testes**: Teste cada melhoria em diferentes cenários para garantir que funcione corretamente.

4. **Feedback do Usuário**: Colete feedback dos usuários sobre as melhorias para continuar refinando a interface.

5. **Documentação**: Mantenha a documentação atualizada com as novas funcionalidades e melhorias.

Estas melhorias tornarão a tela de monitoramento avançado mais intuitiva, com instruções claras para o usuário, melhor integração entre módulos e navegação assistida mais eficiente.

import 'package:flutter/material.dart';
import '../main/monitoring_controller.dart';

/// Widget de controles para o módulo de monitoramento
/// Exibe botões e controles para gerenciar funcionalidades
class MonitoringControlsWidget extends StatelessWidget {
  final MonitoringController controller;
  final bool showAdvancedControls;
  final bool showQuickActions;
  
  const MonitoringControlsWidget({
    super.key,
    required this.controller,
    this.showAdvancedControls = true,
    this.showQuickActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          
          if (showQuickActions) ...[
            _buildQuickActions(),
            const SizedBox(height: 16),
          ],
          
          if (showAdvancedControls) ...[
            _buildAdvancedControls(),
            const SizedBox(height: 16),
          ],
          
          _buildStatusControls(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.control_camera,
          color: Colors.indigo[600],
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Controles de Monitoramento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildControlButton(
                'Iniciar',
                Icons.play_arrow,
                Colors.green,
                () => controller.startNewMonitoring(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildControlButton(
                'Pausar',
                Icons.pause,
                Colors.orange,
                () => _pauseMonitoring(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildControlButton(
                'Parar',
                Icons.stop,
                Colors.red,
                () => _stopMonitoring(),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAdvancedControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Controles Avançados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Controles de localização
        _buildLocationControls(),
        
        const SizedBox(height: 12),
        
        // Controles de mapa
        _buildMapControls(),
        
        const SizedBox(height: 12),
        
        // Controles de dados
        _buildDataControls(),
      ],
    );
  }
  
  Widget _buildLocationControls() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Controles de Localização',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    'GPS Ativo',
                    controller.state.mostrarLocalizacaoAtual,
                    (value) => controller.state.setMostrarLocalizacaoAtual(value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildControlButton(
                    'Atualizar',
                    Icons.refresh,
                    Colors.blue,
                    () => controller.refreshData(),
                    isSmall: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMapControls() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Controles do Mapa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    'Modo Satélite',
                    controller.state.modoSatelite,
                    (value) => controller.state.setModoSatelite(value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    'Mostrar Rota',
                    controller.state.hasRoute,
                    (value) => _toggleRouteDisplay(value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataControls() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_usage, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Controles de Dados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildControlButton(
                    'Sincronizar',
                    Icons.sync,
                    Colors.green,
                    () => _syncData(),
                    isSmall: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildControlButton(
                    'Exportar',
                    Icons.download,
                    Colors.blue,
                    () => _exportData(),
                    isSmall: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildControlButton(
                    'Limpar',
                    Icons.clear_all,
                    Colors.red,
                    () => controller.clearData(),
                    isSmall: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status e Configurações',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Status',
                controller.isLoading ? 'Carregando' : 'Pronto',
                controller.isLoading ? Colors.orange : Colors.green,
                Icons.info_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'Talhões',
                '${controller.availableTalhoes.length}',
                Colors.blue,
                Icons.agriculture,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                'Culturas',
                '${controller.availableCulturas.length}',
                Colors.green,
                Icons.grass,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildControlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isSmall = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isSmall ? 16 : 20),
      label: Text(
        label,
        style: TextStyle(fontSize: isSmall ? 12 : 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 12,
          vertical: isSmall ? 8 : 12,
        ),
      ),
    );
  }
  
  Widget _buildToggleButton(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  // Métodos de controle
  void _pauseMonitoring() {
    // TODO: Implementar pausa do monitoramento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Monitoramento pausado'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  void _stopMonitoring() {
    // TODO: Implementar parada do monitoramento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Monitoramento parado'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _toggleRouteDisplay(bool value) {
    if (value) {
      // TODO: Mostrar rota
    } else {
      controller.state.clearRoute();
    }
  }
  
  void _syncData() {
    // TODO: Implementar sincronização
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sincronizando dados...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _exportData() {
    // TODO: Implementar exportação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando dados...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

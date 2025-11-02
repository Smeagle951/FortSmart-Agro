import 'package:flutter/material.dart';
import '../main/monitoring_controller.dart';

/// Seção de detalhes do monitoramento
/// Exibe informações detalhadas sobre talhões e culturas selecionadas
class MonitoringDetailsSection extends StatelessWidget {
  final MonitoringController controller;
  
  const MonitoringDetailsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _buildDetailsContent(),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(
          Icons.details,
          color: Colors.teal[600],
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Detalhes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailsContent() {
    if (controller.selectedTalhao == null && controller.selectedCultura == null) {
      return _buildNoSelectionMessage();
    }
    
    return Column(
      children: [
        if (controller.selectedTalhao != null) ...[
          _buildTalhaoDetails(),
          const SizedBox(height: 16),
        ],
        
        if (controller.selectedCultura != null) ...[
          _buildCulturaDetails(),
          const SizedBox(height: 16),
        ],
        
        _buildAdditionalInfo(),
      ],
    );
  }
  
  Widget _buildNoSelectionMessage() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma seleção ativa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione um talhão ou cultura para ver os detalhes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTalhaoDetails() {
    final talhao = controller.selectedTalhao!;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Detalhes do Talhão',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Nome', talhao.nome ?? 'N/A'),
            _buildDetailRow('ID', talhao.id ?? 'N/A'),
            if (talhao.area != null)
              _buildDetailRow('Área', '${talhao.area!.toStringAsFixed(2)} ha'),
            if (talhao.culturaId != null)
              _buildDetailRow('Cultura ID', '${talhao.culturaId}'),
            if (talhao.poligono != null)
              _buildDetailRow('Pontos do Polígono', '${talhao.poligono!.length}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCulturaDetails() {
    final cultura = controller.selectedCultura!;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grass, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Detalhes da Cultura',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Nome', cultura.nome ?? 'N/A'),
            _buildDetailRow('ID', cultura.id ?? 'N/A'),
            if (cultura.tipo != null)
              _buildDetailRow('Tipo', cultura.tipo!),
            if (cultura.variedade != null)
              _buildDetailRow('Variedade', cultura.variedade!),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdditionalInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Informações Adicionais',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Localização Ativa', controller.currentPosition != null ? 'Sim' : 'Não'),
            if (controller.currentPosition != null) ...[
              _buildDetailRow('Latitude', '${controller.currentPosition!.latitude.toStringAsFixed(6)}'),
              _buildDetailRow('Longitude', '${controller.currentPosition!.longitude.toStringAsFixed(6)}'),
            ],
            _buildDetailRow('Modo do Mapa', controller.state.modoSatelite ? 'Satélite' : 'Terreno'),
            _buildDetailRow('Status', controller.isLoading ? 'Carregando' : 'Pronto'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

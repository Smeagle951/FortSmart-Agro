import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/infestation_alert.dart';
import '../models/alert_status.dart';

/// Tela de detalhes do alerta
class AlertDetailsScreen extends StatelessWidget {
  final InfestationAlert alert;

  const AlertDetailsScreen({
    Key? key,
    required this.alert,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Alerta'),
        backgroundColor: _getRiskColor(alert.riskLevel),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (alert.status == AlertStatus.active)
            IconButton(
              onPressed: () => _acknowledgeAlert(context),
              icon: const Icon(Icons.check),
              tooltip: 'Reconhecer Alerta',
            ),
          if (alert.status == AlertStatus.acknowledged)
            IconButton(
              onPressed: () => _resolveAlert(context),
              icon: const Icon(Icons.done_all),
              tooltip: 'Resolver Alerta',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal com informações do alerta
            _buildMainInfoCard(),
            const SizedBox(height: 16),
            
            // Card de status e prioridade
            _buildStatusCard(),
            const SizedBox(height: 16),
            
            // Card de mensagem e descrição
            _buildMessageCard(),
            const SizedBox(height: 16),
            
            // Card de origem e metadados
            _buildOriginCard(),
            const SizedBox(height: 16),
            
            // Card de histórico (se reconhecido/resolvido)
            if (alert.isAcknowledged || alert.status == AlertStatus.resolved) ...[
              _buildHistoryCard(),
              const SizedBox(height: 16),
            ],
            
            // Card de notas (se houver)
            if (alert.notes.isNotEmpty) ...[
              _buildNotesCard(),
              const SizedBox(height: 16),
            ],
            
            // Ações
            _buildActionsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getRiskColor(alert.riskLevel).withOpacity(0.1),
              _getRiskColor(alert.riskLevel).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRiskIcon(alert.riskLevel),
                  color: _getRiskColor(alert.riskLevel),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.message.isNotEmpty ? alert.message : 'Alerta de Infestação',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Nível: ${alert.level}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRiskColor(alert.riskLevel),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    alert.riskLevel.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Prioridade: ${alert.priorityScore.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status e Prioridade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Status',
                    _getStatusText(alert.status),
                    _getStatusIcon(alert.status),
                    _getStatusColor(alert.status),
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Prioridade',
                    '${alert.priorityScore.toStringAsFixed(1)}',
                    Icons.priority_high,
                    _getPriorityColor(alert.priorityScore),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: alert.priorityScore / 100.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getPriorityColor(alert.priorityScore)),
            ),
            const SizedBox(height: 8),
            Text(
              'Score de Prioridade: ${alert.priorityScore.toStringAsFixed(1)}/100',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mensagem e Descrição',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (alert.message.isNotEmpty) ...[
              Text(
                'Mensagem:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alert.message,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Descrição:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              alert.description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginCard() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Origem e Metadados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Criado em', dateFormat.format(alert.createdAt), Icons.schedule),
            _buildInfoRow('Origem', alert.origin, Icons.source),
            if (alert.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Metadados:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.metadata.toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histórico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (alert.acknowledgedAt != null) ...[
              _buildInfoRow('Reconhecido em', dateFormat.format(alert.acknowledgedAt!), Icons.check_circle),
              if (alert.acknowledgedBy != null)
                _buildInfoRow('Reconhecido por', alert.acknowledgedBy!, Icons.person),
            ],
            if (alert.resolvedAt != null) ...[
              _buildInfoRow('Resolvido em', dateFormat.format(alert.resolvedAt!), Icons.done_all),
              if (alert.resolvedBy != null)
                _buildInfoRow('Resolvido por', alert.resolvedBy!, Icons.person),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                alert.notes,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (alert.status == AlertStatus.active) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acknowledgeAlert(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Reconhecer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resolveAlert(context),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Resolver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (alert.status == AlertStatus.acknowledged) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resolveAlert(context),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Resolver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Alerta já foi resolvido',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[600], size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _acknowledgeAlert(BuildContext context) {
    // TODO: Implementar reconhecimento do alerta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de reconhecimento em desenvolvimento')),
    );
  }

  void _resolveAlert(BuildContext context) {
    // TODO: Implementar resolução do alerta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de resolução em desenvolvimento')),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'crítico':
      case 'critico':
        return Colors.red;
      case 'alto':
        return Colors.orange;
      case 'médio':
      case 'medio':
        return Colors.yellow[700]!;
      case 'baixo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'crítico':
      case 'critico':
        return Icons.dangerous;
      case 'alto':
        return Icons.warning;
      case 'médio':
      case 'medio':
        return Icons.info;
      case 'baixo':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return 'Ativo';
      case AlertStatus.acknowledged:
        return 'Reconhecido';
      case AlertStatus.resolved:
        return 'Resolvido';
    }
  }

  IconData _getStatusIcon(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return Icons.warning;
      case AlertStatus.acknowledged:
        return Icons.check_circle;
      case AlertStatus.resolved:
        return Icons.done_all;
    }
  }

  Color _getStatusColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return Colors.red;
      case AlertStatus.acknowledged:
        return Colors.orange;
      case AlertStatus.resolved:
        return Colors.green;
    }
  }

  Color _getPriorityColor(double priority) {
    if (priority >= 80) return Colors.red;
    if (priority >= 60) return Colors.orange;
    if (priority >= 40) return Colors.yellow[700]!;
    return Colors.green;
  }
}

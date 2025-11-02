import 'package:flutter/material.dart';
import '../../models/dashboard/dashboard_data.dart';
import '../../utils/date_formatter.dart';
import 'animated_dashboard_card.dart';

/// Widget principal que exibe todos os cards informativos da dashboard
class InformativeDashboardCards extends StatelessWidget {
  final DashboardData dashboardData;
  final VoidCallback? onFarmTap;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onTalhoesTap;
  final VoidCallback? onPlantiosTap;
  final VoidCallback? onMonitoramentosTap;
  final VoidCallback? onEstoqueTap;

  const InformativeDashboardCards({
    Key? key,
    required this.dashboardData,
    this.onFarmTap,
    this.onAlertsTap,
    this.onTalhoesTap,
    this.onPlantiosTap,
    this.onMonitoramentosTap,
    this.onEstoqueTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cards em grid 2x3
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            // Card da Fazenda
            FarmInfoCard(
              farmProfile: dashboardData.farmProfile,
              onTap: onFarmTap,
            ),
            
            // Card de Alertas
            AlertsInfoCard(
              alerts: dashboardData.alerts,
              onTap: onAlertsTap,
            ),
            
            // Card de Talhões
            TalhoesInfoCard(
              talhoesSummary: dashboardData.talhoesSummary,
              onTap: onTalhoesTap,
            ),
            
            // Card de Plantios
            PlantiosInfoCard(
              plantiosAtivos: dashboardData.plantiosAtivos,
              onTap: onPlantiosTap,
            ),
            
            // Card de Monitoramentos
            MonitoramentosInfoCard(
              monitoramentosSummary: dashboardData.monitoramentosSummary,
              onTap: onMonitoramentosTap,
            ),
            
            // Card de Estoque
            EstoqueInfoCard(
              estoqueSummary: dashboardData.estoqueSummary,
              onTap: onEstoqueTap,
            ),
          ],
        ),
      ],
    );
  }
}

/// Card informativo da fazenda
class FarmInfoCard extends StatelessWidget {
  final FarmProfile farmProfile;
  final VoidCallback? onTap;

  const FarmInfoCard({
    Key? key,
    required this.farmProfile,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isConfigured = farmProfile.nome != 'Fazenda não configurada';
    
    return AnimatedDashboardCard(
      hasData: isConfigured,
      successColor: ModuleColors.getFarmColor(),
      baseColor: Colors.grey.shade50,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isConfigured ? ModuleColors.getFarmColor().withOpacity(0.2) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: isConfigured ? ModuleColors.getFarmColor() : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fazenda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isConfigured ? ModuleColors.getFarmColor() : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status principal
              Text(
                isConfigured ? farmProfile.nome : 'Não configurada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isConfigured ? ModuleColors.getFarmColor() : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Detalhes
              _buildDetailRow('Proprietário', farmProfile.proprietario),
              _buildDetailRow('Localização', farmProfile.localizacao),
              _buildDetailRow('Área', '${farmProfile.areaTotal.toStringAsFixed(1)} ha'),
            ],
          ),
        ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card informativo de alertas
class AlertsInfoCard extends StatelessWidget {
  final List<Alert> alerts;
  final VoidCallback? onTap;

  const AlertsInfoCard({
    Key? key,
    required this.alerts,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeAlerts = alerts.where((alert) => alert.isActive).toList();
    final criticalAlerts = activeAlerts.where((alert) => 
      alert.level == AlertLevel.critico || alert.level == AlertLevel.alto).toList();
    
    final hasAlerts = activeAlerts.isNotEmpty;
    final hasCriticalAlerts = criticalAlerts.isNotEmpty;

    return AnimatedDashboardCard(
      hasData: hasAlerts,
      successColor: hasCriticalAlerts ? Colors.red : Colors.orange,
      baseColor: Colors.grey.shade50,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasCriticalAlerts ? Colors.red.withOpacity(0.2) : 
                             hasAlerts ? Colors.orange.withOpacity(0.2) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning,
                      color: hasCriticalAlerts ? Colors.red : 
                             hasAlerts ? Colors.orange : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alertas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasCriticalAlerts ? Colors.red : 
                               hasAlerts ? Colors.orange : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (hasAlerts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasCriticalAlerts ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${activeAlerts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status principal
              Text(
                hasAlerts ? '${activeAlerts.length} ativos' : 'Nenhum ativo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasCriticalAlerts ? Colors.red.shade700 : 
                         hasAlerts ? Colors.orange.shade700 : Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Detalhes
              if (hasAlerts) ...[
                _buildDetailRow('Baixo Estoque', '${alerts.where((a) => a.type == AlertType.estoque).length}'),
                _buildDetailRow('Monitoramentos Pendentes', '${alerts.where((a) => a.type == AlertType.monitoramento).length}'),
              ] else ...[
                _buildDetailRow('Sistema', 'Funcionando normalmente'),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card informativo de talhões
class TalhoesInfoCard extends StatelessWidget {
  final TalhoesSummary talhoesSummary;
  final VoidCallback? onTap;

  const TalhoesInfoCard({
    Key? key,
    required this.talhoesSummary,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasTalhoes = talhoesSummary.totalTalhoes > 0;

    return AnimatedDashboardCard(
      hasData: hasTalhoes,
      successColor: ModuleColors.getTalhoesColor(),
      baseColor: Colors.grey.shade50,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasTalhoes ? ModuleColors.getTalhoesColor().withOpacity(0.2) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.grid_view,
                      color: hasTalhoes ? ModuleColors.getTalhoesColor() : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Talhões',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasTalhoes ? ModuleColors.getTalhoesColor() : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status principal
              Text(
                hasTalhoes ? '${talhoesSummary.totalTalhoes} cadastrados' : 'Nenhum cadastrado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasTalhoes ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Detalhes
              _buildDetailRow('Área Total', '${talhoesSummary.areaTotal.toStringAsFixed(1)} ha'),
              _buildDetailRow('Ativos', '${talhoesSummary.talhoesAtivos} talhões'),
              _buildDetailRow('Última Atualização', DateFormatter.formatDate(talhoesSummary.ultimaAtualizacao)),
            ],
          ),
        ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card informativo de plantios
class PlantiosInfoCard extends StatelessWidget {
  final PlantiosAtivos plantiosAtivos;
  final VoidCallback? onTap;

  const PlantiosInfoCard({
    Key? key,
    required this.plantiosAtivos,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasPlantios = plantiosAtivos.totalPlantios > 0;

    return AnimatedDashboardCard(
      hasData: hasPlantios,
      successColor: ModuleColors.getPlantiosColor(),
      baseColor: Colors.grey.shade50,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasPlantios ? ModuleColors.getPlantiosColor().withOpacity(0.2) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.eco,
                      color: hasPlantios ? ModuleColors.getPlantiosColor() : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plantios',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasPlantios ? ModuleColors.getPlantiosColor() : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status principal
              Text(
                hasPlantios ? '${plantiosAtivos.totalPlantios} culturas' : '0 culturas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasPlantios ? Colors.green.shade700 : Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Detalhes
              _buildDetailRow('Área Plantada', '${plantiosAtivos.areaTotalPlantada.toStringAsFixed(1)} ha'),
              if (hasPlantios && plantiosAtivos.plantios.isNotEmpty) ...[
                _buildDetailRow('Cultura Principal', plantiosAtivos.plantios.first.cultura),
                _buildDetailRow('Variedade', plantiosAtivos.plantios.first.variedade),
              ] else ...[
                _buildDetailRow('Status', 'Nenhum plantio ativo'),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card informativo de monitoramentos
class MonitoramentosInfoCard extends StatelessWidget {
  final MonitoramentosSummary monitoramentosSummary;
  final VoidCallback? onTap;

  const MonitoramentosInfoCard({
    Key? key,
    required this.monitoramentosSummary,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasMonitorings = monitoramentosSummary.realizados > 0 || monitoramentosSummary.pendentes > 0;
    final hasPending = monitoramentosSummary.pendentes > 0;

    return AnimatedDashboardCard(
      hasData: hasMonitorings,
      successColor: ModuleColors.getMonitoramentoColor(),
      baseColor: Colors.grey.shade50,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasMonitorings ? ModuleColors.getMonitoramentoColor().withOpacity(0.2) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bug_report,
                      color: hasMonitorings ? ModuleColors.getMonitoramentoColor() : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Monitoramentos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasMonitorings ? ModuleColors.getMonitoramentoColor() : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (hasPending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${monitoramentosSummary.pendentes}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status principal
              Text(
                hasMonitorings ? '${monitoramentosSummary.realizados} realizados' : '0 realizados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasPending ? Colors.orange.shade700 : 
                         hasMonitorings ? Colors.purple.shade700 : Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Detalhes
              _buildDetailRow('Pendentes', '${monitoramentosSummary.pendentes}'),
              _buildDetailRow('Realizados', '${monitoramentosSummary.realizados}'),
              _buildDetailRow('Último', monitoramentosSummary.ultimoTalhao ?? 'Nenhum'),
            ],
          ),
        ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card informativo de estoque
class EstoqueInfoCard extends StatelessWidget {
  final EstoqueSummary estoqueSummary;
  final VoidCallback? onTap;

  const EstoqueInfoCard({
    Key? key,
    required this.estoqueSummary,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasItems = estoqueSummary.totalItens > 0;
    final hasLowStock = estoqueSummary.itensBaixoEstoque > 0;

    return AnimatedDashboardCard(
      hasData: hasItems,
      successColor: hasLowStock ? Colors.orange : ModuleColors.getEstoqueColor(),
      baseColor: Colors.grey.shade50,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com ícone
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasItems ? ModuleColors.getEstoqueColor().withOpacity(0.2) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory,
                      color: hasItems ? ModuleColors.getEstoqueColor() : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estoque',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasItems ? ModuleColors.getEstoqueColor() : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (hasLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${estoqueSummary.itensBaixoEstoque}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status principal
              Text(
                hasItems ? '${estoqueSummary.totalItens} itens' : '0 itens',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasLowStock ? Colors.red.shade700 : 
                         hasItems ? Colors.orange.shade700 : Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Detalhes
              _buildDetailRow('Total', '${estoqueSummary.totalItens} itens'),
              _buildDetailRow('Baixo Estoque', '${estoqueSummary.itensBaixoEstoque}'),
              if (hasItems && estoqueSummary.principaisInsumos.isNotEmpty) ...[
                _buildDetailRow('Principal', estoqueSummary.principaisInsumos.first.nome),
              ] else ...[
                _buildDetailRow('Status', 'Nenhum item cadastrado'),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/phenological_infestation_service.dart';

/// Card que exibe infestação considerando fenologia
/// Para uso no Relatório Agronômico
class PhenologicalInfestationCard extends StatelessWidget {
  final TalhaoInfestationResult result;
  final VoidCallback? onScheduleApplication;

  const PhenologicalInfestationCard({
    Key? key,
    required this.result,
    this.onScheduleApplication,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(),
          _buildOrganismsList(context),
          if (result.actionRequired) ...[
            const Divider(),
            _buildActionButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getGeneralLevelColor().withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, size: 28, color: Colors.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoramento de Infestação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.eco, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Estágio: ${result.phenologicalStage}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildGeneralLevelBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getGeneralLevelColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        result.generalLevel,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildOrganismsList(BuildContext context) {
    if (result.organisms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            '✅ Nenhuma infestação detectada',
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: result.organisms.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final organism = result.organisms[index];
        return _buildOrganismTile(context, organism);
      },
    );
  }

  Widget _buildOrganismTile(BuildContext context, OrganismInfestationResult organism) {
    final level = organism.level;
    final isCritical = level.isCriticalStage;
    
    return Container(
      color: isCritical ? Colors.red.shade50 : null,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getLevelColor(level.level),
          child: Text(
            level.level[0], // Primeira letra do nível
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                organism.organismName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCritical ? Colors.red.shade900 : null,
                ),
              ),
            ),
            if (isCritical)
              const Icon(Icons.warning, color: Colors.red, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // ✅ PADRÃO MIP: Mostrar TOTAL + MÉDIA
            Text(
              'Total: ${organism.totalQuantity} ${level.unit} | Média: ${organism.avgQuantity.toStringAsFixed(2)}/${level.unit}',
              style: TextStyle(
                fontSize: 13,
                color: _getLevelColor(level.level),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            // ✅ NÍVEL DE AÇÃO baseado na média
            Text(
              'Nível: ${level.level}',
              style: TextStyle(
                fontSize: 12,
                color: _getLevelColor(level.level),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // ✅ FREQUÊNCIA: % de pontos com infestação
            Text(
              'Frequência: ${organism.frequency.toStringAsFixed(1)}% (${organism.pointCount}/${organism.totalPoints} pontos)',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            if (isCritical)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚠️ FASE CRÍTICA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
        children: [
          _buildOrganismDetails(context, level),
        ],
      ),
    );
  }

  Widget _buildOrganismDetails(BuildContext context, InfestationLevel level) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: level.isCriticalStage ? Colors.red.shade50 : Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (level.stageDescription.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level.stageDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (level.damageType.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 18,
                  color: level.isCriticalStage ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level.damageType,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: level.isCriticalStage ? Colors.red.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _buildThresholdsInfo(level),
        ],
      ),
    );
  }

  Widget _buildThresholdsInfo(InfestationLevel level) {
    final thresholds = level.thresholds;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Níveis de Ação (Estágio Atual):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildThresholdRow('BAIXO', thresholds['low'], Colors.green, level.unit),
          _buildThresholdRow('MÉDIO', thresholds['medium'], Colors.orange, level.unit),
          _buildThresholdRow('ALTO', thresholds['high'], Colors.red, level.unit),
          _buildThresholdRow('CRÍTICO', thresholds['critical'], Colors.purple, level.unit),
        ],
      ),
    );
  }

  Widget _buildThresholdRow(String label, dynamic value, Color color, String unit) {
    if (value == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '≤ $value $unit',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AÇÃO RECOMENDADA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Infestação crítica detectada em estágio sensível. '
                        'Aplicação recomendada para evitar perdas.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onScheduleApplication,
              icon: const Icon(Icons.agriculture),
              label: const Text('AGENDAR APLICAÇÃO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGeneralLevelColor() {
    return _getLevelColor(result.generalLevel);
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'CRÍTICO':
        return Colors.purple;
      case 'ALTO':
        return Colors.red;
      case 'MÉDIO':
        return Colors.orange;
      case 'BAIXO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}


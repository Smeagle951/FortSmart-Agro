import 'package:flutter/material.dart';
import '../models/organism_catalog.dart';
import '../utils/enums.dart';

/// Widget para exibir estatísticas do catálogo de organismos
class OrganismCatalogStatistics extends StatelessWidget {
  final List<OrganismCatalog> organisms;
  final List<OrganismCatalog> filteredOrganisms;

  const OrganismCatalogStatistics({
    Key? key,
    required this.organisms,
    required this.filteredOrganisms,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();
    final isFiltered = organisms.length != filteredOrganisms.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: isFiltered ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  isFiltered ? 'Estatísticas (Filtradas)' : 'Estatísticas do Catálogo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isFiltered) ...[
                  const Spacer(),
                  Chip(
                    label: Text('${filteredOrganisms.length}/${organisms.length}'),
                    backgroundColor: Colors.orange.shade100,
                    labelStyle: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Estatísticas principais
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    stats['total'].toString(),
                    Icons.list,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Pragas',
                    stats['pests'].toString(),
                    Icons.bug_report,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Doenças',
                    stats['diseases'].toString(),
                    Icons.medical_services,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Plantas Daninhas',
                    stats['weeds'].toString(),
                    Icons.local_florist,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Estatísticas por cultura
            if (stats['crops'].isNotEmpty) ...[
              const Text(
                'Por Cultura',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (stats['crops'] as Map<String, int>).entries.map((entry) {
                  return Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStatistics() {
    final Map<String, int> organismsByType = {};
    final Map<String, int> organismsByCrop = {};
    
    for (var organism in filteredOrganisms) {
      // Conta por tipo
      final typeKey = organism.type.toString().split('.').last;
      organismsByType[typeKey] = (organismsByType[typeKey] ?? 0) + 1;
      
      // Conta por cultura
      organismsByCrop[organism.cropName] = (organismsByCrop[organism.cropName] ?? 0) + 1;
    }
    
    return {
      'total': filteredOrganisms.length,
      'pests': organismsByType['pest'] ?? 0,
      'diseases': organismsByType['disease'] ?? 0,
      'weeds': organismsByType['weed'] ?? 0,
      'crops': organismsByCrop,
    };
  }
}

import 'package:flutter/material.dart';

class PlantingModuleScreen extends StatelessWidget {
  const PlantingModuleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: const Text('Módulo de Plantio'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildOptionCard(
              context,
              title: 'Cadastro de Plantio',
              description: 'Registre as informações de plantio, incluindo talhão, cultura, data e equipamentos.',
              icon: Icons.agriculture,
              route: '/planting/cadastro',
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              title: 'Experimentos',
              description: 'Gerencie experimentos agrícolas, registrando resultados e observações.',
              icon: Icons.science,
              route: '/planting/experimentos',
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              title: 'Estande de Plantas',
              description: 'Calcule o estande de plantas por hectare com base nas medições de campo.',
              icon: Icons.grass,
              route: '/planting/estande',
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              title: 'Sementes por Hectare',
              description: 'Determine a quantidade de sementes necessárias por hectare.',
              icon: Icons.grain,
              route: '/planting/sementes-por-hectare',
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              title: 'Regulagem de Plantadeira',
              description: 'Configure a plantadeira para obter o estande desejado.',
              icon: Icons.settings,
              route: '/planting/regulagem-plantadeira',
            ),
            const SizedBox(height: 24),
            _buildSyncButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF228B22).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF228B22).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: const Color(0xFF228B22),
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'FortSmartAgro',
                style: TextStyle(
                  color: Color(0xFF228B22),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Módulo de Plantio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gerencie todas as atividades relacionadas ao plantio de forma eficiente.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String route,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF228B22).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF228B22),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Implementar sincronização com a nuvem
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronizando dados com a nuvem...'),
            backgroundColor: Color(0xFF228B22),
          ),
        );
      },
      icon: const Icon(Icons.cloud_sync),
      label: const Text('SINCRONIZAR COM A NUVEM'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF228B22),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PlantingMainMenuScreen extends StatelessWidget {
  const PlantingMainMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: const Text('Módulo de Plantio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              title: 'Cadastro de Plantio',
              icon: Icons.grass,
              description: 'Registre informações sobre plantios, culturas, talhões e equipamentos utilizados.',
              onTap: () {
                Navigator.of(context).pushNamed('/planting/cadastro');
              }
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              title: 'Estande de Plantas',
              icon: Icons.eco,
              description: 'Avalie a densidade de plantas e monitore o desenvolvimento da lavoura.',
              onTap: () {
                Navigator.of(context).pushNamed('/planting/estande');
              }
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              title: 'Experimentos',
              icon: Icons.science,
              description: 'Crie e gerencie experimentos agrícolas para testar novas técnicas e variedades.',
              onTap: () {
                Navigator.of(context).pushNamed('/planting/experimentos');
              }
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              title: 'Desenvolvimento da Cultura',
              icon: Icons.timeline,
              description: 'Acompanhe o desenvolvimento fenológico das culturas, estágios e ciclo.',
              onTap: () {
                Navigator.of(context).pushNamed('/planting/desenvolvimento-cultura');
              }
            ),
            const SizedBox(height: 16),
            _buildModuleCard(
              context,
              title: 'Cálculo de Sementes',
              icon: Icons.calculate,
              description: 'Calcule a quantidade de sementes necessárias por hectare com base em dados agronômicos.',
              onTap: () {
                Navigator.of(context).pushNamed('/planting/calculo-sementes');
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF228B22),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

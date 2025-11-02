import 'package:flutter/material.dart';
// import '../../routes.dart'; // Não utilizado
import '../../modules/planting/screens/stand_screen.dart';
import '../../modules/planting/screens/seeds_per_hectare_screen.dart';
import '../../modules/planting/screens/regulation_screen.dart';
import '../../modules/planting/screens/planting_screen.dart';
import '../../modules/planting/screens/experiment_screen.dart';
import '../colheita/colheita_main_screen.dart';
import 'germination_test/germination_test_main_screen.dart';

class PlantingModuleScreen extends StatelessWidget {
  const PlantingModuleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo de Plantio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader('Calculadoras de Plantio'),
              _buildModuleGrid(context, [
                ModuleItem(
                  title: 'Estande (plantas/ha)',
                  icon: Icons.calculate,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StandScreen()),
                    );
                  },
                ),
                ModuleItem(
                  title: 'Sementes por Hectare',
                  icon: Icons.grain,
                  color: Colors.brown,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SeedsPerHectareScreen()),
                    );
                  },
                ),
                ModuleItem(
                  title: 'Regulagem de Plantadeira',
                  icon: Icons.settings,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegulationScreen()),
                    );
                  },
                ),
              ]),
              
              _buildHeader('Registros de Plantio'),
              _buildModuleGrid(context, [
                ModuleItem(
                  title: 'Cadastro de Plantio',
                  icon: Icons.eco,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlantingScreen()),
                    );
                  },
                ),
                ModuleItem(
                  title: 'Teste de Germinação',
                  icon: Icons.science,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GerminationTestMainScreen()),
                    );
                  },
                ),
                ModuleItem(
                  title: 'Experimentos',
                  icon: Icons.experiment,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExperimentScreen()),
                    );
                  },
                ),
              ]),
              
              _buildHeader('Colheita'),
              _buildModuleGrid(context, [
                ModuleItem(
                  title: 'Módulo de Colheita',
                  icon: Icons.agriculture,
                  color: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ColheitaMainScreen()),
                    );
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context, List<ModuleItem> items) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) => _buildModuleCard(context, item)).toList(),
    );
  }

  Widget _buildModuleCard(BuildContext context, ModuleItem item) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: item.color.withOpacity(0.2),
              radius: 30,
              child: Icon(
                item.icon,
                color: item.color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModuleItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ModuleItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

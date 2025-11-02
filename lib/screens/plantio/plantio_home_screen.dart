import 'package:flutter/material.dart';
import '../../utils/theme_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../database/repositories/calculo_sementes_repository.dart';
import '../../database/repositories/historico_plantio_repository.dart';
import '../../services/data_cache_service.dart';
import '../../routes.dart';
import 'plantio_registro_screen.dart';
import '../historico/historico_plantio_screen.dart';
import 'submods/plantio_estande_plantas_screen.dart';
// import 'submods/tratamento_sementes/tratamento_sementes_screen.dart'; // Comentado temporariamente
// import 'submods/germination_test/widgets/germination_summary_widget.dart'; // Widget não encontrado
// import 'submods/germination_test/widgets/density_alerts_widget.dart'; // Widget não encontrado
import 'submods/germination_test/germination_test_main_screen.dart';
import 'submods/phenological_evolution/screens/phenological_main_screen.dart';

class PlantioHomeScreen extends StatelessWidget {
  final CalculoSementesRepository _calculoRepo = CalculoSementesRepository();
  final DataCacheService _dataCacheService = DataCacheService();
  
  // Removido o const do construtor devido aos campos não constantes
  PlantioHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Módulo Plantio',
        showBackButton: true,
        backgroundColor: FortSmartTheme.plantioAppBar,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            // Widgets de integração com germinação
            // const DensityAlertsWidget(), // Widget não encontrado
            // const GerminationSummaryWidget(), // Widget não encontrado
            const SizedBox(height: 16),
            _buildMenuGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestão de Plantios',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ThemeUtils.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Registre e acompanhe seus plantios com precisão agronômica',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMenuItem(
          context,
          'Novo Plantio',
          Icons.add_circle_outline,
          ThemeUtils.primaryColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PlantioRegistroScreen(),
            ),
          ),
        ),
        _buildMenuItem(
          context,
          'Histórico de Plantio',
          Icons.history,
          FortSmartTheme.plantioIcon,
          () => _abrirHistoricoPlantio(context),
        ),
        _buildMenuItem(
          context,
          'Cálculo de Sementes',
          Icons.grass,
          FortSmartTheme.successColor,
          () => Navigator.pushNamed(context, '/plantio/calculo-sementes'),
        ),
        _buildMenuItem(
          context,
          'Regulagem de Plantadeira',
          Icons.agriculture,
          FortSmartTheme.primaryColor,
          () => Navigator.pushNamed(context, AppRoutes.plantioCalibragemPlantadeira),
        ),
        _buildMenuItem(
          context,
          'Novo Estande de Plantas',
          Icons.eco,
          FortSmartTheme.successColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PlantioEstandePlantasScreen(),
            ),
          ),
        ),
        _buildMenuItem(
          context,
          'Tratamento de Sementes',
          Icons.science,
          FortSmartTheme.primaryColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(
                  child: Text('Módulo de Tratamento de Sementes em desenvolvimento'),
                ),
              ),
            ),
          ),
        ),
        _buildMenuItem(
          context,
          'Calibração por Coleta',
          Icons.science_outlined,
          FortSmartTheme.plantioIcon,
          () => Navigator.pushNamed(context, AppRoutes.plantioCalibragemAduboColeta),
        ),
        _buildMenuItem(
          context,
          'Teste de Germinação',
          Icons.science,
          Colors.green.shade600,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GerminationTestMainScreen(),
            ),
          ),
        ),
        _buildMenuItem(
          context,
          'Evolução Fenológica',
          Icons.timeline,
          Colors.teal.shade600,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PhenologicalMainScreen(),
            ),
          ),
        ),
      ],
    );
  }

  /// Abre a tela de histórico de plantio
  Future<void> _abrirHistoricoPlantio(BuildContext context) async {
    try {
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      // Aguardar a inicialização do banco de dados
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Criar o repositório de histórico
      final historicoRepo = HistoricoPlantioRepository();
      
      // Carregar a lista de talhões para o filtro
      final talhoes = await _dataCacheService.getTalhoes();
      
      print('🔍 DEBUG TALHÕES: Total de talhões carregados: ${talhoes.length}');
      
      // Converter para o formato esperado pela tela de histórico
      final talhoesFormatados = talhoes.map((t) {
        final nome = t.name.isNotEmpty ? t.name : (t.nomeTalhao.isNotEmpty ? t.nomeTalhao : 'Talhão sem nome');
        print('🔍 DEBUG TALHÃO: ID=${t.id}, name="${t.name}", nomeTalhao="${t.nomeTalhao}", nome final="$nome"');
        return {
          'id': t.id.toString(),
          'nome': nome,
        };
      }).toList();
      
      print('🔍 DEBUG: Talhões formatados: $talhoesFormatados');
      
      // Fechar o diálogo de carregamento
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        // Navegar para a tela de histórico
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoricoPlantioScreen(
              repository: historicoRepo,
              talhoes: talhoesFormatados,
            ),
          ),
        );
      }
    } catch (e) {
      // Fechar o diálogo de carregamento em caso de erro
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir histórico: $e')),
        );
      }
    }
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

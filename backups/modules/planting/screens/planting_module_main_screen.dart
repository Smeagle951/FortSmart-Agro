import 'package:flutter/material.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../repositories/machine_repository.dart';
import '../../../models/agricultural_product.dart';
import 'plantio_screen.dart';
import 'estande_screen.dart';
import 'experimento_screen.dart';

class PlantingModuleMainScreen extends StatefulWidget {
  const PlantingModuleMainScreen({Key? key}) : super(key: key);

  @override
  _PlantingModuleMainScreenState createState() => _PlantingModuleMainScreenState();
}

class _PlantingModuleMainScreenState extends State<PlantingModuleMainScreen> with SingleTickerProviderStateMixin {
  // Repositórios
  final _talhaoRepository = TalhaoRepository();
  final _agriculturalProductRepository = AgriculturalProductRepository();
  final _machineRepository = MachineRepository();
  
  bool _isLoading = true;
  bool _hasTalhoes = false;
  bool _hasCulturas = false;
  bool _hasTratores = false;
  bool _hasPlantadeiras = false;
  
  TabController? _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _verificarDadosCadastrados();
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  
  Future<void> _verificarDadosCadastrados() async {
    setState(() => _isLoading = true);
    
    try {
      // Verificar se há talhões cadastrados
      final talhoes = await _talhaoRepository.loadTalhoes();
      _hasTalhoes = talhoes.isNotEmpty;
      
      // Verificar se há culturas cadastradas
      final culturas = await _agriculturalProductRepository.getByType(ProductType.seed);
      _hasCulturas = culturas.isNotEmpty;
      
      // Verificar se há tratores cadastrados
      final tratores = await _machineRepository.getTractors();
      _hasTratores = tratores.isNotEmpty;
      
      // Verificar se há plantadeiras cadastradas
      final plantadeiras = await _machineRepository.getPlanters();
      _hasPlantadeiras = plantadeiras.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar dados cadastrados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _navegarParaCadastroTalhao() {
    // Navegar para a tela de cadastro de talhão com safras
    Navigator.of(context).pushNamed('/talhao/form-safra').then((_) {
      // Ao retornar, verificar novamente se há talhões cadastrados
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaCadastroCultura() {
    // Navegar para a tela de cadastro de cultura
    Navigator.of(context).pushNamed('/cultura/cadastro').then((_) {
      // Ao retornar, verificar novamente se há culturas cadastradas
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaCadastroTrator() {
    // Navegar para a tela de cadastro de trator
    Navigator.of(context).pushNamed('/maquina/cadastro', arguments: {'tipo': 'trator'}).then((_) {
      // Ao retornar, verificar novamente se há tratores cadastrados
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaCadastroPlantadeira() {
    // Navegar para a tela de cadastro de plantadeira
    Navigator.of(context).pushNamed('/maquina/cadastro', arguments: {'tipo': 'plantadeira'}).then((_) {
      // Ao retornar, verificar novamente se há plantadeiras cadastradas
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaPlantio() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlantioScreen(),
      ),
    ).then((_) {
      // Atualizar dados ao retornar
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaEstande() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EstandeScreen(),
      ),
    ).then((_) {
      // Atualizar dados ao retornar
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaExperimento() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExperimentoScreen(),
      ),
    ).then((_) {
      // Atualizar dados ao retornar
      _verificarDadosCadastrados();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: const Text('Módulo de Plantio'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Plantio'),
            Tab(text: 'Estande'),
            Tab(text: 'Experimentos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF228B22)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPlantioTab(),
                _buildEstandeTab(),
                _buildExperimentosTab(),
              ],
            ),
    );
  }
  
  Widget _buildPlantioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Talhão', Icons.crop_square, onAdd: () {}),
          const SizedBox(height: 8),
          _hasTalhoes
              ? _buildAddButton('Selecionar Talhão', onPressed: _navegarParaPlantio)
              : _buildWarningCard(
                  'Nenhum talhão cadastrado',
                  'Cadastrar Talhão',
                  _navegarParaCadastroTalhao,
                  warningColor: Colors.orange,
                ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Cultura', Icons.spa, onAdd: () {}),
          const SizedBox(height: 8),
          _hasCulturas
              ? _buildAddButton('Selecionar Cultura', onPressed: _navegarParaPlantio)
              : _buildWarningCard(
                  'Nenhuma cultura cadastrada',
                  'Cadastrar Cultura',
                  _navegarParaCadastroCultura,
                  warningColor: Colors.orange,
                ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Equipamentos', Icons.agriculture, onAdd: () {}),
          const SizedBox(height: 8),
          _hasTratores
              ? _buildAddButton('Selecionar Trator', onPressed: _navegarParaPlantio)
              : _buildWarningCard(
                  'Nenhum trator cadastrado',
                  'Cadastrar Trator',
                  _navegarParaCadastroTrator,
                  warningColor: Colors.orange,
                ),
          const SizedBox(height: 16),
          _hasPlantadeiras
              ? _buildAddButton('Selecionar Plantadeira', onPressed: _navegarParaPlantio)
              : _buildWarningCard(
                  'Nenhuma plantadeira cadastrada',
                  'Cadastrar Plantadeira',
                  _navegarParaCadastroPlantadeira,
                  warningColor: Colors.orange,
                ),
          const SizedBox(height: 24),
          
          if (_hasTalhoes && _hasCulturas && _hasTratores && _hasPlantadeiras)
            Center(
              child: ElevatedButton(
                onPressed: _navegarParaPlantio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF228B22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'NOVO CADASTRO DE PLANTIO',
                  style: TextStyle(
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
  
  Widget _buildEstandeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Talhão', Icons.crop_square, onAdd: () {}),
          const SizedBox(height: 8),
          _hasTalhoes
              ? _buildAddButton('Selecionar Talhão', onPressed: _navegarParaEstande)
              : _buildWarningCard(
                  'Nenhum talhão cadastrado',
                  'Cadastrar Talhão',
                  _navegarParaCadastroTalhao,
                  warningColor: Colors.orange,
                ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Cultura', Icons.spa, onAdd: () {}),
          const SizedBox(height: 8),
          _hasCulturas
              ? _buildAddButton('Selecionar Cultura', onPressed: _navegarParaEstande)
              : _buildWarningCard(
                  'Nenhuma cultura cadastrada',
                  'Cadastrar Cultura',
                  _navegarParaCadastroCultura,
                  warningColor: Colors.orange,
                ),
          const SizedBox(height: 24),
          
          if (_hasTalhoes && _hasCulturas)
            Center(
              child: ElevatedButton(
                onPressed: _navegarParaEstande,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF228B22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'NOVA AVALIAÇÃO DE ESTANDE',
                  style: TextStyle(
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
  
  Widget _buildExperimentosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Talhão', Icons.crop_square, onAdd: () {}),
          const SizedBox(height: 8),
          _hasTalhoes
              ? _buildAddButton('Selecionar Talhão', onPressed: _navegarParaExperimento)
              : _buildWarningCard(
                  'Nenhum talhão cadastrado',
                  'Cadastrar Talhão',
                  _navegarParaCadastroTalhao,
                  warningColor: Colors.orange,
                ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Cultura', Icons.spa, onAdd: () {}),
          const SizedBox(height: 8),
          _hasCulturas
              ? _buildAddButton('Selecionar Cultura', onPressed: _navegarParaExperimento)
              : _buildWarningCard(
                  'Nenhuma cultura cadastrada',
                  'Cadastrar Cultura',
                  _navegarParaCadastroCultura,
                  warningColor: Colors.orange,
                ),
          const SizedBox(height: 24),
          
          if (_hasTalhoes && _hasCulturas)
            Center(
              child: ElevatedButton(
                onPressed: _navegarParaExperimento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF228B22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'NOVO EXPERIMENTO',
                  style: TextStyle(
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
  
  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF228B22)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Color(0xFF228B22)),
            label: const Text(
              'Adicionar',
              style: TextStyle(color: Color(0xFF228B22)),
            ),
          ),
      ],
    );
  }
  
  Widget _buildWarningCard(String message, String buttonText, VoidCallback onPressed, {Color warningColor = Colors.red}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: warningColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: warningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF228B22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddButton(String text, {required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, color: Color(0xFF228B22)),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF228B22),
        side: const BorderSide(color: Color(0xFF228B22)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

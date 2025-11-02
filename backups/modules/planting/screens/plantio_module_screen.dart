import 'package:flutter/material.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../repositories/machine_repository.dart';
import '../../../models/agricultural_product.dart';
import '../../../models/talhao_model_new.dart';
import '../widgets/selection_dialogs.dart';
import '../services/data_cache_service.dart';

class PlantioModuleScreen extends StatefulWidget {
  const PlantioModuleScreen({Key? key}) : super(key: key);

  @override
  _PlantioModuleScreenState createState() => _PlantioModuleScreenState();
}

class _PlantioModuleScreenState extends State<PlantioModuleScreen> {
  // Repositórios
  final _talhaoRepository = TalhaoRepository();
  final _agriculturalProductRepository = AgriculturalProductRepository();
  final _machineRepository = MachineRepository();
  
  // Serviço de cache para integração entre módulos
  final _dataCacheService = DataCacheService();
  
  // Controllers para os campos de seleção
  final _talhaoController = TextEditingController();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _tratorController = TextEditingController();
  final _plantadeiraController = TextEditingController();
  
  // IDs dos itens selecionados
  TalhaoModel? _talhaoSelecionado;
  AgriculturalProduct? _culturaSelecionada;
  AgriculturalProduct? _variedadeSelecionada;
  dynamic _tratorSelecionado;
  dynamic _plantadeiraSelecionada;
  
  bool _isLoading = true;
  bool _hasTalhoes = false;
  bool _hasCulturas = false;
  bool _hasTratores = false;
  bool _hasPlantadeiras = false;
  
  @override
  void initState() {
    super.initState();
    _verificarDadosCadastrados();
  }
  
  Future<void> _verificarDadosCadastrados() async {
    setState(() => _isLoading = true);
    
    try {
      // Verificar se há talhões cadastrados
      final talhoes = await _talhaoRepository.loadTalhoes();
      _hasTalhoes = talhoes.isNotEmpty;
      
      // Verificar se há culturas cadastradas
      final culturas = await _agriculturalProductRepository.getByTypeIndex(ProductType.seed.index);
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
    // Navegar para a tela de cadastro de talhão com safras (módulo atualizado)
    Navigator.of(context).pushNamed('/plots').then((_) {
      // Ao retornar, verificar novamente se há talhões cadastrados
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaCadastroCultura() {
    // Navegar para a tela de gerenciamento de culturas e pragas
    Navigator.of(context).pushNamed('/farm/crop_management').then((_) {
      // Limpar cache e verificar novamente se há culturas cadastradas
      _dataCacheService.clearCache(); // Limpar cache para forçar nova consulta
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaCadastroTrator() {
    // Navegar para a tela de cadastro de trator (módulo de máquinas)
    Navigator.of(context).pushNamed('/machines/form', arguments: {'type': 'TRATOR'}).then((_) {
      // Limpar cache e verificar novamente se há tratores cadastrados
      _dataCacheService.clearTalhoesCache();
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaCadastroPlantadeira() {
    // Navegar para a tela de cadastro de plantadeira (módulo de máquinas)
    Navigator.of(context).pushNamed('/machines/form', arguments: {'type': 'PLANTADEIRA'}).then((_) {
      // Limpar cache e verificar novamente se há plantadeiras cadastradas
      _dataCacheService.clearTalhoesCache();
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaNovoPlantio() {
    // Verificar se todos os dados estão selecionados
    if (_talhaoSelecionado != null && _culturaSelecionada != null && 
        _tratorSelecionado != null && _plantadeiraSelecionada != null) {
      // Passar os IDs pré-selecionados para a tela de novo plantio
      Navigator.of(context).pushNamed('/plantio/form', arguments: {
        'talhaoId': _talhaoSelecionado!.id,
        'culturaId': _culturaSelecionada!.id,
        'variedadeId': _variedadeSelecionada?.id,
        'tratorId': _tratorSelecionado!.id,
        'plantadeiraId': _plantadeiraSelecionada!.id,
      }).then((_) {
        // Atualizar dados ao retornar
        _verificarDadosCadastrados();
      });
    } else {
      // Mostrar mensagem de erro se algum campo não estiver preenchido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione todos os campos antes de continuar'),
          backgroundColor: const Color(0xFF228B22),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _talhaoController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _tratorController.dispose();
    _plantadeiraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Plantio'),
        backgroundColor: const Color(0xFF228B22), // Cor verde do tema
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFDF8E32)))
            : Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9F9), // Fundo claro para melhor contraste
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      
                      // Seção Talhão
                      _buildSectionTitle('Talhão e Cultura', Icons.map),
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _hasTalhoes
                                ? _buildSelectionField(
                                    'Talhão',
                                    _talhaoController,
                                    _selecionarTalhao,
                                    Icons.map,
                                  )
                                : _buildWarningCard(
                                    'Nenhum talhão cadastrado',
                                    'Cadastrar Talhão',
                                    _navegarParaCadastroTalhao,
                                  ),
                              const SizedBox(height: 16),
                              
                              _hasCulturas
                                ? _buildSelectionField(
                                    'Cultura',
                                    _culturaController,
                                    _selecionarCultura,
                                    Icons.grass,
                                  )
                                : _buildWarningCard(
                                    'Nenhuma cultura cadastrada',
                                    'Cadastrar Cultura',
                                    _navegarParaCadastroCultura,
                                  ),
                              const SizedBox(height: 16),
                              
                              _buildSelectionField(
                                'Variedade (opcional)',
                                _variedadeController,
                                _selecionarVariedade,
                                Icons.eco,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Seção Máquinas
                      _buildSectionTitle('Máquinas', Icons.agriculture),
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _hasTratores
                                ? _buildSelectionField(
                                    'Trator',
                                    _tratorController,
                                    _selecionarTrator,
                                    Icons.agriculture,
                                  )
                                : _buildWarningCard(
                                    'Nenhum trator cadastrado',
                                    'Cadastrar Trator',
                                    _navegarParaCadastroTrator,
                                    warningColor: Colors.orange,
                                  ),
                              const SizedBox(height: 16),
                              
                              _hasPlantadeiras
                                ? _buildSelectionField(
                                    'Plantadeira',
                                    _plantadeiraController,
                                    _selecionarPlantadeira,
                                    Icons.precision_manufacturing,
                                  )
                                : _buildWarningCard(
                                    'Nenhuma plantadeira cadastrada',
                                    'Cadastrar Plantadeira',
                                    _navegarParaCadastroPlantadeira,
                                    warningColor: Colors.orange,
                                  ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      if (_hasTalhoes && _hasCulturas && _hasTratores && _hasPlantadeiras)
                        _buildContinueButton()
                      else
                        _buildRequirementsCard()
                    ],
                  ),
                ),
              ),
      );
  }
  
  Widget _buildHeaderCard() {
    return Card(
      color: const Color(0xFFDF8E32),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.eco, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Cadastro de Plantio',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione os dados necessários para o plantio',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_getCompletedFields()} de 4 campos preenchidos',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFDF8E32), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContinueButton() {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Todos os dados estão prontos!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF228B22)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navegarParaNovoPlantio,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF228B22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_circle_outline),
                  SizedBox(width: 12),
                  Text(
                    'CADASTRAR NOVO PLANTIO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRequirementsCard() {
    return Card(
      color: const Color(0xFFFFF3E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Informações Necessárias',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Para cadastrar um novo plantio, é necessário selecionar:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildRequirementItem('Talhão', _hasTalhoes),
            _buildRequirementItem('Cultura', _hasCulturas),
            _buildRequirementItem('Trator', _hasTratores),
            _buildRequirementItem('Plantadeira', _hasPlantadeiras),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRequirementItem(String name, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }
  
  int _getCompletedFields() {
    int count = 0;
    if (_hasTalhoes && _talhaoSelecionado != null) count++;
    if (_hasCulturas && _culturaSelecionada != null) count++;
    if (_hasTratores && _tratorSelecionado != null) count++;
    if (_hasPlantadeiras && _plantadeiraSelecionada != null) count++;
    return count;
  }
  
  Future<void> _selecionarTalhao() async {
    final talhao = await showTalhaoSelectionDialog(context);
    if (talhao != null) {
      setState(() {
        _talhaoSelecionado = talhao;
        _talhaoController.text = talhao.nome;
      });
    }
  }
  
  Future<void> _selecionarCultura() async {
    final cultura = await showCulturaSelectionDialog(context);
    if (cultura != null) {
      setState(() {
        _culturaSelecionada = cultura;
        _culturaController.text = cultura.name;
        // Reset variedade quando cultura muda
        _variedadeSelecionada = null;
        _variedadeController.text = '';
      });
    }
  }
  
  Future<void> _selecionarVariedade() async {
    if (_culturaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma cultura primeiro'),
          backgroundColor: const Color(0xFF228B22),
        ),
      );
      return;
    }
    
    final variedade = await showVariedadeSelectionDialog(context, _culturaSelecionada!.id);
    if (variedade != null) {
      setState(() {
        _variedadeSelecionada = variedade;
        _variedadeController.text = variedade.name;
      });
    }
  }
  
  Future<void> _selecionarTrator() async {
    // Implementar seleção de trator via modal/dialog
    final tratores = await _machineRepository.getTractors();
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Trator'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: tratores.length,
            itemBuilder: (context, index) {
              final trator = tratores[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: const Color(0xFF228B22),
                  child: Icon(Icons.agriculture, color: Colors.white),
                ),
                title: Text(trator.name),
                subtitle: Text('Trator'),

                onTap: () => Navigator.of(context).pop(trator),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() {
        _tratorSelecionado = result;
        _tratorController.text = result.name;
      });
    }
  }
  
  Future<void> _selecionarPlantadeira() async {
    // Implementar seleção de plantadeira via modal/dialog
    final plantadeiras = await _machineRepository.getPlanters();
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Plantadeira'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: plantadeiras.length,
            itemBuilder: (context, index) {
              final plantadeira = plantadeiras[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: const Color(0xFF228B22),
                  child: Icon(Icons.precision_manufacturing, color: Colors.white),
                ),
                title: Text(plantadeira.name),
                subtitle: Text('Plantadeira'),

                onTap: () {
                  Navigator.of(context).pop(plantadeira);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() {
        _plantadeiraSelecionada = result;
        _plantadeiraController.text = result.name;
      });
    }
  }
  
  // Método para criar campos de seleção personalizados
  Widget _buildSelectionField(String label, TextEditingController controller, Function() onTap, IconData icon) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFDF8E32)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.text.isEmpty ? 'Selecionar' : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: controller.text.isEmpty ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
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
  
  // Método removido pois não é mais utilizado
}

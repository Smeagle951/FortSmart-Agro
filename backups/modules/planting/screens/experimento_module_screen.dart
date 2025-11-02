import 'package:flutter/material.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../models/agricultural_product.dart';

class ExperimentoModuleScreen extends StatefulWidget {
  const ExperimentoModuleScreen({Key? key}) : super(key: key);

  @override
  _ExperimentoModuleScreenState createState() => _ExperimentoModuleScreenState();
}

class _ExperimentoModuleScreenState extends State<ExperimentoModuleScreen> {
  // Repositórios
  final _talhaoRepository = TalhaoRepository();
  final _agriculturalProductRepository = AgriculturalProductRepository();
  
  bool _isLoading = true;
  bool _hasTalhoes = false;
  bool _hasCulturas = false;
  bool _hasFazenda = false;
  
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
      
      // Simular verificação de fazenda (em um sistema real, isso viria de um repositório de fazendas)
      _hasFazenda = false; // Altere para true se quiser simular que há fazendas cadastradas
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
  
  void _tentarNovamente() {
    // Recarregar dados
    _verificarDadosCadastrados();
  }
  
  void _navegarParaNovoExperimento() {
    Navigator.of(context).pushNamed('/planting/experimentos').then((_) {
      // Atualizar dados ao retornar
      _verificarDadosCadastrados();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: const Text('Experimentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Ação para salvar ou exportar dados
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF228B22)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Talhão', Icons.crop_square, onAdd: () {}),
                  const SizedBox(height: 8),
                  _hasTalhoes
                      ? _buildAddButton('Selecionar Talhão', onPressed: _navegarParaNovoExperimento)
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
                      ? _buildAddButton('Selecionar Cultura', onPressed: _navegarParaNovoExperimento)
                      : _buildWarningCard(
                          'Nenhuma cultura cadastrada',
                          'Cadastrar Cultura',
                          _navegarParaCadastroCultura,
                          warningColor: Colors.orange,
                        ),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('Fazenda', Icons.home_work, onAdd: () {}),
                  const SizedBox(height: 8),
                  _hasFazenda
                      ? _buildAddButton('Selecionar Fazenda', onPressed: _navegarParaNovoExperimento)
                      : _buildWarningCard(
                          'Nenhuma fazenda ativa encontrada',
                          'Tentar novamente',
                          _tentarNovamente,
                          warningColor: Colors.red,
                        ),
                  const SizedBox(height: 24),
                  
                  if (_hasTalhoes && _hasCulturas)
                    Center(
                      child: ElevatedButton(
                        onPressed: _navegarParaNovoExperimento,
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

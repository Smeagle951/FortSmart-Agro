import 'package:flutter/material.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../models/agricultural_product.dart';
import '../../../widgets/crop_selector.dart';
import 'estande_screen.dart';
import '../../../widgets/crop_variety_selector.dart';
import '../../../widgets/plot_selector.dart';
import '../services/data_cache_service.dart';

class EstandeModuleScreen extends StatefulWidget {
  const EstandeModuleScreen({Key? key}) : super(key: key);
  
  @override
  State<EstandeModuleScreen> createState() => _EstandeModuleScreenState();
}

class _EstandeModuleScreenState extends State<EstandeModuleScreen> {
  // Estado
  bool _isLoading = false;
  bool _hasTalhoes = false;
  bool _hasCulturas = false;
  String? _plotId;
  String? _cropId;
  String? _cropVarietyId;
  
  // Serviço de cache de dados
  final DataCacheService _dataCacheService = DataCacheService();
  
  @override
  void initState() {
    super.initState();
    _verificarDadosCadastrados();
  }
  
  Future<void> _verificarDadosCadastrados() async {
    setState(() => _isLoading = true);
    
    try {
      // Primeiro tenta verificar se há talhões no cache
      try {
        final talhoes = await _dataCacheService.getTalhoes();
        setState(() => _hasTalhoes = talhoes.isNotEmpty);
      } catch (cacheError) {
        print('Erro ao carregar talhões do cache: $cacheError');
        
        // Se falhar, tenta do repositório tradicional
        final talhaoRepo = TalhaoRepository();
        final talhoes = await talhaoRepo.loadTalhoes();
        setState(() => _hasTalhoes = talhoes.isNotEmpty);
      }
      
      // Primeiro tenta verificar se há culturas no cache
      try {
        final culturas = await _dataCacheService.getCulturas();
        setState(() => _hasCulturas = culturas.isNotEmpty);
      } catch (cacheError) {
        print('Erro ao carregar culturas do cache: $cacheError');
        
        // Se falhar, tenta do repositório tradicional
        final culturaRepo = AgriculturalProductRepository();
        final culturas = await culturaRepo.getByTypeIndex(ProductType.seed.index);
        setState(() => _hasCulturas = culturas.isNotEmpty);
      }
    } catch (e) {
      print('Erro ao verificar dados cadastrados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF228B22),
      ),
    );
  }
  
  void _navegarParaCadastroTalhao() {
    // Corrigido para usar a rota TALHOES_SAFRA definida no arquivo de rotas
    Navigator.of(context).pushNamed('/talhoes/safra').then((_) {
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaCadastroCultura() {
    // Corrigido para usar a rota farmCrops definida no arquivo de rotas
    Navigator.of(context).pushNamed('/farm/crops').then((_) {
      _verificarDadosCadastrados();
    });
  }
  
  void _navegarParaListaEstande() {
    // Como não existe uma rota específica para lista de estande, usamos a mesma tela EstandeScreen
    // mas passamos um parâmetro indicando que deve mostrar a lista
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EstandeScreen(),
        settings: RouteSettings(
          arguments: {
            'showList': true,
          },
        ),
      ),
    );
  }
  
  void _salvarEstande() {
    // Validar se todos os campos foram preenchidos
    if (_plotId == null) {
      _mostrarErro('Selecione um talhão');
      return;
    }
    
    if (_cropId == null) {
      _mostrarErro('Selecione uma cultura');
      return;
    }
    
    if (_cropVarietyId == null) {
      _mostrarErro('Selecione uma variedade');
      return;
    }
    
    // Navegar para a tela de cadastro de estande usando a classe EstandeScreen diretamente
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EstandeScreen(
          // Passamos os argumentos diretamente para a tela
          // Nota: EstandeScreen espera um estandeId opcional, mas podemos passar os outros dados via rota
        ),
        settings: RouteSettings(
          arguments: {
            'plotId': _plotId,
            'cropId': _cropId,
            'cropVarietyId': _cropVarietyId,
          },
        ),
      ),
    );
  }
  
  Widget _buildWarningCard(String message, String buttonText, VoidCallback onPressed) {
    return Card(
      color: Colors.amber[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF228B22),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estande de Plantas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _navegarParaListaEstande,
            tooltip: 'Listar Estandes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção de seleção de talhão
                  _buildCard(
                    title: 'Talhão',
                    icon: Icons.crop_square,
                    children: [
                      if (!_hasTalhoes)
                        _buildWarningCard(
                          'Nenhum talhão cadastrado',
                          'Cadastrar Talhão',
                          _navegarParaCadastroTalhao,
                        )
                      else
                        Column(
                          children: [
                            PlotSelector(
                              onChanged: (plotId) {
                                setState(() {
                                  _plotId = plotId;
                                });
                              },
                              isRequired: true,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _navegarParaCadastroTalhao,
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Talhão'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Seção de seleção de cultura
                  _buildCard(
                    title: 'Cultura',
                    icon: Icons.grass,
                    children: [
                      if (!_hasCulturas)
                        _buildWarningCard(
                          'Nenhuma cultura cadastrada',
                          'Cadastrar Cultura',
                          _navegarParaCadastroCultura,
                        )
                      else
                        Column(
                          children: [
                            CropSelector(
                              onChanged: (cropId) {
                                setState(() {
                                  _cropId = cropId;
                                  _cropVarietyId = null; // Resetar a variedade quando mudar a cultura
                                });
                              },
                              isRequired: true,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _navegarParaCadastroCultura,
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Cultura'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Seção de seleção de variedade
                  if (_cropId != null)
                    _buildCard(
                      title: 'Variedade',
                      icon: Icons.category,
                      children: [
                        CropVarietySelector(
                          cropId: _cropId!,
                          onChanged: (varietyId) {
                            setState(() {
                              _cropVarietyId = varietyId;
                            });
                          },
                          isRequired: true,
                        ),
                      ],
                    ),
                  
                  SizedBox(height: 24),
                  
                  // Botão para cadastrar estande
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: (_hasTalhoes && _hasCulturas) ? _salvarEstande : null,
                      icon: Icon(Icons.add),
                      label: Text('Cadastrar Estande'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

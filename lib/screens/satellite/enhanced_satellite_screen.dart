import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/talhao_model_new.dart';
import 'package:fortsmart_agro/modules/planting/services/data_cache_service.dart';
import 'package:fortsmart_agro/widgets/enhanced_farm_map.dart';
import 'package:fortsmart_agro/utils/snackbar_helper.dart';
import 'package:fortsmart_agro/widgets/app_drawer.dart';
import 'package:fortsmart_agro/widgets/crop_selector.dart';
import 'package:fortsmart_agro/models/agricultural_product.dart';
import 'package:fortsmart_agro/utils/model_adapters.dart';
import 'package:fortsmart_agro/repositories/talhao_repository.dart';
import 'package:fortsmart_agro/utils/cultura_colors.dart';
import 'package:latlong2/latlong.dart';


/// Tela melhorada para visualização de satélite com seleção de culturas
class EnhancedSatelliteScreen extends StatefulWidget {
  const EnhancedSatelliteScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedSatelliteScreen> createState() => _EnhancedSatelliteScreenState();
}

class _EnhancedSatelliteScreenState extends State<EnhancedSatelliteScreen> {
  final DataCacheService _dataCacheService = DataCacheService();
  List<TalhaoModel> _talhoes = [];
  bool _isLoading = true;
  bool _showSatelliteLayer = true;
  // Variáveis de controle para o estado da tela
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _atualizarMapa() {
    setState(() {
      _isLoading = true;
    });
    _loadData();
  }
  
  Color _getDefaultColorFromName(String name) {
    return CulturaColorsUtils.getColorForName(name);
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final talhoes = await _dataCacheService.getTalhoes(forceRefresh: true);
      
      // Converter os talhões para o formato novo se necessário
      final List<TalhaoModel> convertedTalhoes = ModelAdapters.convertToNewTalhaoModelList(talhoes);
      
      setState(() {
        _talhoes = convertedTalhoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(context, 'Erro ao carregar talhões: $e');
      }
    }
  }
  
  void _onTalhaoSelected(TalhaoModel talhao) {
    // Exibir modal com detalhes do talhão
    _showTalhaoDetailsModal(talhao);
  }
  
  void _showTalhaoDetailsModal(TalhaoModel talhao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  talhao.nome ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                FutureBuilder<double>(
                  future: _getTalhaoArea(talhao),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildInfoRow('Área', '${snapshot.data!.toStringAsFixed(2)} ha');
                    } else {
                      return _buildInfoRow('Área', 'Calculando...');
                    }
                  },
                ),
                _buildInfoRow('Cultura', _getCulturaName(talhao.culturaId?.toString()) ?? ''),
                _buildInfoRow('Safra', talhao.safraAtual?.safra ?? 'N/A'),
                _buildInfoRow('Cultura Atual', talhao.safraAtual?.culturaNome ?? 'Não definida'),
                const SizedBox(height: 16),
                const Text(
                  'Atualizar cultura',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CropSelector(
                  onChanged: (cropId) {
                    Navigator.pop(context);
                    _updateTalhaoCultura(talhao, cropId.id?.toString() ?? '');
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  String _getCulturaName(String? culturaId) {
    if (culturaId == null) return 'Não definida';
    
    // Implementar busca do nome da cultura pelo ID
    return 'Cultura #$culturaId';
  }


  
  Future<void> _updateTalhaoCultura(TalhaoModel talhao, String cropId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Atualizar o talhão com a nova cultura
      // Buscar a cultura pelo ID
      final culturas = await _dataCacheService.getCulturas(forceRefresh: false);
      
      // Determinar o nome da cultura e a cor
      String culturaNome = 'Cultura não encontrada';
      Color culturaCor = Color(0xFF4CAF50); // Verde padrão
      
      // Procurar a cultura na lista
      for (var c in culturas) {
        if (c.id.toString() == cropId.toString()) {
          culturaNome = c.name;
          // Tentar obter a cor da cultura, se disponível
          try {
            // Como AgriculturalProduct não tem colorValue, usamos uma cor padrão baseada no nome
            culturaCor = _getDefaultColorFromName(culturaNome);
            
            // Se no futuro a classe tiver uma propriedade de cor, podemos usar assim:
            // if (c is AgriculturalProduct && c.color != null) {
            //   culturaCor = c.color;
            // }  
          } catch (e) {
            print('Erro ao definir cor da cultura: $e');
          }
          break;
        }
      }
      
      // Criar uma nova safra com a cultura selecionada
      final updatedTalhao = talhao.adicionarSafraNomeada(
        safra: talhao.safraAtualPeriodo ?? 'Safra ${DateTime.now().year}', // Usar valor padrão se for nulo
        culturaId: cropId,
        culturaNome: culturaNome,
        culturaCor: culturaCor,
      );
      
      // Salvar no repositório usando o método existente para atualizar talhão
      final talhaoRepository = TalhaoRepository();
      await talhaoRepository.updateTalhao(updatedTalhao);
      
      // Atualizar a lista local
      final index = _talhoes.indexWhere((t) => t.id == talhao.id);
      if (index >= 0) {
        setState(() {
          _talhoes[index] = updatedTalhao;
        });
      }
      
      SnackbarHelper.showSuccessSnackbar(
        context, 
        'Cultura atualizada para $culturaNome',
      );
    } catch (e) {
      SnackbarHelper.showErrorSnackbar(
        context, 
        'Erro ao atualizar cultura: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satélite'),
        actions: [
          IconButton(
            icon: Icon(_showSatelliteLayer ? Icons.satellite_alt : Icons.map),
            onPressed: () {
              setState(() {
                _showSatelliteLayer = !_showSatelliteLayer;
              });
            },
            tooltip: _showSatelliteLayer ? 'Mostrar mapa básico' : 'Mostrar satélite',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Mapa principal
          EnhancedFarmMap(
            talhoes: _talhoes,
            onTalhaoTap: _onTalhaoSelected,
            showSatelliteLayer: _showSatelliteLayer,
          ),
          
          // Indicador de carregamento
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      // Barra inferior com botões de ação
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.layers),
                onPressed: () {
                  setState(() {
                    _showSatelliteLayer = !_showSatelliteLayer;
                  });
                },
                tooltip: 'Alternar camadas',
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Implementar filtro de talhões
                },
                tooltip: 'Filtrar talhões',
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  // Mostrar informações sobre o mapa
                },
                tooltip: 'Informações',
              ),
              IconButton(
                icon: const Icon(Icons.save_alt),
                onPressed: () {
                  // Implementar exportação de dados
                },
                tooltip: 'Exportar dados',
              ),
            ],
          ),
        ),
      ),
      // Botão flutuante para adicionar novo talhão
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implementar adição de novo talhão
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Obtém área de um talhão usando cálculo geodésico preciso
  Future<double> _getTalhaoArea(TalhaoModel talhao) async {
    try {
      print('🔄 Calculando área para talhão: ${talhao.name}');
      
      // 1. Tentar obter área do modelo diretamente (prioridade máxima)
      if (talhao.area != null && talhao.area! > 0) {
        print('📊 Área do talhão ${talhao.name}: ${talhao.area!.toStringAsFixed(2)} ha (dados salvos)');
        return talhao.area!;
      }
      
      // 2. Tentar obter área do polígono
      if (talhao.poligonos.isNotEmpty) {
        final poligono = talhao.poligonos.first;
        
        // Verificar se o polígono tem área calculada
        if (poligono.area != null && poligono.area! > 0) {
          print('📊 Área do polígono ${talhao.name}: ${poligono.area!.toStringAsFixed(2)} ha (dados salvos)');
          return poligono.area!;
        }
        
        // Calcular área dos pontos usando PolygonMetricsService
        if (poligono.pontos.isNotEmpty) {
          final pontos = poligono.pontos
              .where((p) => p.latitude != null && p.longitude != null)
              .map((p) => LatLng(p.latitude!, p.longitude!))
              .toList();
          
          if (pontos.length >= 3) {
            print('🔄 Calculando área para talhão ${talhao.name} com ${pontos.length} pontos...');
            
            // Calcular área usando fórmula de Gauss
            final area = _calculateAreaHectares(pontos);
            
            // Validar se a área calculada é razoável (entre 0.1 e 10000 ha)
            if (area > 0.1 && area < 10000) {
              print('✅ Área calculada para ${talhao.name}: ${area.toStringAsFixed(2)} ha');
              return area;
            } else {
              print('⚠️ Área calculada inválida para ${talhao.name}: ${area.toStringAsFixed(2)} ha');
            }
          } else {
            print('⚠️ Talhão ${talhao.name} tem menos de 3 pontos válidos: ${pontos.length}');
          }
        } else {
          print('⚠️ Talhão ${talhao.name} não tem pontos no polígono');
        }
      } else {
        print('⚠️ Talhão ${talhao.name} não tem polígonos');
      }
      
      print('⚠️ Não foi possível calcular área para talhão ${talhao.name}');
      return 0.0;
    } catch (e) {
      print('❌ Erro ao obter área do talhão ${talhao.name}: $e');
      return 0.0;
    }
  }

  /// Calcula área em hectares usando fórmula de Gauss
  double _calculateAreaHectares(List<LatLng> pontos) {
    if (pontos.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < pontos.length; i++) {
      int j = (i + 1) % pontos.length;
      area += pontos[i].latitude * pontos[j].longitude;
      area -= pontos[j].latitude * pontos[i].longitude;
    }
    
    area = (area.abs() / 2.0) * 111319.9 * 111319.9; // Converter para metros quadrados
    return area / 10000.0; // Converter para hectares
  }
}

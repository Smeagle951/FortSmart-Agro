import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/models/plantio_model.dart' as plantio_model;
import '../../providers/cultura_provider.dart';
import '../../services/lista_plantio_service.dart';
import '../../models/talhao_model.dart';
import '../../models/poligono_model.dart';
import '../../database/models/crop.dart' as crop_model;
import '../../models/crop_variety.dart';
import '../../models/agricultural_product.dart';
import '../../services/plantio_service.dart';
import '../../services/talhao_module_service.dart';
import '../../services/cultura_talhao_service.dart';
import '../../services/data_cache_service.dart';
import '../../services/variety_cycle_service.dart';
import '../../repositories/crop_variety_repository.dart';
import '../../repositories/talhao_repository.dart';
import '../../screens/talhoes_com_safras/providers/talhao_provider.dart';
import '../../widgets/variety_cycle_selector.dart';
import '../../widgets/variedade_selector.dart';
import '../../services/manual_variety_service.dart';

import '../../widgets/app_bar_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart' as app_error;
import '../../utils/snackbar_utils.dart';
import '../../utils/snackbar_helper.dart';
import 'subarea_routes.dart';
import 'talhao_detalhes_screen.dart';
import '../../models/experimento_talhao_model.dart';

// Classe para gerenciar múltiplas variedades por talhão
class VariedadeTalhao {
  final String id;
  final String talhaoId;
  final String variedadeId;
  final String variedadeNome;
  final double areaHectares;
  final String? observacoes;
  final DateTime dataCriacao;

  VariedadeTalhao({
    required this.id,
    required this.talhaoId,
    required this.variedadeId,
    required this.variedadeNome,
    required this.areaHectares,
    this.observacoes,
    required this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhaoId': talhaoId,
      'variedadeId': variedadeId,
      'variedadeNome': variedadeNome,
      'areaHectares': areaHectares,
      'observacoes': observacoes,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory VariedadeTalhao.fromMap(Map<String, dynamic> map) {
    return VariedadeTalhao(
      id: map['id'] ?? '',
      talhaoId: map['talhaoId'] ?? '',
      variedadeId: map['variedadeId'] ?? '',
      variedadeNome: map['variedadeNome'] ?? '',
      areaHectares: (map['areaHectares'] ?? 0.0).toDouble(),
      observacoes: map['observacoes'],
      dataCriacao: DateTime.parse(map['dataCriacao'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Widget para gerenciar múltiplas variedades por talhão
class _MultiploVariedadesWidget extends StatefulWidget {
  final String talhaoId;
  final String talhaoNome;
  final double talhaoArea;
  final String culturaId;
  final List<VariedadeTalhao> variedadesExistentes;
  final Function(List<VariedadeTalhao>) onVariedadesChanged;

  const _MultiploVariedadesWidget({
    required this.talhaoId,
    required this.talhaoNome,
    required this.talhaoArea,
    required this.culturaId,
    required this.variedadesExistentes,
    required this.onVariedadesChanged,
  });

  @override
  _MultiploVariedadesWidgetState createState() => _MultiploVariedadesWidgetState();
}

class _MultiploVariedadesWidgetState extends State<_MultiploVariedadesWidget> {
  List<VariedadeTalhao> _variedades = [];
  List<CropVariety> _variedadesDisponiveis = [];
  double _areaTotalUtilizada = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _variedades = List.from(widget.variedadesExistentes);
    _calcularAreaTotal();
    _carregarVariedadesDisponiveis();
  }

  void _calcularAreaTotal() {
    _areaTotalUtilizada = _variedades.fold(0.0, (sum, variedade) => sum + variedade.areaHectares);
  }

  Future<void> _carregarVariedadesDisponiveis() async {
    try {
      // Carregar variedades do banco de dados
      final cropVarietyRepository = CropVarietyRepository();
      _variedadesDisponiveis = await cropVarietyRepository.getByCropId(widget.culturaId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar variedades: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _adicionarVariedade() {
    if (_areaTotalUtilizada >= widget.talhaoArea) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Área total do talhão (${widget.talhaoArea.toStringAsFixed(2)} ha) já foi utilizada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final areaDisponivel = widget.talhaoArea - _areaTotalUtilizada;
    
    showDialog(
      context: context,
      builder: (context) => _AdicionarVariedadeDialog(
        variedadesDisponiveis: _variedadesDisponiveis,
        areaDisponivel: areaDisponivel,
        onAdicionar: (variedadeId, variedadeNome, areaHectares, observacoes) {
          final novaVariedade = VariedadeTalhao(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            talhaoId: widget.talhaoId,
            variedadeId: variedadeId,
            variedadeNome: variedadeNome,
            areaHectares: areaHectares,
            observacoes: observacoes,
            dataCriacao: DateTime.now(),
          );
          
          setState(() {
            _variedades.add(novaVariedade);
            _calcularAreaTotal();
          });
          
          widget.onVariedadesChanged(_variedades);
        },
        onNovaVariedadeCriada: () {
          // Recarregar variedades quando uma nova for criada
          _carregarVariedadesDisponiveis();
        },
      ),
    );
  }

  void _removerVariedade(int index) {
    setState(() {
      _variedades.removeAt(index);
      _calcularAreaTotal();
    });
    
    widget.onVariedadesChanged(_variedades);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informações do talhão
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talhão: ${widget.talhaoNome}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Área total: ${widget.talhaoArea.toStringAsFixed(2)} ha'),
              Text('Área utilizada: ${_areaTotalUtilizada.toStringAsFixed(2)} ha'),
              Text('Área disponível: ${(widget.talhaoArea - _areaTotalUtilizada).toStringAsFixed(2)} ha'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Botão para adicionar variedade
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _adicionarVariedade,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Variedade'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Lista de variedades
        Expanded(
          child: _variedades.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma variedade adicionada',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _variedades.asMap().entries.map((entry) {
                      final index = entry.key;
                      final variedade = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(variedade.variedadeNome),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Área: ${variedade.areaHectares.toStringAsFixed(2)} ha'),
                              if (variedade.observacoes != null && variedade.observacoes!.isNotEmpty)
                                Text('Obs: ${variedade.observacoes}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removerVariedade(index),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

// Dialog para adicionar nova variedade
class _AdicionarVariedadeDialog extends StatefulWidget {
  final List<CropVariety> variedadesDisponiveis;
  final double areaDisponivel;
  final Function(String variedadeId, String variedadeNome, double areaHectares, String? observacoes) onAdicionar;
  final VoidCallback? onNovaVariedadeCriada;

  const _AdicionarVariedadeDialog({
    required this.variedadesDisponiveis,
    required this.areaDisponivel,
    required this.onAdicionar,
    this.onNovaVariedadeCriada,
  });

  @override
  _AdicionarVariedadeDialogState createState() => _AdicionarVariedadeDialogState();
}

class _AdicionarVariedadeDialogState extends State<_AdicionarVariedadeDialog> {
  String? _variedadeSelecionada;
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  @override
  void dispose() {
    _areaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _criarNovaVariedade() {
    // Navegar para o módulo de Culturas da Fazenda
    Navigator.of(context).pushNamed('/farm/crops').then((_) {
      // Recarregar variedades quando retornar
      if (widget.onNovaVariedadeCriada != null) {
        widget.onNovaVariedadeCriada!();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nova variedade criada! Lista de variedades atualizada.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      print('Erro ao navegar para Culturas da Fazenda: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao navegar: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _adicionar() {
    if (_variedadeSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma variedade')),
      );
      return;
    }

    final area = double.tryParse(_areaController.text);
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma área válida')),
      );
      return;
    }

    if (area > widget.areaDisponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Área não pode ser maior que ${widget.areaDisponivel.toStringAsFixed(2)} ha')),
      );
      return;
    }

    final variedade = widget.variedadesDisponiveis.firstWhere((v) => v.id == _variedadeSelecionada);
    
    widget.onAdicionar(
      variedade.id,
      variedade.name,
      area,
      _observacoesController.text.isEmpty ? null : _observacoesController.text,
    );
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Variedade'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão para criar nova variedade
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () => _criarNovaVariedade(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Criar Nova Variedade'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Divisor
          const Divider(),
          const SizedBox(height: 16),
          
          // Título para seleção de variedade existente
          const Text(
            'Ou selecione uma variedade existente:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          
          DropdownButtonFormField<String>(
            value: _variedadeSelecionada,
            decoration: const InputDecoration(
              labelText: 'Variedade',
              border: OutlineInputBorder(),
            ),
            items: widget.variedadesDisponiveis.map((variedade) {
              return DropdownMenuItem(
                value: variedade.id,
                child: Text(variedade.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _variedadeSelecionada = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _areaController,
            decoration: InputDecoration(
              labelText: 'Área (hectares)',
              hintText: 'Máximo: ${widget.areaDisponivel.toStringAsFixed(2)} ha',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _observacoesController,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _adicionar,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}


class PlantioRegistroScreen extends StatefulWidget {
  final String? plantioId; // Se fornecido, carrega um plantio existente para edição

  const PlantioRegistroScreen({Key? key, this.plantioId}) : super(key: key);

  @override
  _PlantioRegistroScreenState createState() => _PlantioRegistroScreenState();
}

class _PlantioRegistroScreenState extends State<PlantioRegistroScreen> {
  // Variáveis de estado
  
  // Serviços
  final ListaPlantioService _listaPlantioService = ListaPlantioService();
  final PlantioService _plantioService = PlantioService();
  final DataCacheService _dataCacheService = DataCacheService();
  final TalhaoModuleService _talhaoModuleService = TalhaoModuleService();
  final CulturaTalhaoService _culturaService = CulturaTalhaoService();
  final VarietyCycleService _varietyCycleService = VarietyCycleService();

  
  // Estado
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Dados do plantio
  DateTime _dataPlantio = DateTime.now();
  TalhaoModel? _talhaoSelecionado;
  String? _safraId;
  crop_model.Crop? _culturaSelecionada;
  AgriculturalProduct? _culturaNovaSelecionada;
  CropVariety? _variedadeSelecionada;
  
  // Novo sistema de variedade e ciclo
  VarietyCycleSelection? _varietyCycleSelection;
  String? _selectedVarietyId; // ID da variedade selecionada no dialog
  
  // Dados para listas
  List<TalhaoModel> _talhoes = [];
  List<crop_model.Crop> _culturas = [];
  List<AgriculturalProduct> _culturasNovas = [];
  List<CropVariety> _variedades = [];
  
  // Sistema de múltiplas variedades por talhão
  List<VariedadeTalhao> _variedadesTalhao = [];
  
  // Foto e localização
  String? _fotoPath;
  double? _latitude;
  double? _longitude;

  // Getters para exibição
  String? get _talhaoNome => _talhaoSelecionado?.name ?? 'Selecione um talhão';
  String? get _safraNome => _safraId ?? 'Selecione uma safra';
  String? get _culturaNome => _culturaNovaSelecionada?.name ?? _culturaSelecionada?.nome ?? 'Selecione uma cultura';
  String? get _variedadeNome {
    if (_variedadesTalhao.isNotEmpty) {
      return '${_variedadesTalhao.length} variedades selecionadas';
    }
    return _varietyCycleSelection?.displayName ?? _variedadeSelecionada?.name ?? 'Selecione variedade e ciclo';
  }
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  // Método para carregar dados iniciais
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Carregar talhões e culturas
      await Future.wait([
        _carregarTalhoes(),
        _carregarCulturas(),
      ]);
      
      // Se for edição, carregar dados do plantio existente
      if (widget.plantioId != null) {
        await _carregarPlantioExistente();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    }
  }
  
  // Carregar talhões disponíveis
  Future<void> _carregarTalhoes() async {
    try {
      print('🔄 Iniciando carregamento de talhões reais...');
      
      // Primeiro, tentar carregar do TalhaoProvider (serviço unificado)
      try {
        // Verificar se o Provider está disponível no contexto
        if (Provider.of<TalhaoProvider>(context, listen: false) != null) {
          final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
          await talhaoProvider.carregarTalhoes();
          
          if (talhaoProvider.talhoes.isNotEmpty) {
            // Converter TalhaoSafraModel para TalhaoModel
            final talhoesConvertidos = talhaoProvider.talhoes.map((talhaoSafra) => TalhaoModel(
              id: talhaoSafra.id,
              name: talhaoSafra.nome,
              area: talhaoSafra.area ?? 0.0,
              poligonos: [PoligonoModel.criar(
                pontos: talhaoSafra.poligonos.isNotEmpty ? talhaoSafra.poligonos.first.pontos : [],
                talhaoId: talhaoSafra.id,
                area: talhaoSafra.area ?? 0.0,
                perimetro: 0.0, // Calcular se necessário
              )],
              dataCriacao: talhaoSafra.dataCriacao,
              dataAtualizacao: DateTime.now(),
              safras: [],
            )).toList();
            
            _talhoes = talhoesConvertidos;
            print('✅ ${talhaoProvider.talhoes.length} talhões carregados do TalhaoProvider (serviço unificado)');
            for (var talhao in talhaoProvider.talhoes) {
              print('  - ${talhao.nome} (ID: ${talhao.id})');
            }
            setState(() {}); // Atualizar UI
            return;
          } else {
            print('⚠️ TalhaoProvider retornou lista vazia, tentando outras fontes...');
          }
        } else {
          print('⚠️ TalhaoProvider não está disponível no contexto, tentando outras fontes...');
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoProvider: $e');
      }
      
      // Segundo, tentar carregar do DataCacheService (que já foi corrigido)
      try {
        print('🔄 Tentando carregar do DataCacheService...');
        _talhoes = await _dataCacheService.getTalhoes();
        if (_talhoes.isNotEmpty) {
          print('✅ ${_talhoes.length} talhões carregados do DataCacheService');
          setState(() {}); // Atualizar UI
          return;
        } else {
          print('⚠️ DataCacheService retornou lista vazia');
        }
      } catch (e) {
        print('❌ Erro ao carregar do DataCacheService: $e');
      }
      
      // Terceiro, tentar carregar do TalhaoModuleService
      try {
        print('🔄 Tentando carregar do TalhaoModuleService...');
        await _talhaoModuleService.initialize();
        _talhoes = await _talhaoModuleService.getTalhoes();
        
        if (_talhoes.isNotEmpty) {
          print('✅ ${_talhoes.length} talhões carregados do TalhaoModuleService');
          setState(() {}); // Atualizar UI
          return;
        } else {
          print('⚠️ TalhaoModuleService retornou lista vazia');
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoModuleService: $e');
      }
      
      // Quarto, tentar carregar do repositório de talhões (fallback)
      try {
        print('🔄 Tentando carregar do TalhaoRepository (fallback)...');
        final talhaoRepository = TalhaoRepository();
        _talhoes = await talhaoRepository.getTalhoes();
        
        if (_talhoes.isNotEmpty) {
          print('✅ ${_talhoes.length} talhões carregados do TalhaoRepository (fallback)');
          setState(() {}); // Atualizar UI
          return;
        } else {
          print('⚠️ TalhaoRepository retornou lista vazia');
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoRepository: $e');
      }
      
      // Se chegou até aqui, não conseguiu carregar nenhum talhão real
      print('❌ Nenhum talhão real encontrado em nenhuma fonte');
      _talhoes = []; // Lista vazia em vez de fallback
      setState(() {}); // Atualizar UI
      
    } catch (e) {
      print('❌ Erro geral ao carregar talhões: $e');
      _talhoes = []; // Lista vazia em vez de fallback
      setState(() {}); // Atualizar UI
    }
  }
  
  // Função para converter string para ProductType
  ProductType _getProductTypeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'herbicide':
      case 'herbicida':
        return ProductType.herbicide;
      case 'insecticide':
      case 'inseticida':
        return ProductType.insecticide;
      case 'fungicide':
      case 'fungicida':
        return ProductType.fungicide;
      case 'fertilizer':
      case 'fertilizante':
        return ProductType.fertilizer;
      case 'growth':
      case 'regulador':
        return ProductType.growth;
      case 'adjuvant':
      case 'adjuvante':
        return ProductType.adjuvant;
      case 'seed':
      case 'semente':
        return ProductType.seed;
      default:
        return ProductType.other;
    }
  }
  
  // Carregar culturas disponíveis
  Future<void> _carregarCulturas() async {
    try {
      print('🔄 Carregando culturas para plantio...');
      
      // Primeiro, tentar carregar do CulturaProvider (método unificado)
      try {
        final culturaProvider = Provider.of<CulturaProvider>(context, listen: false);
        final culturasProvider = await culturaProvider.getCulturasParaPlantio();
        
        if (culturasProvider.isNotEmpty) {
          _culturasNovas = culturasProvider.map((cultura) => AgriculturalProduct(
            id: cultura.id,
            name: cultura.name,
            description: cultura.description ?? '',
            type: ProductType.seed,
            colorValue: cultura.color.value.toString(),
          )).toList();
          print('✅ ${_culturasNovas.length} culturas carregadas do CulturaProvider');
          
          // Carregar culturas legadas para compatibilidade
          try {
            _culturas = await _dataCacheService.getCulturasCrop();
            print('✅ ${_culturas.length} culturas legadas carregadas');
          } catch (e) {
            print('❌ Erro ao carregar culturas legadas: $e');
            _culturas = [];
          }
          
          print('✅ Total de culturas carregadas: ${_culturasNovas.length} novas + ${_culturas.length} legadas');
          setState(() {}); // Atualizar UI
          return; // Sair se conseguiu carregar do provider
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaProvider: $e');
      }
      
      // Fallback: tentar carregar do DataCacheService
      try {
        final culturasCache = await _dataCacheService.getCulturas();
        if (culturasCache.isNotEmpty) {
          _culturasNovas = culturasCache;
          print('✅ ${_culturasNovas.length} culturas carregadas do DataCacheService (fallback)');
        }
      } catch (e) {
        print('❌ Erro ao carregar do DataCacheService: $e');
      }
      
      // Fallback: tentar carregar do serviço de cultura
      try {
        final culturas = await _culturaService.listarCulturas();
        List<AgriculturalProduct> culturasConvertidas = [];
        
        if (culturas.isNotEmpty) {
          if (culturas.first is Map<String, dynamic>) {
            // Se for uma lista de Map, converter para AgriculturalProduct
            culturasConvertidas = (culturas as List<Map<String, dynamic>>).map((cultura) => 
              AgriculturalProduct(
                id: cultura['id']?.toString() ?? '',
                name: cultura['name']?.toString() ?? cultura['nome']?.toString() ?? 'Cultura',
                description: cultura['description']?.toString() ?? '',
                type: _getProductTypeFromString(cultura['type']?.toString() ?? ''),
                colorValue: cultura['color']?.toString() ?? '#4CAF50',
              )
            ).toList();
          } else {
            // Se for uma lista de AgriculturalProduct, usar diretamente
            culturasConvertidas = culturas as List<AgriculturalProduct>;
          }
          
          // Combinar com as culturas já carregadas
          if (_culturasNovas.isEmpty) {
            _culturasNovas = culturasConvertidas;
          } else {
            // Adicionar apenas culturas que não existem
            for (final cultura in culturasConvertidas) {
              if (!_culturasNovas.any((c) => c.id == cultura.id)) {
                _culturasNovas.add(cultura);
              }
            }
          }
          print('✅ ${culturasConvertidas.length} culturas adicionais carregadas do CulturaService (fallback)');
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaService: $e');
      }
      
      // Carregar culturas legadas para compatibilidade
      try {
        _culturas = await _dataCacheService.getCulturasCrop();
        print('✅ ${_culturas.length} culturas legadas carregadas');
      } catch (e) {
        print('❌ Erro ao carregar culturas legadas: $e');
        _culturas = [];
      }
      
      print('✅ Total de culturas carregadas: ${_culturasNovas.length} novas + ${_culturas.length} legadas');
      setState(() {}); // Atualizar UI
      
    } catch (e) {
      print('❌ Erro geral ao carregar culturas: $e');
      _culturasNovas = [];
      _culturas = [];
      setState(() {}); // Atualizar UI
    }
  }
  
  // Carregar variedades de uma cultura
  Future<void> _carregarVariedades(String culturaId) async {
    try {
      print('🔄 Carregando variedades para cultura ID: $culturaId');
      
      // Primeiro, tentar carregar do DataCacheService
      try {
        print('🔄 Tentando carregar variedades do DataCacheService...');
        final variedadesData = await _dataCacheService.getVariedades(culturaId: culturaId);
        if (variedadesData.isNotEmpty) {
          _variedades = variedadesData.map((variedade) {
            // O DataCacheService retorna AgriculturalProduct
            return CropVariety(
              cropId: culturaId,
              name: variedade.name,
              cycleDays: 0, // Valor padrão
              description: variedade.notes ?? '',
            );
          }).toList();
          print('✅ ${_variedades.length} variedades carregadas do DataCacheService');
          setState(() {}); // Atualizar UI
          return;
        } else {
          print('⚠️ DataCacheService retornou lista vazia de variedades');
        }
      } catch (e) {
        print('❌ Erro ao carregar do DataCacheService: $e');
      }
      
      // Segundo, tentar carregar do serviço de cultura
      try {
        print('🔄 Tentando carregar variedades do CulturaTalhaoService...');
        final variedadesData = await _culturaService.listarVariedadesPorCultura(culturaId);
        print('🔍 DEBUG: variedadesData recebido: ${variedadesData.length} itens');
        for (var item in variedadesData) {
          print('  - Item: $item');
        }
        
        if (variedadesData.isNotEmpty) {
          _variedades = variedadesData.map((variedade) => CropVariety(
            cropId: culturaId,
            name: variedade['nome']?.toString() ?? variedade['name']?.toString() ?? 'Variedade',
            cycleDays: int.tryParse(variedade['ciclo_dias']?.toString() ?? variedade['cycleDays']?.toString() ?? '0'),
            description: variedade['descricao']?.toString() ?? variedade['description']?.toString() ?? '',
          )).toList();
          print('✅ ${_variedades.length} variedades carregadas do CulturaTalhaoService');
          print('🎯 VARIEDADES FINAIS:');
          for (var v in _variedades) {
            print('  - ${v.name} (ID: ${v.id})');
          }
          setState(() {}); // Atualizar UI
          return;
        } else {
          print('⚠️ CulturaTalhaoService retornou lista vazia de variedades');
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaTalhaoService: $e');
      }
      
      // Terceiro, tentar carregar do repositório de variedades
      try {
        print('🔄 Tentando carregar variedades do CropVarietyRepository...');
        final cropVarietyRepository = CropVarietyRepository();
        final variedadesData = await cropVarietyRepository.getByCropId(culturaId);
        if (variedadesData.isNotEmpty) {
          _variedades = variedadesData;
          print('✅ ${_variedades.length} variedades carregadas do CropVarietyRepository');
          setState(() {}); // Atualizar UI
          return;
        } else {
          print('⚠️ CropVarietyRepository retornou lista vazia de variedades');
        }
      } catch (e) {
        print('❌ Erro ao carregar do CropVarietyRepository: $e');
      }
      
      // Quarto, tentar buscar variedades no módulo de Culturas da Fazenda
      try {
        print('🔄 Tentando buscar variedades no módulo de Culturas da Fazenda...');
        final culturas = await _dataCacheService.getCulturas();
        
        // Filtrar produtos que são variedades da cultura selecionada
        final variedadesEncontradas = culturas.where((cultura) {
          // Verificar se é uma variedade (tem parentId) e se pertence à cultura selecionada
          return cultura.parentId == culturaId || 
                 cultura.tags?.contains('variedade') == true ||
                 cultura.name.toLowerCase().contains('variedade');
        }).toList();
        
        if (variedadesEncontradas.isNotEmpty) {
          _variedades = variedadesEncontradas.map((variedade) => CropVariety(
            cropId: culturaId,
            name: variedade.name,
            cycleDays: 0, // Valor padrão
            description: variedade.notes ?? variedade.description ?? '',
          )).toList();
          print('✅ ${_variedades.length} variedades encontradas no módulo de Culturas da Fazenda');
          setState(() {}); // Atualizar UI
          return;
        } else {
          print('⚠️ Nenhuma variedade encontrada no módulo de Culturas da Fazenda');
        }
      } catch (e) {
        print('❌ Erro ao buscar no módulo de Culturas da Fazenda: $e');
      }
      
      // Quinto, criar variedades padrão baseadas na cultura se não encontrar nenhuma
      try {
        print('🔄 Criando variedades padrão para a cultura...');
        AgriculturalProduct? cultura;
        try {
          cultura = _culturasNovas.firstWhere(
            (c) => c.id == culturaId,
          );
        } catch (e) {
          try {
            final cropCultura = _culturas.firstWhere(
              (c) => c.id.toString() == culturaId,
            );
            // Converter Crop para AgriculturalProduct
            cultura = AgriculturalProduct(
              id: cropCultura.id.toString(),
              name: cropCultura.name,
              description: cropCultura.description ?? '',
              type: ProductType.seed,
            );
          } catch (e2) {
            // Se não encontrar em nenhuma lista, criar um produto padrão
            cultura = AgriculturalProduct(
              id: culturaId,
              name: 'Cultura Desconhecida',
              type: ProductType.seed,
            );
          }
        }
        
        // Criar variedades padrão baseadas no nome da cultura
        _variedades = _criarVariedadesPadrao(cultura.name, culturaId);
        print('✅ ${_variedades.length} variedades padrão criadas para ${cultura.name}');
        setState(() {}); // Atualizar UI
        return;
        
      } catch (e) {
        print('❌ Erro ao criar variedades padrão: $e');
      }
      
      // Se chegou até aqui, não conseguiu carregar nenhuma variedade
      print('❌ Nenhuma variedade encontrada para cultura ID: $culturaId');
      _variedades = [];
      setState(() {}); // Atualizar UI
      
    } catch (e) {
      print('❌ Erro geral ao carregar variedades: $e');
      _variedades = [];
      setState(() {}); // Atualizar UI
    }
  }
  
  /// Cria variedades padrão baseadas no nome da cultura
  List<CropVariety> _criarVariedadesPadrao(String nomeCultura, String culturaId) {
    final culturaLower = nomeCultura.toLowerCase();
    List<CropVariety> variedades = [];
    
    if (culturaLower.contains('soja')) {
      variedades = [
        CropVariety(cropId: culturaId, name: 'Soja RR', cycleDays: 120, description: 'Soja Roundup Ready'),
        CropVariety(cropId: culturaId, name: 'Soja Intacta', cycleDays: 125, description: 'Soja com tecnologia Intacta'),
        CropVariety(cropId: culturaId, name: 'Soja Convencional', cycleDays: 115, description: 'Soja convencional'),
      ];
    } else if (culturaLower.contains('milho')) {
      variedades = [
        CropVariety(cropId: culturaId, name: 'Milho Convencional', cycleDays: 130, description: 'Milho convencional'),
        CropVariety(cropId: culturaId, name: 'Milho Transgênico', cycleDays: 135, description: 'Milho com tecnologia transgênica'),
        CropVariety(cropId: culturaId, name: 'Milho Pipoca', cycleDays: 110, description: 'Milho pipoca'),
      ];
    } else if (culturaLower.contains('algodão') || culturaLower.contains('algodao')) {
      variedades = [
        CropVariety(cropId: culturaId, name: 'Algodão RR', cycleDays: 180, description: 'Algodão Roundup Ready'),
        CropVariety(cropId: culturaId, name: 'Algodão BT', cycleDays: 175, description: 'Algodão com tecnologia BT'),
      ];
    } else if (culturaLower.contains('trigo')) {
      variedades = [
        CropVariety(cropId: culturaId, name: 'Trigo de Sequeiro', cycleDays: 120, description: 'Trigo adaptado ao sequeiro'),
        CropVariety(cropId: culturaId, name: 'Trigo Irrigado', cycleDays: 110, description: 'Trigo para irrigação'),
      ];
    } else {
      // Variedades genéricas para outras culturas
      variedades = [
        CropVariety(cropId: culturaId, name: 'Variedade 1', cycleDays: 120, description: 'Variedade padrão'),
        CropVariety(cropId: culturaId, name: 'Variedade 2', cycleDays: 125, description: 'Variedade alternativa'),
        CropVariety(cropId: culturaId, name: 'Variedade 3', cycleDays: 130, description: 'Variedade experimental'),
      ];
    }
    
    return variedades;
  }
  
  // Carrega dados do plantio existente para edição
  Future<void> _carregarPlantioExistente() async {
    try {
      if (widget.plantioId == null) return;
      final plantio = await _plantioService.getPlantioById(widget.plantioId!);
      if (plantio != null) {
        setState(() {
          _dataPlantio = plantio.dataPlantio ?? DateTime.now();
          _talhaoSelecionado = _talhoes.firstWhere(
            (t) => t.id == plantio.talhaoId,
            orElse: () => TalhaoModel(
              id: '0',
              name: 'Desconhecido',
              poligonos: const [],
              area: 0.0,
              dataCriacao: DateTime.now(),
              dataAtualizacao: DateTime.now(),
              fazendaId: '',
              safras: [],
              sincronizado: false,
            ),
          );
          _safraId = plantio.safraId;
          // Tentar encontrar cultura no novo módulo primeiro
          try {
            _culturaNovaSelecionada = _culturasNovas.firstWhere(
              (c) => c.id == plantio.culturaId,
            );
            _culturaSelecionada = null;
          } catch (e) {
            // Se não encontrar no novo módulo, procurar nas culturas legadas
            _culturaSelecionada = _culturas.firstWhere(
              (c) => c.id.toString() == plantio.culturaId,
              orElse: () => _culturas.isNotEmpty ? _culturas.first : crop_model.Crop(
                id: 0,
                name: 'Desconhecido',
                description: 'Cultura desconhecida',
              ),
            );
            _culturaNovaSelecionada = null;
          }
          _variedadeSelecionada = null; // Ajustar se houver variedades
          _varietyCycleSelection = null; // Resetar seleção nova
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar plantio existente: $e';
      });
    }
  }

  // Método para selecionar um talhão
  Future<void> _selecionarTalhao() async {
    print('🔍 Verificando talhões disponíveis: ${_talhoes.length}');
    for (var talhao in _talhoes) {
      print('  - ${talhao.name} (ID: ${talhao.id})');
    }
    
    if (_talhoes.isEmpty) {
      print('❌ Lista de talhões está vazia, tentando recarregar...');
      await _carregarTalhoes();
      
      if (_talhoes.isEmpty) {
        SnackbarUtils.showErrorSnackBar(context, 'Nenhum talhão disponível. Verifique se há talhões cadastrados no módulo de Talhões.');
        return;
      }
    }
    
    final result = await showDialog<TalhaoModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Expanded(
              child: Text(
                'Selecione um Talhão',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                Navigator.of(context).pop();
                await _carregarTalhoes();
                _selecionarTalhao();
              },
              tooltip: 'Recarregar',
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: _talhoes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 48, color: Colors.orange),
                      SizedBox(height: 16),
                      Text('Nenhum talhão encontrado'),
                      SizedBox(height: 8),
                      Text('Verifique se há talhões cadastrados no módulo de Talhões'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _talhoes.map((talhao) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          talhao.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        talhao.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Área: ${talhao.area?.toStringAsFixed(2) ?? '-'} ha'),
                      onTap: () => Navigator.of(context).pop(talhao),
                    )).toList(),
                  ),
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
        _talhaoSelecionado = result;
        _safraId = result.safras.isNotEmpty ? result.safras.first.id : null;
      });
    }
  }

  // Método para selecionar uma cultura
  Future<void> _selecionarCultura() async {
    if (_culturasNovas.isEmpty && _culturas.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Nenhuma cultura disponível');
      return;
    }
    
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione uma Cultura'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (_culturasNovas.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Culturas da Fazenda',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ..._culturasNovas.map((cultura) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _parseColor((cultura.colorValue ?? Colors.green.value).toString()),
                    child: const Icon(Icons.eco, color: Colors.white),
                  ),
                  title: Text(cultura.name),
                  subtitle: Text('Cultura: ${cultura.category ?? 'Não categorizada'}'),
                  onTap: () => Navigator.of(context).pop({
                    'tipo': 'cultura_nova',
                    'cultura': cultura,
                  }),
                )).toList(),
              ],
              if (_culturas.isNotEmpty) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Culturas Legadas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ..._culturas.map((cultura) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(cultura.colorValue ?? Colors.green.value),
                    child: const Icon(Icons.grass, color: Colors.white),
                  ),
                  title: Text(cultura.nome ?? 'Sem nome'),
                  subtitle: Text('Sistema legado'),
                  onTap: () => Navigator.of(context).pop({
                    'tipo': 'cultura_legada',
                    'cultura': cultura,
                  }),
                )).toList(),
              ],
            ],
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
        if (result['tipo'] == 'cultura_nova') {
          _culturaNovaSelecionada = result['cultura'];
          _culturaSelecionada = null;
          // Carregar variedades da cultura selecionada
          _carregarVariedades(result['cultura'].id);
        } else {
          _culturaSelecionada = result['cultura'];
          _culturaNovaSelecionada = null;
          // Carregar variedades da cultura selecionada
          _carregarVariedades(result['cultura'].id.toString());
        }
        _variedadeSelecionada = null; // Resetar variedade
        _varietyCycleSelection = null; // Resetar seleção nova
      });
    }
  }

  // Método para selecionar variedade e ciclo (MÚLTIPLAS VARIEDADES)
  Future<void> _selecionarVariedadeECiclo() async {
    final culturaNome = _culturaNovaSelecionada?.name ?? _culturaSelecionada?.nome;
    if (culturaNome == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma cultura primeiro');
      return;
    }

    if (_talhaoSelecionado == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione um talhão primeiro');
      return;
    }

    final culturaId = (_culturaNovaSelecionada?.id ?? _culturaSelecionada?.id ?? '').toString();
    
    // Mostrar dialog para gerenciar múltiplas variedades
    final result = await showDialog<List<VariedadeTalhao>>(
      context: context,
      builder: (context) => _buildMultiploVariedadesDialog(culturaId, culturaNome),
    );
    
    if (result != null) {
      setState(() {
        _variedadesTalhao = result;
      });
      
      SnackbarUtils.showSuccessSnackBar(
        context, 
        '${result.length} variedades adicionadas ao talhão!'
      );
    }
  }
  
  // Dialog para gerenciar múltiplas variedades
  Widget _buildMultiploVariedadesDialog(String culturaId, String culturaNome) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.eco, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Múltiplas Variedades - $culturaNome',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: _MultiploVariedadesWidget(
          talhaoId: _talhaoSelecionado!.id,
          talhaoNome: _talhaoSelecionado!.name,
          talhaoArea: _talhaoSelecionado!.area ?? 0.0,
          culturaId: culturaId,
          variedadesExistentes: _variedadesTalhao,
          onVariedadesChanged: (variedades) {
            // Atualizar a lista de variedades do talhão
            setState(() {
              _variedadesTalhao = variedades;
            });
            print('🔄 Variedades do talhão atualizadas: ${variedades.length}');
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            // Retornar as variedades selecionadas
            Navigator.of(context).pop(_variedadesTalhao);
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  // Método para selecionar data de plantio
  Future<void> _selecionarDataPlantio() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dataPlantio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (result != null) {
      setState(() {
        _dataPlantio = result;
      });
    }
  }

  // Capturar foto de plantabilidade
  Future<void> _capturarFoto() async {
    try {
      // Verificar permissão de câmera
      final status = await Permission.camera.request();
      if (status.isDenied) {
        SnackbarUtils.showErrorSnackBar(
          context, 
          'Permissão de câmera negada. Não é possível capturar foto.'
        );
        return;
      }
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Qualidade da imagem
        maxWidth: 1920, // Largura máxima
        maxHeight: 1080, // Altura máxima
      );
      
      if (image != null) {
        print('📸 Foto capturada: ${image.path}');
        setState(() {
          _fotoPath = image.path;
        });
        SnackbarUtils.showSuccessSnackBar(
          context, 
          'Foto capturada com sucesso!'
        );
      }
    } catch (e) {
      print('❌ Erro ao capturar foto: $e');
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao capturar foto: $e'
      );
    }
  }

  // Obter localização GPS
  Future<void> _obterLocalizacao() async {
    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          SnackbarUtils.showErrorSnackBar(
            context, 
            'Permissão de localização negada.'
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        SnackbarUtils.showErrorSnackBar(
          context, 
          'Permissão de localização negada permanentemente.'
        );
        return;
      }
      
      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      SnackbarUtils.showSuccessSnackBar(
        context, 
        'Localização obtida com sucesso!'
      );
    } catch (e) {
      print('Erro ao obter localização: $e');
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao obter localização: $e'
      );
    }
  }

  // Salvar plantio
  Future<void> _salvarPlantio() async {
    // Validações básicas
    if (_talhaoSelecionado == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione um talhão');
      return;
    }
    
    if (_culturaNovaSelecionada == null && _culturaSelecionada == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma cultura');
      return;
    }
    
    // Verificar se há variedades selecionadas (sistema de múltiplas variedades)
    if (_variedadesTalhao.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma variedade e ciclo');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Criar observação completa com informações de variedade e ciclo
      String? observacao;
      String variedadeNome = '';
      
      if (_variedadesTalhao.isNotEmpty) {
        // Sistema de múltiplas variedades: usar a primeira variedade selecionada
        variedadeNome = _variedadesTalhao.first.variedadeNome;
        observacao = 'Variedades selecionadas: ${_variedadesTalhao.map((v) => '${v.variedadeNome} (${v.areaHectares} ha)').join(', ')}';
        if (_fotoPath != null) {
          observacao += ' | Foto: $_fotoPath';
        }
      } else if (_varietyCycleSelection != null) {
        // Novo sistema: incluir informações completas de variedade e ciclo
        variedadeNome = _varietyCycleSelection!.variety.name;
        observacao = 'Variedade: ${_varietyCycleSelection!.variety.name} (${_varietyCycleSelection!.variety.type}) - Ciclo: ${_varietyCycleSelection!.cycle.name} (${_varietyCycleSelection!.cycle.days} dias)';
        if (_fotoPath != null) {
          observacao += ' | Foto: $_fotoPath';
        }
      } else {
        // Sistema antigo: manter compatibilidade
        variedadeNome = _variedadeSelecionada?.name ?? 'Variedade não especificada';
        observacao = _fotoPath != null ? 'Foto: $_fotoPath' : null;
      }

      // Criar objeto de plantio usando o modelo correto
      // ✅ Agora só registra dados BÁSICOS - população/espaçamento virão do Estande!
      final plantio = plantio_model.Plantio(
        id: widget.plantioId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        talhaoId: _talhaoSelecionado!.id,
        cultura: _culturaNovaSelecionada?.name ?? _culturaSelecionada?.nome ?? '',
        variedade: variedadeNome,
        dataPlantio: _dataPlantio,
        hectares: _talhaoSelecionado!.area, // Área do talhão
        observacao: observacao,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Salvar plantio usando o serviço correto
      await _listaPlantioService.criarOuAtualizarPlantio(plantio);
      
      setState(() {
        _isSaving = false;
      });
      
      SnackbarUtils.showSuccessSnackBar(
        context, 
        'Plantio salvo com sucesso!'
      );
      
      // Voltar para a tela anterior
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      print('Erro ao salvar plantio: $e');
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao salvar plantio: $e'
      );
    }
  }

  // Função para converter string de cor para Color
  Color _parseColor(String colorString) {
    try {
      if (colorString.isEmpty) {
        return Colors.green;
      }
      
      // Remover espaços em branco
      colorString = colorString.trim();
      
      // Se já é um objeto Color, retornar cor padrão
      if (colorString.contains('Color(')) {
        return Colors.green;
      }
      
      if (colorString.startsWith('#')) {
        String hex = colorString.substring(1);
        // Validar se o hex é válido (apenas dígitos hexadecimais)
        if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
          return Color(int.parse('0xFF$hex'));
        } else if (RegExp(r'^[0-9A-Fa-f]{3}$').hasMatch(hex)) {
          // Expandir cores de 3 dígitos
          hex = hex.split('').map((c) => c + c).join();
          return Color(int.parse('0xFF$hex'));
        } else {
          print('❌ Hex inválido: $hex');
          return Colors.green;
        }
      } else if (colorString.startsWith('0x')) {
        // Validar se é um número hexadecimal válido
        if (RegExp(r'^0x[0-9A-Fa-f]{8}$').hasMatch(colorString)) {
          return Color(int.parse(colorString));
        } else {
          print('❌ Valor 0x inválido: $colorString');
          return Colors.green;
        }
      } else if (RegExp(r'^[0-9]+$').hasMatch(colorString)) {
        // Se é apenas um número
        return Color(int.parse(colorString));
      } else {
        print('❌ Formato de cor não reconhecido: $colorString');
        return Colors.green;
      }
    } catch (e) {
      print('❌ Erro ao converter cor: $colorString - $e');
      return Colors.green;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: widget.plantioId == null ? 'Novo Plantio' : 'Editar Plantio',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? app_error.AppErrorWidget(message: _errorMessage!)
              : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTalhaoSafraSection(),
          const SizedBox(height: 16),
          _buildCulturaVariedadeSection(),
          const SizedBox(height: 16),
          _buildDataPlantioSection(),
          const SizedBox(height: 16),
          _buildFotoLocalizacaoSection(),
        ],
      ),
    );
  }
  
  // Seção de Talhão e Safra
  Widget _buildTalhaoSafraSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.landscape, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Talhão e Safra',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListTile(
                title: Text(
                  _talhaoNome ?? 'Selecione um talhão',
                  style: TextStyle(
                    color: _talhaoSelecionado != null ? Colors.black87 : Colors.grey.shade600,
                    fontWeight: _talhaoSelecionado != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                subtitle: _talhaoSelecionado != null
                    ? Text(
                        'Área: ${_talhaoSelecionado!.area?.toStringAsFixed(2) ?? '-'} ha',
                        style: TextStyle(color: Colors.grey.shade700),
                      )
                    : null,
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                onTap: _selecionarTalhao,
              ),
            ),
            const SizedBox(height: 8),
            if (_safraId != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Safra: $_safraNome'),
              ),
            const SizedBox(height: 16),
            if (_talhaoSelecionado != null)
              ElevatedButton.icon(
                onPressed: _abrirGestaoSubareas,
                icon: const Icon(Icons.map),
                label: const Text('Gestão de Subáreas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Seção de Cultura e Variedade
  Widget _buildCulturaVariedadeSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Cultura e Variedade',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListTile(
                title: Text(
                  _culturaNome ?? 'Selecione uma cultura',
                  style: TextStyle(
                    color: (_culturaSelecionada != null || _culturaNovaSelecionada != null) 
                        ? Colors.black87 
                        : Colors.grey.shade600,
                    fontWeight: (_culturaSelecionada != null || _culturaNovaSelecionada != null) 
                        ? FontWeight.w500 
                        : FontWeight.normal,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                onTap: _selecionarCultura,
              ),
            ),
            const SizedBox(height: 8),
            if (_culturaSelecionada != null || _culturaNovaSelecionada != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  title: Text(
                    _variedadeNome ?? 'Selecione uma variedade',
                    style: TextStyle(
                      color: _variedadeSelecionada != null ? Colors.black87 : Colors.grey.shade600,
                      fontWeight: _variedadeSelecionada != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                  onTap: _selecionarVariedadeECiclo,
                ),
              ),
            // Adicionar mensagem de erro se não há variedades
            if ((_culturaSelecionada != null || _culturaNovaSelecionada != null) && _variedades.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhuma variedade disponível para esta cultura',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
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
  
  // Seção de Data de Plantio
  Widget _buildDataPlantioSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Data de Plantio',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListTile(
                title: Text(
                  DateFormat('dd/MM/yyyy').format(_dataPlantio),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Data do plantio',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                onTap: _selecionarDataPlantio,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Seção de Foto e Localização
  Widget _buildFotoLocalizacaoSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.purple.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Foto e Localização',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capturar Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _obterLocalizacao,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Obter GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_fotoPath != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Image.file(
                        File(_fotoPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Erro ao carregar imagem: $error');
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Erro ao carregar imagem',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },

                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _fotoPath = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_latitude != null && _longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitude: ${_latitude!.toStringAsFixed(6)}'),
                      Text('Longitude: ${_longitude!.toStringAsFixed(6)}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _salvarPlantio,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Salvar Plantio'),
      ),
    );
  }

  // Método para abrir a gestão de subáreas
  Future<void> _abrirGestaoSubareas() async {
    if (_talhaoSelecionado == null) {
      SnackbarHelper.showWarning(context, 'Selecione um talhão primeiro');
      return;
    }

    try {
      // Criar um experimento baseado no talhão selecionado
      final experimento = Experimento(
        id: 'exp_${_talhaoSelecionado!.id}_${DateTime.now().millisecondsSinceEpoch}',
        nome: 'Experimento ${_talhaoSelecionado!.nome}',
        talhaoId: _talhaoSelecionado!.id.toString(),
        talhaoNome: _talhaoSelecionado!.nome,
        dataInicio: DateTime.now(),
        status: 'ativo',
        criadoEm: DateTime.now(),
        cultura: _culturaSelecionada?.nome,
        variedade: _variedadeSelecionada?.nome,
      );

      // Navegar diretamente para a tela de detalhes do talhão
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TalhaoDetalhesScreen(experimento: experimento),
        ),
      );
      
      // Se retornou algo, atualizar a tela
      if (result != null) {
        setState(() {});
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Erro ao abrir gestão de subáreas: $e');
    }
  }

}
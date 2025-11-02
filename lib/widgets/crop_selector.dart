import 'package:flutter/material.dart';
import '../models/crop.dart' as app_crop;
import '../database/models/crop.dart' as db_crop;
import '../models/agricultural_product.dart' show AgriculturalProduct, ProductType;

import '../repositories/crop_repository.dart';
import '../repositories/agricultural_product_repository.dart';
import '../modules/planting/services/data_cache_service.dart';
import '../utils/model_converter_utils.dart';
import 'loading_error_feedback.dart';

/// Widget para seleção de culturas a partir do banco de dados
class CropSelector extends StatefulWidget {
  final app_crop.Crop? initialValue;
  final Function(app_crop.Crop) onChanged;
  final bool isRequired;
  final String label;

  const CropSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Cultura',
  }) : super(key: key);

  @override
  State<CropSelector> createState() => _CropSelectorState();
}

class _CropSelectorState extends State<CropSelector> {
  final CropRepository _cropRepository = CropRepository();
  final AgriculturalProductRepository _agriculturalProductRepository = AgriculturalProductRepository();
  final DataCacheService _dataCacheService = DataCacheService();
  
  List<app_crop.Crop> _crops = [];
  app_crop.Crop? _selectedCrop;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCrop = widget.initialValue;
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<AgriculturalProduct> culturas = <AgriculturalProduct>[];
      
      // Forçar atualização do cache para garantir dados mais recentes
      try {
        // Primeiro, tentar carregar todas as culturas do repositório
        culturas = await _agriculturalProductRepository.getAll();
        
        // Filtrar apenas as culturas (tipo semente)
        culturas = culturas.where((c) => c.type == ProductType.seed).toList();
        
        print('Carregadas ${culturas.length} culturas diretamente do repositório');
        
        // Se não encontrou culturas, tentar pelo cache
        if (culturas.isEmpty) {
          final dbCulturas = await _dataCacheService.getCulturas(forceRefresh: true);
          // Não podemos fazer cast direto, precisamos converter os modelos
          culturas = dbCulturas.map((dbCrop) => ModelConverterUtils.dbCropToAgriculturalProduct(dbCrop as db_crop.Crop)).toList();
          print('Carregadas ${culturas.length} culturas do cache');
        }
        
        if (culturas.isNotEmpty) {
          setState(() {
            // Converter os objetos AgriculturalProduct para o modelo Crop usado pelo widget
            _crops = culturas.map((cultura) => ModelConverterUtils.agriculturalProductToAppCrop(cultura)).toList();
            
            // Verificar se temos uma cultura selecionada e se ela ainda existe na lista
            if (_selectedCrop != null) {
              final cropExists = _crops.any((crop) => crop.id == _selectedCrop!.id);
              if (!cropExists) {
                _selectedCrop = null;
              }
            }
            
            _isLoading = false;
          });
          return;
        }
      } catch (cacheError) {
        print('Erro ao carregar culturas: $cacheError');
      }
      
      // Se não conseguir do cache, tenta do repositório tradicional
      final dbCrops = await _cropRepository.getAll();
      
      setState(() {
        _crops = dbCrops.map((dbCrop) => app_crop.Crop(
          id: dbCrop.id,
          name: dbCrop.name,
          description: dbCrop.description,
          scientificName: dbCrop.scientificName,
          growthCycle: dbCrop.growthCycle,
          plantSpacing: dbCrop.plantSpacing,
          rowSpacing: dbCrop.rowSpacing,
          plantingDepth: dbCrop.plantingDepth,
          idealTemperature: dbCrop.idealTemperature,
          waterRequirement: dbCrop.waterRequirement,
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar culturas: $e';
      });
      print('Erro ao carregar culturas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingErrorFeedback(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadCrops,
      loadingText: 'Carregando culturas...',
      errorTitle: 'Erro ao carregar culturas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label + (widget.isRequired ? ' *' : ''),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _crops.isEmpty
              ? _buildEmptyCropsMessage()
              : _buildDropdown(),
        ],
      ),
    );
  }

  Widget _buildEmptyCropsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nenhuma cultura cadastrada',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cadastre culturas antes de continuar',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Navegar para o módulo de Culturas e Pragas, submódulo de Culturas da Fazenda
                    Navigator.of(context).pushNamed('/culturas-pragas/culturas-fazenda').then((_) {
                      // Recarregar as culturas quando retornar
                      _loadCrops();
                    });
                  },
                  child: const Text('Cadastrar Cultura'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    // Garantir que não há valores duplicados na lista de crops
    final uniqueCrops = <int, app_crop.Crop>{};
    for (var crop in _crops) {
      if (crop.id != null) {
        uniqueCrops[crop.id!] = crop;
      }
    }
    final uniqueCropsList = uniqueCrops.values.toList();
    
    return DropdownButtonFormField<app_crop.Crop>(
      value: _selectedCrop,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      isDense: true,
      items: uniqueCropsList.map((crop) {
        return DropdownMenuItem<app_crop.Crop>(
          value: crop,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  crop.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      validator: widget.isRequired ? (value) {
        if (value == null) {
          return 'Por favor, selecione uma cultura';
        }
        return null;
      } : null,
      onChanged: (app_crop.Crop? newValue) {
        setState(() {
          _selectedCrop = newValue;
        });
        if (newValue != null) {
          widget.onChanged(newValue);
        }
      },
    );
  }
  
  // Função utilitária para converter do modelo do banco para o modelo do app
  app_crop.Crop _convertDbCropToAppCrop(db_crop.Crop dbCrop) {
    return ModelConverterUtils.dbCropToAppCrop(dbCrop);
  }
}

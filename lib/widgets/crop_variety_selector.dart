import 'package:flutter/material.dart';
import '../models/crop_variety.dart';
import '../models/agricultural_product.dart';
import '../repositories/crop_variety_repository.dart';
import '../repositories/agricultural_product_repository.dart';
// Importação removida - não utilizada
import '../modules/planting/services/data_cache_service.dart';

/// Widget para seleção de variedades de culturas a partir do banco de dados
class CropVarietySelector extends StatefulWidget {
  final String? initialValue;
  final String? cropId;
  final Function(String) onChanged;
  final bool isRequired;
  final String label;

  const CropVarietySelector({
    Key? key,
    this.initialValue,
    required this.cropId,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Variedade',
  }) : super(key: key);

  @override
  State<CropVarietySelector> createState() => _CropVarietySelectorState();
}

class _CropVarietySelectorState extends State<CropVarietySelector> {
  final CropVarietyRepository _varietyRepository = CropVarietyRepository();
  final AgriculturalProductRepository _agriculturalProductRepository = AgriculturalProductRepository();
  final DataCacheService _dataCacheService = DataCacheService();
  List<CropVariety> _varieties = [];
  String? _selectedVarietyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedVarietyId = widget.initialValue;
    if (widget.cropId != null) {
      _loadVarieties();
    }
  }

  @override
  void didUpdateWidget(CropVarietySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cropId != oldWidget.cropId) {
      _selectedVarietyId = null;
      if (widget.cropId != null) {
        _loadVarieties();
      } else {
        setState(() {
          _varieties = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVarieties() async {
    if (widget.cropId == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> variedades = [];
      
      // Forçar atualização do cache para garantir dados mais recentes
      try {
        // Primeiro, tentar carregar todas as variedades do repositório
        final allProducts = await _agriculturalProductRepository.getAll();
        
        // Filtrar apenas as variedades que têm parentId igual ao cropId
        if (widget.cropId != null && widget.cropId!.isNotEmpty) {
          variedades = allProducts.where((v) => 
            v.type == ProductType.seed && 
            (v.parentId == widget.cropId || 
             (v.tags != null && v.tags!.contains('cultura_${widget.cropId}')))  
          ).toList();
          
          print('Carregadas ${variedades.length} variedades diretamente do repositório para cultura ${widget.cropId}');
        }
        
        // Se não encontrou variedades, tentar pelo cache
        if (variedades.isEmpty && widget.cropId != null) {
          // Obter todas as variedades e filtrar manualmente pelo culturaId
          final cachedVariedades = await _dataCacheService.getVariedades(
            forceRefresh: true,
          );
          // Filtrar apenas as variedades da cultura selecionada
          final filteredVariedades = cachedVariedades.where(
            (v) => v.culturaId.toString() == widget.cropId
          ).toList();
          variedades = filteredVariedades;
          print('Carregadas ${variedades.length} variedades do cache para cultura ${widget.cropId}');
        }
        
        if (variedades.isNotEmpty) {
          setState(() {
            // Converter os objetos AgriculturalProduct para o modelo CropVariety usado pelo widget
            _varieties = variedades.map((variedade) => CropVariety(
              id: variedade.id,
              name: variedade.name,
              description: variedade.notes,
              cropId: variedade.parentId?.toString() ?? '0',
            )).toList();
            
            // Verificar se temos uma variedade selecionada e se ela ainda existe na lista
            if (_selectedVarietyId != null) {
              final varietyExists = _varieties.any((variety) => variety.id.toString() == _selectedVarietyId);
              if (!varietyExists) {
                _selectedVarietyId = null;
              }
            }
            
            _isLoading = false;
          });
          return;
        }
      } catch (cacheError) {
        print('Erro ao carregar variedades: $cacheError');
      }
      
      // Se não conseguir do cache, tenta do repositório tradicional
      final varieties = await _varietyRepository.getByCropId(widget.cropId!);
      setState(() {
        _varieties = varieties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar variedades: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        widget.cropId == null
            ? _buildNoCropSelectedMessage()
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _varieties.isEmpty
                    ? _buildEmptyVarietiesMessage()
                    : _buildDropdown(),
      ],
    );
  }

  Widget _buildNoCropSelectedMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selecione uma cultura primeiro',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVarietiesMessage() {
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
                  'Nenhuma variedade cadastrada para esta cultura',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cadastre variedades antes de continuar',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Navegar para o módulo de Culturas e Pragas, submódulo de Variedades de Culturas
                    Navigator.of(context).pushNamed('/culturas-pragas/variedades', arguments: {'cropId': widget.cropId}).then((_) {
                      // Recarregar as variedades quando retornar
                      _loadVarieties();
                    });
                  },
                  child: const Text('Cadastrar Variedade'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedVarietyId,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Selecione uma variedade'),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onChanged: (String? newValue) {
            setState(() {
              _selectedVarietyId = newValue;
            });
            if (newValue != null) {
              widget.onChanged(newValue);
            }
          },
          items: _varieties.map<DropdownMenuItem<String>>((CropVariety variety) {
            return DropdownMenuItem<String>(
              value: variety.id,
              child: Text(variety.name),
            );
          }).toList(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/crop.dart';
import 'package:fortsmart_agro/models/variety.dart';
import 'package:fortsmart_agro/modules/planting/models/plantio_model.dart';
import 'package:fortsmart_agro/modules/planting/services/data_cache_service.dart';
import 'package:fortsmart_agro/modules/planting/services/plantio_service.dart';
import 'package:fortsmart_agro/modules/planting/widgets/plantio_form.dart';
import 'package:fortsmart_agro/utils/date_formatter.dart';
import 'package:fortsmart_agro/utils/logger.dart';

/// Tela para visualização e edição de detalhes de um plantio
class PlantioDetalhesScreen extends StatefulWidget {
  final PlantioModel plantio;

  const PlantioDetalhesScreen({
    Key? key,
    required this.plantio,
  }) : super(key: key);

  @override
  State<PlantioDetalhesScreen> createState() => _PlantioDetalhesScreenState();
}

class _PlantioDetalhesScreenState extends State<PlantioDetalhesScreen> {
  final PlantioService _plantioService = PlantioService();
  final DataCacheService _dataCacheService = DataCacheService();
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  late PlantioModel _plantio;
  
  // Dados para exibição
  String _nomeTalhao = 'Carregando...';
  String _nomeCultura = 'Carregando...';
  String _nomeVariedade = '';
  String _nomeTrator = '';
  String _nomePlantadeira = '';
  String _nomeCalibragem = '';
  String _nomeEstande = '';
  
  @override
  void initState() {
    super.initState();
    _plantio = widget.plantio;
    _carregarDadosRelacionados();
  }
  
  Future<void> _carregarDadosRelacionados() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Carrega dados do talhão, cultura e variedade
      final talhao = await _dataCacheService.getTalhao(_plantio.talhaoId);
      final culturas = await _dataCacheService.getCulturas();
      final cultura = culturas.firstWhere(
        (c) => c.id.toString() == _plantio.culturaId.toString(),
        orElse: () => Crop(id: 0, name: 'Cultura não encontrada', description: '', scientificName: '')
      );
      
      final variedades = await _dataCacheService.getVariedades();
      final variedade = _plantio.variedadeId != null ? 
          variedades.firstWhere(
            (v) => v['id'].toString() == _plantio.variedadeId.toString(),
            orElse: () => {'id': '', 'name': 'Variedade não encontrada'}
          ) : null;
      
      // Atualiza os nomes básicos
      if (mounted) {
        setState(() {
          _nomeTalhao = talhao?.nome ?? 'Talhão não encontrado';
          _nomeCultura = cultura.name ?? 'Cultura não encontrada';
          _nomeVariedade = variedade != null ? variedade['name'] ?? '' : '';
        });
      }
      
      // Carrega as máquinas com tratamento seguro para a lista maquinasIds
      if (_plantio.maquinasIds != null && _plantio.maquinasIds.isNotEmpty) {
        // Carrega o trator (primeira máquina na lista)
        final trator = await _dataCacheService.getMachine(_plantio.maquinasIds[0]);
        if (trator != null && mounted) {
          setState(() {
            _nomeTrator = trator.name; // Usando name do modelo Machine unificado
          });
        }
        
        // Carrega a plantadeira (segunda máquina na lista)
        if (_plantio.maquinasIds.length > 1) {
          final plantadeira = await _dataCacheService.getMachine(_plantio.maquinasIds[1]);
          if (plantadeira != null && mounted) {
            setState(() {
              _nomePlantadeira = plantadeira.name; // Usando name do modelo Machine unificado
            });
          }
        }
      }

      // Carrega a calibragem e o estande
      if (_plantio.calibragemId != null) {
        final calibragem = await _dataCacheService.getCalibragemSemente(_plantio.calibragemId!);
        if (calibragem != null && mounted) {
          setState(() {
            _nomeCalibragem = 'Densidade: ${calibragem.densidadeMetro} sementes/m';
          });
        }
      }

      if (_plantio.estandeId != null) {
        final estande = await _dataCacheService.getEstande(_plantio.estandeId!);
        if (estande != null && mounted) {
          setState(() {
            final data = estande.dataAvaliacao ?? DateTime.now();
            final plantas = estande.plantasPorHectare ?? 0;
            _nomeEstande = 'Data: ${DateFormatter.format(data)} - $plantas plantas/ha';
          });
        }
      }
    } catch (e) {
      Logger.error('Erro ao carregar dados relacionados: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _atualizarPlantio(PlantioModel plantio) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _plantioService.atualizar(plantio);
      
      setState(() {
        _plantio = plantio;
        _isEditing = false;
      });
      
      _carregarDadosRelacionados();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantio atualizado com sucesso!')),
        );
      }
    } catch (e) {
      Logger.error('Erro ao atualizar plantio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar plantio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Plantio'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PlantioForm(
                    plantio: _plantio,
                    onSave: _atualizarPlantio,
                    isEditing: true,
                  ),
                )
              : _buildDetalhes(),
    );
  }
  
  Widget _buildDetalhes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações Gerais',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Talhão', _nomeTalhao),
                  _buildInfoRow('Cultura', _nomeCultura),
                  if (_nomeVariedade.isNotEmpty)
                    _buildInfoRow('Variedade', _nomeVariedade),
                  _buildInfoRow('Data do Plantio', DateFormatter.format(_plantio.dataPlantio)),
                  _buildInfoRow('População', '${_plantio.populacao} plantas/ha'),
                  _buildInfoRow('Espaçamento', '${_plantio.espacamento} cm'),
                  _buildInfoRow('Profundidade', '${_plantio.profundidade} cm'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Máquinas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (_nomeTrator.isNotEmpty)
                    _buildInfoRow('Trator', _nomeTrator),
                  if (_nomePlantadeira.isNotEmpty)
                    _buildInfoRow('Plantadeira', _nomePlantadeira),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_nomeCalibragem.isNotEmpty || _nomeEstande.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calibragem e Estande',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    if (_nomeCalibragem.isNotEmpty)
                      _buildInfoRow('Calibragem', _nomeCalibragem),
                    if (_nomeEstande.isNotEmpty)
                      _buildInfoRow('Estande', _nomeEstande),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          if (_plantio.observacoes != null && _plantio.observacoes!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text(_plantio.observacoes!),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações do Sistema',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('ID', _plantio.id),
                  _buildInfoRow('Criado em', DateFormatter.formatWithTime(_plantio.criadoEm)),
                  _buildInfoRow('Atualizado em', DateFormatter.formatWithTime(_plantio.atualizadoEm)),
                  _buildInfoRow('Sincronizado', _plantio.sincronizado ? 'Sim' : 'Não'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// Extensões removidas pois não são mais necessárias

extension on List<Variety>? {
  get nome => null;
}

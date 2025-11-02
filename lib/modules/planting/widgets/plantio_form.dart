import 'package:flutter/material.dart';
import 'package:fortsmart_agro/modules/planting/models/plantio_model.dart';
import 'package:fortsmart_agro/modules/planting/services/data_cache_service.dart';
import 'package:fortsmart_agro/modules/planting/services/plantio_service.dart';
// import 'package:fortsmart_agro/utils/date_utils.dart'; // Removido - não utilizado
import 'package:fortsmart_agro/widgets/calibragem_semente_selector.dart';
import 'package:fortsmart_agro/widgets/cultura_selector.dart';
import 'package:fortsmart_agro/widgets/custom_date_picker.dart';
// import 'package:fortsmart_agro/widgets/custom_dropdown.dart'; // Removido - não utilizado
import 'package:fortsmart_agro/widgets/custom_text_field.dart';
import 'package:fortsmart_agro/widgets/estande_selector.dart';
// import 'package:fortsmart_agro/widgets/machine_selector.dart'; // Widget removido
import 'package:fortsmart_agro/widgets/talhao_selector.dart';
import 'package:fortsmart_agro/widgets/variedade_selector.dart';
import 'package:intl/intl.dart';

/// Widget de formulário para cadastro e edição de plantios
class PlantioForm extends StatefulWidget {
  final PlantioModel? plantio;
  final Function(PlantioModel) onSave;
  final bool isEditing;

  const PlantioForm({
    Key? key,
    this.plantio,
    required this.onSave,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<PlantioForm> createState() => _PlantioFormState();
}

class _PlantioFormState extends State<PlantioForm> {
  final _formKey = GlobalKey<FormState>();
  final PlantioService _plantioService = PlantioService();
  final DataCacheService _dataCacheService = DataCacheService();
  
  // Controladores
  final TextEditingController _dataPlantioController = TextEditingController();
  final TextEditingController _populacaoController = TextEditingController();
  final TextEditingController _espacamentoController = TextEditingController();
  final TextEditingController _profundidadeController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  
  // Valores do formulário
  String? _talhaoId;
  String? _culturaId;
  String? _variedadeId;
  String? _tratorId;
  String? _plantadeiraId;
  String? _calibragemId;
  String? _estandeId;
  DateTime _dataPlantio = DateTime.now();
  int _populacao = 0;
  double _espacamento = 0.0;
  double _profundidade = 0.0;
  String _observacoes = '';
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.plantio != null) {
      _talhaoId = widget.plantio!.talhaoId;
      _culturaId = widget.plantio!.culturaId;
      _variedadeId = widget.plantio!.variedadeId;
      _tratorId = widget.plantio!.tratorId;
      _plantadeiraId = widget.plantio!.plantadeiraId;
      _calibragemId = widget.plantio!.calibragemId;
      _estandeId = widget.plantio!.estandeId;
      _dataPlantio = widget.plantio!.dataPlantio;
      _populacao = widget.plantio!.populacao;
      _espacamento = widget.plantio!.espacamento;
      _profundidade = widget.plantio!.profundidade;
      _observacoes = widget.plantio!.observacoes ?? '';
      
      _dataPlantioController.text = DateFormat('dd/MM/yyyy').format(_dataPlantio);
      _populacaoController.text = _populacao.toString();
      _espacamentoController.text = _espacamento.toString();
      _profundidadeController.text = _profundidade.toString();
      _observacoesController.text = _observacoes;
    }
  }
  
  @override
  void dispose() {
    _dataPlantioController.dispose();
    _populacaoController.dispose();
    _espacamentoController.dispose();
    _profundidadeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
  
  Future<void> _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Criar lista de máquinas IDs a partir do trator e plantadeira selecionados
        List<String> maquinasIds = [];
        if (_tratorId != null) maquinasIds.add(_tratorId!);
        if (_plantadeiraId != null) maquinasIds.add(_plantadeiraId!);
        
        final plantio = widget.plantio?.copyWith(
          talhaoId: _talhaoId!,
          culturaId: _culturaId!,
          variedadeId: _variedadeId,
          dataPlantio: _dataPlantio,
          populacao: _populacao,
          espacamento: _espacamento,
          profundidade: _profundidade,
          maquinasIds: maquinasIds,
          calibragemId: _calibragemId,
          estandeId: _estandeId,
          observacoes: _observacoes,
        ) ?? PlantioModel(
          id: _plantioService.gerarId(),
          talhaoId: _talhaoId!,
          culturaId: _culturaId!,
          variedadeId: _variedadeId,
          dataPlantio: _dataPlantio,
          populacao: _populacao,
          espacamento: _espacamento,
          profundidade: _profundidade,
          maquinasIds: maquinasIds,
          calibragemId: _calibragemId,
          estandeId: _estandeId,
          observacoes: _observacoes,
          sincronizado: false,
          criadoEm: DateTime.now(),
          atualizadoEm: DateTime.now(),
        );
        
        widget.onSave(plantio);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar plantio: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TalhaoSelector(
            initialValue: _talhaoId,
            onChanged: (value) {
              setState(() {
                _talhaoId = value.id;
              });
            },
            
          ),
          const SizedBox(height: 16),
          
          CulturaSelector(
            initialValue: _culturaId,
            onChanged: (value) {
              setState(() {
                _culturaId = value.id.toString();
                // Limpa a variedade quando muda a cultura
                _variedadeId = null;
              });
            },
          ),
          const SizedBox(height: 16),
          
          if (_culturaId != null)
            VariedadeSelector(
              initialValue: _variedadeId,
              culturaId: _culturaId,
              onChanged: (value) {
                setState(() {
                  _variedadeId = value;
                });
              },
              isRequired: false,
              showAddButton: true,
            ),
          if (_culturaId != null)
            const SizedBox(height: 16),
          
          // MachineSelector( // Widget removido
          //   initialValue: _tratorId,
          //   onChanged: (value) {
          //     setState(() {
          //       _tratorId = value;
          //     });
          //   },
          //   label: 'Trator',
          //   machineType: 'trator',
          // ),
          const SizedBox(height: 16),
          
          // MachineSelector( // Widget removido
          //   initialValue: _plantadeiraId,
          //   onChanged: (value) {
          //     setState(() {
          //       _plantadeiraId = value;
          //     });
          //   },
          //   label: 'Plantadeira',
          //   machineType: 'plantadeira',
          // ),
          const SizedBox(height: 16),
          
          if (_talhaoId != null && _culturaId != null)
            CalibragemSementeSelector(
              initialValue: _calibragemId,
              onChanged: (value) {
                setState(() {
                  _calibragemId = value;
                });
              },
              talhaoId: _talhaoId,
              culturaId: _culturaId,
              showAddButton: true,
            ),
          if (_talhaoId != null && _culturaId != null)
            const SizedBox(height: 16),
          
          if (_talhaoId != null && _culturaId != null)
            EstandeSelector(
              initialValue: _estandeId,
              onChanged: (value) {
                setState(() {
                  _estandeId = value;
                });
              },
              talhaoId: _talhaoId,
              culturaId: _culturaId,
              showAddButton: true,
            ),
          if (_talhaoId != null && _culturaId != null)
            const SizedBox(height: 16),
          
          CustomDatePicker(
            label: 'Data do Plantio',
            initialDate: _dataPlantio,
            onDateSelected: (date) {
              setState(() {
                _dataPlantio = date;
              });
            }, onChanged: (DateTime ) {  },
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _populacaoController,
            label: 'População (plantas/ha)',
            keyboardType: TextInputType.number,
            
            onChanged: (value) {
              _populacao = int.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _espacamentoController,
            label: 'Espaçamento (cm)',
            keyboardType: TextInputType.number,
            
            onChanged: (value) {
              _espacamento = double.tryParse(value) ?? 0.0;
            },
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _profundidadeController,
            label: 'Profundidade (cm)',
            keyboardType: TextInputType.number,
            
            onChanged: (value) {
              _profundidade = double.tryParse(value) ?? 0.0;
            },
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _observacoesController,
            label: 'Observações',
            maxLines: 3,
            onChanged: (value) {
              _observacoes = value;
            },
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _isLoading ? null : _salvar,
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(widget.isEditing ? 'Atualizar' : 'Cadastrar'),
          ),
        ],
      ),
    );
  }
}

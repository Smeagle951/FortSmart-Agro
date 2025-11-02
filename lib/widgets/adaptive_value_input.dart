import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/organism_catalog_service.dart';
import '../utils/logger.dart';

/// Widget de Input Adaptativo para Valores de Monitoramento
/// Se ajusta automaticamente baseado na unidade do organismo selecionado
class AdaptiveValueInput extends StatefulWidget {
  final String? organismId;
  final double? initialValue;
  final Function(double) onValueChanged;
  final Function(String)? onUnitChanged;
  final bool enabled;
  final String? errorText;
  final String? hintText;
  final bool showPreview;

  const AdaptiveValueInput({
    Key? key,
    this.organismId,
    this.initialValue,
    required this.onValueChanged,
    this.onUnitChanged,
    this.enabled = true,
    this.errorText,
    this.hintText,
    this.showPreview = true,
  }) : super(key: key);

  @override
  State<AdaptiveValueInput> createState() => _AdaptiveValueInputState();
}

class _AdaptiveValueInputState extends State<AdaptiveValueInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Map<String, dynamic>? _organism;
  double? _normalizedValue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrganism();
    _updateController();
  }

  @override
  void didUpdateWidget(AdaptiveValueInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organismId != widget.organismId) {
      _loadOrganism();
    }
    if (oldWidget.initialValue != widget.initialValue) {
      _updateController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Carrega informações do organismo
  Future<void> _loadOrganism() async {
    if (widget.organismId == null) return;

    setState(() => _isLoading = true);
    
    try {
      final catalogService = OrganismCatalogService();
      final organism = await catalogService.getOrganismById(widget.organismId!);
      
      setState(() {
        _organism = organism;
        _isLoading = false;
      });
      
      _updateNormalizedValue();
    } catch (e) {
      Logger.error('AdaptiveValueInput: Erro ao carregar organismo: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Atualiza o controller com o valor inicial
  void _updateController() {
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!.toString();
      _updateNormalizedValue();
    }
  }

  /// Atualiza o valor normalizado
  void _updateNormalizedValue() {
    if (_organism == null || _controller.text.isEmpty) {
      _normalizedValue = null;
      return;
    }

    try {
      final rawValue = double.parse(_controller.text);
      // TODO: Implementar normalizeValue para Map<String, dynamic>
      _normalizedValue = rawValue; // Temporário - implementar normalização
    } catch (e) {
      _normalizedValue = null;
    }
  }

  /// Obtém o tipo de input baseado na unidade
  TextInputType _getInputType() {
    if (_organism == null) return TextInputType.number;
    
    switch (_organism!['unidade']?.toString()) {
      case 'percent_folha':
      case 'percent_plantas':
        return TextInputType.number;
      case 'individuos/10_plantas':
      case 'individuos/planta':
      case 'individuos/m2':
        return TextInputType.number;
      case 'plantas/m2':
        return TextInputType.number;
      default:
        return TextInputType.number;
    }
  }

  /// Obtém o formato de entrada baseado na unidade
  List<TextInputFormatter> _getInputFormatters() {
    if (_organism == null) return [];

    switch (_organism!['unidade']?.toString()) {
      case 'percent_folha':
      case 'percent_plantas':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          _PercentInputFormatter(),
        ];
      case 'individuos/10_plantas':
      case 'individuos/planta':
      case 'individuos/m2':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          _PositiveNumberFormatter(),
        ];
      case 'plantas/m2':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          _PositiveNumberFormatter(),
        ];
      default:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ];
    }
  }

  /// Obtém o hint text baseado na unidade
  String _getHintText() {
    if (_organism == null) return widget.hintText ?? 'Digite o valor';
    
    switch (_organism!['unidade']?.toString()) {
      case 'percent_folha':
        return 'Ex: 25.5 (percentual de folhas)';
      case 'percent_plantas':
        return 'Ex: 30.0 (percentual de plantas)';
      case 'individuos/10_plantas':
        return 'Ex: 5.2 (indivíduos por 10 plantas)';
      case 'individuos/planta':
        return 'Ex: 0.8 (indivíduos por planta)';
      case 'individuos/m2':
        return 'Ex: 12.5 (indivíduos por m²)';
      case 'plantas/m2':
        return 'Ex: 8.0 (plantas por m²)';
      default:
        return widget.hintText ?? 'Digite o valor';
    }
  }

  /// Obtém o sufixo baseado na unidade
  String _getSuffix() {
    if (_organism == null) return '';
    
    switch (_organism!['unidade']?.toString()) {
      case 'percent_folha':
      case 'percent_plantas':
        return '%';
      case 'individuos/10_plantas':
        return ' ind/10pl';
      case 'individuos/planta':
        return ' ind/pl';
      case 'individuos/m2':
        return ' ind/m²';
      case 'plantas/m2':
        return ' pl/m²';
      default:
        return '';
    }
  }

  /// Obtém o nível de alerta baseado no valor
  String? _getAlertLevel() {
    if (_organism == null || _normalizedValue == null) return null;
    
    // TODO: Implementar getAlertLevel para Map<String, dynamic>
    return null; // Temporário
  }

  /// Obtém a cor do alerta
  Color _getAlertColor() {
    final level = _getAlertLevel();
    switch (level) {
      case 'baixo':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      case 'critico':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Obtém o ícone baseado no tipo de organismo
  IconData _getOrganismIcon() {
    if (_organism == null) return Icons.bug_report;
    
    switch (_organism!['tipo']?.toString()) {
      case 'praga':
        return Icons.bug_report;
      case 'doenca':
        return Icons.coronavirus;
      case 'daninha':
        return Icons.local_florist;
      default:
        return Icons.bug_report;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de entrada principal
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled && !_isLoading,
          keyboardType: _getInputType(),
          inputFormatters: _getInputFormatters(),
          decoration: InputDecoration(
            labelText: _organism?['nome']?.toString() ?? 'Valor',
            hintText: _getHintText(),
            suffixText: _getSuffix(),
            errorText: widget.errorText,
            prefixIcon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(_getOrganismIcon()),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey[100],
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              widget.onValueChanged(0);
              _normalizedValue = null;
            } else {
              try {
                final doubleValue = double.parse(value);
                widget.onValueChanged(doubleValue);
                _updateNormalizedValue();
              } catch (e) {
                // Valor inválido, não atualizar
              }
            }
            setState(() {});
          },
        ),
        
        const SizedBox(height: 8),
        
        // Preview de normalização (se habilitado)
        if (widget.showPreview && _organism != null && _normalizedValue != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getAlertColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getAlertColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getAlertLevel() == 'critico' ? Icons.warning : Icons.info,
                  color: _getAlertColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor Normalizado: ${_normalizedValue!.toStringAsFixed(2)} ind/10pl',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getAlertColor(),
                        ),
                      ),
                      if (_getAlertLevel() != null)
                        Text(
                          'Nível: ${_getAlertLevel()!.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getAlertColor(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        // Informações do organismo
        if (_organism != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  _getOrganismIcon(),
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_organism!.nome} (${_organism!.unidade})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Formatter para percentuais (0-100)
class _PercentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    final double? value = double.tryParse(newValue.text);
    if (value == null) return oldValue;
    
    if (value < 0 || value > 100) return oldValue;
    
    return newValue;
  }
}

/// Formatter para números positivos
class _PositiveNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    final double? value = double.tryParse(newValue.text);
    if (value == null) return oldValue;
    
    if (value < 0) return oldValue;
    
    return newValue;
  }
}

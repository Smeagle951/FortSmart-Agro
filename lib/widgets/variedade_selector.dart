import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/variety.dart';
import 'package:fortsmart_agro/modules/planting/models/variedade_model.dart';
import 'package:fortsmart_agro/services/culture_import_service.dart';
import 'package:fortsmart_agro/modules/planting/services/variedade_service.dart';
import 'package:fortsmart_agro/services/manual_variety_service.dart';
import 'package:fortsmart_agro/utils/logger.dart';

/// Widget para seleção de variedades a partir do cache ou repositório
class VariedadeSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final bool isRequired;
  final String label;
  final String? culturaId;
  final bool showAddButton;

  const VariedadeSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Variedade',
    this.culturaId,
    this.showAddButton = false,
  }) : super(key: key);

  @override
  State<VariedadeSelector> createState() => _VariedadeSelectorState();
}

class _VariedadeSelectorState extends State<VariedadeSelector> {
  final CultureImportService _cultureImportService = CultureImportService();
  final VariedadeService _variedadeService = VariedadeService();
  List<dynamic> _variedades = [];
  String? _selectedVariedadeId;
  bool _isLoading = true;
  bool _isManualMode = false;
  final TextEditingController _manualVarietyController = TextEditingController();
  String? _manualVarietyName;

  @override
  void initState() {
    super.initState();
    _selectedVariedadeId = widget.initialValue;
    _loadVariedades();
    _loadManualVarietyIfNeeded();
  }

  @override
  void didUpdateWidget(VariedadeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar variedades se a cultura mudar
    if (widget.culturaId != oldWidget.culturaId) {
      _loadVariedades();
    }
  }

  @override
  void dispose() {
    _manualVarietyController.dispose();
    super.dispose();
  }

  Future<void> _loadVariedades() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> variedades = [];
      
      // Primeiro tenta carregar do CultureImportService (módulo Culturas da Fazenda)
      if (widget.culturaId != null) {
        variedades = await _cultureImportService.getVarietiesByCrop(widget.culturaId!);
      } else {
        // Se não tiver cultura específica, carrega todas as variedades do serviço
        final listaVariedades = await _variedadeService.listar();
        variedades = listaVariedades;
      }
      
      // Verificar se o ID selecionado existe na lista de variedades carregadas
      bool selectedIdExists = false;
      
      if (_selectedVariedadeId != null) {
        // Verificar se o ID selecionado existe em alguma variedade da lista
        for (var variedade in variedades) {
          String id;
          if (variedade is VariedadeModel) {
            id = variedade.id;
          } else if (variedade is Variety) {
            id = variedade.id.toString();
          } else {
            // Fallback para outros tipos
            id = variedade['id'].toString();
          }
          
          if (id == _selectedVariedadeId) {
            selectedIdExists = true;
            break;
          }
        }
      }
      
      setState(() {
        _variedades = variedades;
        // Se o ID selecionado não existir na lista, limpar a seleção
        if (!selectedIdExists && _selectedVariedadeId != null) {
          print('ID selecionado $_selectedVariedadeId não encontrado nas variedades carregadas');
          _selectedVariedadeId = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar variedades: $e');
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

  /// Carrega variedade manual se o ID inicial for de uma variedade manual
  Future<void> _loadManualVarietyIfNeeded() async {
    if (_selectedVariedadeId != null && _selectedVariedadeId!.startsWith('manual_')) {
      final varietyName = await ManualVarietyService.getManualVarietyName(_selectedVariedadeId!);
      if (varietyName != null) {
        setState(() {
          _manualVarietyName = varietyName;
          _manualVarietyController.text = varietyName;
          _isManualMode = true;
        });
      }
    }
  }

  /// Obtém o nome da variedade selecionada (manual ou da lista)
  String? getSelectedVarietyName() {
    if (_isManualMode && _manualVarietyName != null) {
      return _manualVarietyName;
    } else if (_selectedVariedadeId != null) {
      // Buscar na lista de variedades carregadas
      for (var variedade in _variedades) {
        String id;
        if (variedade is VariedadeModel) {
          id = variedade.id;
        } else if (variedade is Variety) {
          id = variedade.id.toString();
        } else {
          id = variedade['id'].toString();
        }
        
        if (id == _selectedVariedadeId) {
          if (variedade is VariedadeModel) {
            return variedade.nome;
          } else if (variedade is Variety) {
            return variedade.nome;
          } else {
            return variedade['nome'] ?? 'Sem nome';
          }
        }
      }
    }
    return null;
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
        
        // Botão para alternar entre modo manual e seleção
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isManualMode = !_isManualMode;
                    if (_isManualMode) {
                      _selectedVariedadeId = null;
                      _manualVarietyController.clear();
                      _manualVarietyName = null;
                    } else {
                      _manualVarietyController.clear();
                      _manualVarietyName = null;
                    }
                  });
                },
                icon: Icon(_isManualMode ? Icons.list : Icons.edit),
                label: Text(_isManualMode ? 'Selecionar da Lista' : 'Digitar Manualmente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isManualMode ? Colors.blue : Colors.orange,
                  side: BorderSide(color: _isManualMode ? Colors.blue : Colors.orange),
                  backgroundColor: _isManualMode ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isManualMode
                ? _buildManualInput()
                : _variedades.isEmpty
                    ? _buildEmptyVariedadesMessage()
                    : _buildDropdown(),
        
        // Mostrar informação da variedade selecionada
        if (_selectedVariedadeId != null && !_isManualMode)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Variedade selecionada: "${getSelectedVarietyName() ?? 'Desconhecida'}"',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.showAddButton && !_isManualMode)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: OutlinedButton.icon(
              onPressed: () {
                print('🔍 Tentando navegar para cadastro de variedades...');
                print('🔍 Cultura ID: ${widget.culturaId}');
                
                // Navegar para tela de cadastro de variedades
                Navigator.pushNamed(context, '/variedades/cadastro', arguments: {
                  'culturaId': widget.culturaId,
                }).then((_) {
                  print('🔍 Retornou da tela de cadastro, recarregando variedades...');
                  _loadVariedades();
                }).catchError((error) {
                  print('❌ Erro ao navegar para cadastro de variedades: $error');
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova Variedade'),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyVariedadesMessage() {
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
                  'Nenhuma variedade encontrada',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.culturaId != null 
                      ? 'Cadastre variedades para esta cultura antes de continuar'
                      : 'Cadastre variedades antes de continuar',
                  style: const TextStyle(fontSize: 12),
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
          value: _selectedVariedadeId,
          isExpanded: true,
          hint: Text(widget.label + (widget.isRequired ? ' *' : '')),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (value) {
            setState(() {
              _selectedVariedadeId = value;
            });
            if (value != null) {
              widget.onChanged(value);
            }
          },
          items: _variedades.map<DropdownMenuItem<String>>((dynamic variedade) {
            String id;
            String nome;
            
            if (variedade is VariedadeModel) {
              id = variedade.id;
              nome = variedade.nome;
            } else if (variedade is Variety) {
              id = variedade.id.toString();
              nome = variedade.nome;
            } else {
              // Fallback para outros tipos
              id = variedade['id'].toString();
              nome = variedade['nome'] ?? 'Sem nome';
            }
            
            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                nome,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildManualInput() {
    final hasText = _manualVarietyController.text.isNotEmpty;
    final isValid = hasText && _manualVarietyController.text.length >= 2;
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isValid ? Colors.green : hasText ? Colors.orange : Colors.blue, 
              width: 2
            ),
            borderRadius: BorderRadius.circular(8),
            color: isValid 
                ? Colors.green.withOpacity(0.05) 
                : hasText 
                    ? Colors.orange.withOpacity(0.05) 
                    : Colors.blue.withOpacity(0.05),
          ),
          child: TextField(
            controller: _manualVarietyController,
            decoration: InputDecoration(
              hintText: 'Digite o nome da variedade manualmente',
              prefixIcon: Icon(
                isValid ? Icons.check_circle : hasText ? Icons.warning : Icons.edit, 
                color: isValid ? Colors.green : hasText ? Colors.orange : Colors.blue
              ),
              suffixIcon: _manualVarietyController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _manualVarietyController.clear();
                        _manualVarietyName = null;
                        widget.onChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            onChanged: (value) async {
              setState(() {
                // Força rebuild para atualizar a validação visual
              });
              
              // Armazenar o nome da variedade manual
              _manualVarietyName = value;
              
              // Gerar um ID único para a variedade manual
              if (value.isNotEmpty) {
                final manualId = 'manual_${value.hashCode}';
                
                // Armazenar o nome da variedade no serviço
                await ManualVarietyService.storeManualVarietyName(manualId, value);
                
                widget.onChanged(manualId);
              } else {
                widget.onChanged('');
              }
            },
          ),
        ),
        if (hasText)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.warning,
                  color: isValid ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isValid 
                        ? 'Variedade manual válida: "${_manualVarietyController.text}"'
                        : 'Digite pelo menos 2 caracteres para uma variedade válida',
                    style: TextStyle(
                      fontSize: 12,
                      color: isValid ? Colors.green : Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hasText && !isValid)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Dica: Use nomes descritivos como "Soja RR 2024" ou "Milho Híbrido 123"',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

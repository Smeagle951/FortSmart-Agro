import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cultura_model.dart';
import '../providers/cultura_provider.dart';
import '../providers/talhao_provider.dart';
import '../utils/area_formatter.dart';

/// Modal para edição completa do talhão
class TalhaoEditorModal extends StatefulWidget {
  final String nomeTalhao;
  final String? nomeCultura;
  final String? nomeSafra;
  final double area;
  final List<dynamic> pontos;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const TalhaoEditorModal({
    Key? key,
    required this.nomeTalhao,
    this.nomeCultura,
    this.nomeSafra,
    required this.area,
    required this.pontos,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<TalhaoEditorModal> createState() => _TalhaoEditorModalState();
}

class _TalhaoEditorModalState extends State<TalhaoEditorModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _areaController = TextEditingController();
  
  CulturaModel? _culturaSelecionada;
  String? _safraSelecionada;
  Color _corSelecionada = Colors.green;
  IconData _iconeSelecionado = Icons.agriculture;
  bool _isLoading = false;
  
  // Lista de safras disponíveis
  final List<String> _safras = [
    '2024/2025',
    '2023/2024',
    '2022/2023',
    '2021/2022',
    '2020/2021',
  ];

  // Paleta de cores para seleção
  final List<Color> _coresDisponiveis = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.pink,
    Colors.lime,
    Colors.brown,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
  ];

  // Ícones disponíveis para culturas
  final List<IconData> _iconesDisponiveis = [
    Icons.agriculture,
    Icons.eco,
    Icons.grass,
    Icons.grain,
    Icons.spa,
    Icons.local_florist,
    Icons.park,
    Icons.forest,
    Icons.nature,
    Icons.landscape,
    Icons.wb_sunny,
    Icons.water_drop,
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _nomeController.text = widget.nomeTalhao;
    _areaController.text = widget.area.toStringAsFixed(2);
    _safraSelecionada = widget.nomeSafra ?? _safras.first;
    
    // Buscar cultura por nome
    if (widget.nomeCultura != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCulturaByName(widget.nomeCultura!);
      });
    }
  }

  void _loadCulturaByName(String nomeCultura) {
    final culturaProvider = Provider.of<CulturaProvider>(context, listen: false);
    try {
      _culturaSelecionada = culturaProvider.culturas.firstWhere(
        (c) => c.name.toLowerCase().trim() == nomeCultura.toLowerCase().trim(),
      );
      _corSelecionada = _culturaSelecionada!.color;
      setState(() {});
    } catch (e) {
      // Usar primeira cultura disponível
      if (culturaProvider.culturas.isNotEmpty) {
        _culturaSelecionada = culturaProvider.culturas.first;
        _corSelecionada = _culturaSelecionada!.color;
        setState(() {});
      }
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_culturaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma cultura'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Criar dados atualizados do talhão
      final talhaoAtualizado = {
        'nome': _nomeController.text.trim(),
        'cultura': _culturaSelecionada!,
        'safra': _safraSelecionada,
        'area': double.tryParse(_areaController.text) ?? widget.area,
        'cor': _corSelecionada,
        'icone': _iconeSelecionado,
        'pontos': widget.pontos,
      };

      // Simular delay de salvamento
      await Future.delayed(const Duration(seconds: 1));
      
      widget.onSave(talhaoAtualizado);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
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
      backgroundColor: Colors.transparent,
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _corSelecionada.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconeSelecionado,
                    color: _corSelecionada,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar Talhão',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Personalize as informações do seu talhão',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Formulário
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do talhão
                      _buildSectionTitle('Nome do Talhão'),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          hintText: 'Digite o nome do talhão',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Cultura
                      _buildSectionTitle('Cultura'),
                      _buildCulturaDropdown(),
                      
                      const SizedBox(height: 20),
                      
                      // Safra
                      _buildSectionTitle('Safra'),
                      _buildSafraDropdown(),
                      
                      const SizedBox(height: 20),
                      
                      // Área
                      _buildSectionTitle('Área (hectares)'),
                      TextFormField(
                        controller: _areaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Digite a área em hectares',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.area_chart),
                          suffixText: 'ha',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Área é obrigatória';
                          }
                          final area = double.tryParse(value);
                          if (area == null || area <= 0) {
                            return 'Área deve ser um número válido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Cor personalizada
                      _buildSectionTitle('Cor do Talhão'),
                      _buildColorSelector(),
                      
                      const SizedBox(height: 20),
                      
                      // Ícone personalizado
                      _buildSectionTitle('Ícone do Talhão'),
                      _buildIconSelector(),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _salvarAlteracoes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _corSelecionada,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Salvar Alterações'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCulturaDropdown() {
    return Consumer<CulturaProvider>(
      builder: (context, culturaProvider, child) {
        return DropdownButtonFormField<CulturaModel>(
          value: _culturaSelecionada,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.eco),
          ),
          items: culturaProvider.culturas.map((cultura) {
            return DropdownMenuItem<CulturaModel>(
              value: cultura,
              child: Row(
                children: [
                  cultura.getIconOrInitial(size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cultura.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _culturaSelecionada = value;
              if (value != null) {
                _corSelecionada = value.color;
              }
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Selecione uma cultura';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildSafraDropdown() {
    return DropdownButtonFormField<String>(
      value: _safraSelecionada,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
      ),
      items: _safras.map((safra) {
        return DropdownMenuItem<String>(
          value: safra,
          child: Text(safra),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _safraSelecionada = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Selecione uma safra';
        }
        return null;
      },
    );
  }

  Widget _buildColorSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _coresDisponiveis.map((cor) {
          final isSelected = cor == _corSelecionada;
          return GestureDetector(
            onTap: () {
              setState(() {
                _corSelecionada = cor;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIconSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _iconesDisponiveis.map((icone) {
          final isSelected = icone == _iconeSelecionado;
          return GestureDetector(
            onTap: () {
              setState(() {
                _iconeSelecionado = icone;
              });
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? _corSelecionada.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? _corSelecionada : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Icon(
                icone,
                color: isSelected ? _corSelecionada : Colors.grey[600],
                size: 24,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

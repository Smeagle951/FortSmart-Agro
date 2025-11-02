import 'package:flutter/material.dart';
import '../models/cultura_model.dart';
import '../models/talhao_model.dart';
import '../models/safra_talhao_model.dart';
import 'safe_dropdown_button.dart';

/// Bottom sheet para edição de talhão
class TalhaoEditorBottomSheet extends StatefulWidget {
  final TalhaoModel? talhao;
  final List<CulturaModel> cultures;
  final List<String> safras;
  final Function(TalhaoModel) onSave;
  final Function(TalhaoModel)? onDelete;
  final VoidCallback onCancel;

  const TalhaoEditorBottomSheet({
    Key? key,
    this.talhao,
    required this.cultures,
    required this.safras,
    required this.onSave,
    this.onDelete,
    required this.onCancel,
  }) : super(key: key);

  /// Método estático para mostrar o bottom sheet
  static Future<void> show({
    required BuildContext context,
    required TalhaoModel talhao,
    required List<CulturaModel> culturas,
    required Function(TalhaoModel) onSaved,
    Function(TalhaoModel)? onDeleted,
  }) async {
    final safras = ['2024/2025', '2023/2024', '2022/2023'];
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TalhaoEditorBottomSheet(
        talhao: talhao,
        cultures: culturas,
        safras: safras,
        onSave: onSaved,
        onDelete: onDeleted,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  State<TalhaoEditorBottomSheet> createState() => _TalhaoEditorBottomSheetState();
}

class _TalhaoEditorBottomSheetState extends State<TalhaoEditorBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _observacoesController;
  String? _selectedCulturaId;
  String? _selectedSafra;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.talhao?.nome ?? '');
    _observacoesController = TextEditingController(text: widget.talhao?.observacoes ?? '');
    
    // CORREÇÃO: Carregar cultura corretamente
    _selectedCulturaId = _getCulturaIdFromTalhao(widget.talhao);
    
    // CORREÇÃO: Inicializar safra de forma segura
    _selectedSafra = _getSafraFromTalhao(widget.talhao);
    
    print('🚨 DEBUG CULTURA - TalhaoEditorBottomSheet initState:');
    print('  - Talhão: ${widget.talhao?.name}');
    print('  - Cultura ID do talhão: ${widget.talhao?.culturaId}');
    print('  - Cultura selecionada: $_selectedCulturaId');
    print('  - Safra selecionada: $_selectedSafra');
    print('  - Safras disponíveis: ${widget.safras}');
    print('  - Safras do talhão: ${widget.talhao?.safras?.length ?? 0}');
    print('  - Culturas disponíveis: ${widget.cultures.map((c) => '${c.id}: ${c.name}').join(', ')}');
    if (widget.talhao?.safras?.isNotEmpty == true) {
      print('  - Primeira safra cultura: ${widget.talhao?.safras?.first.culturaNome}');
      print('  - Primeira safra cultura ID: ${widget.talhao?.safras?.first.culturaId}');
    }
    
    // VALIDAÇÃO FINAL: Verificar se o valor selecionado é válido
    if (_selectedCulturaId != null) {
      final culturaExiste = widget.cultures.any((c) => c.id == _selectedCulturaId);
      if (!culturaExiste) {
        print('🚨 ERRO: Cultura selecionada não existe na lista!');
        print('🚨 ID inválido: $_selectedCulturaId');
        print('🚨 IDs válidos: ${widget.cultures.map((c) => c.id).join(', ')}');
        
        // CORREÇÃO: Forçar uso da primeira cultura disponível
        if (widget.cultures.isNotEmpty) {
          _selectedCulturaId = widget.cultures.first.id;
          print('🚨 CORREÇÃO: Usando primeira cultura disponível: $_selectedCulturaId');
        }
      } else {
        print('✅ Cultura selecionada é válida: $_selectedCulturaId');
      }
    }
  }
  
  /// Obtém o ID da cultura do talhão de forma robusta
  String? _getCulturaIdFromTalhao(TalhaoModel? talhao) {
    if (talhao == null) return widget.cultures.isNotEmpty ? widget.cultures.first.id : null;
    
    // Primeiro, tentar obter da propriedade culturaId
    if (talhao.culturaId != null && talhao.culturaId!.isNotEmpty) {
      final culturaId = talhao.culturaId!;
      
      // CORREÇÃO: Validar se o ID existe na lista de culturas disponíveis
      final culturaExiste = widget.cultures.any((c) => c.id == culturaId);
      if (culturaExiste) {
        print('🔍 DEBUG CULTURA - Usando culturaId do talhão: $culturaId');
        return culturaId;
      } else {
        print('⚠️ DEBUG CULTURA - ID de cultura inválido: $culturaId, buscando alternativa');
        
        // CORREÇÃO: Se for um ID custom_ que não existe, tentar encontrar por nome
        if (culturaId.startsWith('custom_')) {
          print('🔍 DEBUG CULTURA - ID custom_ detectado: $culturaId, tentando encontrar por nome...');
          
          // Tentar extrair o nome da cultura do ID custom_
          String? nomeCultura;
          if (culturaId.contains('_')) {
            final partes = culturaId.split('_');
            if (partes.length > 1) {
              nomeCultura = partes.sublist(1).join('_'); // Pega tudo depois do primeiro _
            }
          }
          
          // Tentar encontrar por nome extraído do ID
          if (nomeCultura != null && nomeCultura.isNotEmpty) {
            try {
              final culturaEncontrada = widget.cultures.firstWhere(
                (c) => c.name.toLowerCase().contains(nomeCultura.toLowerCase()) ||
                       nomeCultura.toLowerCase().contains(c.name.toLowerCase()),
              );
              print('✅ DEBUG CULTURA - Cultura encontrada por nome do ID: ${culturaEncontrada.name} (ID: ${culturaEncontrada.id})');
              return culturaEncontrada.id;
            } catch (e) {
              print('⚠️ DEBUG CULTURA - Cultura não encontrada por nome do ID: $nomeCultura');
            }
          }
          
          // Tentar encontrar por nome da cultura se disponível
          if (talhao.crop != null && talhao.crop!.name.isNotEmpty) {
            try {
              final culturaEncontrada = widget.cultures.firstWhere(
                (c) => c.name.toLowerCase() == talhao.crop!.name.toLowerCase(),
              );
              print('✅ DEBUG CULTURA - Cultura encontrada por nome: ${culturaEncontrada.name} (ID: ${culturaEncontrada.id})');
              return culturaEncontrada.id;
            } catch (e) {
              print('⚠️ DEBUG CULTURA - Cultura não encontrada por nome: ${talhao.crop!.name}');
            }
          }
        }
      }
    }
    
    // Segundo, tentar obter da primeira safra
    if (talhao.safras != null && talhao.safras!.isNotEmpty) {
      final primeiraSafra = talhao.safras!.first;
      if (primeiraSafra.culturaId != null && primeiraSafra.culturaId!.isNotEmpty) {
        final culturaId = primeiraSafra.culturaId!;
        
        // CORREÇÃO: Validar se o ID existe na lista de culturas disponíveis
        final culturaExiste = widget.cultures.any((c) => c.id == culturaId);
        if (culturaExiste) {
          print('🔍 DEBUG CULTURA - Usando culturaId da primeira safra: $culturaId');
          return culturaId;
        } else {
          print('⚠️ DEBUG CULTURA - ID de cultura da safra inválido: $culturaId');
          
          // CORREÇÃO: Se for um ID custom_ que não existe, tentar encontrar por nome
          if (culturaId.startsWith('custom_')) {
            print('🔍 DEBUG CULTURA - ID custom_ da safra detectado: $culturaId');
            
            // Tentar extrair o nome da cultura do ID custom_
            String? nomeCultura;
            if (culturaId.contains('_')) {
              final partes = culturaId.split('_');
              if (partes.length > 1) {
                nomeCultura = partes.sublist(1).join('_'); // Pega tudo depois do primeiro _
              }
            }
            
            // Tentar encontrar por nome extraído do ID
            if (nomeCultura != null && nomeCultura.isNotEmpty) {
              try {
                final culturaEncontrada = widget.cultures.firstWhere(
                  (c) => c.name.toLowerCase().contains(nomeCultura.toLowerCase()) ||
                         nomeCultura.toLowerCase().contains(c.name.toLowerCase()),
                );
                print('✅ DEBUG CULTURA - Cultura encontrada por nome do ID da safra: ${culturaEncontrada.name} (ID: ${culturaEncontrada.id})');
                return culturaEncontrada.id;
              } catch (e) {
                print('⚠️ DEBUG CULTURA - Cultura não encontrada por nome do ID da safra: $nomeCultura');
              }
            }
            
            // Tentar encontrar por nome da safra
            if (primeiraSafra.culturaNome != null && primeiraSafra.culturaNome!.isNotEmpty) {
              print('🔍 DEBUG CULTURA - Tentando encontrar por nome da safra: ${primeiraSafra.culturaNome}');
              try {
                final culturaEncontrada = widget.cultures.firstWhere(
                  (c) => c.name.toLowerCase() == primeiraSafra.culturaNome!.toLowerCase(),
                );
                print('✅ DEBUG CULTURA - Cultura encontrada por nome da safra: ${culturaEncontrada.name} (ID: ${culturaEncontrada.id})');
                return culturaEncontrada.id;
              } catch (e) {
                print('⚠️ DEBUG CULTURA - Cultura não encontrada por nome da safra: ${primeiraSafra.culturaNome}');
              }
            }
          }
        }
      }
    }
    
    // Terceiro, tentar encontrar por nome da cultura
    if (talhao.crop != null && talhao.crop!.name.isNotEmpty) {
      try {
        final culturaEncontrada = widget.cultures.firstWhere(
          (c) => c.name.toLowerCase() == talhao.crop!.name.toLowerCase(),
        );
        print('🔍 DEBUG CULTURA - Encontrada cultura por nome: ${culturaEncontrada.name} (ID: ${culturaEncontrada.id})');
        return culturaEncontrada.id;
      } catch (e) {
        print('⚠️ DEBUG CULTURA - Cultura não encontrada por nome: ${talhao.crop!.name}');
      }
    }
    
    // Fallback: usar primeira cultura disponível
    if (widget.cultures.isNotEmpty) {
      print('🔍 DEBUG CULTURA - Usando primeira cultura disponível: ${widget.cultures.first.name} (ID: ${widget.cultures.first.id})');
      return widget.cultures.first.id;
    }
    
    return null;
  }

  /// Obtém a safra do talhão de forma segura
  String? _getSafraFromTalhao(TalhaoModel? talhao) {
    if (talhao == null) return widget.safras.isNotEmpty ? widget.safras.first : null;
    
    // Primeiro, tentar obter da propriedade safraAtual
    if (talhao.safraAtual?.nome != null && talhao.safraAtual!.nome.isNotEmpty) {
      final safraNome = talhao.safraAtual!.nome;
      if (widget.safras.contains(safraNome)) {
        print('🔍 DEBUG SAFRA - Usando safraAtual do talhão: $safraNome');
        return safraNome;
      }
    }
    
    // Segundo, tentar obter da primeira safra
    if (talhao.safras != null && talhao.safras!.isNotEmpty) {
      final primeiraSafra = talhao.safras!.first;
      if (primeiraSafra is SafraTalhaoModel && primeiraSafra.safraId != null && primeiraSafra.safraId!.isNotEmpty) {
        final safraId = primeiraSafra.safraId!;
        if (widget.safras.contains(safraId)) {
          print('🔍 DEBUG SAFRA - Usando safraId da primeira safra: $safraId');
          return safraId;
        }
      }
    }
    
    // Terceiro, tentar obter da propriedade safraId
    if (talhao.safraId != null && talhao.safraId!.isNotEmpty) {
      final safraId = talhao.safraId!;
      if (widget.safras.contains(safraId)) {
        print('🔍 DEBUG SAFRA - Usando safraId do talhão: $safraId');
        return safraId;
      }
    }
    
    // Fallback: usar primeira safra disponível
    if (widget.safras.isNotEmpty) {
      print('🔍 DEBUG SAFRA - Usando primeira safra disponível: ${widget.safras.first}');
      return widget.safras.first;
    }
    
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.edit, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                widget.talhao == null ? 'Novo Talhão' : 'Editar Talhão',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Formulário
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Talhão',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Seleção de cultura
          SafeDropdownButtonFormField<String>(
            value: _selectedCulturaId != null && widget.cultures.any((c) => c.id == _selectedCulturaId) 
                ? _selectedCulturaId 
                : (widget.cultures.isNotEmpty ? widget.cultures.first.id : null),
            decoration: const InputDecoration(
              labelText: 'Cultura',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.eco),
            ),
            items: widget.cultures.map((cultura) {
              return DropdownMenuItem(
                value: cultura.id,
                child: Row(
                  children: [
                    Text(cultura.name, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(cultura.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCulturaId = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Seleção de safra
          SafeDropdownButtonFormField<String>(
            value: _selectedSafra != null && widget.safras.contains(_selectedSafra) 
                ? _selectedSafra 
                : (widget.safras.isNotEmpty ? widget.safras.first : null),
            decoration: const InputDecoration(
              labelText: 'Safra',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            items: widget.safras.map((safra) {
              return DropdownMenuItem(
                value: safra,
                child: Text(safra),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSafra = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Observações
          TextField(
            controller: _observacoesController,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          
          // Botões de ação
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : widget.onCancel,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTalhao,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
              
              // Botão de remover (apenas se talhão existir)
              if (widget.talhao != null && widget.onDelete != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _confirmDelete,
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Remover Talhão', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _saveTalhao() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome do talhão é obrigatório')),
      );
      return;
    }

    if (_selectedCulturaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma cultura')),
      );
      return;
    }

    if (_selectedSafra == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma safra')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // CORREÇÃO: Validar se o ID da cultura é válido antes de salvar
    final culturaExiste = widget.cultures.any((c) => c.id == _selectedCulturaId);
    if (!culturaExiste) {
      print('⚠️ DEBUG CULTURA - ID de cultura inválido: $_selectedCulturaId, usando primeira cultura disponível');
      _selectedCulturaId = widget.cultures.isNotEmpty ? widget.cultures.first.id : null;
      
      if (_selectedCulturaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma cultura disponível')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }
    
    // CORREÇÃO: Obter dados da cultura selecionada
    final culturaSelecionada = widget.cultures.firstWhere(
      (c) => c.id == _selectedCulturaId,
      orElse: () => widget.cultures.first,
    );
    
    print('🔍 DEBUG CULTURA - Salvando talhão:');
    print('  - Nome: ${_nameController.text.trim()}');
    print('  - Cultura ID: $_selectedCulturaId');
    print('  - Cultura Nome: ${culturaSelecionada.name}');
    print('  - Safra: $_selectedSafra');

    // CORREÇÃO: Atualizar safras com a cultura correta
    List<dynamic> safrasAtualizadas = [];
    if (widget.talhao?.safras != null && widget.talhao!.safras!.isNotEmpty) {
      // Atualizar safras existentes com a nova cultura
      safrasAtualizadas = widget.talhao!.safras!.map((safra) {
        if (safra is SafraTalhaoModel) {
          return safra.copyWith(
            safraId: _selectedSafra!,
            culturaId: _selectedCulturaId!,
            culturaNome: culturaSelecionada.name,
            culturaCor: culturaSelecionada.color,
            dataAtualizacao: DateTime.now(),
          );
        }
        return safra;
      }).toList();
    } else {
      // Criar nova safra se não existir
      safrasAtualizadas = [
        SafraTalhaoModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          talhaoId: widget.talhao?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          safraId: _selectedSafra!,
          culturaId: _selectedCulturaId!,
          culturaNome: culturaSelecionada.name,
          culturaCor: culturaSelecionada.color,
          area: widget.talhao?.area ?? 0.0,
          dataCadastro: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          ativo: true,
          sincronizado: false,
        ),
      ];
    }

    print('🔍 DEBUG CULTURA - Safras atualizadas:');
    for (var safra in safrasAtualizadas) {
      if (safra is SafraTalhaoModel) {
        print('  - Safra: ${safra.safraId}, Cultura: ${safra.culturaNome} (ID: ${safra.culturaId}), Cor: ${safra.culturaCor.value}');
      }
    }

    final talhao = TalhaoModel(
      id: widget.talhao?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      poligonos: widget.talhao?.poligonos ?? [],
      area: widget.talhao?.area ?? 0.0,
      fazendaId: widget.talhao?.fazendaId,
      dataCriacao: widget.talhao?.dataCriacao ?? DateTime.now(),
      dataAtualizacao: DateTime.now(),
      sincronizado: false,
      observacoes: _observacoesController.text.trim(),
      metadados: widget.talhao?.metadados,
      safras: safrasAtualizadas, // CORREÇÃO: Usar safras atualizadas em vez de lista vazia
      culturaId: _selectedCulturaId!,
      safraId: _selectedSafra!,
      crop: culturaSelecionada,
    );

    print('🔍 DEBUG CULTURA - Talhão criado com cultura: ${talhao.crop?.name} (ID: ${talhao.culturaId})');
    widget.onSave(talhao);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirmar Exclusão'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja remover o talhão "${widget.talhao?.name}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fechar diálogo
              Navigator.pop(context); // Fechar bottom sheet
              if (widget.talhao != null && widget.onDelete != null) {
                widget.onDelete!(widget.talhao!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
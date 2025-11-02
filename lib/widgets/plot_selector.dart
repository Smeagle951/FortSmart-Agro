import 'package:flutter/material.dart';
import '../models/talhao_model.dart';
import '../services/data_cache_service.dart';
import '../services/talhao_diagnostic_service.dart';
import 'loading_error_feedback.dart';


/// Widget para seleção de talhões a partir do banco de dados
class PlotSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final bool isRequired;
  final String label;

  const PlotSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Talhão',
  }) : super(key: key);

  @override
  State<PlotSelector> createState() => _PlotSelectorState();
}

class _PlotSelectorState extends State<PlotSelector> {
  List<TalhaoModel> _talhoes = [];
  String? _selectedTalhaoId;
  bool _isLoading = false;
  String? _errorMessage;

  void initState() {
    super.initState();
    _selectedTalhaoId = widget.initialValue;
    _loadTalhoes();
  }

  Future<void> _loadTalhoes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataCacheService = DataCacheService();
      
      // Tentar carregar talhões com recarga forçada
      _talhoes = await dataCacheService.recarregarTalhoes();

      if (_talhoes.isEmpty) {
        // Se não há talhões, criar alguns de exemplo automaticamente
        await _criarTalhoesExemplo();
        _talhoes = await dataCacheService.recarregarTalhoes();
        
        if (_talhoes.isEmpty) {
          setState(() {
            _errorMessage = 'Erro ao criar talhões de exemplo. Verifique o banco de dados.';
            _isLoading = false;
          });
          return;
        }
      }

      // Verificar se o valor inicial existe na lista de talhões
      String? selectedId;
      
      if (widget.initialValue?.isNotEmpty == true) {
        // Verificar se o ID inicial existe na lista de talhões
        bool talhaoExists = _talhoes.any((talhao) => talhao.id == widget.initialValue);
        
        if (talhaoExists) {
          selectedId = widget.initialValue;
        } else {
          print('Talhão com ID ${widget.initialValue} não encontrado na lista de talhões');
          // Usar o primeiro talhão como fallback
          if (_talhoes.isNotEmpty) {
            selectedId = _talhoes.first.id;
            widget.onChanged(_talhoes.first.id);
          }
        }
      } else if (_talhoes.isNotEmpty) {
        selectedId = _talhoes.first.id;
        widget.onChanged(_talhoes.first.id);
      }
      
      setState(() {
        _isLoading = false;
        _selectedTalhaoId = selectedId;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar talhões: $e';
      });
      print('Erro ao carregar talhões: $e');
    }
  }

  /// Cria talhões de exemplo se não houver nenhum cadastrado
  Future<void> _criarTalhoesExemplo() async {
    try {
      final diagnosticService = TalhaoDiagnosticService();
      await diagnosticService.criarTalhoesExemplo();
    } catch (e) {
      print('Erro ao criar talhões de exemplo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingErrorFeedback(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadTalhoes,
      loadingText: 'Carregando talhões...',
      errorTitle: 'Erro ao carregar talhões',
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
          _talhoes.isEmpty
              ? _buildEmptyTalhoesMessage()
              : _buildDropdown(),
        ],
      ),
    );
  }

  Widget _buildEmptyTalhoesMessage() {
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
                  'Nenhum talhão cadastrado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cadastre talhões antes de continuar',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/talhoes').then((result) {
                      if (result == true) {
                        _loadTalhoes();
                      }
                    });
                  },
                  child: const Text('Cadastrar Talhão'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaText(TalhaoModel talhao) {
    // A checagem de nulo é válida, o linter pode estar incorreto.
    // O campo 'area' no TalhaoModel é nullable (double?).
    if (talhao.area == null || talhao.area == 0) {
      return const SizedBox.shrink();
    }
    return Text(
      '${talhao.area!.toStringAsFixed(1)} ha',
      style: TextStyle(color: Colors.grey[600], fontSize: 12),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTalhaoId,
          isExpanded: true,
          hint: Text(widget.label + (widget.isRequired ? ' *' : '')),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down),
          isDense: true,
          onChanged: (value) {
            setState(() {
              _selectedTalhaoId = value;
            });
            if (value != null) widget.onChanged(value);
          },
          items: _talhoes.map<DropdownMenuItem<String>>((TalhaoModel talhao) {
            return DropdownMenuItem<String>(
              value: talhao.id,
              child: Row(
                children: [
                  // Miniatura do polígono se existir (opcional, depende do seu widget PlotThumbnail)
                  // PlotThumbnail(plot: talhao, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          talhao.nome,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (talhao.safraAtual != null && talhao.safraAtual!.safra.isNotEmpty)
                          Text(
                            'Safra: ${talhao.safraAtual!.safra}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (talhao.safraAtual != null && talhao.safraAtual!.culturaNome.isNotEmpty)
                          Text(
                            'Cultura: ${talhao.safraAtual!.culturaNome}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _buildAreaText(talhao),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../models/integration/agro_context.dart';
import '../../models/talhao_model.dart';
import '../../models/safra_model.dart';
import '../../models/agricultural_product.dart';
import '../../services/module_integration_service.dart';
import '../../services/data_cache_service.dart';

/// Widget para seleção integrada de talhão, safra e cultura
/// Permite navegar entre todas as entidades do contexto agrícola
class AgroContextSelector extends StatefulWidget {
  final AgroContext? initialContext;
  final Function(AgroContext) onContextSelected;
  final bool showClearButton;
  final String? title;

  const AgroContextSelector({
    Key? key,
    this.initialContext,
    required this.onContextSelected,
    this.showClearButton = true,
    this.title,
  }) : super(key: key);

  @override
  State<AgroContextSelector> createState() => _AgroContextSelectorState();
}

class _AgroContextSelectorState extends State<AgroContextSelector> {
  final ModuleIntegrationService _integrationService = ModuleIntegrationService();
  final DataCacheService _cacheService = DataCacheService();
  
  // Estados para manter o contexto atual
  String? _talhaoId;
  String? _safraId;
  String? _culturaId;
  
  // Cache de dados
  List<TalhaoModel> _talhoes = [];
  List<SafraModel> _safras = [];
  List<AgriculturalProduct> _culturas = [];
  
  // Estados para controlar carregamento
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    
    // Inicializar com o contexto fornecido, se existir
    if (widget.initialContext != null) {
      _talhaoId = widget.initialContext!.talhaoId;
      _safraId = widget.initialContext!.safraId;
      _culturaId = widget.initialContext!.culturaId;
    } else if (_integrationService.hasCurrentContext()) {
      // Usar o contexto atual do serviço se não foi fornecido um inicial
      final context = _integrationService.currentContext!;
      _talhaoId = context.talhaoId;
      _safraId = context.safraId;
      _culturaId = context.culturaId;
    }
    
    _carregarDados();
  }
  
  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Carregar todos os talhões
      _talhoes = await _cacheService.getTalhoes();
      
      // Se um talhão já está selecionado, carregar suas safras
      if (_talhaoId != null) {
        await _carregarSafras(_talhaoId!);
        
        // Se uma safra já está selecionada, carregar culturas
        if (_safraId != null) {
          await _carregarCulturas();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _carregarSafras(String talhaoId) async {
    final talhao = _talhoes.firstWhere(
      (t) => t.id == talhaoId,
      orElse: () => throw Exception('Talhão não encontrado: $talhaoId'),
    );
    
    setState(() {
      _safras = talhao.safras;
    });
  }
  
  Future<void> _carregarCulturas() async {
    try {
      _culturas = await _cacheService.getCulturas();
    } catch (e) {
      print('Erro ao carregar culturas: $e');
      _culturas = [];
    }
  }
  
  void _selecionarTalhao(String? talhaoId) async {
    if (talhaoId == null || talhaoId == _talhaoId) return;
    
    setState(() {
      _talhaoId = talhaoId;
      _safraId = null;
      _culturaId = null;
      _safras = [];
    });
    
    await _carregarSafras(talhaoId);
  }
  
  void _selecionarSafra(String? safraId) {
    if (safraId == null || safraId == _safraId) return;
    
    setState(() {
      _safraId = safraId;
      _culturaId = null;
    });
    
    // Buscar a cultura associada à safra selecionada
    final safra = _safras.firstWhere((s) => s.id == safraId);
    if (safra.culturaId != null) {
      setState(() {
        _culturaId = safra.culturaId;
      });
      
      // Notificar que o contexto foi selecionado completamente
      if (_talhaoId != null && _safraId != null && _culturaId != null) {
        _notificarSelecaoCompleta();
      }
    } else {
      // Se a safra não tem cultura associada, carregar todas as culturas
      _carregarCulturas();
    }
  }
  
  void _selecionarCultura(String? culturaId) {
    if (culturaId == null || culturaId == _culturaId) return;
    
    setState(() {
      _culturaId = culturaId;
    });
    
    // Notificar que o contexto foi selecionado completamente
    if (_talhaoId != null && _safraId != null && _culturaId != null) {
      _notificarSelecaoCompleta();
    }
  }
  
  void _limparSelecao() {
    setState(() {
      _talhaoId = null;
      _safraId = null;
      _culturaId = null;
      _safras = [];
    });
  }
  
  void _notificarSelecaoCompleta() {
    if (_talhaoId != null && _safraId != null && _culturaId != null) {
      final context = AgroContext(
        talhaoId: _talhaoId!,
        safraId: _safraId!,
        culturaId: _culturaId!,
      );
      
      // Atualizar o contexto no serviço de integração
      _integrationService.setCurrentContext(
        talhaoId: _talhaoId!,
        safraId: _safraId!,
        culturaId: _culturaId!,
      );
      
      // Notificar o callback
      widget.onContextSelected(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          if (widget.title != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                widget.title!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
          // Mensagem de erro, se houver
          if (_errorMessage.isNotEmpty)
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
            
          // Indicador de carregamento
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seletor de talhão
                _buildDropdown(
                  label: 'Talhão',
                  value: _talhaoId,
                  items: _talhoes.map((talhao) => DropdownMenuItem(
                    value: talhao.id,
                    child: Text(talhao.nome),
                  )).toList(),
                  onChanged: _selecionarTalhao,
                ),
                
                // Seletor de safra
                _buildDropdown(
                  label: 'Safra',
                  value: _safraId,
                  items: _safras.map((safra) => DropdownMenuItem(
                    value: safra.id,
                    child: Text(safra.safra),
                  )).toList(),
                  onChanged: _selecionarSafra,
                  enabled: _talhaoId != null,
                ),
                
                // Seletor de cultura
                _buildDropdown(
                  label: 'Cultura',
                  value: _culturaId,
                  items: _culturas.map((cultura) => DropdownMenuItem(
                    value: cultura.id,
                    child: Text(cultura.name),
                  )).toList(),
                  onChanged: _selecionarCultura,
                  enabled: _talhaoId != null && _safraId != null,
                ),
                
                // Botão para limpar seleção
                if (widget.showClearButton)
                  Align(
                    // alignment: Alignment.centerRight, // alignment não é suportado em Marker no flutter_map 5.0.0
                    child: TextButton.icon(
                      onPressed: _limparSelecao,
                      icon: Icon(Icons.clear),
                      label: Text('Limpar Seleção'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: SizedBox(),
              hint: Text('Selecione $label'),
              onChanged: enabled ? onChanged : null,
              items: items.isEmpty
                  ? [
                      DropdownMenuItem<String>(
                        enabled: false,
                        value: null,
                        child: Text(
                          'Nenhum item disponível',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    ]
                  : items,
            ),
          ),
        ],
      ),
    );
  }
}

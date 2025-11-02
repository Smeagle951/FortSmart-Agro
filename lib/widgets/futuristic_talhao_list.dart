import 'package:flutter/material.dart';
import '../utils/area_formatter.dart';
import '../models/talhao_model.dart';
import 'glass_morphism_container.dart';

class FuturisticTalhaoList extends StatefulWidget {
  final List<TalhaoModel> talhoes;
  final Function(TalhaoModel)? onTalhaoSelected;
  final Function(TalhaoModel)? onTalhaoEdit;
  final Function(TalhaoModel)? onTalhaoDuplicate;
  final Function(TalhaoModel)? onTalhaoDelete;
  final TalhaoModel? selectedTalhao;
  final bool isCompactMode;
  
  const FuturisticTalhaoList({
    Key? key,
    required this.talhoes,
    this.onTalhaoSelected,
    this.onTalhaoEdit,
    this.onTalhaoDuplicate,
    this.onTalhaoDelete,
    this.selectedTalhao,
    this.isCompactMode = false,
  }) : super(key: key);

  @override
  State<FuturisticTalhaoList> createState() => _FuturisticTalhaoListState();
}

class _FuturisticTalhaoListState extends State<FuturisticTalhaoList> {
  String _searchQuery = '';
  String _culturaFilter = '';
  bool _showFilters = false;
  List<TalhaoModel> _filteredTalhoes = [];
  TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _filterTalhoes();
  }
  
  @override
  void didUpdateWidget(FuturisticTalhaoList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.talhoes != oldWidget.talhoes) {
      _filterTalhoes();
    }
  }
  
  void _filterTalhoes() {
    setState(() {
      _filteredTalhoes = widget.talhoes.where((talhao) {
        // Filtrar por pesquisa
        final matchesSearch = _searchQuery.isEmpty ||
            talhao.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            ((talhao.crop?.name ?? 'Sem cultura').toLowerCase()).contains(_searchQuery.toLowerCase()) ||
            (talhao.observacoes?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase());
        
        // Filtrar por cultura
        final matchesCultura = _culturaFilter.isEmpty ||
            (talhao.crop?.name ?? 'Sem cultura').toLowerCase() == _culturaFilter.toLowerCase();
        
        return matchesSearch && matchesCultura;
      }).toList();
    });
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterTalhoes();
    });
  }
  
  void _onCulturaFilterChanged(String cultura) {
    setState(() {
      _culturaFilter = _culturaFilter == cultura ? '' : cultura;
      _filterTalhoes();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Obter lista de culturas únicas
    final culturas = widget.talhoes.map((t) => t.crop?.name ?? 'Sem cultura').toSet().toList()..sort();
    
    return GlassMorphismContainer(
      borderRadius: 16,
      blur: 15,
      opacity: 0.1,
      borderColor: Colors.white.withOpacity(0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho com pesquisa e filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Talhões',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Botão para exibir/ocultar filtros
                    _NeonIconButton(
                      icon: _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      tooltip: _showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Campo de pesquisa
                _SearchField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
                
                // Filtros de cultura
                if (_showFilters)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showFilters ? null : 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'Filtrar por Cultura:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: culturas.map((cultura) {
                            final isSelected = _culturaFilter.toLowerCase() == cultura.toLowerCase();
                            // Criar um talhão temporário apenas para obter a cor
                            // Como cultura é uma string e o parâmetro espera app_crop.Crop, usamos uma abordagem alternativa
                            Color cor = Colors.green;
                            try {
                              // Tentar obter a cor diretamente sem criar o modelo
                              final talhoes = widget.talhoes.where((t) => (t.crop?.name ?? 'Sem cultura') == cultura);
                              if (talhoes.isNotEmpty) {
                                cor = talhoes.first.cor;
                              }
                            } catch (e) {
                              // Em caso de erro, usar a cor padrão
                              cor = Colors.green;
                            }
                            
                            return InkWell(
                              // onTap: () => _onCulturaFilterChanged(cultura), // onTap não é suportado em Polygon no flutter_map 5.0.0
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? cor.withOpacity(0.2) : Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? cor : cor.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: cor.withOpacity(0.3),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: cor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cultura,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de talhões
          Container(
            constraints: BoxConstraints(
              maxHeight: widget.isCompactMode ? 200 : 400,
            ),
            padding: const EdgeInsets.only(top: 8),
            child: _filteredTalhoes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _searchQuery.isNotEmpty || _culturaFilter.isNotEmpty
                            ? 'Nenhum talhão encontrado com os filtros atuais'
                            : 'Nenhum talhão cadastrado',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredTalhoes.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final talhao = _filteredTalhoes[index];
                      final isSelected = widget.selectedTalhao?.id == talhao.id;
                      
                      return _TalhaoListItem(
                        talhao: talhao,
                        isSelected: isSelected,
                        onTap: () {
                          if (widget.onTalhaoSelected != null) {
                            widget.onTalhaoSelected!(talhao);
                          }
                        }, // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
                        onEdit: widget.onTalhaoEdit != null
                            ? () => widget.onTalhaoEdit!(talhao)
                            : null,
                        onDuplicate: widget.onTalhaoDuplicate != null
                            ? () => widget.onTalhaoDuplicate!(talhao)
                            : null,
                        onDelete: widget.onTalhaoDelete != null
                            ? () => widget.onTalhaoDelete!(talhao)
                            : null,
                        isCompactMode: widget.isCompactMode,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  
  const _SearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          hintText: 'Buscar talhões...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _TalhaoListItem extends StatelessWidget {
  final TalhaoModel talhao;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final bool isCompactMode;
  
  const _TalhaoListItem({
    Key? key,
    required this.talhao,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.isCompactMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cor = talhao.cor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? cor : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cor.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ícone da cultura
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cor.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          talhao.name.isNotEmpty ? talhao.name[0].toUpperCase() : 'T',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Informações principais
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            talhao.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            talhao.crop?.name ?? 'Sem cultura',
                            style: TextStyle(
                              color: cor,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Indicador de área
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        AreaFormatter.formatHectaresFixed(talhao.area),
                        style: TextStyle(
                          color: cor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Observações e ações (visíveis apenas se não estiver no modo compacto ou se estiver selecionado)
                if (!isCompactMode || isSelected)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (talhao.observacoes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 10),
                        Text(
                          talhao.observacoes ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // Ações
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Indicador de sincronização
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: talhao.sincronizado
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: talhao.sincronizado
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  talhao.sincronizado ? Icons.cloud_done : Icons.cloud_off,
                                  size: 12,
                                  color: talhao.sincronizado ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  talhao.sincronizado ? 'Sincronizado' : 'Offline',
                                  style: TextStyle(
                                    color: talhao.sincronizado ? Colors.green : Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          
                          // Botões de ação
                          if (onEdit != null)
                            _NeonIconButton(
                              icon: Icons.edit,
                              onPressed: onEdit!,
                              tooltip: 'Editar talhão',
                              color: Colors.blue,
                              mini: true,
                            ),
                          
                          if (onDuplicate != null) ...[
                            const SizedBox(width: 8),
                            _NeonIconButton(
                              icon: Icons.copy,
                              onPressed: onDuplicate!,
                              tooltip: 'Duplicar talhão',
                              color: Colors.amber,
                              mini: true,
                            ),
                          ],
                          
                          if (onDelete != null) ...[
                            const SizedBox(width: 8),
                            _NeonIconButton(
                              icon: Icons.delete,
                              onPressed: onDelete!,
                              tooltip: 'Excluir talhão',
                              color: Colors.red,
                              mini: true,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeonIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color color;
  final bool mini;
  
  const _NeonIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.color,
    this.mini = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: mini ? 32 : 40,
      height: mini ? 32 : 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // onTap: onPressed, // onTap não é suportado em Polygon no flutter_map 5.0.0
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: mini ? 16 : 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

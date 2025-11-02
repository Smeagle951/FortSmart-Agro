import 'package:flutter/material.dart';
import '../utils/area_formatter.dart';
import 'dart:io';
import '../models/talhao_model.dart';
import 'glass_morphism_container.dart';

/// Widget para exibir a lista de talhões com filtragem e pesquisa
class TalhaoListWidget extends StatelessWidget {
  final List<TalhaoModel> talhoes;
  final TalhaoModel? selectedTalhao;
  final String searchQuery;
  final String? culturaFilter;
  final Function(TalhaoModel) onTalhaoTap;
  final Function(TalhaoModel) onTalhaoEditTap;
  final Function(TalhaoModel) onTalhaoDeleteTap;
  final Function(String) onSearchChanged;
  final Function(String?) onCulturaFilterChanged;

  const TalhaoListWidget({
    Key? key,
    required this.talhoes,
    this.selectedTalhao,
    required this.searchQuery,
    this.culturaFilter,
    required this.onTalhaoTap,
    required this.onTalhaoEditTap,
    required this.onTalhaoDeleteTap,
    required this.onSearchChanged,
    required this.onCulturaFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lista filtrada de talhões
    List<TalhaoModel> filteredTalhoes = [];
    if (talhoes.isNotEmpty && searchQuery.isNotEmpty) {
      filteredTalhoes = talhoes.where((talhao) {
        final nome = talhao.nome?.toLowerCase() ?? '';
        final safra = talhao.safra?.toString().toLowerCase() ?? '';
        final cultura = talhao.crop?.name.toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        
        return nome.contains(query) || 
               safra.contains(query) || 
               cultura.contains(query);
      }).toList();
    } else {
      filteredTalhoes = talhoes;
    }
    
    // Lista de culturas únicas para o filtro
    final culturas = talhoes.map((t) => t.crop ?? '').toSet().toList()..sort();
    
    return GlassMorphismContainer(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho com título e total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Talhões',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${filteredTalhoes.length} de ${talhoes.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Campo de busca
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar talhões...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white60),
              filled: true,
              fillColor: Colors.black45,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          
          // Filtro de culturas
          Builder(builder: (context) {
            // Validar se o valor selecionado existe na lista de culturas
            String? validatedFilter = culturaFilter;
            
            // Se o valor não for nulo, verificar se existe na lista de culturas
            if (validatedFilter != null && !culturas.contains(validatedFilter)) {
              print('Cultura selecionada "$validatedFilter" não encontrada na lista de culturas');
              validatedFilter = null; // Resetar para null se não existir
            }
            
            return DropdownButtonFormField<String?>(
              value: validatedFilter,
              decoration: InputDecoration(
                hintText: 'Filtrar por cultura',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.filter_list, color: Colors.white60),
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              style: const TextStyle(color: Colors.white),
              dropdownColor: Colors.black87,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas as culturas'),
                ),
                ...culturas.map((cultura) => DropdownMenuItem<String?>(
                  value: cultura.toString(),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: talhoes.firstWhere((t) => (t.crop?.name ?? '') == cultura, orElse: () => talhoes.first).crop?.color ?? Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(cultura.toString()),
                    ],
                  ),
                )),
              ],
              onChanged: onCulturaFilterChanged,
            );
          }),
          const SizedBox(height: 16),
          
          // Lista de talhões
          Expanded(
            child: filteredTalhoes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: Colors.white60,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty || culturaFilter != null
                              ? 'Nenhum talhão encontrado com os filtros atuais'
                              : 'Nenhum talhão cadastrado',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTalhoes.length,
                    itemBuilder: (context, index) {
                      final talhao = filteredTalhoes[index];
                      final isSelected = selectedTalhao?.id == talhao.id;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? Colors.black.withOpacity(0.7)
                              : Colors.black38,
                          border: Border.all(
                            color: isSelected
                                ? talhao.crop?.color ?? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: talhao.crop?.color ?? Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: talhao.crop?.color ?? Colors.green,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.eco,
                                color: talhao.crop?.color ?? Colors.green,
                                size: 24,
                              ),
                            ),
                          ),
                          title: Text(
                            talhao.nome ?? 'Sem nome',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                talhao.crop?.name ?? '',
                                style: TextStyle(
                                  color: talhao.crop?.color ?? Colors.green.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                'Área: ${AreaFormatter.formatHectaresFixed(talhao.area)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => onTalhaoEditTap(talhao),
                                tooltip: 'Editar Talhão',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => onTalhaoDeleteTap(talhao),
                                tooltip: 'Excluir Talhão',
                              ),
                            ],
                          ),
                          onTap: () => onTalhaoTap(talhao),
                          selected: isSelected,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

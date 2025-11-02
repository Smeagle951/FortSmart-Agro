import 'package:flutter/material.dart';
import '../../../models/talhao_model_new.dart';
import '../../../models/agricultural_product.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../utils/app_colors.dart';
import '../services/data_cache_service.dart';

/// Widget para exibir um campo de seleção com ícone e rótulo
class SelectionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  final IconData icon;
  final bool required;

  const SelectionField({
    Key? key,
    required this.label,
    required this.controller,
    required this.onTap,
    required this.icon,
    this.required = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        prefixIcon: Icon(icon),
      ),
      validator: required ? (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione $label';
        }
        return null;
      } : null,
    );
  }
}

/// Exibe um diálogo para seleção de talhão
Future<TalhaoModel?> showTalhaoSelectionDialog(BuildContext context) async {
  final talhaoRepository = TalhaoRepository();
  
  // Carregar talhões
  final talhoes = await talhaoRepository.loadTalhoes();
  
  if (talhoes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nenhum talhão cadastrado'),
        backgroundColor: Colors.orange,
      ),
    );
    return null;
  }
  
  return showDialog<TalhaoModel>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Selecionar Talhão'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            // Campo de pesquisa
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Pesquisar talhão...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Implementar filtro de pesquisa
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: talhoes.length,
                itemBuilder: (context, index) {
                  final talhao = talhoes[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(talhao.nome.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(talhao.nome),
                    subtitle: Text('Área: ${talhao.area.toStringAsFixed(2)} ha'),

                    onTap: () => Navigator.of(context).pop(talhao),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

/// Exibe um diálogo para seleção de cultura
Future<AgriculturalProduct?> showCulturaSelectionDialog(BuildContext context) async {
  final productRepository = AgriculturalProductRepository();
  final dataCacheService = DataCacheService();
  
  // Carregar culturas usando o DataCacheService para garantir integração
  List<AgriculturalProduct> culturas = [];
  
  try {
    // Primeiro tenta carregar do cache com atualização forçada
    culturas = await dataCacheService.getCulturas(forceRefresh: true);
    
    // Se não encontrou nada no cache, tenta diretamente do repositório
    if (culturas.isEmpty) {
      culturas = await productRepository.getByType(ProductType.seed);
    }
    
    // Filtra apenas as culturas (tipo semente)
    culturas = culturas.where((c) => c.type == ProductType.seed).toList();
    
    print('Carregadas ${culturas.length} culturas para o diálogo de seleção');
  } catch (e) {
    print('Erro ao carregar culturas: $e');
    // Última tentativa direta do repositório
    culturas = await productRepository.getByType(ProductType.seed);
  }
  
  if (culturas.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nenhuma cultura cadastrada'),
        backgroundColor: Colors.orange,
      ),
    );
    return null;
  }
  
  return showDialog<AgriculturalProduct>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Selecione uma cultura'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            // Campo de pesquisa
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Pesquisar cultura...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Implementar filtro de pesquisa
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: culturas.length,
                itemBuilder: (context, index) {
                  final cultura = culturas[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryColor,
                      child: Icon(Icons.spa, color: Colors.white),
                    ),
                    title: Text(cultura.name),
                    subtitle: Text('Cultura'),

                    onTap: () => Navigator.of(context).pop(cultura),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

/// Exibe um diálogo para seleção de variedade com base na cultura selecionada
Future<AgriculturalProduct?> showVariedadeSelectionDialog(BuildContext context, String culturaId) async {
  final productRepository = AgriculturalProductRepository();
  
  // Carregar variedades da cultura selecionada
  final variedades = await productRepository.getByType(ProductType.seed);
  
  // Filtrar apenas as variedades da cultura selecionada
  final variedadesFiltradas = variedades.where((v) => v.parentId == culturaId).toList();
  
  if (variedadesFiltradas.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nenhuma variedade cadastrada para esta cultura'),
        backgroundColor: Colors.orange,
      ),
    );
    return null;
  }
  
  return showDialog<AgriculturalProduct>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Selecione uma variedade'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            // Campo de pesquisa
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Pesquisar variedade...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Implementar filtro de pesquisa
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: variedadesFiltradas.length,
                itemBuilder: (context, index) {
                  final variedade = variedadesFiltradas[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondaryColor,
                      child: Icon(Icons.grain, color: Colors.white),
                    ),
                    title: Text(variedade.name),
                    subtitle: Text(variedade.notes ?? 'Variedade'),
                    onTap: () => Navigator.of(context).pop(variedade),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

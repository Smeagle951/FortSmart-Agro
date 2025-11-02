import 'package:flutter/material.dart';
import '../../../models/agricultural_product.dart';

class AdvancedCultureFilter extends StatefulWidget {
  final List<AgriculturalProduct> culturas;
  final Function(List<AgriculturalProduct>) onFiltered;

  const AdvancedCultureFilter({
    Key? key,
    required this.culturas,
    required this.onFiltered,
  }) : super(key: key);

  @override
  _AdvancedCultureFilterState createState() => _AdvancedCultureFilterState();
}

class _AdvancedCultureFilterState extends State<AdvancedCultureFilter> {
  String _searchQuery = '';
  List<String> _selectedManufacturers = [];
  List<String> _allManufacturers = [];
  bool _showOnlyWithVarieties = false;

  @override
  void initState() {
    super.initState();
    _extractManufacturers();
  }

  @override
  void didUpdateWidget(AdvancedCultureFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.culturas != widget.culturas) {
      _extractManufacturers();
    }
  }

  void _extractManufacturers() {
    final manufacturers = widget.culturas
        .map((c) => c.manufacturer ?? 'Não especificado')
        .toSet()
        .toList();
    manufacturers.sort();
    setState(() {
      _allManufacturers = manufacturers;
    });
  }

  void _applyFilters() {
    List<AgriculturalProduct> filteredCulturas = widget.culturas;
    
    // Aplicar filtro de texto
    if (_searchQuery.isNotEmpty) {
      filteredCulturas = filteredCulturas.where((cultura) {
        return cultura.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (cultura.manufacturer?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    
    // Aplicar filtro de fabricantes
    if (_selectedManufacturers.isNotEmpty) {
      filteredCulturas = filteredCulturas.where((cultura) {
        final manufacturer = cultura.manufacturer ?? 'Não especificado';
        return _selectedManufacturers.contains(manufacturer);
      }).toList();
    }
    
    // Aplicar outros filtros conforme necessário
    
    // Notificar o widget pai sobre as culturas filtradas
    widget.onFiltered(filteredCulturas);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de pesquisa
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Pesquisar cultura',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
        ),
        
        // Filtro de fabricantes
        ExpansionTile(
          title: const Text('Fabricantes'),
          children: [
            Wrap(
              spacing: 8.0,
              children: _allManufacturers.map((manufacturer) {
                final isSelected = _selectedManufacturers.contains(manufacturer);
                return FilterChip(
                  label: Text(manufacturer),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedManufacturers.add(manufacturer);
                      } else {
                        _selectedManufacturers.remove(manufacturer);
                      }
                    });
                    _applyFilters();
                  },
                  backgroundColor: const Color(0xFF228B22),
                  selectedColor: const Color(0xFF228B22).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF228B22),
                );
              }).toList(),
            ),
          ],
        ),
        
        // Outros filtros
        SwitchListTile(
          title: const Text('Mostrar apenas com variedades'),
          value: _showOnlyWithVarieties,
          onChanged: (value) {
            setState(() {
              _showOnlyWithVarieties = value;
            });
            _applyFilters();
          },
          activeColor: const Color(0xFF228B22),
        ),
        
        const Divider(),
        
        // Botões de ação
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedManufacturers = [];
                    _showOnlyWithVarieties = false;
                  });
                  _applyFilters();
                },
                child: const Text('Limpar Filtros'),
              ),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF228B22),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

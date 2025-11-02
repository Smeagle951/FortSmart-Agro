/// 🌱 Widget de Busca de Testes de Germinação
/// 
/// Campo de busca elegante com funcionalidades avançadas
/// seguindo padrão visual FortSmart

import 'package:flutter/material.dart';
import '../../../../../../utils/fortsmart_theme.dart';

class GerminationSearchWidget extends StatefulWidget {
  final String searchText;
  final ValueChanged<String> onSearchChanged;

  const GerminationSearchWidget({
    super.key,
    required this.searchText,
    required this.onSearchChanged,
  });

  @override
  State<GerminationSearchWidget> createState() => _GerminationSearchWidgetState();
}

class _GerminationSearchWidgetState extends State<GerminationSearchWidget> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchText);
  }

  @override
  void didUpdateWidget(GerminationSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchText != widget.searchText) {
      _controller.text = widget.searchText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSearching 
              ? FortSmartTheme.primaryColor 
              : Colors.grey[300]!,
          width: _isSearching ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Buscar por cultura, variedade ou lote...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _isSearching 
                ? FortSmartTheme.primaryColor 
                : Colors.grey[500],
          ),
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          widget.onSearchChanged(value);
        },
        onTap: () {
          setState(() => _isSearching = true);
        },
        onSubmitted: (value) {
          setState(() => _isSearching = false);
        },
        onTapOutside: (event) {
          setState(() => _isSearching = false);
        },
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (widget.searchText.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _controller.clear();
              widget.onSearchChanged('');
            },
            color: Colors.grey[600],
            tooltip: 'Limpar busca',
          ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.search, size: 20),
              onPressed: () {
                setState(() => _isSearching = false);
                FocusScope.of(context).unfocus();
              },
              color: FortSmartTheme.primaryColor,
              tooltip: 'Buscar',
            ),
        ],
      );
    }
    
    if (_isSearching) {
      return IconButton(
        icon: const Icon(Icons.search, size: 20),
        onPressed: () {
          setState(() => _isSearching = false);
          FocusScope.of(context).unfocus();
        },
        color: FortSmartTheme.primaryColor,
        tooltip: 'Buscar',
      );
    }
    
    return IconButton(
      icon: const Icon(Icons.tune, size: 20),
      onPressed: () => _showAdvancedSearch(),
      color: Colors.grey[600],
      tooltip: 'Busca avançada',
    );
  }

  void _showAdvancedSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Busca Avançada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSearchOption(
              Icons.science,
              'Por Cultura',
              'Buscar por nome da cultura',
              () => _searchByCulture(),
            ),
            _buildSearchOption(
              Icons.local_activity,
              'Por Variedade',
              'Buscar por nome da variedade',
              () => _searchByVariety(),
            ),
            _buildSearchOption(
              Icons.inventory,
              'Por Lote',
              'Buscar por número do lote',
              () => _searchByLot(),
            ),
            _buildSearchOption(
              Icons.calendar_today,
              'Por Data',
              'Buscar por período',
              () => _searchByDate(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: FortSmartTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _searchByCulture() {
    // TODO: Implementar busca por cultura
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Busca por cultura em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _searchByVariety() {
    // TODO: Implementar busca por variedade
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Busca por variedade em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _searchByLot() {
    // TODO: Implementar busca por lote
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Busca por lote em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _searchByDate() {
    // TODO: Implementar busca por data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Busca por data em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

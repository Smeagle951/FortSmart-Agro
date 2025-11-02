import 'package:flutter/material.dart';
import '../widgets/overflow_safe_widget.dart';
import '../mixins/overflow_fix_mixin.dart';

/// Tela de exemplo mostrando como usar o sistema de correção automática de overflow
class OverflowFixExampleScreen extends StatefulWidget {
  const OverflowFixExampleScreen({Key? key}) : super(key: key);

  @override
  State<OverflowFixExampleScreen> createState() => _OverflowFixExampleScreenState();
}

class _OverflowFixExampleScreenState extends State<OverflowFixExampleScreen> with OverflowFixMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedMapType;
  String? _selectedZoomLevel;

  @override
  Widget build(BuildContext context) {
    return OverflowSafeScaffold(
      title: 'Exemplo - Correção Automática de Overflow',
      body: OverflowSafeWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            OverflowSafeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistema de Correção Automática',
                    style: TextStyle(
                      fontSize: getAdaptiveFontSize(20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este sistema detecta e corrige automaticamente problemas de overflow em telas menores.',
                    style: TextStyle(
                      fontSize: getAdaptiveFontSize(14),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Formulário adaptativo
            OverflowSafeCard(
              child: OverflowSafeForm(
                children: [
                  Text(
                    'Configurações do Mapa',
                    style: TextStyle(
                      fontSize: getAdaptiveFontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo de nome
                  OverflowSafeTextField(
                    label: 'Nome do Mapa',
                    hint: 'Digite o nome do mapa',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.map),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dropdown de tipo de mapa
                  OverflowSafeDropdown<String>(
                    label: 'Tipo de Mapa',
                    value: _selectedMapType,
                    items: const [
                      DropdownMenuItem(value: 'satellite', child: Text('Satélite')),
                      DropdownMenuItem(value: 'streets', child: Text('Ruas')),
                      DropdownMenuItem(value: 'outdoors', child: Text('Externo')),
                      DropdownMenuItem(value: 'topo', child: Text('Topográfico')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMapType = value;
                      });
                    },
                    prefixIcon: const Icon(Icons.layers),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dropdown de nível de zoom
                  OverflowSafeDropdown<String>(
                    label: 'Nível de Zoom',
                    value: _selectedZoomLevel,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Baixo (10-15)')),
                      DropdownMenuItem(value: 'medium', child: Text('Médio (13-18)')),
                      DropdownMenuItem(value: 'high', child: Text('Alto (15-20)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedZoomLevel = value;
                      });
                    },
                    prefixIcon: const Icon(Icons.zoom_in),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Grid adaptativo
            OverflowSafeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opções de Download',
                    style: TextStyle(
                      fontSize: getAdaptiveFontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  OverflowSafeGrid(
                    children: [
                      _buildOptionCard(
                        'Talhões',
                        Icons.map,
                        Colors.green,
                        () => _showMessage('Download de talhões'),
                      ),
                      _buildOptionCard(
                        'Área Livre',
                        Icons.edit_location,
                        Colors.blue,
                        () => _showMessage('Download de área livre'),
                      ),
                      _buildOptionCard(
                        'Fazenda Completa',
                        Icons.home,
                        Colors.orange,
                        () => _showMessage('Download da fazenda completa'),
                      ),
                      _buildOptionCard(
                        'Configurações',
                        Icons.settings,
                        Colors.purple,
                        () => _showMessage('Configurações de download'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botões adaptativos
            OverflowSafeCard(
              child: Column(
                children: [
                  OverflowSafeButton(
                    text: 'Baixar Mapas Selecionados',
                    icon: Icons.download,
                    backgroundColor: Colors.green,
                    onPressed: _downloadMaps,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  OverflowSafeButton(
                    text: 'Limpar Seleção',
                    icon: Icons.clear,
                    backgroundColor: Colors.red,
                    onPressed: _clearSelection,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  OverflowSafeButton(
                    text: 'Configurações Avançadas',
                    icon: Icons.settings,
                    backgroundColor: Colors.blue,
                    onPressed: _openAdvancedSettings,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informações de status
            OverflowSafeCard(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Status do Sistema',
                        style: TextStyle(
                          fontSize: getAdaptiveFontSize(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tela: ${isSmallScreen ? "Pequena" : isMediumScreen ? "Média" : "Grande"}',
                    style: TextStyle(fontSize: getAdaptiveFontSize(14)),
                  ),
                  Text(
                    'Overflow: Corrigido automaticamente',
                    style: TextStyle(fontSize: getAdaptiveFontSize(14)),
                  ),
                  Text(
                    'Scroll: Habilitado em ambas as direções',
                    style: TextStyle(fontSize: getAdaptiveFontSize(14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSystemInfo,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.info, color: Colors.white),
      ),
    );
  }

  /// Constrói card de opção
  Widget _buildOptionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: getAdaptiveFontSize(12),
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra mensagem
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Download de mapas
  void _downloadMaps() {
    if (_nameController.text.isEmpty) {
      _showMessage('Digite o nome do mapa');
      return;
    }
    
    if (_selectedMapType == null) {
      _showMessage('Selecione o tipo de mapa');
      return;
    }
    
    if (_selectedZoomLevel == null) {
      _showMessage('Selecione o nível de zoom');
      return;
    }
    
    _showMessage('Download iniciado: ${_nameController.text}');
  }

  /// Limpa seleção
  void _clearSelection() {
    setState(() {
      _nameController.clear();
      _selectedMapType = null;
      _selectedZoomLevel = null;
    });
    _showMessage('Seleção limpa');
  }

  /// Abre configurações avançadas
  void _openAdvancedSettings() {
    _showMessage('Configurações avançadas abertas');
  }

  /// Mostra informações do sistema
  void _showSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Sistema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tela: ${isSmallScreen ? "Pequena" : isMediumScreen ? "Média" : "Grande"}'),
            Text('Largura: ${MediaQuery.of(context).size.width.toStringAsFixed(0)}px'),
            Text('Altura: ${MediaQuery.of(context).size.height.toStringAsFixed(0)}px'),
            Text('Fonte base: ${getAdaptiveFontSize(14).toStringAsFixed(1)}px'),
            const SizedBox(height: 8),
            const Text('Sistema de correção automática ativo!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

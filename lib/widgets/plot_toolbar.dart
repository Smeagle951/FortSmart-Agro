import 'package:flutter/material.dart';

/// Widget para exibir uma barra de ferramentas para edição de talhões
class PlotToolbar extends StatelessWidget {
  final bool isDrawMode;
  final bool isGpsMode;
  final bool isEraseMode;
  final VoidCallback onDrawMode;
  final VoidCallback onGpsMode;
  final VoidCallback onEraseMode;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool canUndo;
  final bool canClear;
  final bool canSave;
  
  const PlotToolbar({
    Key? key,
    required this.isDrawMode,
    required this.isGpsMode,
    required this.isEraseMode,
    required this.onDrawMode,
    required this.onGpsMode,
    required this.onEraseMode,
    required this.onUndo,
    required this.onClear,
    required this.onSave,
    required this.onCancel,
    this.canUndo = false,
    this.canClear = false,
    this.canSave = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modos de edição
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                icon: Icons.edit,
                label: 'Desenho',
                isActive: isDrawMode,
                onPressed: onDrawMode,
                activeColor: const Color(0xFF4CAF50),
              ),
              _buildToolButton(
                icon: Icons.gps_fixed,
                label: 'GPS',
                isActive: isGpsMode,
                onPressed: onGpsMode,
                activeColor: const Color(0xFF2196F3),
              ),
              _buildToolButton(
                icon: Icons.delete,
                label: 'Borracha',
                isActive: isEraseMode,
                onPressed: onEraseMode,
                activeColor: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          
          // Ações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.undo,
                label: 'Desfazer',
                onPressed: canUndo ? onUndo : null,
                color: const Color(0xFF2196F3),
              ),
              _buildActionButton(
                icon: Icons.delete_sweep,
                label: 'Limpar',
                onPressed: canClear ? onClear : null,
                color: Colors.orange,
              ),
              _buildActionButton(
                icon: Icons.save,
                label: 'Salvar',
                onPressed: canSave ? onSave : null,
                color: const Color(0xFF4CAF50),
              ),
              _buildActionButton(
                icon: Icons.cancel,
                label: 'Cancelar',
                onPressed: onCancel,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Constrói um botão de ferramenta
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: activeColor, width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? activeColor : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Constrói um botão de ação
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    final bool isEnabled = onPressed != null;
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isEnabled ? color : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

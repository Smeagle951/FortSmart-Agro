import 'package:flutter/material.dart';
import '../services/fluent_polygon_editor_service.dart';

/// Widget de controles para edição fluida de polígonos
/// Fornece interface intuitiva para ativar/desativar modo de edição
class FluentPolygonEditorControls extends StatefulWidget {
  final FluentPolygonEditorService editorService;
  final VoidCallback? onEditingStateChanged;
  final bool showAdvancedControls;
  
  const FluentPolygonEditorControls({
    Key? key,
    required this.editorService,
    this.onEditingStateChanged,
    this.showAdvancedControls = true,
  }) : super(key: key);
  
  @override
  State<FluentPolygonEditorControls> createState() => _FluentPolygonEditorControlsState();
}

class _FluentPolygonEditorControlsState extends State<FluentPolygonEditorControls> {
  bool _isEditing = false;
  String _statusMessage = '';
  
  @override
  void initState() {
    super.initState();
    _setupEditorService();
  }
  
  void _setupEditorService() {
    widget.editorService.onStatusChanged = (message) {
      setState(() {
        _statusMessage = message;
      });
    };
  }
  
  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
    
    if (_isEditing) {
      widget.editorService.enableEditing();
    } else {
      widget.editorService.disableEditing();
    }
    
    widget.onEditingStateChanged?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Controles principais
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão principal de edição
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isEditing ? Icons.edit_off : Icons.edit,
                    color: _isEditing ? Colors.red : Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _isEditing ? 'Desativar Edição' : 'Ativar Edição Fluida',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isEditing ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Botão de toggle
              ElevatedButton.icon(
                onPressed: _toggleEditing,
                icon: Icon(
                  _isEditing ? Icons.stop : Icons.play_arrow,
                  size: 16,
                ),
                label: Text(_isEditing ? 'Parar Edição' : 'Iniciar Edição'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              // Controles avançados
              if (widget.showAdvancedControls && _isEditing) ...[
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 8),
                
                // Instruções de uso
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como usar:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildInstruction('• Toque nos pontos vermelhos para selecionar'),
                      _buildInstruction('• Arraste para mover pontos existentes'),
                      _buildInstruction('• Toque nos pontos laranja para criar novos pontos'),
                      _buildInstruction('• Use tolerância ampla - não precisa mirar precisamente'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Status da edição
        if (_isEditing && _statusMessage.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.green,
                  size: 14,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildInstruction(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

/// Widget compacto para controles rápidos
class FluentPolygonEditorQuickControls extends StatelessWidget {
  final FluentPolygonEditorService editorService;
  final VoidCallback? onEditingStateChanged;
  
  const FluentPolygonEditorQuickControls({
    Key? key,
    required this.editorService,
    this.onEditingStateChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _editingStateStream(),
      builder: (context, snapshot) {
        final isEditing = snapshot.data ?? false;
        
        return FloatingActionButton.small(
          onPressed: () {
            if (isEditing) {
              editorService.disableEditing();
            } else {
              editorService.enableEditing();
            }
            onEditingStateChanged?.call();
          },
          backgroundColor: isEditing ? Colors.red : Colors.blue,
          child: Icon(
            isEditing ? Icons.edit_off : Icons.edit,
            color: Colors.white,
            size: 18,
          ),
        );
      },
    );
  }
  
  Stream<bool> _editingStateStream() {
    return Stream.periodic(Duration(milliseconds: 100))
        .map((_) => editorService.isEditing);
  }
}

import 'package:flutter/material.dart';

/// Widget para o menu de botões flutuantes da tela de talhões
class PlotFabMenu extends StatefulWidget {
  final VoidCallback onDrawMode;
  final VoidCallback onGpsMode;
  final VoidCallback onEraseMode;
  
  const PlotFabMenu({
    Key? key,
    required this.onDrawMode,
    required this.onGpsMode,
    required this.onEraseMode,
  }) : super(key: key);
  
  @override
  _PlotFabMenuState createState() => _PlotFabMenuState();
}

class _PlotFabMenuState extends State<PlotFabMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão de desenho manual
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
          child: FloatingActionButton.small(
            heroTag: 'drawButton',
            onPressed: () {
              widget.onDrawMode();
              _toggleMenu();
            },
            // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
            foregroundColor: Colors.blue,
            child: const Icon(Icons.edit),
            tooltip: 'Desenhar manualmente',
          ),
        ),
        const SizedBox(height: 8),
        
        // Botão de GPS
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: FloatingActionButton.small(
            heroTag: 'gpsButton',
            onPressed: () {
              widget.onGpsMode();
              _toggleMenu();
            },
            // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
            foregroundColor: Colors.green,
            child: const Icon(Icons.gps_fixed),
            tooltip: 'Usar GPS',
          ),
        ),
        const SizedBox(height: 8),
        
        // Botão de borracha
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: FloatingActionButton.small(
            heroTag: 'eraseButton',
            onPressed: () {
              widget.onEraseMode();
              _toggleMenu();
            },
            // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
            foregroundColor: Colors.red,
            child: const Icon(Icons.delete),
            tooltip: 'Apagar pontos',
          ),
        ),
        const SizedBox(height: 16),
        
        // Botão principal
        FloatingActionButton(
          heroTag: 'mainButton',
          onPressed: _toggleMenu,
          // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animationController,
          ),
          tooltip: 'Criar talhão',
        ),
      ],
    );
  }
}

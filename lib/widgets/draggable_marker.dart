import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DraggableMarker extends StatefulWidget {
  final LatLng initialPosition;
  final Function(LatLng) onPositionChanged;
  final Function()? onDelete;
  final int index;
  final bool isSelected;

  const DraggableMarker({
    Key? key,
    required this.initialPosition,
    required this.onPositionChanged,
    required this.index,
    this.onDelete,
    this.isSelected = false,
  }) : super(key: key);

  @override
  _DraggableMarkerState createState() => _DraggableMarkerState();
}

class _DraggableMarkerState extends State<DraggableMarker> {
  late LatLng _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Marcador principal
        GestureDetector(
          onPanUpdate: (details) {
            // Converter o movimento do gesto para mudança nas coordenadas
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final offset = renderBox.globalToLocal(details.globalPosition);
            
            // Calcular nova posição
            final newPosition = LatLng(
              _position.latitude - (details.delta.dy / 10000),
              _position.longitude + (details.delta.dx / 10000),
            );
            
            setState(() {
              _position = newPosition;
            });
            
            widget.onPositionChanged(newPosition);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: widget.isSelected ? Colors.blue.withOpacity(0.9) : Colors.green.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${widget.index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
        
        // Indicador de arrasto
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.drag_indicator,
              size: 14,
              color: Colors.black54,
            ),
          ),
        ),
        
        // Botão de exclusão
        if (widget.onDelete != null)
          Positioned(
            top: -5,
            right: -5,
            child: GestureDetector(
              // onTap: widget.onDelete, // onTap não é suportado em Polygon no flutter_map 5.0.0
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

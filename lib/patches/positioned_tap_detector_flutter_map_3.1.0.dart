// Patch completo para compatibilidade entre positioned_tap_detector_2 e flutter_map 3.1.0
// Este arquivo fornece todas as classes e funções necessárias para o flutter_map 3.1.0

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Implementações seguras para null safety que substituem as funções globais
int hashValues(dynamic a, dynamic b) => Object.hash(a ?? 0, b ?? 0);
int hashList(List<dynamic>? list) => Object.hashAll(list ?? []);

// Definição do tipo TapPositionCallback que o flutter_map 3.1.0 espera
typedef TapPositionCallback = void Function(TapPosition position);

/// Classe TapPosition que é usada pelo flutter_map
class TapPosition {
  const TapPosition({
    required this.global,
    required this.local,
  });

  final Offset global;
  final Offset local;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is TapPosition &&
        other.global == global &&
        other.local == local;
  }

  @override
  // Implementação segura para null safety
  int get hashCode => Object.hash(global, local);

  Offset get relative => local;

  @override
  String toString() => 'TapPosition(global: $global, local: $local)';
}

/// Classe TapPositionController que é usada como base
class TapPositionController {
  TapPosition? _downPosition;
  TapPosition? _upPosition;
  TapDownDetails? _tapDownDetails;
  TapUpDetails? _tapUpDetails;

  TapPosition? get position => _upPosition ?? _downPosition;
  TapPosition? get downPosition => _downPosition;
  TapPosition? get upPosition => _upPosition;
  TapDownDetails? get tapDownDetails => _tapDownDetails;
  TapUpDetails? get tapUpDetails => _tapUpDetails;
  
  void _updateDown(TapPosition position, TapDownDetails? details) {
    _downPosition = position;
    _tapDownDetails = details;
  }

  void _updateUp(TapPosition position, TapUpDetails? details) {
    _upPosition = position;
    _tapUpDetails = details;
  }
}

/// Classe PositionedTapController que o flutter_map 3.1.0 espera
class PositionedTapController extends TapPositionController {
  // Callbacks que o flutter_map 3.1.0 espera com os tipos corretos
  void Function(TapDownDetails)? onTapDown;
  void Function()? onTap;
  void Function()? onLongPress;
}

/// Tap detector que fornece a posição do tap (global, local)
class PositionedTapDetector2 extends StatefulWidget {
  const PositionedTapDetector2({
    Key? key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.behavior,
    this.controller,
    this.doubleTapDelay = const Duration(milliseconds: 250),
  }) : super(key: key);

  final Widget child;
  final PositionCallback? onTap;
  final PositionCallback? onDoubleTap;
  final PositionCallback? onLongPress;
  final PositionCallback? onSecondaryTap;
  final HitTestBehavior? behavior;
  final TapPositionController? controller;
  final Duration doubleTapDelay;

  @override
  PositionedTapDetector2State createState() => PositionedTapDetector2State();
}

class PositionedTapDetector2State extends State<PositionedTapDetector2> {
  TapPosition? _downPosition;
  TapPosition? _upPosition;
  TapPosition? _longPressPosition;
  Timer? _doubleTapTimer;
  int _consecutiveTaps = 0;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    final position = TapPosition(
      global: details.globalPosition,
      local: details.localPosition,
    );
    _downPosition = position;
    widget.controller?._updateDown(position, details);
    
    // Chamar o callback onTapDown se estiver definido no controller
    if (widget.controller is PositionedTapController) {
      final ptController = widget.controller as PositionedTapController;
      ptController.onTapDown?.call(details); // Passando TapDownDetails diretamente
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _upPosition = TapPosition(
      global: details.globalPosition,
      local: details.localPosition,
    );
    widget.controller?._updateUp(_upPosition!, details);
  }

  void _handleLongPress() {
    if (_downPosition == null) return;
    _longPressPosition = _downPosition;
    widget.onLongPress?.call(_longPressPosition!);
    
    // Chamar o callback onLongPress se estiver definido no controller
    if (widget.controller is PositionedTapController) {
      final ptController = widget.controller as PositionedTapController;
      ptController.onLongPress?.call(); // Não passa parâmetros
    }
  }

  void _handleTap() {
    if (_upPosition == null) return;
    
    _consecutiveTaps++;
    
    if (_consecutiveTaps == 1) {
      if (widget.onDoubleTap != null) {
        _doubleTapTimer = Timer(widget.doubleTapDelay, () {
          if (mounted && _consecutiveTaps == 1) {
            widget.onTap?.call(_upPosition!);
            
            // Chamar o callback onTap se estiver definido no controller
            if (widget.controller is PositionedTapController) {
              final ptController = widget.controller as PositionedTapController;
              ptController.onTap?.call(); // Não passa parâmetros
            }
          }
          _consecutiveTaps = 0;
        });
      } else {
        widget.onTap?.call(_upPosition!);
        
        // Chamar o callback onTap se estiver definido no controller
        if (widget.controller is PositionedTapController) {
          final ptController = widget.controller as PositionedTapController;
          ptController.onTap?.call(); // Não passa parâmetros
        }
        _consecutiveTaps = 0;
      }
    } else if (_consecutiveTaps == 2) {
      _doubleTapTimer?.cancel();
      widget.onDoubleTap?.call(_upPosition!);
      _consecutiveTaps = 0;
    }
  }

  void _handleSecondaryTap(TapUpDetails details) {
    if (widget.onSecondaryTap == null) return;
    
    final position = TapPosition(
      global: details.globalPosition,
      local: details.localPosition,
    );
    
    widget.onSecondaryTap?.call(position);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      onSecondaryTapUp: _handleSecondaryTap,
      child: widget.child,
    );
  }
}

typedef PositionCallback = void Function(TapPosition position);

// Classe para aplicar o patch
class PositionedTapDetectorFlutterMapPatch {
  static void apply() {
    // O simples fato de importar este arquivo já aplica o patch
    // pois as funções e classes são definidas globalmente
    print('PositionedTapDetector patch para flutter_map 3.1.0 aplicado com sucesso');
  }
}

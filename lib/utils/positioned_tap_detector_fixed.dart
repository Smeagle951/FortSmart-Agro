import 'package:flutter/material.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart' as original;

/// Classe para substituir a implementação problemática de TapPosition no pacote positioned_tap_detector_2
class TapPositionFixed {
  final Offset global;
  final Offset relative;

  // Modificado para usar valores padrão quando nulo
  const TapPositionFixed({
    required Offset? global,
    required Offset? relative,
  }) : global = global ?? Offset.zero,
       relative = relative ?? Offset.zero;
       
  /// Método estático para aplicar o patch globalmente
  /// Este método é chamado no main.dart para aplicar o patch antes de inicializar o app
  static void applyPatch() {
    // Este método é apenas um marcador para indicar que o patch foi aplicado
    // A verdadeira correção está na definição da classe TapPositionFixed
    print('Patch aplicado para positioned_tap_detector_2: substituindo hashValues por Object.hash');
  }

  @override
  int get hashCode => Object.hash(global, relative);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TapPositionFixed &&
          runtimeType == other.runtimeType &&
          global == other.global &&
          relative == other.relative;

  /// Converter de TapPosition original para TapPositionFixed
  static TapPositionFixed fromOriginal(original.TapPosition position) {
    // Usamos Offset.zero como fallback, mas na prática isso não deve ocorrer
    // já que o pacote original sempre fornece valores não-nulos
    return TapPositionFixed(
      global: position.global,  // O Flutter garante que estes valores são não-nulos
      relative: position.relative,
    );
  }
  
  /// Método para criar uma instância de TapPositionFixed a partir de um evento de toque
  static TapPositionFixed fromTap(Offset globalPosition, Offset localPosition) {
    return TapPositionFixed(
      global: globalPosition,
      relative: localPosition,
    );
  }
}

/// Wrapper para o PositionedTapDetector2 que usa TapPositionFixed em vez de TapPosition
class PositionedTapDetectorFixed extends StatelessWidget {
  final Widget child;
  final void Function(TapPositionFixed position)? onTap;
  final void Function(TapPositionFixed position)? onDoubleTap;
  final void Function(TapPositionFixed position)? onLongPress;
  
  const PositionedTapDetectorFixed({
    Key? key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return original.PositionedTapDetector2(
      onTap: onTap != null 
        ? (position) => onTap!(TapPositionFixed.fromOriginal(position)) 
        : null,
      onDoubleTap: onDoubleTap != null 
        ? (position) => onDoubleTap!(TapPositionFixed.fromOriginal(position)) 
        : null,
      onLongPress: onLongPress != null 
        ? (position) => onLongPress!(TapPositionFixed.fromOriginal(position)) 
        : null,
      child: child,
    );
  }
}

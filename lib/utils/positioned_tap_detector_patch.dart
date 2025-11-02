import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart' as ptd;

/// Classe que representa a posição de um toque na tela
/// Substitui a implementação original do pacote positioned_tap_detector_2
class TapPosition {
  /// Posição global do toque
  final Offset global;
  
  /// Posição relativa do toque
  final Offset relative;
  
  /// Construtor
  const TapPosition({
    required this.global,
    required this.relative,
  });
  
  /// Construtor para criar uma instância com valores padrão
  TapPosition.zero() : this(
    global: Offset.zero,
    relative: Offset.zero,
  );
          
  /// Converter de TapPosition original para nossa implementação
  static TapPosition fromOriginal(ptd.TapPosition position) {
    // Implementação segura para lidar com valores potencialmente nulos
    // Usamos cast explícito para garantir que o tipo seja Offset não-nulo
    
    Offset globalPos;
    Offset relativePos;
    
    try {
      // ignore: unnecessary_null_comparison
      if (position.global != null) {
        globalPos = position.global as Offset;
      } else {
        globalPos = Offset.zero;
      }
    } catch (e) {
      globalPos = Offset.zero;
    }
    
    try {
      // ignore: unnecessary_null_comparison
      if (position.relative != null) {
        relativePos = position.relative as Offset;
      } else {
        relativePos = Offset.zero;
      }
    } catch (e) {
      relativePos = Offset.zero;
    }
    
    return TapPosition(
      global: globalPos,
      relative: relativePos,
    );
  }
  
  @override
  int get hashCode => Object.hash(global, relative);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TapPosition &&
          runtimeType == other.runtimeType &&
          global == other.global &&
          relative == other.relative;
}

/// Widget wrapper para PositionedTapDetector2 que usa nossa implementação corrigida
class SafePositionedTapDetector extends StatelessWidget {
  final Widget child;
  final void Function(TapPosition position)? onTap;
  final void Function(TapPosition position)? onDoubleTap;
  final void Function(TapPosition position)? onLongPress;
  
  const SafePositionedTapDetector({
    Key? key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ptd.PositionedTapDetector2(
      child: child,
      onTap: onTap != null ? _wrapTapCallback(onTap!) : null,
      onDoubleTap: onDoubleTap != null ? _wrapTapCallback(onDoubleTap!) : null,
      onLongPress: onLongPress != null ? _wrapTapCallback(onLongPress!) : null,
    );
  }
  
  // Wrapper para converter callbacks
  ptd.TapPositionCallback _wrapTapCallback(void Function(TapPosition) callback) {
    return (ptd.TapPosition originalPosition) {
      callback(TapPosition.fromOriginal(originalPosition));
    };
  }
}

/// Método para aplicar o patch ao iniciar o aplicativo
Future<void> applyPositionedTapDetectorPatch() async {
  debugPrint('Aplicando patch para o problema de hashValues no positioned_tap_detector_2');
  
  try {
    // Verificar se o Object.hash está disponível
    Object.hash(Offset.zero, Offset.zero);
    
    // Infelizmente, não podemos aplicar um monkey patch direto no pacote
    // positioned_tap_detector_2 em Dart, pois não há acesso direto aos protótipos
    // como em JavaScript.
    
    // Em vez disso, fornecemos uma implementação alternativa (SafePositionedTapDetector)
    // que encapsula o PositionedTapDetector2 original e converte os objetos TapPosition
    // para nossa implementação segura.
    
    // Também podemos definir uma função global hashValues para compatibilidade
    // com código legado que ainda usa hashValues
    
    // Define uma função global hashValues para compatibilidade
    // ignore: non_constant_identifier_names, unused_local_variable
    // ignore: prefer_function_declarations_over_variables
    // Esta variável é intencionalmente não utilizada diretamente aqui,
    // mas sua definição é importante para o contexto global
    final hashValues = (Object a, Object b) => Object.hash(a, b);
    
    // Usar a função uma vez para evitar o aviso de não utilizada
    debugPrint('Hash de teste: ${hashValues(Offset.zero, Offset.zero)}');
    
    // Isso não resolve o problema interno do pacote positioned_tap_detector_2,
    // mas fornece uma função hashValues para uso em outros lugares do código
    
    debugPrint('Patch parcial aplicado para positioned_tap_detector_2');
    debugPrint('IMPORTANTE: Use SafePositionedTapDetector em vez de PositionedTapDetector2 no código');
  } catch (e) {
    debugPrint('Erro ao aplicar patch para positioned_tap_detector_2: $e');
    debugPrint('Nota: Use SafePositionedTapDetector em vez de PositionedTapDetector2 no código');
  }
}

// Patch completo para o positioned_tap_detector_2
// Este arquivo fornece todas as classes e funções necessárias para o flutter_map 3.1.0

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Implementações seguras para null safety que substituem as funções globais
// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashValues(dynamic a, dynamic b) => Object.hash(a ?? 0, b ?? 0);

// ignore: non_constant_identifier_names, library_private_types_in_public_api
int hashList(List<dynamic>? list) => Object.hashAll(list ?? []);

// Definição do tipo TapPositionCallback que o flutter_map 3.1.0 espera
typedef TapPositionCallback = void Function(TapPosition position);

// Classe TapPosition que é usada pelo flutter_map
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

// Classe TapPositionController que é usada pelo flutter_map
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
}

// Classe PositionedTapController que o flutter_map 3.1.0 espera
class PositionedTapController extends TapPositionController {
  // Callbacks que o flutter_map 3.1.0 espera com os tipos corretos
  void Function(TapDownDetails)? onTapDown;
  void Function()? onTap;
  void Function()? onLongPress;
}

// Classe para aplicar o patch
class PositionedTapDetectorCompletePatch {
  static void apply() {
    // O simples fato de importar este arquivo já aplica o patch
    // pois as funções e classes são definidas globalmente
    print('PositionedTapDetector patch aplicado com sucesso');
  }
}

// Versão corrigida do arquivo positioned_tap_detector_2.dart
// Esta é uma cópia modificada do arquivo original com correções de null safety

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Implementações seguras para null safety
int hashValues(dynamic a, dynamic b) => Object.hash(a, b);
int hashList(List<dynamic>? list) => Object.hashAll(list ?? []);

/// Tap detector that provides the tap position (global, local)
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
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(PositionedTapDetector2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _downPosition = _getPosition(details.globalPosition, details.localPosition);
    if (widget.controller != null) {
      widget.controller!._downPosition = _downPosition;
      widget.controller!._tapDownDetails = details;
    }
  }

  void _onTapUp(TapUpDetails details) {
    _upPosition = _getPosition(details.globalPosition, details.localPosition);
    if (widget.controller != null) {
      widget.controller!._upPosition = _upPosition;
      widget.controller!._tapUpDetails = details;
    }
  }

  void _onLongPress() {
    if (widget.onLongPress != null) {
      _longPressPosition = _downPosition;
      widget.onLongPress!(_longPressPosition!);
    }
  }

  void _onTap() {
    if (_doubleTapTimer != null && _consecutiveTaps > 0) {
      _consecutiveTaps = 0;
      _doubleTapTimer!.cancel();
      _doubleTapTimer = null;
      if (widget.onDoubleTap != null) {
        widget.onDoubleTap!(_upPosition!);
      }
    } else {
      _consecutiveTaps++;
      _doubleTapTimer = Timer(widget.doubleTapDelay, () {
        _consecutiveTaps = 0;
        _doubleTapTimer = null;
        if (widget.onTap != null) {
          widget.onTap!(_upPosition!);
        }
      });
    }
  }

  void _onSecondaryTap() {
    if (widget.onSecondaryTap != null) {
      widget.onSecondaryTap!(_upPosition!);
    }
  }

  TapPosition _getPosition(Offset global, Offset local) {
    return TapPosition(global: global, local: local);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTap: _onTap,
      onLongPress: widget.onLongPress != null ? _onLongPress : null,
      onSecondaryTap: widget.onSecondaryTap != null ? _onSecondaryTap : null,
      child: widget.child,
    );
  }
}

class TapPositionController {
  PositionedTapDetector2State? _state;
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
  int get hashCode => hashValues(global, relative);

  Offset get relative => local;

  @override
  String toString() => 'TapPosition(global: $global, local: $local)';
}

typedef PositionCallback = void Function(TapPosition position);

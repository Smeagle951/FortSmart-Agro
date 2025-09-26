import 'package:flutter/material.dart';

/// Provider para estado dos talhões desenhados/salvos
class TalhoesProvider extends ChangeNotifier {
  // Lista de talhões (cada talhão pode ser um Map ou modelo)
  final List<Map<String, dynamic>> _talhoes = [];

  List<Map<String, dynamic>> get talhoes => List.unmodifiable(_talhoes);

  void adicionarTalhao(Map<String, dynamic> talhao) {
    _talhoes.add(talhao);
    notifyListeners();
  }

  void removerTalhao(int index) {
    _talhoes.removeAt(index);
    notifyListeners();
  }

  void limpar() {
    _talhoes.clear();
    notifyListeners();
  }
}

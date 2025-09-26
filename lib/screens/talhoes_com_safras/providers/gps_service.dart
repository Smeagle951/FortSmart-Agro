import 'package:flutter/material.dart';

/// Serviço/Provider para gerenciamento do modo GPS (caminhada)
class GpsService extends ChangeNotifier {
  bool _caminhadaAtiva = false;
  List<Offset> _trilha = [];

  bool get caminhadaAtiva => _caminhadaAtiva;
  List<Offset> get trilha => List.unmodifiable(_trilha);

  void iniciarCaminhada() {
    _caminhadaAtiva = true;
    _trilha.clear();
    notifyListeners();
  }

  void adicionarPonto(Offset ponto) {
    if (_caminhadaAtiva) {
      _trilha.add(ponto);
      notifyListeners();
    }
  }

  void finalizarCaminhada() {
    _caminhadaAtiva = false;
    notifyListeners();
  }

  void cancelar() {
    _caminhadaAtiva = false;
    _trilha.clear();
    notifyListeners();
  }
}

import 'package:flutter/material.dart';

class SafraModel {
  final String id;
  final String nome;
  final String culturaId;
  final int anoInicio;
  final int anoFim;
  final bool ativa;

  SafraModel({
    required this.id,
    required this.nome,
    required this.culturaId,
    required this.anoInicio,
    required this.anoFim,
    this.ativa = true,
  });

  // Método para criar uma cópia com alterações
  SafraModel copyWith({
    String? id,
    String? nome,
    String? culturaId,
    int? anoInicio,
    int? anoFim,
    bool? ativa,
  }) {
    return SafraModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      culturaId: culturaId ?? this.culturaId,
      anoInicio: anoInicio ?? this.anoInicio,
      anoFim: anoFim ?? this.anoFim,
      ativa: ativa ?? this.ativa,
    );
  }

  // Método para converter para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'culturaId': culturaId,
      'anoInicio': anoInicio,
      'anoFim': anoFim,
      'ativa': ativa ? 1 : 0,
    };
  }

  // Método para criar a partir de Map (ao ler do banco)
  factory SafraModel.fromMap(Map<String, dynamic> map) {
    return SafraModel(
      id: map['id'],
      nome: map['nome'],
      culturaId: map['culturaId'],
      anoInicio: map['anoInicio'],
      anoFim: map['anoFim'],
      ativa: map['ativa'] == 1,
    );
  }
}

class SafraProvider with ChangeNotifier {
  final List<SafraModel> _safras = [
    SafraModel(
      id: '1',
      nome: 'Safra 2024/2025',
      culturaId: '1', // Soja
      anoInicio: 2024,
      anoFim: 2025,
      ativa: true,
    ),
    SafraModel(
      id: '2',
      nome: 'Safra 2023/2024',
      culturaId: '1', // Soja
      anoInicio: 2023,
      anoFim: 2024,
      ativa: false,
    ),
    SafraModel(
      id: '3',
      nome: 'Safra 2024/2025',
      culturaId: '2', // Milho
      anoInicio: 2024,
      anoFim: 2025,
      ativa: true,
    ),
    SafraModel(
      id: '4',
      nome: 'Safra 2024/2025',
      culturaId: '4', // Café
      anoInicio: 2024,
      anoFim: 2025,
      ativa: true,
    ),
  ];

  // Getter para todas as safras
  List<SafraModel> get safras => [..._safras];

  // Getter para safras ativas
  List<SafraModel> get safrasAtivas => _safras.where((safra) => safra.ativa).toList();

  // Getter para safras por cultura
  List<SafraModel> getSafrasPorCultura(String culturaId) {
    return _safras.where((safra) => safra.culturaId == culturaId).toList();
  }

  // Getter para safras ativas por cultura
  List<SafraModel> getSafrasAtivasPorCultura(String culturaId) {
    return _safras.where((safra) => safra.culturaId == culturaId && safra.ativa).toList();
  }

  // Buscar safra por ID
  SafraModel? findById(String id) {
    try {
      return _safras.firstWhere((safra) => safra.id == id);
    } catch (e) {
      return null;
    }
  }

  // Adicionar nova safra
  void addSafra(SafraModel safra) {
    _safras.add(safra);
    notifyListeners();
  }

  // Atualizar safra existente
  void updateSafra(SafraModel safra) {
    final index = _safras.indexWhere((s) => s.id == safra.id);
    if (index >= 0) {
      _safras[index] = safra;
      notifyListeners();
    }
  }

  // Remover safra
  void removeSafra(String id) {
    _safras.removeWhere((safra) => safra.id == id);
    notifyListeners();
  }

  // Duplicar safra com novo ano
  SafraModel duplicarSafra(String id, {int? novoAnoInicio, int? novoAnoFim}) {
    final safraOriginal = findById(id);
    if (safraOriginal == null) {
      throw Exception('Safra não encontrada');
    }

    final novoId = DateTime.now().millisecondsSinceEpoch.toString();
    final anoInicio = novoAnoInicio ?? (safraOriginal.anoInicio + 1);
    final anoFim = novoAnoFim ?? (safraOriginal.anoFim + 1);

    final novaSafra = SafraModel(
      id: novoId,
      nome: 'Safra $anoInicio/$anoFim',
      culturaId: safraOriginal.culturaId,
      anoInicio: anoInicio,
      anoFim: anoFim,
      ativa: true,
    );

    addSafra(novaSafra);
    return novaSafra;
  }

  // Carregar safras do banco de dados
  Future<void> carregarSafras() async {
    // Implementar lógica para carregar do banco de dados
    // Por enquanto, usamos os dados mockados
    notifyListeners();
  }
}

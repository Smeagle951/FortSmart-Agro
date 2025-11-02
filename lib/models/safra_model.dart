import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

/// Modelo para representar uma safra associada a um talhão
class SafraModel {
  final String id;
  final String talhaoId;
  final String safra; // Ex: "2024/2025"
  final String culturaId; // Referência ao ID da cultura no módulo Culturas
  final String culturaNome;
  final String culturaCor; // Cor em formato hexadecimal (ex: '#FF0000')
  
  // Novos campos obrigatórios
  final String periodo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final bool ativa;
  final String nome;

  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final bool sincronizado;

  var variedadeId;

  SafraModel({
    required this.id,
    required this.talhaoId,
    required this.safra,
    required this.culturaId,
    required this.culturaNome,
    required this.culturaCor,
    required this.dataCriacao,
    required this.dataAtualizacao,
    required this.sincronizado,
    required this.periodo,
    required this.dataInicio,
    required this.dataFim,
    required this.ativa,
    required this.nome,
  });

  /// Cria uma nova safra com valores padrão
  factory SafraModel.criar({
    required String talhaoId,
    required String safra,
    required String culturaId,
    required String culturaNome,
    required String culturaCor,
    bool sincronizado = false,
    String? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? ativa,
    String? nome,
  }) {
    final now = DateTime.now();
    final id = const Uuid().v4();

    return SafraModel(
      id: id,
      talhaoId: talhaoId,
      safra: safra,
      culturaId: culturaId,
      culturaNome: culturaNome,
      culturaCor: culturaCor,
      dataCriacao: now,
      dataAtualizacao: now,
      sincronizado: sincronizado,
      periodo: periodo ?? safra, // Usar safra como período se não fornecido
      dataInicio: dataInicio ?? now, // Data atual como início se não fornecida
      dataFim: dataFim ?? now.add(const Duration(days: 365)), // Um ano após como fim se não fornecida
      ativa: ativa ?? true, // Ativa por padrão
      nome: nome ?? culturaNome, // Nome da cultura como nome se não fornecido
    );
  }

  /// Cria uma cópia da safra com alguns valores alterados
  SafraModel copyWith({
    String? id,
    String? talhaoId,
    String? safra,
    String? culturaId,
    String? culturaNome,
    String? culturaCor,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? sincronizado,
    String? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? ativa,
    String? nome,
  }) {
    return SafraModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      safra: safra ?? this.safra,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      culturaCor: culturaCor ?? this.culturaCor,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      sincronizado: sincronizado ?? this.sincronizado,
      periodo: periodo ?? this.periodo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      ativa: ativa ?? this.ativa,
      nome: nome ?? this.nome,
    );
  }

  /// Converte a safra para um mapa (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhaoId': talhaoId,
      'safra': safra,
      'culturaId': culturaId,
      'culturaNome': culturaNome,
      'culturaCor': culturaCor,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'sincronizado': sincronizado,
      'periodo': periodo,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
      'ativa': ativa,
      'nome': nome,
    };
  }

  /// Cria uma safra a partir de um mapa (para carregar do banco de dados)
  factory SafraModel.fromMap(Map<String, dynamic> map) {
    // Converter valor de cor para string hexadecimal se necessário
    String corValue;
    if (map['culturaCor'] is int) {
      // Se for um valor inteiro (Color.value), converte para string hexadecimal
      corValue = '#${(map['culturaCor'] & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    } else {
      // Se já for string, usa diretamente
      corValue = map['culturaCor'] as String;
    }
    
    final now = DateTime.now();
    
    return SafraModel(
      id: map['id'],
      talhaoId: map['talhaoId'],
      safra: map['safra'],
      culturaId: map['culturaId'],
      culturaNome: map['culturaNome'],
      culturaCor: corValue,
      dataCriacao: DateTime.parse(map['dataCriacao']),
      dataAtualizacao: DateTime.parse(map['dataAtualizacao']),
      sincronizado: map['sincronizado'] ?? false,
      periodo: map['periodo'] ?? map['safra'],
      dataInicio: map['dataInicio'] != null ? DateTime.parse(map['dataInicio']) : now,
      dataFim: map['dataFim'] != null ? DateTime.parse(map['dataFim']) : now.add(const Duration(days: 365)),
      ativa: map['ativa'] ?? true,
      nome: map['nome'] ?? map['culturaNome'],
    );
  }
  
  /// Construtor para compatibilidade com código legado
  /// Fornece valores padrão para todos os parâmetros obrigatórios
  factory SafraModel.fromLegacy({
    String? id,
    String? talhaoId,
    String? safra,
    String? culturaId,
    String? culturaNome,
    dynamic culturaCor,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? sincronizado,
    String? periodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? ativa,
    String? nome,
  }) {
    final now = DateTime.now();
    
    // Converter cor para string hexadecimal
    String corHex;
    if (culturaCor is Color) {
      corHex = '#${(culturaCor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    } else if (culturaCor is String) {
      corHex = culturaCor;
    } else {
      corHex = '#4CAF50'; // Verde padrão em hexadecimal
    }
    
    final safraNome = safra ?? 'Safra atual';
    final culturaNomeFinal = culturaNome ?? 'Cultura não especificada';
    
    return SafraModel(
      id: id ?? const Uuid().v4(),
      talhaoId: talhaoId ?? '',
      safra: safraNome,
      culturaId: culturaId ?? '',
      culturaNome: culturaNomeFinal,
      culturaCor: corHex,
      dataCriacao: dataCriacao ?? now,
      dataAtualizacao: dataAtualizacao ?? now,
      sincronizado: sincronizado ?? false,
      periodo: periodo ?? safraNome,
      dataInicio: dataInicio ?? now,
      dataFim: dataFim ?? now.add(const Duration(days: 365)),
      ativa: ativa ?? true,
      nome: nome ?? culturaNomeFinal,
    );
  }

  /// Retorna um ícone representativo da cultura
  String get icone {
    final culturaLower = culturaNome.toLowerCase();
    
    if (culturaLower.contains('soja')) {
      return '🌱'; // Broto - Soja
    } else if (culturaLower.contains('milho')) {
      return '🌽'; // Milho 
    } else if (culturaLower.contains('algodão') || culturaLower.contains('algodao')) {
      return '☁️'; // Nuvem - Algodão
    } else if (culturaLower.contains('girassol')) {
      return '🌻'; // Girassol
    } else if (culturaLower.contains('sorgo') || culturaLower.contains('trigo')) {
      return '🌾'; // Trigo
    } else if (culturaLower.contains('feijão') || culturaLower.contains('feijao')) {
      return '🪖'; // Feijão 
    } else if (culturaLower.contains('arroz')) {
      return '🍚'; // Arroz
    } else if (culturaLower.contains('café') || culturaLower.contains('cafe')) {
      return '☕'; // Café
    } else if (culturaLower.contains('cana')) {
      return '🎟'; // Cana
    } else {
      return '📎'; // Outros
    }
  }

  // O período agora é um campo próprio da classe
  // Não é mais necessário o getter
  
  /// Converte a string hexadecimal para um objeto Color
  Color get cor {
    try {
      if (culturaCor.startsWith('#')) {
        return Color(int.parse('FF${culturaCor.substring(1)}', radix: 16));
      } else {
        // Tenta converter diretamente se não começar com #
        return Color(int.parse(culturaCor));
      }
    } catch (e) {
      // Retorna uma cor padrão em caso de erro
      return Colors.green;
    }
  }
}

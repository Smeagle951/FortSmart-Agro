import 'package:flutter/material.dart';
import '../models/cultura_model.dart';
import '../models/talhoes/talhao_safra_model.dart';
import '../models/agricultural_product_model.dart';

/// Classe utilitária para adaptar diferentes representações de culturas
/// Facilita a conversão entre CulturaModel, CulturaFazendaModel e AgriculturalProduct
/// e padroniza o acesso aos campos nome/name
class CulturaAdapter {
  /// Converte um CulturaModel para um CulturaFazendaModel
  static CulturaFazendaModel toCulturaFazenda(CulturaModel cultura, String idFazenda) {
    // Usar cor verde padrão para todos os polígonos (sem cores por cultura)
    final colorHex = '#4CAF50'; // Verde padrão
    
    return CulturaFazendaModel(
      id: cultura.id,
      idFazenda: idFazenda,
      name: cultura.name, // Usa o getter 'name' que retorna 'nome'
      corHex: colorHex,
      ativa: true,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
    );
  }

  /// Converte um CulturaFazendaModel para um CulturaModel
  static CulturaModel toCulturaModel(CulturaFazendaModel culturaFazenda) {
    // Converter a cor para o formato esperado pelo CulturaModel
    String corStr = culturaFazenda.corHex;
    if (corStr.startsWith('#')) {
      corStr = '0xFF${corStr.substring(1)}';
    }
    
    return CulturaModel(
      id: culturaFazenda.id,
      nome: culturaFazenda.name, // Usa o campo padronizado 'name'
      cor: corStr,
      descricao: 'Cultura da fazenda: ${culturaFazenda.idFazenda}',
      tags: ['cultura_fazenda', culturaFazenda.idFazenda],
    );
  }

  /// Converte um AgriculturalProduct para um CulturaModel
  static CulturaModel fromAgriculturalProduct(AgriculturalProduct product) {
    // Converter a cor para string
    String corStr;
    if (product.color is Color) {
      final colorValue = (product.color as Color).value.toRadixString(16).substring(2);
      corStr = '0xFF$colorValue';
    } else if (product.color is String) {
      final colorString = product.color.toString();
      if (colorString.startsWith('#')) {
        corStr = '0xFF${colorString.substring(1)}';
      } else {
        corStr = colorString;
      }
    } else {
      corStr = '0xFF2E7D66'; // Cor padrão
    }
    
    return CulturaModel(
      id: product.id,
      nome: product.name,
      descricao: product.description,
      cor: corStr,
      tags: product.tags,
    );
  }

  /// Converte um CulturaModel para um AgriculturalProduct
  static AgriculturalProduct toAgriculturalProduct(CulturaModel cultura) {
    // Usar o getter color que já converte a string para Color
    final color = cultura.color;
    
    return AgriculturalProduct(
      id: cultura.id,
      name: cultura.name, // Usa o getter 'name' que retorna 'nome'
      description: cultura.descricao ?? '',
      color: color,
      type: 'culture',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: cultura.tags,
    );
  }

  /// Cria um CulturaModel com valores padrão
  static CulturaModel createDefault({
    String? id,
    String? nome,
    String? descricao,
    String? cor,
    List<String>? tags,
  }) {
    return CulturaModel(
      id: id,
      nome: nome ?? 'Nova Cultura',
      descricao: descricao,
      cor: cor ?? '0xFF2E7D66', // Cor verde padrão
      tags: tags ?? [],
    );
  }

  /// Converte uma lista de mapas para uma lista de CulturaModel
  static List<CulturaModel> listFromMaps(List<dynamic>? mapList) {
    if (mapList == null) return [];
    
    return mapList
        .map((item) {
          if (item is Map<String, dynamic>) {
            return CulturaModel(
              id: item['id'],
              nome: item['nome'] ?? item['name'] ?? '',
              descricao: item['descricao'],
              ciclo: item['ciclo'],
              tipo: item['tipo'],
              cor: item['cor']?.toString() ?? '0xFF2E7D66',
              parentId: item['parentId'],
              tags: item['tags'] != null 
                  ? item['tags'].toString().split(',') 
                  : [],
            );
          }
          return createDefault();
        })
        .toList();
  }
}

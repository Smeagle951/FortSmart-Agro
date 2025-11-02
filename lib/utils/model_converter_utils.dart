import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/poligono_model.dart';
import '../models/crop.dart' as app_crop;
import '../database/models/crop.dart' as db_crop;
import '../models/agricultural_product.dart';

/// Extensões para facilitar a conversão entre modelos
extension AgriculturalProductExtensions on AgriculturalProduct {
  /// Converte um AgriculturalProduct para app_crop.Crop
  app_crop.Crop toAppCrop() => ModelConverterUtils.agriculturalProductToAppCrop(this);
}

/// Extensões para facilitar a conversão entre modelos
extension AppCropExtensions on app_crop.Crop {
  /// Converte um app_crop.Crop para AgriculturalProduct
  AgriculturalProduct toAgriculturalProduct() => ModelConverterUtils.appCropToAgriculturalProduct(this);
}

/// Extensões para facilitar a conversão entre modelos
extension DbCropExtensions on db_crop.Crop {
  /// Converte um db_crop.Crop para app_crop.Crop
  app_crop.Crop toAppCrop() => ModelConverterUtils.dbCropToAppCrop(this);
  
  /// Converte um db_crop.Crop para AgriculturalProduct
  AgriculturalProduct toAgriculturalProduct() => ModelConverterUtils.dbCropToAgriculturalProduct(this);
}

/// Utilitário para conversão entre diferentes modelos de dados
/// Resolve problemas de incompatibilidade entre tipos no projeto
class ModelConverterUtils {
  /// Converte um modelo db_crop.Crop para AgriculturalProduct (fallback para CropSelector)
  static AgriculturalProduct dbCropToAgriculturalProduct(db_crop.Crop dbCrop) {
    return AgriculturalProduct(
      id: dbCrop.id.toString(),
      name: dbCrop.name,
      notes: dbCrop.scientificName, // Usando scientificName como notes (campo válido)
      // description removido pois não existe em AgriculturalProduct,
      type: ProductType.seed, // fallback assume tipo semente
      colorValue: dbCrop.cor.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: dbCrop.isSynced,
      // iconPath removido pois não existe em db_crop.Crop,
    );
  }
  /// Converte uma lista de pontos LatLng para um modelo de Polígono
  static PoligonoModel latLngListToPoligono(List<LatLng> pontos, String talhaoId) {
    // O construtor PoligonoModel.criar espera uma String para talhaoId
    return PoligonoModel.criar(
      pontos: pontos,
      talhaoId: talhaoId,
    );
  }

  /// Converte uma lista de listas de pontos LatLng para uma lista de modelos de Polígono
  static List<PoligonoModel> latLngListsToPoligonos(List<List<LatLng>> poligonos, String talhaoId) {
    return poligonos.map((pontos) => latLngListToPoligono(pontos, talhaoId)).toList();
  }

  /// Converte um modelo de cultura do banco de dados para o modelo de aplicação
  static app_crop.Crop dbCropToAppCrop(db_crop.Crop dbCrop) {
    // O modelo db_crop.Crop tem um getter 'cor' que retorna um int
    final int colorVal = dbCrop.cor; // Usando o getter 'cor' que retorna um int
    
    // Converter o ID de String para int? conforme esperado pelo construtor
    int? idInt;
    try {
      idInt = int.tryParse(dbCrop.id.toString());
    } catch (e) {
      // Em caso de erro, mantém null
      idInt = null;
    }
    
    return app_crop.Crop(
      id: idInt,
      name: dbCrop.name,
      description: dbCrop.description,
      colorValue: colorVal,
    );
  }

  /// Converte um AgriculturalProduct para o modelo Crop da aplicação
  static app_crop.Crop agriculturalProductToAppCrop(AgriculturalProduct product) {
    // Convertendo o ID para String e o colorValue (que é String) para int
    int colorVal = Colors.green.value;
    if (product.colorValue != null && product.colorValue!.isNotEmpty) {
      try {
        // Tenta converter o valor hexadecimal para int
        if (product.colorValue!.startsWith('0x')) {
          colorVal = int.parse(product.colorValue!);
        } else if (product.colorValue!.startsWith('#')) {
          colorVal = int.parse('0xFF${product.colorValue!.substring(1)}');
        } else {
          colorVal = int.parse('0xFF${product.colorValue!}');
        }
      } catch (e) {
        // Mantém o valor padrão em caso de erro
      }
    }
    
    return app_crop.Crop(
      id: int.tryParse(product.id.toString()),
      name: product.name,
      description: product.description ?? product.notes ?? '',
      // scientificName removido pois não existe em AgriculturalProduct,
      colorValue: colorVal,
      iconPath: product.iconPath,
      isSynced: product.isSynced,
      isDefault: false,
    );
  }
  
  /// Converte um modelo Crop da aplicação para AgriculturalProduct
  static AgriculturalProduct appCropToAgriculturalProduct(app_crop.Crop crop) {
    // Convertendo o colorValue (que é int) para String
    String colorString = '';
    if (crop.colorValue != null) {
      try {
        // Converte o valor int para string hexadecimal
        colorString = '#${crop.colorValue!.toRadixString(16).padLeft(8, '0').substring(2)}';
      } catch (e) {
        // Mantém o valor padrão em caso de erro
      }
    }
    
    return AgriculturalProduct(
      id: crop.id?.toString() ?? '0',
      name: crop.name,
      // description removido pois não existe em AgriculturalProduct,
      notes: crop.description,
      // scientificName removido pois não existe em AgriculturalProduct,
      type: ProductType.seed, // Assume tipo semente como padrão
      colorValue: colorString,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: crop.isSynced ?? false,
      iconPath: crop.iconPath,
    );
  }

  /// Converte um modelo Crop da aplicação para String (para compatibilidade com seletores)
  static String appCropToString(app_crop.Crop? crop) {
    return crop?.id.toString() ?? '';
  }

  /// Converte uma String para um modelo Crop da aplicação (para compatibilidade com seletores)
  static app_crop.Crop? stringToAppCrop(String? cropId, List<app_crop.Crop> crops) {
    if (cropId == null || cropId.isEmpty) return null;
    try {
      return crops.firstWhere(
        (crop) => crop.id.toString() == cropId,
        orElse: () => _createDefaultCrop(cropId),
      );
    } catch (e) {
      // Criação de um modelo de fallback em caso de erro
      return _createDefaultCrop(cropId);
    }
  }
  
  /// Cria um modelo Crop padrão com valores seguros
  static app_crop.Crop _createDefaultCrop(String id) {
    // Usando o valor int diretamente para colorValue
    final int colorVal = Colors.grey.value;
    
    // Converter o ID de String para int? conforme esperado pelo construtor
    int? idInt;
    try {
      idInt = int.tryParse(id);
    } catch (e) {
      // Em caso de erro, mantém null
      idInt = null;
    }
    
    return app_crop.Crop(
      id: idInt,
      name: 'Cultura não encontrada',
      description: '',
      colorValue: colorVal,
    );
  }

  /// Obtém a cor associada a uma cultura
  static Color getCropColor(app_crop.Crop? crop) {
    if (crop == null || crop.colorValue == null) {
      return Colors.green;
    }
    return Color(crop.colorValue!);
  }

  /// Verifica se um valor é nulo e retorna um valor padrão se for
  static T valueOrDefault<T>(T? value, T defaultValue) {
    return value ?? defaultValue;
  }

  /// Converte um valor para boolean com segurança
  static bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || 
             value == '1' || 
             value.toLowerCase() == 'sim' ||
             value.toLowerCase() == 'yes';
    }
    return false;
  }
}

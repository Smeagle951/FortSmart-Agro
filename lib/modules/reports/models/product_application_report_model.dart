import '../../../modules/product_application/models/product_application_model.dart';

/// Modelo para o relatório de gasto de produtos por aplicação
class ProductApplicationReportModel {
  /// Data de início do período de filtro
  final DateTime? startDate;
  
  /// Data de fim do período de filtro
  final DateTime? endDate;
  
  /// Cultura aplicada para filtro (opcional)
  final String? cropName;
  
  /// Talhão para filtro (opcional)
  final String? fieldName;
  
  /// Produto utilizado para filtro (opcional)
  final String? productName;
  
  /// Responsável pela aplicação para filtro (opcional)
  final String? responsiblePerson;
  
  /// Lista de aplicações incluídas no relatório
  final List<ProductApplicationModel> applications;
  
  /// Nome da propriedade/fazenda
  final String farmName;
  
  /// Data e hora da geração do relatório
  final DateTime generationDate;

  ProductApplicationReportModel({
    this.startDate,
    this.endDate,
    this.cropName,
    this.fieldName,
    this.productName,
    this.responsiblePerson,
    required this.applications,
    required this.farmName,
    DateTime? generationDate,
  }) : this.generationDate = generationDate ?? DateTime.now();

  /// Retorna as aplicações filtradas com base nos critérios do relatório
  List<ProductApplicationModel> get filteredApplications {
    List<ProductApplicationModel> result = List.from(applications);
    
    if (startDate != null && endDate != null) {
      result = result.where((a) => 
        a.applicationDate != null && 
        a.applicationDate!.isAfter(startDate!) && 
        a.applicationDate!.isBefore(endDate!.add(const Duration(days: 1)))).toList();
    } else if (startDate != null) {
      result = result.where((a) => 
        a.applicationDate != null && 
        a.applicationDate!.isAfter(startDate!)).toList();
    } else if (endDate != null) {
      result = result.where((a) => 
        a.applicationDate != null && 
        a.applicationDate!.isBefore(endDate!.add(const Duration(days: 1)))).toList();
    }
    
    if (cropName?.isNotEmpty ?? false) {
      result = result.where((a) => 
        a.cropName != null && 
        a.cropName!.toLowerCase().contains(cropName?.toLowerCase() ?? '')).toList();
    }
    
    if (fieldName?.isNotEmpty ?? false) {
      result = result.where((a) => 
        a.plotName != null && 
        a.plotName!.toLowerCase().contains(fieldName?.toLowerCase() ?? '')).toList();
    }
    
    if (productName?.isNotEmpty ?? false) {
      result = result.where((a) => 
        a.products != null && 
        a.products!.any((p) => 
          p.productName != null && 
          p.productName!.toLowerCase().contains(productName?.toLowerCase() ?? '')
        )).toList();
    }
    
    if (responsiblePerson?.isNotEmpty ?? false) {
      result = result.where((a) => 
        a.responsibleName != null && 
        a.responsibleName!.toLowerCase().contains(responsiblePerson?.toLowerCase() ?? '')).toList();
    }
    
    return result;
  }

  /// Calcula o custo total das aplicações
  double get totalApplicationCost {
    double total = 0.0;
    for (var application in filteredApplications) {
      if (application.products == null) continue;
      
      for (var product in application.products!) {
        if (product.totalDose == null || product.dosePerHectare == null) continue;
        total += (product.totalDose! * product.dosePerHectare!);
      }
    }
    return total;
  }
}

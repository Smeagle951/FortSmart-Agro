import 'package:intl/intl.dart';
import '../database/models/inventory.dart' as db;

/// Modelo para representar um item no estoque (produto agrícola)
/// Esta classe serve como adaptador para o modelo de banco de dados
class InventoryItem {
  final String? id;
  final String name;
  final String type; // Herbicida, Inseticida, Fungicida, etc.
  final String formulation; // SC, EC, WG, etc.
  final String unit; // L, kg, g, etc.
  final double quantity;
  final String location;
  final DateTime? expirationDate;
  final String? manufacturer;
  final double? minimumLevel;
  final String? registrationNumber;
  final String? pdfPath;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category; // Adicionando a propriedade category

  InventoryItem({
    this.id,
    required this.name,
    required this.type,
    required this.formulation,
    required this.unit,
    required this.quantity,
    required this.location,
    this.expirationDate,
    this.manufacturer,
    this.minimumLevel,
    this.registrationNumber,
    this.pdfPath,
    this.syncStatus = 0,
    this.category, // Adicionando o parâmetro category
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do item com valores atualizados
  InventoryItem copyWith({
    String? id,
    String? name,
    String? type,
    String? formulation,
    String? unit,
    double? quantity,
    String? location,
    DateTime? expirationDate,
    String? manufacturer,
    double? minimumLevel,
    String? registrationNumber,
    String? pdfPath,
    int? syncStatus,
    String? category, // Adicionando o parâmetro category
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      formulation: formulation ?? this.formulation,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      expirationDate: expirationDate ?? this.expirationDate,
      manufacturer: manufacturer ?? this.manufacturer,
      minimumLevel: minimumLevel ?? this.minimumLevel,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      pdfPath: pdfPath ?? this.pdfPath,
      syncStatus: syncStatus ?? this.syncStatus,
      category: category ?? this.category, // Adicionando o parâmetro category
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte o item para um mapa (para armazenamento no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id != null ? int.tryParse(id!) : null,
      'name': name,
      'type': type,
      'formulation': formulation,
      'unit': unit,
      'quantity': quantity,
      'location': location,
      'expiration_date': expirationDate != null ? DateFormat('yyyy-MM-dd').format(expirationDate!) : null,
      'manufacturer': manufacturer,
      'minimum_level': minimumLevel,
      'registration_number': registrationNumber,
      'pdf_path': pdfPath,
      'sync_status': syncStatus,
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
      'updated_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(updatedAt),
      'category': category ?? type, // Mapeando category para compatibilidade
    };
  }

  /// Cria um item a partir de um mapa (do banco de dados)
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id']?.toString(),
      name: map['name'],
      type: map['type'] ?? map['category'] ?? '',
      formulation: map['formulation'] ?? '',
      unit: map['unit'],
      quantity: map['quantity'],
      location: map['location'] ?? '',
      expirationDate: map['expiration_date'] != null 
          ? (map['expiration_date'] is String 
              ? DateFormat('yyyy-MM-dd').parse(map['expiration_date']) 
              : map['expiration_date'])
          : null,
      manufacturer: map['manufacturer'],
      minimumLevel: map['minimum_level'],
      registrationNumber: map['registration_number'],
      pdfPath: map['pdf_path'],
      syncStatus: map['sync_status'] ?? 0,
      category: map['category'], // Adicionando a propriedade category
      createdAt: map['created_at'] is String 
          ? DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] is String 
          ? DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  /// Cria um objeto InventoryItem a partir de um modelo de banco de dados
  static InventoryItem fromDbModel(db.InventoryItem dbItem) {
    return InventoryItem(
      id: dbItem.id?.toString(),
      name: dbItem.name,
      type: dbItem.type ?? 'Não especificado',
      formulation: dbItem.formulation ?? 'Não especificado',
      unit: dbItem.unit,
      quantity: dbItem.quantity,
      location: dbItem.location ?? 'Não especificado',
      expirationDate: dbItem.expirationDate != null ? DateTime.tryParse(dbItem.expirationDate!) : null,
      manufacturer: dbItem.manufacturer,
      minimumLevel: dbItem.minimumLevel,
      registrationNumber: dbItem.registrationNumber,
      pdfPath: dbItem.pdfPath,
      syncStatus: dbItem.syncStatus,
      category: dbItem.category,
      createdAt: DateTime.tryParse(dbItem.createdAt),
      updatedAt: DateTime.tryParse(dbItem.updatedAt),
    );
  }

  /// Converte para o modelo de banco de dados
  db.InventoryItem toDbModel() {
    return db.InventoryItem(
      id: id != null ? int.tryParse(id!) : null,
      name: name,
      category: category ?? type, // Mapeando category para compatibilidade
      type: type,
      formulation: formulation,
      unit: unit,
      quantity: quantity,
      location: location,
      expirationDate: expirationDate?.toIso8601String(),
      manufacturer: manufacturer,
      minimumLevel: minimumLevel,
      registrationNumber: registrationNumber,
      pdfPath: pdfPath,
      createdAt: createdAt.toIso8601String(),
      updatedAt: updatedAt.toIso8601String(),
      syncStatus: syncStatus,
    );
  }

  /// Verifica se o produto está próximo da validade
  bool isNearExpiration() {
    if (expirationDate == null) return false;
    
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 30 && daysUntilExpiration > 0;
  }

  /// Verifica se o produto está vencido
  bool isExpired() {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  /// Verifica se o estoque está abaixo do nível mínimo
  bool isBelowMinimumLevel() {
    if (minimumLevel == null) return false;
    return quantity <= minimumLevel!;
  }

  /// Verifica se o estoque está baixo
  bool isLowStock() {
    return minimumLevel != null && quantity <= minimumLevel!;
  }

  /// Getter para compatibilidade com código legado
  double get minimumStock => minimumLevel ?? 0.0;

  /// Retorna o nome completo do produto com formulação
  String getFullName() {
    return '$name $formulation';
  }

  /// Retorna a quantidade formatada com unidade
  String getFormattedQuantity() {
    return '${quantity.toStringAsFixed(2)} $unit';
  }
}

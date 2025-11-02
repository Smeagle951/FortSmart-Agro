class PragaImage {
  final int? id;
  final String imageBase64;
  final String colorHex;
  final int? cropId;
  final int? pestId;
  final int? diseaseId;
  final int? weedId;
  final DateTime createdAt;

  PragaImage({
    this.id,
    required this.imageBase64,
    required this.colorHex,
    this.cropId,
    this.pestId,
    this.diseaseId,
    this.weedId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_base64': imageBase64,
      'color_hex': colorHex,
      'crop_id': cropId,
      'pest_id': pestId,
      'disease_id': diseaseId,
      'weed_id': weedId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PragaImage.fromMap(Map<String, dynamic> map) {
    return PragaImage(
      id: map['id'],
      imageBase64: map['image_base64'],
      colorHex: map['color_hex'],
      cropId: map['crop_id'],
      pestId: map['pest_id'],
      diseaseId: map['disease_id'],
      weedId: map['weed_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
} 
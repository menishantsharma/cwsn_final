class SubcategoryModel {
  final int id;
  final String name;
  final String? shortDescription;
  final String? imageUrl;

  SubcategoryModel({
    required this.id,
    required this.name,
    this.shortDescription,
    this.imageUrl,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      shortDescription: json['short_description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

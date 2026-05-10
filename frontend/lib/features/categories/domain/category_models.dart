class CategoryModel {
  final int id;
  final String name;
  final String? imageUrl;
  final String? shortDescription;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.shortDescription,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      shortDescription: json['short_description'] as String?,
    );
  }
}

class SubcategoryModel {
  final int id;
  final String name;
  final String? shortDescription;
  final String? imageUrl;
  final int categoryId;

  const SubcategoryModel({
    required this.id,
    required this.name,
    this.shortDescription,
    this.imageUrl,
    required this.categoryId,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      shortDescription: json['short_description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category'] as int,
    );
  }
}

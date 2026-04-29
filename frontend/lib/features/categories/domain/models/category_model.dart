import 'package:frontend/features/categories/domain/models/subcategory_model.dart';

class CategoryModel {
  final int id;
  final String name;
  final String? imageUrl;
  final String? shortDescription;
  final List<SubcategoryModel> subcategories;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.shortDescription,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      subcategories: (json['subcategories'] as List<dynamic>)
          .map(
            (subcategoryJson) => SubcategoryModel.fromJson(
              subcategoryJson as Map<String, dynamic>,
            ),
          )
          .toList(),
      shortDescription: json['short_description'] as String?,
    );
  }
}

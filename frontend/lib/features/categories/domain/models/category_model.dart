class CategoryModel {
  final int id;
  final String name;
  final String? imageUrl;
  final String? shortDescription;

  CategoryModel({
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

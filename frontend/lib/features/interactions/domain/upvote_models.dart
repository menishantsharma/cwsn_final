class UpvoteModel {
  final int id;
  final int serviceId;

  const UpvoteModel({required this.id, required this.serviceId});

  factory UpvoteModel.fromJson(Map<String, dynamic> json) {
    return UpvoteModel(
      id: json['id'] as int,
      serviceId: json['service'] as int,
    );
  }
}

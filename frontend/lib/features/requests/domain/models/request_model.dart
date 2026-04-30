class RequestModel {
  final int id;
  final int serviceId;
  final String serviceTitle;
  final int childId;
  final String childName;
  final int childAge;
  final String childGender;
  final String status;
  final String? note;
  final String cwsnUserName;
  final String? caregiverPhone;
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.childId,
    required this.childName,
    required this.childAge,
    required this.childGender,
    required this.status,
    this.note,
    required this.cwsnUserName,
    this.caregiverPhone,
    required this.createdAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as int,
      serviceId: json['service'] as int,
      serviceTitle: json['service_title'] as String,
      childId: json['child'] as int,
      childName: json['child_name'] as String,
      childAge: json['child_age'] as int,
      childGender: json['child_gender'] as String,
      status: json['status'] as String,
      note: json['note'] as String?,
      cwsnUserName: json['cwsn_user_name'] as String,
      caregiverPhone: json['caregiver_phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  RequestModel copyWith({String? status}) {
    return RequestModel(
      id: id,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      childId: childId,
      childName: childName,
      childAge: childAge,
      childGender: childGender,
      status: status ?? this.status,
      note: note,
      cwsnUserName: cwsnUserName,
      caregiverPhone: caregiverPhone,
      createdAt: createdAt,
    );
  }
}

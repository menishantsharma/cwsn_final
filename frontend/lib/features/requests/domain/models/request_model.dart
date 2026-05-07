class RequestModel {
  final int id;
  final int serviceId;
  final String serviceTitle;
  final int childId;
  final String childName;
  final int childAge;
  final String childGender;
  final int cwsnUserId;
  final String cwsnUserName;
  final String? cwsnUserPhone;
  final int caregiverId;
  final String caregiverName;
  final String? caregiverPhone;
  final String status;
  final String? note;
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.childId,
    required this.childName,
    required this.childAge,
    required this.childGender,
    required this.cwsnUserId,
    required this.cwsnUserName,
    this.cwsnUserPhone,
    required this.caregiverId,
    required this.caregiverName,
    this.caregiverPhone,
    required this.status,
    this.note,
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
      cwsnUserId: json['cwsn_user'] as int,
      cwsnUserName: json['cwsn_user_name'] as String,
      cwsnUserPhone: json['cwsn_user_phone'] as String?,
      caregiverId: json['caregiver'] as int,
      caregiverName: json['caregiver_name'] as String,
      caregiverPhone: json['caregiver_phone'] as String?,
      status: json['status'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  RequestModel copyWith({
    String? status,
    String? caregiverPhone,
    String? cwsnUserPhone,
  }) {
    return RequestModel(
      id: id,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      childId: childId,
      childName: childName,
      childAge: childAge,
      childGender: childGender,
      cwsnUserId: cwsnUserId,
      cwsnUserName: cwsnUserName,
      cwsnUserPhone: cwsnUserPhone ?? this.cwsnUserPhone,
      caregiverId: caregiverId,
      caregiverName: caregiverName,
      caregiverPhone: caregiverPhone ?? this.caregiverPhone,
      status: status ?? this.status,
      note: note,
      createdAt: createdAt,
    );
  }
}

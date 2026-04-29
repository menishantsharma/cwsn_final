class CaregiverProfileModel {
  final int id;
  final String name;
  final String? gender;
  final String? aboutMe;
  final String? qualifications;
  final List<String> languages;
  final int upvoteCount;

  CaregiverProfileModel({
    required this.id,
    required this.name,
    this.gender,
    this.aboutMe,
    this.qualifications,
    required this.languages,
    required this.upvoteCount,
  });

  factory CaregiverProfileModel.fromJson(Map<String, dynamic> json) {
    return CaregiverProfileModel(
      id: json['id'] as int,
      name: json['name'] as String,
      gender: json['gender'] as String?,
      aboutMe: json['about_me'] as String?,
      qualifications: json['qualifications'] as String?,
      languages: List<String>.from(json['languages'] ?? []),
      upvoteCount: json['upvote_count'] as int,
    );
  }
}

class ServiceModel {
  final int id;
  final String title;
  final String? description;
  final String? image;
  final String serviceType;
  final String paymentType;
  final int upvoteCount;
  final int? targetAgeMin;
  final int? targetAgeMax;
  final String targetGender;
  final CaregiverProfileModel? caregiverProfile;

  ServiceModel({
    required this.id,
    required this.title,
    this.description,
    this.image,
    required this.serviceType,
    required this.paymentType,
    required this.upvoteCount,
    this.targetAgeMin,
    this.targetAgeMax,
    required this.targetGender,
    this.caregiverProfile,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      serviceType: json['service_type'] as String,
      paymentType: json['payment_type'] as String,
      upvoteCount: json['upvote_count'] as int,
      targetAgeMin: json['target_age_min'] as int?,
      targetAgeMax: json['target_age_max'] as int?,
      targetGender: json['target_gender'] as String,
      caregiverProfile: json['caregiver_profile'] != null
          ? CaregiverProfileModel.fromJson(json['caregiver_profile'])
          : null,
    );
  }
}

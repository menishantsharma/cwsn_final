class CwsnProfileModel {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String streetAddress;
  final String landmark;
  final String postalCode;
  final String phoneNumber;

  CwsnProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.streetAddress,
    required this.landmark,
    required this.postalCode,
    required this.phoneNumber,
  });

  factory CwsnProfileModel.fromJson(Map<String, dynamic> json) {
    return CwsnProfileModel(
      id: json['id'] as int,
      name: json['name'] as String,
      age: int.tryParse(json['age'].toString()) ?? 0,
      gender: json['gender'] as String,
      streetAddress: json['street_address'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
    );
  }
}

class CaregiverProfileModel {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String aboutMe;
  final String qualifications;
  final List<String> languages;

  CaregiverProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.aboutMe,
    required this.qualifications,
    required this.languages,
  });

  factory CaregiverProfileModel.fromJson(Map<String, dynamic> json) {
    return CaregiverProfileModel(
      id: json['id'] as int,
      name: json['name'] as String,
      age: int.tryParse(json['age'].toString()) ?? 0,
      gender: json['gender'] as String,
      aboutMe: json['about_me'] as String? ?? '',
      qualifications: json['qualifications'] as String? ?? '',
      languages: List<String>.from(json['languages'] ?? []),
    );
  }
}

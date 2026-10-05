class UserProfile {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> medications;
  final List<String> medicalHistory;
  final String preferredLanguage;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.bloodGroup,
    this.allergies = const [],
    this.medications = const [],
    this.medicalHistory = const [],
    this.preferredLanguage = 'en',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id']?.toString() ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    age: json['age'],
    gender: json['gender'],
    bloodGroup: json['blood_group'],
    allergies: List<String>.from(json['allergies'] ?? []),
    medications: List<String>.from(json['medications'] ?? []),
    medicalHistory: List<String>.from(json['medical_history'] ?? []),
    preferredLanguage: json['preferred_language'] ?? 'en',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'age': age,
    'gender': gender,
    'blood_group': bloodGroup,
    'allergies': allergies,
    'medications': medications,
    'medical_history': medicalHistory,
    'preferred_language': preferredLanguage,
  };
}

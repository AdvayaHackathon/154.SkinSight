class UserModel {
  final String uid;
  final String email;
  final String userType; // 'patient' or 'doctor'
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? doctorId; // For patients: the ID of their doctor
  final String? pid; // Patient ID (only for patients)
  final List<String>? patientIds; // For doctors: list of patient IDs
  final Map<String, dynamic>? additionalInfo;

  UserModel({
    required this.uid,
    required this.email,
    required this.userType,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.doctorId,
    this.pid,
    this.patientIds,
    this.additionalInfo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      userType: json['userType'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      doctorId: json['doctorId'],
      pid: json['pid'],
      patientIds: json['patientIds'] != null 
          ? List<String>.from(json['patientIds']) 
          : null,
      additionalInfo: json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'userType': userType,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'doctorId': doctorId,
      'pid': pid,
      'patientIds': patientIds,
      'additionalInfo': additionalInfo,
    };
  }
} 
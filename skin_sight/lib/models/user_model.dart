class UserModel {
  final String uid;
  final String email;
  final String userType; // 'patient' or 'doctor'
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final Map<String, dynamic>? additionalInfo;

  UserModel({
    required this.uid,
    required this.email,
    required this.userType,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
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
      'additionalInfo': additionalInfo,
    };
  }
} 
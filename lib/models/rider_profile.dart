
class RiderProfile {
  final String fullName;
  final String gender;
  final String contactNumber;
  final String email;
  final String dateOfBirth;
  final String? profileImagePath;

  const RiderProfile({
    this.fullName = '',
    this.gender = '',
    this.contactNumber = '',
    this.email = '',
    this.dateOfBirth = '',
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'gender': gender,
      'contactNumber': contactNumber,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'profileImagePath': profileImagePath,
    };
  }

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      fullName: json['fullName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      profileImagePath: json['profileImagePath'] as String?,
    );
  }

  RiderProfile copyWith({
    String? fullName,
    String? gender,
    String? contactNumber,
    String? email,
    String? dateOfBirth,
    String? profileImagePath,
    bool clearProfileImage = false,
  }) {
    return RiderProfile(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImagePath: clearProfileImage
          ? null
          : profileImagePath ?? this.profileImagePath,
    );
  }
}

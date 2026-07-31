class UserModel {
  final int? userId;
  final String username;
  final String email;
  final String? phone;
  final String? profileImage;
  final String role;
  final String status;
  final String? citizenId;
  final String? address;
  final String? documentStatus;
  final String? submissionDate;
  final String? documentImage;
  final List<String> interests;

  UserModel({
    this.userId,
    required this.username,
    required this.email,
    this.phone,
    this.profileImage,
    this.role = 'buyer',
    this.status = 'active',
    this.citizenId,
    this.address,
    this.documentStatus,
    this.submissionDate,
    this.documentImage,
    this.interests = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedInterests = [];
    if (json['interests'] != null) {
      if (json['interests'] is List) {
        parsedInterests = List<String>.from(json['interests']);
      } else if (json['interests'] is String) {
        parsedInterests = (json['interests'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return UserModel(
      userId: json['user_id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      profileImage: json['profile_image'],
      role: json['role'] ?? 'buyer',
      status: json['status'] ?? 'active',
      citizenId: json['citizen_id'],
      address: json['address'],
      documentStatus: json['document_status'],
      submissionDate: json['submission_date'],
      documentImage: json['document_image'],
      interests: parsedInterests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'role': role,
      'status': status,
      'citizen_id': citizenId,
      'address': address,
      'document_status': documentStatus,
      'submission_date': submissionDate,
      'document_image': documentImage,
      'interests': interests,
    };
  }

  UserModel copyWith({
    int? userId,
    String? username,
    String? email,
    String? phone,
    String? profileImage,
    String? role,
    String? status,
    String? citizenId,
    String? address,
    String? documentStatus,
    String? submissionDate,
    String? documentImage,
    List<String>? interests,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      status: status ?? this.status,
      citizenId: citizenId ?? this.citizenId,
      address: address ?? this.address,
      documentStatus: documentStatus ?? this.documentStatus,
      submissionDate: submissionDate ?? this.submissionDate,
      documentImage: documentImage ?? this.documentImage,
      interests: interests ?? this.interests,
    );
  }
}

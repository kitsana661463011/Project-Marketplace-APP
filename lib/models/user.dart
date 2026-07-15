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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}

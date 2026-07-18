import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? password;
  final String? photoBase64;
  final DateTime createdAt;
  final String? shopId;
  final String? role; // 'super_admin' | 'shop_admin' | 'shop_employee'

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.password,
    this.photoBase64,
    required this.createdAt,
    this.shopId,
    this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      password: map['password'],
      photoBase64: map['photoBase64'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shopId: map['shopId'],
      role: map['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'password': password,
      'photoBase64': photoBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'shopId': shopId,
      'role': role,
    };
  }
}

import 'dart:convert';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final DateTime createdAt;
  final String ageGroup;
  final String? imgUrl;
  final String? phoneNumber;
  final String? token;

  UserModel({
    required this.uid,
    this.imgUrl,
    this.phoneNumber,
    required this.createdAt,
    required this.email,
    required this.displayName,
    required this.role,
    required this.ageGroup,
    this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "displayName": displayName,
      "role": role,
      "ageGroup": ageGroup,
      "createdAt": createdAt.toIso8601String(),
      "token": token,
      "imgUrl": imgUrl,
      "phoneNumber": phoneNumber,
    };
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromMap(Map<String, dynamic> map) {
    String safeString(dynamic value) {
      if (value == null) return "";
      if (value is String) return value;
      return value.toString();
    }

    // Logic: Helper to look for 'ageGroup' or 'age_group' to prevent default error
    String getAgeGroup(Map<String, dynamic> m) {
      String val = safeString(m['ageGroup'] ?? m['age_group']);
      return val.isEmpty ? "6 - 8" : val;
    }

    if (map.containsKey('user') && map['user'] is Map) {
      final userMap = map['user'] as Map<String, dynamic>;
      return UserModel(
        uid: safeString(userMap['uid']),
        imgUrl: safeString(userMap['imgUrl']),
        phoneNumber: safeString(userMap['phoneNumber']),
        email: safeString(userMap['email']),
        displayName: safeString(userMap['displayName']),
        role: safeString(userMap['role']),
        ageGroup: getAgeGroup(userMap),
        createdAt: userMap['createdAt'] != null
            ? DateTime.tryParse(userMap['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        token: safeString(map['token']),
      );
    }

    return UserModel(
      uid: safeString(map['uid']),
      email: safeString(map['email']),
      displayName: safeString(map['displayName']),
      imgUrl: safeString(map['imgUrl']),
      phoneNumber: safeString(map['phoneNumber']),
      role: safeString(map['role']),
      ageGroup: getAgeGroup(map),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      token: safeString(map['token']),
    );
  }

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? ageGroup,
    DateTime? createdAt,
    String? imgUrl,
    String? phoneNumber,
    String? token,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      imgUrl: imgUrl ?? this.imgUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      ageGroup: ageGroup ?? this.ageGroup,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
    );
  }
}
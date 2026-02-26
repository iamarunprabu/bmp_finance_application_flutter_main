class User {
  final int? id;
  final String? userId;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? role;
  final List<String>? authorities;
  final bool? active;
  final bool? notLocked;
  final String? profileImageUrl;
  final DateTime? lastLoginDate;
  final DateTime? lastLoginDateDisplay;
  final DateTime? joinDate;

  User({
    this.id,
    this.userId,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.authorities,
    this.active,
    this.notLocked,
    this.profileImageUrl,
    this.lastLoginDate,
    this.lastLoginDateDisplay,
    this.joinDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: json['role'],
      authorities: json['authorities'] != null
          ? List<String>.from(json['authorities'])
          : null,
      active: json['active'],
      notLocked: json['notLocked'],
      profileImageUrl: json['profileImageUrl'],
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.tryParse(json['lastLoginDate'].toString())
          : null,
      lastLoginDateDisplay: json['lastLoginDateDisplay'] != null
          ? DateTime.tryParse(
              json['lastLoginDateDisplay'].toString())
          : null,
      joinDate: json['joinDate'] != null
          ? DateTime.tryParse(json['joinDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'authorities': authorities,
      'active': active,
      'notLocked': notLocked,
      'profileImageUrl': profileImageUrl,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'lastLoginDateDisplay':
          lastLoginDateDisplay?.toIso8601String(),
      'joinDate': joinDate?.toIso8601String(),
    };
  }
}

class LoginRequest {
  final String username;
  final String password;
  final String role;

  LoginRequest(this.username, this.password, this.role);

  Map<String, dynamic> toJson() => {
    "username": username,
    "password": password,
    "role": role,
  };
}

class LoginResponse {
  final String token;
  final String role;
  final String fName;
  final String lName;
  final int id;
  LoginResponse({
    required this.token,
    required this.role,
    required this.fName,
    required this.lName,
    required this.id,
  });

  // Map is the returned type from the api call , so can't direct assign the response to the model must map between then using this function
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final user = json['data']['user']; // drill into data.user
    final token = json['data']['accessToken']; // drill into data.accessToken
    return LoginResponse(
      token: token,
      role: user['role'],
      id: user['id'],
      fName: user['fName'],
      lName: user['lName'],
    );
  }
}

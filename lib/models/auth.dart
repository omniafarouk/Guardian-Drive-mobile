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
  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'],
    role: json['role'],
    id: json['id'],
    fName: json['fName'],
    lName: json['lName'],
  );
}

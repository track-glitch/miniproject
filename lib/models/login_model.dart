class LoginModel {
  String? username;
  String? password;
  String? usertype;

  LoginModel({
    this.username,
    this.password,
    this.usertype,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      username: json['username'],
      password: json['password'],
      usertype: json['usertype'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'usertype': usertype,
    };
  }
}

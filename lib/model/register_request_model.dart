class RegisterRequestModel {
  String? name;
  String? mobileNumber;
  String? email;
  String? organisationName;
  String? password;

  RegisterRequestModel(
      {this.name,
        this.mobileNumber,
        this.email,
        this.organisationName,
        this.password});

  RegisterRequestModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    mobileNumber = json['mobileNumber'];
    email = json['email'];
    organisationName = json['organisationName'];
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['mobileNumber'] = this.mobileNumber;
    data['email'] = this.email;
    data['organisationName'] = this.organisationName;
    data['password'] = this.password;
    return data;
  }
}
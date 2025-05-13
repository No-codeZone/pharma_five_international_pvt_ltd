class ResetPasswordRequestModel {
  String? email;
  String? otp;
  String? newPassword;

  ResetPasswordRequestModel({this.email, this.otp, this.newPassword});

  ResetPasswordRequestModel.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    otp = json['otp'];
    newPassword = json['newPassword'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['email'] = this.email;
    data['otp'] = this.otp;
    data['newPassword'] = this.newPassword;
    return data;
  }
}
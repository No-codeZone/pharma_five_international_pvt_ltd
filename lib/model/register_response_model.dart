class RegisterResponseModel {
  bool? success;
  String? message;
  Data? data;

  RegisterResponseModel({this.success, this.message, this.data});

  RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? sno;
  String? name;
  String? mobileNumber;
  String? email;
  String? organisationName;
  String? password;
  String? status;
  String? role;
  String? createdDatetime;
  String? updatedDatetime;

  Data(
      {this.sno,
        this.name,
        this.mobileNumber,
        this.email,
        this.organisationName,
        this.password,
        this.status,
        this.role,
        this.createdDatetime,
        this.updatedDatetime});

  Data.fromJson(Map<String, dynamic> json) {
    sno = json['sno'];
    name = json['name'];
    mobileNumber = json['mobileNumber'];
    email = json['email'];
    organisationName = json['organisationName'];
    password = json['password'];
    status = json['status'];
    role = json['role'];
    createdDatetime = json['createdDatetime'];
    updatedDatetime = json['updatedDatetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sno'] = this.sno;
    data['name'] = this.name;
    data['mobileNumber'] = this.mobileNumber;
    data['email'] = this.email;
    data['organisationName'] = this.organisationName;
    data['password'] = this.password;
    data['status'] = this.status;
    data['role'] = this.role;
    data['createdDatetime'] = this.createdDatetime;
    data['updatedDatetime'] = this.updatedDatetime;
    return data;
  }
}
class ViewEnquiryResponseModel {
  Data? data;
  String? responseMessage;
  int? responseCode;

  ViewEnquiryResponseModel(
      {this.data, this.responseMessage, this.responseCode});

  ViewEnquiryResponseModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    responseMessage = json['responseMessage'];
    responseCode = json['responseCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['responseMessage'] = this.responseMessage;
    data['responseCode'] = this.responseCode;
    return data;
  }
}

class Data {
  String? genericName;
  String? mobileNumber;
  String? email;
  String? organisationName;
  String? createdDatetime;

  Data(
      {this.genericName,
        this.mobileNumber,
        this.email,
        this.organisationName,
        this.createdDatetime});

  Data.fromJson(Map<String, dynamic> json) {
    genericName = json['genericName'];
    mobileNumber = json['mobileNumber'];
    email = json['email'];
    organisationName = json['organisationName'];
    createdDatetime = json['createdDatetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['genericName'] = this.genericName;
    data['mobileNumber'] = this.mobileNumber;
    data['email'] = this.email;
    data['organisationName'] = this.organisationName;
    data['createdDatetime'] = this.createdDatetime;
    return data;
  }
}
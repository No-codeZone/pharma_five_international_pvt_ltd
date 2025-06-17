class DeleteEnquiryResponseModel {
  DeleteEnquiryData? data;
  String? responseMessage;
  int? responseCode;

  DeleteEnquiryResponseModel(
      {this.data, this.responseMessage, this.responseCode});

  DeleteEnquiryResponseModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new DeleteEnquiryData.fromJson(json['data']) : null;
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

class DeleteEnquiryData {
  String? genericName;
  String? mobileNumber;
  String? email;
  String? organisationName;
  String? createdDatetime;
  int? read;
  int? status;

  DeleteEnquiryData(
      {this.genericName,
        this.mobileNumber,
        this.email,
        this.organisationName,
        this.createdDatetime,
        this.read,
        this.status});

  DeleteEnquiryData.fromJson(Map<String, dynamic> json) {
    genericName = json['genericName'];
    mobileNumber = json['mobileNumber'];
    email = json['email'];
    organisationName = json['organisationName'];
    createdDatetime = json['createdDatetime'];
    read = json['read'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['genericName'] = this.genericName;
    data['mobileNumber'] = this.mobileNumber;
    data['email'] = this.email;
    data['organisationName'] = this.organisationName;
    data['createdDatetime'] = this.createdDatetime;
    data['read'] = this.read;
    data['status'] = this.status;
    return data;
  }
}
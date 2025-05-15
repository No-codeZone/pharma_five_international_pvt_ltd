class ResponseEnquiryModel {
  Data? data;
  String? responseMessage;
  int? responseCode;

  ResponseEnquiryModel({this.data, this.responseMessage, this.responseCode});

  ResponseEnquiryModel.fromJson(Map<String, dynamic> json) {
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
  int? id;
  int? empId;
  int? productId;
  int? status;
  String? createdDatetime;

  Data(
      {this.id, this.empId, this.productId, this.status, this.createdDatetime});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    empId = json['empId'];
    productId = json['productId'];
    status = json['status'];
    createdDatetime = json['createdDatetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['empId'] = this.empId;
    data['productId'] = this.productId;
    data['status'] = this.status;
    data['createdDatetime'] = this.createdDatetime;
    return data;
  }
}